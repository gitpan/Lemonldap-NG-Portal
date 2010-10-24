##@file
# Web form authentication backend file

##@class
# Web form authentication backend class
package Lemonldap::NG::Portal::_WebForm;

use Lemonldap::NG::Portal::Simple qw(:all);
use strict;

our $VERSION = '0.992';

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
    return PE_FIRSTACCESS
      unless ( $self->param('user') );
    return PE_FORMEMPTY
      unless (
        ( $self->{user} = $self->param('user') )
        && (   ( $self->{password} = $self->param('password') )
            || ( $self->{newpassword} = $self->param('newpassword') ) )
      );
    $self->{oldpassword}     = $self->param('oldpassword');
    $self->{confirmpassword} = $self->param('confirmpassword');
    $self->{timezone}        = $self->param('timezone');
    $self->{userControl} ||= '^[\w\.\-@]+$';
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
