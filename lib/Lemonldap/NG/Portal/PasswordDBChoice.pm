##@file
# Choice user backend file

##@class
# Choice user backend class
package Lemonldap::NG::Portal::PasswordDBChoice;

use strict;
use Lemonldap::NG::Portal::_Choice;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.2.2_01';

## @apmethod int passwordDBInit()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub passwordDBInit {
    my $self = shift;
    return $self->_choice->try( 'passwordDBInit', 2 );
}

## @apmethod int modifyPassword()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub modifyPassword {
    my $self = shift;
    return $self->_choice->try( 'modifyPassword', 2 );
}

1;
