package Lemonldap::NG::Portal::AuthMulti;

use Lemonldap::NG::Portal::_Multi;

our $VERSION = '0.1';

sub authInit {
    my $self = shift;
    return $self->_multi->try('authInit',0);
}

sub extractFormInfo {
    my $self = shift;
    return $self->_multi->try('extractFormInfo',0);
}

sub setAuthSessionInfo {
    my $self = shift;
    return $self->_multi->try('setAuthSessionInfo',0);
}

sub authenticate {
    my $self = shift;
    return $self->_multi->try('authenticate',0);
}

1;

