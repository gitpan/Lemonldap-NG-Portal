##@file
# Choice user backend file

##@class
# Choice user backend class
package Lemonldap::NG::Portal::UserDBChoice;

use strict;
use Lemonldap::NG::Portal::_Choice;
use Lemonldap::NG::Portal::Simple;

#inherits Lemonldap::NG::Portal::_Choice

our $VERSION = '0.99';

## @apmethod int userDBInit()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub userDBInit {
    my $self = shift;
    return $self->_choice->try( 'userDBInit', 1 );
}

## @apmethod int getUser()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub getUser {
    my $self = shift;
    return $self->_choice->try( 'getUser', 1 );
}

## @apmethod int setSessionInfo()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my $self = shift;
    return $self->_choice->try( 'setSessionInfo', 1 );
}

## @apmethod int setGroups()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub setGroups {
    my $self = shift;
    return $self->_choice->try( 'setGroups', 1 );
}

1;
