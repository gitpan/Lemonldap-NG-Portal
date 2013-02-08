## @file
# Demo userDB mechanism

## @class
# Demo userDB mechanism class
package Lemonldap::NG::Portal::UserDBDemo;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.2.0';

## @apmethod int userDBInit()
# Check AuthDemo use
# @return Lemonldap::NG::Portal constant
sub userDBInit {
    my $self = shift;

    if ( $self->get_module('auth') eq 'Demo' ) {
        return PE_OK;
    }
    else {
        $self->lmLog( "Use UserDBDemo only with AuthDemo", 'error' );
        return PE_ERROR;
    }

    PE_OK;
}

## @apmethod int getUser()
# Check known accounts
# @return Lemonldap::NG::Portal constant
sub getUser {
    my $self = shift;

    return PE_USERNOTFOUND
      unless ( defined $self->{_demoAccounts}->{ $self->{user} } );

    PE_OK;
}

## @apmethod int setSessionInfo()
# Get sample data
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my $self = shift;

    foreach ( keys %{ $self->{exportedVars} } ) {
        $self->{sessionInfo}->{$_} =
          $self->{_demoAccounts}->{ $self->{user} }->{$_}
          || "";
    }

    PE_OK;
}

## @apmethod int setGroups()
# Do nothing
# @return Lemonldap::NG::Portal constant
sub setGroups {
    PE_OK;
}

1;

