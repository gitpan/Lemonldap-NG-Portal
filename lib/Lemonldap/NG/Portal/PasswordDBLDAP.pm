##@file
# LDAP password backend file

##@class
# LDAP password backend class
package Lemonldap::NG::Portal::PasswordDBLDAP;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_LDAP 'ldap';    #link protected ldap
use Lemonldap::NG::Portal::UserDBLDAP;      #inherits

#inherits Lemonldap::NG::Portal::_SMTP

our $VERSION = '0.99.1';

*_formateFilter = *Lemonldap::NG::Portal::UserDBLDAP::formateFilter;
*_search        = *Lemonldap::NG::Portal::UserDBLDAP::search;

## @apmethod int passwordDBInit()
# Load SMTP functions
# @return Lemonldap::NG::Portal constant
sub passwordDBInit {
    my $self = shift;
    eval { use base qw(Lemonldap::NG::Portal::_SMTP) };
    if ($@) {
        $self->lmLog( "Unable to load SMTP functions ($@)", 'error' );
        return PE_ERROR;
    }
    PE_OK;
}

## @apmethod int modifyPassword()
# Modify the password by LDAP mechanism.
# @return Lemonldap::NG::Portal constant
sub modifyPassword {
    my $self = shift;

    # Exit method if no password change requested
    return PE_OK unless ( $self->{newpassword} );

    unless ( $self->ldap ) {
        return PE_LDAPCONNECTFAILED;
    }

    # Set the dn unless done before
    unless ( $self->{dn} ) {
        my $tmp = $self->_subProcess(qw(_formateFilter _search));
        return $tmp if ($tmp);
    }

    $self->lmLog( "Modify password request for " . $self->{dn}, 'debug' );

    # Call the modify password method
    my $code = $self->ldap->userModifyPassword(
        $self->{dn},              $self->{newpassword},
        $self->{confirmpassword}, $self->{oldpassword}
    );

    # Update password in session if needed
    my $infos;
    $infos->{_password} = $self->{newpassword};
    $self->updateSession($infos)
      if ( $self->{storePassword} and $code == PE_PASSWORD_OK );

    return $code;
}

## @apmethod int resetPassword()
# Reset the password
# @return Lemonldap::NG::Portal constant
sub resetPassword {
    my $self = shift;

    # Exit method if no mail and mail_token
    return PE_OK unless ( $self->{mail} && $self->{mail_token} );

    unless ( $self->ldap ) {
        return PE_LDAPCONNECTFAILED;
    }

    # Set the dn unless done before
    unless ( $self->{dn} ) {
        my $tmp = $self->_subProcess(qw(_formateFilter _search));
        return $tmp if ($tmp);
    }

    $self->lmLog( "Reset password request for " . $self->{dn}, 'debug' );

    # Generate a complex password
    my $password = $self->gen_password( $self->{randomPasswordRegexp} );

    $self->lmLog( "Generated password: " . $password, 'debug' );

    # Call the modify password method
    my $pe_error =
      $self->ldap->userModifyPassword( $self->{dn}, $password, $password );

    return $pe_error unless ( $pe_error == PE_PASSWORD_OK );

    # If Password Policy, set the PwdReset flag
    if ( $self->{ldapPpolicyControl} ) {
        my $result =
          $self->ldap->modify( $self->{dn},
            replace => { 'pwdReset' => 'TRUE' } );

        unless ( $result->code == 0 ) {
            $self->lmLog( "LDAP modify pwdReset error: " . $result->code,
                'error' );
            return PE_LDAPERROR;
        }

        $self->lmLog( "pwdReset set to TRUE", 'debug' );
    }

    # Store password to forward it to the user
    $self->{reset_password} = $password;

    PE_OK;
}

1;
