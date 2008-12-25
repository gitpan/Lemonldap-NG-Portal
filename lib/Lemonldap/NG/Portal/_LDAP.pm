package Lemonldap::NG::Portal::_LDAP;

use Net::LDAP;
use base qw(Net::LDAP);

our $VERSION = '0.1';

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
        my $mesg = $self->{ldap}->start_tls(%h);
        if ( $mesg->code ) {
            print STDERR __PACKAGE__ . " StartTLS failed\n";
            return 0;
        }
    }
    $self->{portal} = $portal;
    return $self;
}

# 6. LDAP bind with Lemonldap::NG account or anonymous unless defined
sub bind {
    my $self = shift;
    my $mesg;
    my ( $dn, %args ) = @_;
    $dn ||= $self->{portal}->{managerDn};
    $args{password} ||= $self->{portal}->{managerPassword};
    if ( $dn && $args{password} ) {
        $mesg = $self->SUPER::bind( $dn, %args );
    }
    else {
        $mesg = $self->SUPER::bind();
    }
    return $mesg;
}

1;
