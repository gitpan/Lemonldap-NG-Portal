##@file
# Null password backend file

##@class
# Null password backend class
package Lemonldap::NG::Portal::PasswordDBNull;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.0.0';

## @apmethod int passwordDBInit()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub passwordDBInit {
    PE_OK;
}

## @apmethod int modifyPassword()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub modifyPassword {
    PE_OK;
}

## @apmethod int resetPassword()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub resetPassword {
    PE_OK;
}

1;
