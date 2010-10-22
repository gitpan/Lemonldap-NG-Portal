##@file
# LDAP user database backend file

##@class
# LDAP user database backend class
package Lemonldap::NG::Portal::UserDBLDAP;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_LDAP 'ldap';    #link protected ldap

our $VERSION = '0.991';

## @method int userDBInit()
# Transform ldapGroupAttributeNameSearch in ARRAY ref
# @return Lemonldap::NG::Portal constant
sub userDBInit {
    my $self = shift;

    unless ( ref $self->{ldapGroupAttributeNameSearch} eq 'ARRAY' ) {
        my @values = split( /\s/, $self->{ldapGroupAttributeNameSearch} );
        $self->{ldapGroupAttributeNameSearch} = \@values;
    }

    PE_OK;
}

## @apmethod int getUser()
# 7) Launch formateFilter() and search()
# @return Lemonldap::NG::Portal constant
sub getUser {
    my $self = shift;
    return $self->_subProcess(qw(formateFilter search));
}

## @apmethod protected int formateFilter()
# Set the LDAP filter.
# By default, the user is searched in the LDAP server with its UID.
# @return Lemonldap::NG::Portal constant
sub formateFilter {
    my $self = shift;
    $self->{LDAPFilter} =
        $self->{mail}
      ? $self->{mailLDAPFilter}
      : $self->{AuthLDAPFilter}
      || $self->{LDAPFilter};
    $self->lmLog( "LDAP submitted filter: " . $self->{LDAPFilter}, 'debug' )
      if ( $self->{LDAPFilter} );
    $self->{LDAPFilter} ||= '(&(uid=$user)(objectClass=inetOrgPerson))';
    $self->{LDAPFilter} =~ s/\$(user|_?password|mail)/$self->{$1}/g;
    $self->{LDAPFilter} =~ s/\$(\w+)/$self->{sessionInfo}->{$1}/g;
    $self->lmLog( "LDAP transformed filter: " . $self->{LDAPFilter}, 'debug' );
    PE_OK;
}

## @apmethod protected int search()
# Search the LDAP DN of the user.
# @return Lemonldap::NG::Portal constant
sub search {
    my $self = shift;
    unless ( $self->ldap ) {
        return PE_LDAPCONNECTFAILED;
    }
    my $mesg = $self->ldap->search(
        base   => $self->{ldapBase},
        scope  => 'sub',
        filter => $self->{LDAPFilter},
        (
            ref( $self->{exportedVars} )
            ? ( attrs => values( %{ $self->{exportedVars} } ) )
            : ()
        ),
    );
    $self->lmLog(
        'LDAP Search with base: '
          . $self->{ldapBase}
          . ' and filter: '
          . $self->{LDAPFilter},
        'debug'
    );
    if ( $mesg->code() != 0 ) {
        $self->lmLog( 'LDAP Search error: ' . $mesg->error, 'error' );
        return PE_LDAPERROR;
    }
    unless ( $self->{entry} = $mesg->entry(0) ) {
        my $user = $self->{mail} || $self->{user};
        $self->_sub( 'userError', "$user was not found in LDAP directory" );
        return PE_BADCREDENTIALS;
    }
    $self->{dn} = $self->{entry}->dn();
    PE_OK;
}

## @apmethod int setSessionInfo()
# 7) Load all parameters included in exportedVars parameter.
# Multi-value parameters are loaded in a single string with
# a separator (param multiValuesSeparator)
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my $self = shift;
    $self->{sessionInfo}->{dn} = $self->{dn};
    unless ( $self->{exportedVars} ) {
        foreach (qw(uid cn mail)) {
            $self->{sessionInfo}->{$_} =
              $self->{ldap}->getLdapValue( $self->{entry}, $_ ) || "";
        }
    }
    elsif ( ref( $self->{exportedVars} ) eq 'HASH' ) {
        foreach ( keys %{ $self->{exportedVars} } ) {
            $self->{sessionInfo}->{$_} =
              $self->{ldap}
              ->getLdapValue( $self->{entry}, $self->{exportedVars}->{$_} )
              || "";
        }
    }
    else {
        $self->abort('Only hash reference are supported now in exportedVars');
    }
    PE_OK;
}

## @apmethod int setGroups()
# Load all groups in $groups.
# @return Lemonldap::NG::Portal constant
sub setGroups {
    my $self   = shift;
    my $groups = $self->{sessionInfo}->{groups};

    if ( $self->{ldapGroupBase} ) {

        # Push group attribute value for recursive search
        push(
            @{ $self->{ldapGroupAttributeNameSearch} },
            $self->{ldapGroupAttributeNameGroup}
          )
          if (  $self->{ldapGroupRecursive}
            and $self->{ldapGroupAttributeNameGroup} ne "dn" );

        # Get value for group search
        my $group_value =
          $self->{ldap}
          ->getLdapValue( $self->{entry}, $self->{ldapGroupAttributeNameUser} );

        $self->lmLog(
            "Searching LDAP groups in "
              . $self->{ldapGroupBase}
              . " for $group_value",
            'debug'
        );

        # Call searchGroups
        $groups .= $self->{ldap}->searchGroups(
            $self->{ldapGroupBase}, $self->{ldapGroupAttributeName},
            $group_value,           $self->{ldapGroupAttributeNameSearch}
        );
    }

    $self->{sessionInfo}->{groups} = $groups;
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

    # Write in LDAP
    $self->lmLog( "Replace $key attribute in LDAP with value $value", 'debug' );
    my $modification =
      $self->{ldap}->modify( $self->{dn}, replace => { $key => $value } );

    # Check result
    if ( $modification->code ) {
        $self->lmLog(
            "LDAP error " . $modification->code . ": " . $modification->error,
            'error' );
        return 0;
    }

    return 1;
}

1;

