##@file
# DBI password backend file

##@class
# DBI password backend class
package Lemonldap::NG::Portal::PasswordDBDBI;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::AuthDBI;    #inherits
use base qw(Lemonldap::NG::Portal::_DBI );

#inherits Lemonldap::NG::Portal::_SMTP

our $VERSION = '0.992';

## @apmethod int passwordDBInit()
# Load SMTP functions and call DBI authInit()
# @return Lemonldap::NG::Portal constant
sub passwordDBInit {
    my $self = shift;
    eval { use base qw(Lemonldap::NG::Portal::_SMTP) };
    if ($@) {
        $self->lmLog( "Unable to load SMTP functions ($@)", 'error' );
        return PE_ERROR;
    }
    unless ( $self->{dbiPasswordMailCol} ) {
        $self->lmLog( "Missing configuration parameters for DBI password reset",
            'error' );
        return PE_ERROR;
    }
    return $self->Lemonldap::NG::Portal::AuthDBI::authInit();
}

## @apmethod int modifyPassword()
# Modify the password
# @return Lemonldap::NG::Portal constant
sub modifyPassword {
    my $self = shift;

    # Exit if no password change requested
    return PE_OK unless ( $self->{newpassword} );

    # Verify confirmation password matching
    return PE_PASSWORD_MISMATCH
      unless ( $self->{newpassword} eq $self->{confirmpassword} );

    # Connect
    my $dbh =
      $self->dbh( $self->{dbiAuthChain}, $self->{dbiAuthUser},
        $self->{dbiAuthPassword} );
    return PE_ERROR unless $dbh;

    my $user = $self->{sessionInfo}->{_user};

    # Check old passord
    if ( $self->{oldpassword} ) {

        # Password hash
        my $password =
          $self->hash_password( $self->{oldpassword},
            $self->{dbiAuthPasswordHash} );

        my $result = $self->check_password( $user, $password );

        unless ($result) {
            return PE_BADOLDPASSWORD;
        }
    }

    # Modify password
    my $password =
      $self->hash_password( $self->{newpassword},
        $self->{dbiAuthPasswordHash} );

    my $result = $self->modify_password( $user, $password );

    unless ($result) {
        return PE_ERROR;
    }

    $self->lmLog( "Password changed for $user", 'debug' );

    # Update password in session if needed
    my $infos;
    $infos->{_password} = $self->{newpassword};
    $self->updateSession($infos) if ( $self->{storePassword} );

    PE_PASSWORD_OK;
}

## @apmethod int resetPassword()
# Reset the password
# @return Lemonldap::NG::Portal constant
sub resetPassword {
    my $self = shift;

    # Exit method if no mail and mail_token
    return PE_OK unless ( $self->{mail} && $self->{mail_token} );

    $self->lmLog( "Reset password request for " . $self->{mail}, 'debug' );

    # Generate a complex password
    my $password = $self->gen_password( $self->{randomPasswordRegexp} );

    $self->lmLog( "Generated password: " . $password, 'debug' );

    # Modify password
    my $hpassword =
      $self->hash_password( $password, $self->{dbiAuthPasswordHash} );
    my $result =
      $self->modify_password( $self->{mail}, $hpassword,
        $self->{dbiPasswordMailCol} );

    return PE_ERROR unless $result;

    # Store password to forward it to the user
    $self->{reset_password} = $password;

    PE_OK;
}

1;
