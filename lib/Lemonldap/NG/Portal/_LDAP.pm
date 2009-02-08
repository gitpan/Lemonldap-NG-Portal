##@file
# LDAP common functions

##@class
# LDAP common functions
package Lemonldap::NG::Portal::_LDAP;

use Net::LDAP;
use base qw(Net::LDAP);

our $VERSION = '0.11';

## @cmethod Lemonldap::NG::Portal::_LDAP new(Lemonldap::NG::Portal::Simple portal)
# Build a Net::LDAP object using parameters issued from $portal
# @return Lemonldap::NG::Portal::_LDAP object
sub new {
    my $class  = shift;
    my $portal = shift;
    my $self;
    unless ($portal) {
        $class->abort("$class : portal argument required !");
    }
    my $useTls = 0;
    my $tlsParam;
    foreach my $server ( split /[\s,]+/, $portal->{ldapServer} ) {
        if ( $server =~ m{^ldap\+tls://([^/]+)/?\??(.*)$} ) {
            $useTls   = 1;
            $server   = $1;
            $tlsParam = $2 || "";
        }
        else {
            $useTls = 0;
        }
        last
          if $self = Net::LDAP->new(
            $server,
            port    => $portal->{ldapPort},
            onerror => undef,
          );
    }
    unless ($self) {
        print STDERR "$@\n";
        return 0;
    }
    bless $self, $class;
    if ($useTls) {
        my %h = split( /[&=]/, $tlsParam );
        $h{cafile} = $portal->{caFile} if ( $portal->{caFile} );
        $h{capath} = $portal->{caPath} if ( $portal->{caPath} );
        my $mesg = $self->start_tls(%h);
        if ( $mesg->code ) {
            print STDERR __PACKAGE__ . " StartTLS failed\n";
            return 0;
        }
    }
    $self->{portal} = $portal;
    return $self;
}

## @method Net::LDAP::Message bind(string dn, %args)
# Reimplementation of Net::LDAP::bind(). Connection is done :
# - with $dn and $args->{password} as dn/password if defined,
# - or with Lemonldap::NG account,
# - or with an anonymous bind.
# @param $dn LDAP distinguish name
# @param %args See Net::LDAP(3) manpage for more
# @return Net::LDAP::Message
sub bind {
    my $self = shift;
    my $mesg;
    my ( $dn, %args ) = @_;
    unless($dn) {
        $dn = $self->{portal}->{managerDn};
        $args{password} = $self->{portal}->{managerPassword};
    }
    if ( $dn && $args{password} ) {
        $mesg = $self->SUPER::bind( $dn, %args );
    }
    else {
        $mesg = $self->SUPER::bind();
    }
    return $mesg;
}

1;
