##@file
# Demo password backend file

##@class
# Demo password backend class
package Lemonldap::NG::Portal::PasswordDBDemo;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.2.0';

## @apmethod int passwordDBInit()
# Check the use of AuthDemo
# @return Lemonldap::NG::Portal constant
sub passwordDBInit {
    my $self = shift;

    if ( $self->get_module('auth') eq 'Demo' ) {
        return PE_OK;
    }
    else {
        $self->lmLog( "Use PasswordDBDemo only with AuthDemo", 'error' );
        return PE_ERROR;
    }

    PE_OK;
}

## @apmethod int modifyPassword()
# Check old password and password mismatch
# @return Lemonldap::NG::Portal constant
sub modifyPassword {
    my $self = shift;

    # Exit if no password change requested
    return PE_OK unless ( $self->{newpassword} );

    # Verify confirmation password matching
    return PE_PASSWORD_MISMATCH
      unless ( $self->{newpassword} eq $self->{confirmpassword} );

    # Check old password
    if ( $self->{oldpassword} ) {

        # Old password must be the same as uid
        return PE_BADOLDPASSWORD
          if ( $self->{oldpassword} ne $self->{sessionInfo}->{uid} );
    }

    # Else accept all passwords
    # They will not be changed
    PE_OK;
}

1;
