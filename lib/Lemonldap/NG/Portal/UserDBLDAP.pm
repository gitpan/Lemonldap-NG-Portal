##@file
# LDAP user database backend file

##@class
# LDAP user database backend class
package Lemonldap::NG::Portal::UserDBLDAP;

use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_LDAP;

our $VERSION = '0.1';

## @method private Lemonldap::NG::Portal::_LDAP ldap()
# @return Lemonldap::NG::Portal::_LDAP object
sub ldap {
    my $self = shift;
    unless ( ref( $self->{ldap} ) ) {
        my $mesg = $self->{ldap}->bind
          if ( $self->{ldap} = Lemonldap::NG::Portal::_LDAP->new($self) );
        if ( $mesg->code != 0 ) {
            return 0;
        }
    }
    return $self->{ldap};
}

## @method int userDBInit()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub userDBInit {
    PE_OK;
}

## @method int getUser()
# 7) Launch formateFilter() and search()
# @return Lemonldap::NG::Portal constant
sub getUser {
    my $self = shift;
    return $self->_subProcess(qw(formateFilter search));
}

## @method int formateFilter()
# Set the LDAP filter.
# By default, the user is searched in the LDAP server with its UID.
# @return Lemonldap::NG::Portal constant
sub formateFilter {
    my $self = shift;
    $self->{filter} = $self->{authFilter} || $self->{filter} || "(&(uid=" . $self->{user} . ")(objectClass=inetOrgPerson))";
    PE_OK;
}

## @method int search()
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
        filter => $self->{filter},
    );
    if ( $mesg->code() != 0 ) {
        print STDERR $mesg->error . "\n";
        return PE_LDAPERROR;
    }
    return PE_BADCREDENTIALS unless ( $self->{entry} = $mesg->entry(0) );
    $self->{dn} = $self->{entry}->dn();
    PE_OK;
}

## @method int setSessionInfo()
# 7) Load all parameters included in exportedVars parameter.
# Multi-value parameters are loaded in a single string with
# '; ' separator
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my ($self) = @_;
    $self->{sessionInfo}->{dn} = $self->{dn};
    $self->{sessionInfo}->{startTime} =
      &POSIX::strftime( "%Y%m%d%H%M%S", localtime() );
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

1;

