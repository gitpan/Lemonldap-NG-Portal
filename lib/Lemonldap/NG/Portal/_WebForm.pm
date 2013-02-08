##@file
# Web form authentication backend file

##@class
# Web form authentication backend class
package Lemonldap::NG::Portal::_WebForm;

use Lemonldap::NG::Portal::Simple qw(:all);
use strict;

our $VERSION = '1.2.0';

## @apmethod int authInit()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authInit {
    PE_OK;
}

## @apmethod int extractFormInfo()
# Read username and password from POST datas
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;

    # Detect first access and empty forms
    my $defUser        = defined $self->param('user');
    my $defPassword    = defined $self->param('password');
    my $defOldPassword = defined $self->param('oldpassword');

    # 1. No user defined at all -> first access
    return PE_FIRSTACCESS unless $defUser;

    # 2. If user and password defined -> login form
    if ( $defUser && $defPassword ) {
        return PE_FORMEMPTY
          unless ( ( $self->{user} = $self->param('user') )
            && ( $self->{password} = $self->param('password') ) );
    }

    # 3. If user and oldpassword defined -> password form
    if ( $defUser && $defOldPassword ) {
        return PE_PASSWORDFORMEMPTY
          unless ( ( $self->{user} = $self->param('user') )
            && ( $self->{oldpassword}     = $self->param('oldpassword') )
            && ( $self->{newpassword}     = $self->param('newpassword') )
            && ( $self->{confirmpassword} = $self->param('confirmpassword') ) );
    }

    # Other parameters
    $self->{timezone} = $self->param('timezone');
    $self->{userControl} ||= '^[\w\.\-@]+$';

    # Check user
    return PE_MALFORMEDUSER unless ( $self->{user} =~ /$self->{userControl}/o );

    PE_OK;
}

## @apmethod int setAuthSessionInfo()
# Set password in session datas if wanted.
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    # authenticationLevel
    # -1 if password can be remebered
    # +1 for user/password with HTTPS
    $self->{_authnLevel} ||= 0;
    $self->{_authnLevel} += 1 if $self->https();
    $self->{_authnLevel} -= 1 if $self->{portalAutocomplete};

    $self->{sessionInfo}->{authenticationLevel} = $self->{_authnLevel};

    # Store user submitted login for basic rules
    $self->{sessionInfo}->{'_user'} = $self->{'user'};

    # Store submitted password if set in configuration
    # WARNING: it can be a security hole
    if ( $self->{storePassword} ) {
        $self->{sessionInfo}->{'_password'} = $self->{'newpassword'}
          || $self->{'password'};
    }

    # Store user timezone
    $self->{sessionInfo}->{'_timezone'} = $self->{'timezone'};

    PE_OK;
}

1;
