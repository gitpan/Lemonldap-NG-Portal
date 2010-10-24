##@file
# DBI common functions

##@class
# DBI common functions
package Lemonldap::NG::Portal::_DBI;

use DBI;
use base qw(Exporter);
use Lemonldap::NG::Portal::Simple;
use strict;

our @EXPORT = qw(dbh);

our $VERSION = '0.992';

## @method protected Lemonldap::NG::Portal::_DBI dbh(string dbiChain, string dbiUser, string dbiPassword)
# Create connection to database
# @param dbiChain DBI connection chain
# @param dbiUser DBI connection user
# @param dbiPassword DBI connection password
# @return dbh object
sub dbh {
    my $self        = shift;
    my $dbiChain    = shift;
    my $dbiUser     = shift;
    my $dbiPassword = shift;
    my $dbh;

    # Open connection to database
    eval {
        $dbh =
          DBI->connect_cached( $dbiChain, $dbiUser, $dbiPassword,
            { RaiseError => 1, },
          );
    };
    if ($@) {
        $self->lmLog( "DBI connection error: $@", 'error' );
        return 0;
    }

    $self->{_dbh} = $dbh;
    return $dbh;
}

## @method protected Lemonldap::NG::Portal::_DBI hash_password(string password, string hash)
# Return hashed password for SQL SELECT WHERE clause
# @param password clear password
# @param hash hash mechanism
# @return hashed password
sub hash_password {
    my $self     = shift;
    my $password = shift;
    my $hash     = shift;

    if ( $hash =~ /^(md5|sha|sha1)$/i ) {
        $self->lmLog( "Using " . uc($hash) . " to hash password", 'debug' );
        return uc($hash) . "('$password')";
    }
    else {
        $self->lmLog( "No valid password hash, using clear text for password",
            'debug' );
        return $password;
    }

}

## @method protected Lemonldap::NG::Portal::_DBI check_password(string user, string password)
# Verify user and password with SQL SELECT
# @param user user
# @param password password
# @return boolean result
sub check_password {
    my $self        = shift;
    my $dbh         = shift;
    my $user        = $self->{user};
    my $password    = $self->{password};
    my $table       = $self->{dbiAuthTable};
    my $loginCol    = $self->{dbiAuthLoginCol};
    my $passwordCol = $self->{dbiAuthPasswordCol};

    # Password hash
    $password = $self->hash_password( $password, $self->{dbiAuthPasswordHash} );

    my @rows = ();
    eval {
        my $sth = $dbh->prepare(
            "SELECT $loginCol FROM $table WHERE $loginCol=? AND $passwordCol=?"
        );
        $sth->execute( $user, $password );
        @rows = $sth->fetchrow_array();
    };
    if ($@) {
        $self->lmLog( "DBI error: $@", 'error' );
        return 0;
    }

    if ( @rows == 1 ) {
        $self->lmLog( "One row returned by SQL query", 'debug' );
        return 1;
    }
    else {
        $self->lmLog( "Bad password for $user", 'error' );
        return 0;
    }

}

## @method protected Lemonldap::NG::Portal::_DBI modify_password(string user, string password, string userCol, string passwordCol)
# Modify password with SQL UPDATE
# @param user user
# @param password password
# @param userCol optional user column
# @param passwordCol optional password column
# @return boolean result
sub modify_password {
    my $self        = shift;
    my $user        = shift;
    my $password    = shift;
    my $userCol     = shift || $self->{dbiAuthLoginCol};
    my $passwordCol = shift || $self->{dbiAuthPasswordCol};

    my $table = $self->{dbiAuthTable};

    eval {
        my $sth =
          $self->{_dbh}
          ->prepare("UPDATE $table SET $passwordCol=? WHERE $userCol=?");
        $sth->execute( $password, $user );
    };
    if ($@) {
        $self->lmLog( "DBI password modification error: $@", 'error' );
        return 0;
    }

    return 1;
}

1;
