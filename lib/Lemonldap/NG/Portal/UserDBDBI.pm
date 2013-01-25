## @file
# DBI userDB mechanism

## @class
# DBI userDB mechanism class
package Lemonldap::NG::Portal::UserDBDBI;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_DBI;    #inherits

our $VERSION = '1.2.2_01';

## @apmethod int userDBInit()
# Set default values
# @return Lemonldap::NG::Portal constant
sub userDBInit {
    my $self = shift;

    # DBI access to user is the same as authentication by default
    $self->{dbiUserChain}    ||= $self->{dbiAuthChain};
    $self->{dbiUserUser}     ||= $self->{dbiAuthUser};
    $self->{dbiUserPassword} ||= $self->{dbiAuthPassword};
    $self->{dbiUserTable}    ||= $self->{dbiAuthTable};
    $self->{userPivot}       ||= $self->{dbiAuthLoginCol};

    PE_OK;
}

## @apmethod int getUser()
# Do nothing
# @return Lemonldap::NG::Portal constant
sub getUser {
    my $self = shift;

    # Connect
    my $dbh =
      $self->dbh( $self->{dbiUserChain}, $self->{dbiUserUser},
        $self->{dbiUserPassword} );
    return PE_ERROR unless $dbh;

    my $table = $self->{dbiUserTable};
    my $pivot = $self->{userPivot};
    my $user  = $self->{user};

    # If in mailProcess, adapt search criteriums
    if ( $self->{mail} ) {
        $pivot = $self->{dbiPasswordMailCol};
        $user  = $self->{mail};
    }

    $user =~ s/'/''/g;
    my $sth;

    eval {
        $sth = $dbh->prepare("SELECT * FROM $table WHERE $pivot=?");
        $sth->execute($user);
    };
    if ($@) {
        $self->lmLog( "DBI error: $@", 'error' );
        return PE_ERROR;
    }

    unless ( $self->{entry} = $sth->fetchrow_hashref() ) {
        $self->lmLog( "User $user not found", 'notice' );
        return PE_BADCREDENTIALS;
    }

    # In mail process, get user value
    if ( $self->{mail} ) {
        $table = $self->{dbiAuthTable};
        $pivot = $self->{dbiAuthLoginCol};
        $user  = $self->{entry}->{ $self->{userPivot} };
        eval {
            $sth = $dbh->prepare("SELECT * FROM $table WHERE $pivot=?");
            $sth->execute($user);
        };
        if ($@) {
            $self->lmLog( "DBI error: $@", 'error' );
            return PE_ERROR;
        }

        my $results;

        unless ( $results = $sth->fetchrow_hashref() ) {
            $self->lmLog( "User $user not found", 'notice' );
            return PE_BADCREDENTIALS;
        }

        $self->{user} = $results->{$pivot};
    }

    PE_OK;
}

## @apmethod int setSessionInfo()
# Get columns for each exportedVars
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my $self = shift;

    # Set _user unless already defined
    $self->{sessionInfo}->{_user} ||= $self->{user};

    # Return if no data to collect
    return PE_OK
      unless ( $self->{exportedVars}
        and ref( $self->{exportedVars} ) eq 'HASH' );

    while ( my ( $var, $attr ) = each %{ $self->{exportedVars} } ) {
        $self->{sessionInfo}->{$var} = $self->{entry}->{$attr}
          if ( defined $self->{entry}->{$attr} );
    }

    PE_OK;
}

## @apmethod int setGroups()
# Do nothing
# @return Lemonldap::NG::Portal constant
sub setGroups {
    PE_OK;
}

## @method boolean setUserDBValue(string key, string value)
# Store a value in UserDB
# @param key Key in user information
# @param value Value to store
# @return result
sub setUserDBValue {
    my ( $self, $key, $value ) = splice @_;

    # Mandatory attributes
    return 0 unless defined $key;

    # Write in database
    $self->lmLog( "Replace $key attribute in database with value $value",
        'debug' );

    # Connect
    my $dbh =
      $self->dbh( $self->{dbiUserChain}, $self->{dbiUserUser},
        $self->{dbiUserPassword} );
    return 0 unless $dbh;

    my $table = $self->{dbiUserTable};
    my $pivot = $self->{userPivot};
    my $user  = $self->{user};

    $user =~ s/'/''/g;
    my $sth;

    eval {
        $sth = $dbh->prepare("UPDATE $table SET $key = $value WHERE $pivot=?");
        $sth->execute($user);
    };

    # Check result
    if ($@) {
        $self->lmLog( "DBI error: $@", 'error' );
        return 0;
    }

    return 1;
}

1;

