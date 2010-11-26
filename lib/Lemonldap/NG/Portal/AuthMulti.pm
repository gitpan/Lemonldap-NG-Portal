## @file
# Authentication chaining mechanism

## @class
# Authentication chaining mechanism
package Lemonldap::NG::Portal::AuthMulti;

use Lemonldap::NG::Portal::_Multi;    #inherits

our $VERSION = '1.0.0';

sub authInit {
    my $self = shift;
    return $self->_multi->try( 'authInit', 0 );
}

sub extractFormInfo {
    my $self = shift;
    return $self->_multi->try( 'extractFormInfo', 0 );
}

sub setAuthSessionInfo {
    my $self = shift;
    return $self->_multi->try( 'setAuthSessionInfo', 0 );
}

sub authenticate {
    my $self = shift;
    return $self->_multi->try( 'authenticate', 0 );
}

sub authFinish {
    my $self = shift;
    return $self->_multi->try( 'authFinish', 0 );
}

sub authLogout {
    my $self = shift;
    return $self->_multi->try( 'authLogout', 0 );
}

sub authForce {
    my $self = shift;
    return $self->_multi->try( 'authForce', 0 );
}

1;

