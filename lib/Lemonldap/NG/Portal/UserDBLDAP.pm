##@file
# LDAP user database backend file

##@class
# LDAP user database backend class
package Lemonldap::NG::Portal::UserDBLDAP;

use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_LDAP 'ldap';    #link protected ldap

our $VERSION = '0.2';

## @method int userDBInit()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub userDBInit {
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
    );
    $self->lmLog(
        "LDAP Search with base: "
          . $self->{ldapBase}
          . " and filter: "
          . $self->{LDAPFilter},
        'debug'
    );
    if ( $mesg->code() != 0 ) {
        $self->lmLog( "LDAP Search error: " . $mesg->error, 'error' );
        return PE_LDAPERROR;
    }
    unless ( $self->{entry} = $mesg->entry(0) ) {
        $user = $self->{mail} || $self->{user};
        $self->_sub( 'userError', "$user was not found in LDAP directory" );
        return PE_BADCREDENTIALS;
    }
    $self->{dn} = $self->{entry}->dn();
    PE_OK;
}

## @apmethod int setSessionInfo()
# 7) Load all parameters included in exportedVars parameter.
# Multi-value parameters are loaded in a single string with
# '; ' separator
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my ($self) = @_;
    $self->{sessionInfo}->{dn} = $self->{dn};
    unless ( $self->{exportedVars} ) {
        foreach (qw(uid cn mail)) {
            $self->{sessionInfo}->{$_} =
              join( '; ', $self->{entry}->get_value($_) ) || "";
        }
    }
    elsif ( ref( $self->{exportedVars} ) eq 'HASH' ) {
        foreach ( keys %{ $self->{exportedVars} } ) {
            if ( my $tmp = $ENV{$_} ) {
                $tmp =~ s/[\r\n]/ /gs;
                $self->{sessionInfo}->{$_} = $tmp;
            }
            else {
                $self->{sessionInfo}->{$_} = join( '; ',
                    $self->{entry}->get_value( $self->{exportedVars}->{$_} ) )
                  || "";
            }
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
    my ($self) = @_;
    my $groups = $self->{sessionInfo}->{groups};

    $self->{ldapGroupObjectClass}         ||= "groupOfNames";
    $self->{ldapGroupAttributeName}       ||= "member";
    $self->{ldapGroupAttributeNameUser}   ||= "dn";
    $self->{ldapGroupAttributeNameSearch} ||= ["cn"];

    if (   $self->{ldapGroupBase}
        && $self->{sessionInfo}->{ $self->{ldapGroupAttributeNameUser} } )
    {
        my $searchFilter =
          "(&(objectClass=" . $self->{ldapGroupObjectClass} . ")(|";
        foreach (
            split(
                /[;]/,
                $self->{sessionInfo}->{ $self->{ldapGroupAttributeNameUser} }
            )
          )
        {
            $searchFilter .=
              "(" . $self->{ldapGroupAttributeName} . "=" . $_ . ")";
        }
        $searchFilter .= "))";
        my $mesg = $self->{ldap}->search(
            base   => $self->{ldapGroupBase},
            filter => $searchFilter,
            attrs  => $self->{ldapGroupAttributeNameSearch},
        );
        if ( $mesg->code() == 0 ) {
            foreach my $entry ( $mesg->all_entries ) {
                my $nbAttrs = @{ $self->{ldapGroupAttributeNameSearch} };
                for ( my $i = 0 ; $i < $nbAttrs ; $i++ ) {
                    my @data =
                      $entry->get_value(
                        $self->{ldapGroupAttributeNameSearch}[$i] );
                    if (@data) {
                        $groups .= $data[0];
                        $groups .= "|"
                          if (
                            $i + 1 < $nbAttrs
                            && $entry->get_value(
                                $self->{ldapGroupAttributeNameSearch}[ $i + 1 ]
                            )
                          );
                    }
                }
                $groups .= "; ";
            }
            $groups =~ s/; $//g;
        }
    }

    $self->{sessionInfo}->{groups} = $groups;
    PE_OK;
}

1;
