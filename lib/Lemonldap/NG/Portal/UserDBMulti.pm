package Lemonldap::NG::Portal::UserDBMulti;

use Lemonldap::NG::Portal::_Multi;

our $VERSION = '0.1';

sub userDBInit {
    my $self = shift;
    return $self->_multi->try('userDBInit',1);
}

sub getUser {
    my $self = shift;
    return $self->_multi->try('getUser',1);
}

sub setSessionInfo {
    my $self = shift;
    return $self->_multi->try('setSessionInfo',1);
}

sub setGroups {
    my $self = shift;
    return $self->_multi->try('setGroups',1);
}

1;
