package Lemonldap::NG::Portal::_WebForm;

use Lemonldap::NG::Portal::Simple qw(:all);
use strict;

sub authInit {
    PE_OK;
}

sub extractFormInfo {
    my $self = shift;
    return PE_FIRSTACCESS
      unless ( $self->param('user') );
    return PE_FORMEMPTY
      unless ( length( $self->{'user'} = $self->param('user') ) > 0
        && length( $self->{'password'} = $self->param('password') ) > 0 );
    PE_OK;
}

sub setAuthSessionInfo {
    my $self = shift;

    # Store submitted password if set in configuration
    # WARNING: it can be a security hole
    if ( $self->{storePassword} ) {
        $self->{sessionInfo}->{'_password'} = $self->{'password'};
    }
    PE_OK;
}

1;
