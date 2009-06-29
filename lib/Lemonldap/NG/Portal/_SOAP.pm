## @file
# SOAP methods for Lemonldap::NG portal

## @class
# Add SOAP methods to the Lemonldap::NG portal.
package Lemonldap::NG::Portal::_SOAP;

use strict;
use Lemonldap::NG::Portal::Simple;
require SOAP::Lite;

our $VERSION = '0.1';

## @method void startSoapServices()
# Check the URI requested (PATH_INFO environment variable) and launch the
# corresponding SOAP methods using soapTest().
# If "soapOnly" is set, reject otehr request. Else, simply return.
sub startSoapServices {
    my $self = shift;
    $self->{CustomSOAPServices} ||= {};

    # TODO: insert here the SAML SOAP functions
    $self->{CustomSOAPServices}->{'/SAMLAuthority'} = '' if($self->{SAMLIssuer});
    if (
        $ENV{PATH_INFO}
        and my $tmp = {
            %{$self->{CustomSOAPServices}},
            '/sessions'      => 'getAttributes',
            '/adminSessions' => 'getAttributes setAttributes '
              . 'newSession deleteSession get_key_from_all_sessions',
            '/config'        => 'getConfig lastCfg'
        }->{ $ENV{PATH_INFO} }
      )
    {
        $self->soapTest($tmp);
        $self->{soapOnly} = 1;
    }
    else {
        $self->soapTest("getCookies error");
    }
    $self->abort( 'Bad request', 'Only SOAP requests are accepted here' )
      if ( $self->{soapOnly} );
}

####################
# SOAP subroutines #
####################

=begin WSDL

_IN user $string User name
_IN password $string Password
_RETURN $getCookiesResponse Response

=end WSDL

=cut

##@method SOAP::Data getCookies(string user,string password)
# Called in SOAP context, returns cookies in an array.
# This subroutine works only for portals working with user and password
#@param user uid
#@param password password
#@return session => { error => code , cookies => { cookieName1 => value ,... } }
sub getCookies {
    my $self = shift;
    $self->{error} = PE_OK;
    ( $self->{user}, $self->{password} ) = ( shift, shift );
    $self->lmLog( "SOAP authentication request for $self->{user}", 'debug' );
    unless ( $self->{user} && $self->{password} ) {
        $self->{error} = PE_FORMEMPTY;
    }
    else {
        $self->{error} = $self->_subProcess(
            qw(authInit userDBInit getUser setAuthSessionInfo setSessionInfo
              setMacros setGroups authenticate store buildCookie)
        );
    }
    my @tmp = ();
    push @tmp, SOAP::Data->name( error => $self->{error} );
    my @cookies = ();
    unless ( $self->{error} ) {
        foreach ( @{ $self->{cookie} } ) {
            push @cookies, SOAP::Data->name( $_->name, $_->value );
        }
    }
    else {
        my @cookieNames = split /\s+/, $self->{cookieName};
        foreach (@cookieNames) {
            push @cookies, SOAP::Data->name( $_, 0 );
        }
    }
    push @tmp, SOAP::Data->name( cookies => \SOAP::Data->value(@cookies) );
    my $res = SOAP::Data->name( session => \SOAP::Data->value(@tmp) );
    $self->updateStatus;
    return $res;
}

=begin WSDL

_IN id $string Cookie value
_RETURN $getAttributesResponse Response

=end WSDL

=cut

##@method SOAP::Data getAttributes(string id)
# Return attributes of the session identified by $id.
# @param $id Cookie value
# @return SOAP::Data sequence
sub getAttributes {
    my ( $self, $id ) = @_;
    die 'id is required' unless ($id);
    my $h = $self->getApacheSession( $id, 1 );
    my @tmp = ();
    unless ($h) {
        $self->_sub( 'userNotice',
            "SOAP attributes request: session $id not found" );
        push @tmp, SOAP::Data->name( error => 1 )->type('int');
    }
    else {
        $self->_sub( 'userInfo',
            "SOAP attributes request for " . $h->{ $self->{whatToTrace} } );
        push @tmp, SOAP::Data->name( error => 0 )->type('int');
        push @tmp,
          SOAP::Data->name( attributes =>
              _buildSoapHash( $h, split /\s+/, $self->{exportedAttr} ) );
        untie %$h;
    }
    my $res = SOAP::Data->name( session => \SOAP::Data->value(@tmp) );
    return $res;
}

## @method SOAP::Data setAttributes(string id,hashref args)
# Update datas in the session referenced by $id
# @param $id Id of the session
# @param $args datas to store
# @return true if succeed
sub setAttributes {
    my ( $self, $id, $args ) = @_;
    die 'id is required' unless ($id);
    my $h = $self->getApacheSession($id);
    unless ($h) {
        $self->lmLog( "Session $id does not exists ($@)", 'warn' );
        return 0;
    }
    $self->lmLog( "SOAP request to update session $id", 'debug' );
    $h->{$_} = $args->{$_} foreach ( keys %{$args} );
    untie %$h;
    return 1;
}

##@method SOAP::Data getConfig()
# Return Lemonldap::NG configuration. Warning, this is not a well formed
# SOAP::Data object so it can be difficult to read by other languages than
# Perl. It's not really a problem since this function is written to be read by
# Lemonldap::NG components and is not designed to be shared.
# @return hashref serialized in SOAP by SOAP::Lite
sub getConfig {
    my $self = shift;
    my $conf = $self->_getLmConf() or die("No configuration available");
    return $conf;
}

##@method int lastCfg()
# SOAP method that return the last configuration number.
# Call Lemonldap::NG::Common::Conf::lastCfg().
# @return Last configuration number
sub lastCfg {
    my $self = shift;
    return $self->{lmConf}->lastCfg();
}

##@fn private SOAP::Data _buildSoapHash()
# Serialize a hashref into SOAP::Data. Types are fixed to "string".
# @return SOAP::Data serialized datas
sub _buildSoapHash {
    my ( $h, @keys ) = @_;
    my @tmp = ();
    @keys = keys %$h unless (@keys);
    foreach (@keys) {
        if ( ref( $h->{$_} ) eq 'ARRAY' ) {
            push @tmp,
              SOAP::Data->name( $_, \SOAP::Data->value( @{ $h->{$_} } ) );
        }
        elsif ( ref( $h->{$_} ) ) {
            push @tmp, SOAP::Data->name( $_ => _buildSoapHash( $h->{$_} ) );
        }
        else {
            push @tmp, SOAP::Data->name( $_, $h->{$_} )->type('string')
              if ( defined( $h->{$_} ) );
        }
    }
    return \SOAP::Data->value(@tmp);
}

## @method SOAP::Data newSession(hashref args)
# Store a new session.
# @return Session datas
sub newSession {
    my ( $self, $args ) = @_;
    my $h = $self->getApacheSession();
    if ($@) {
        $self->lmLog( "Unable to create session", 'error' );
        return 0;
    }
    $h->{$_} = $args->{$_} foreach ( keys %{$args} );
    $h->{_utime} = time();
    $args->{$_} = $h->{$_} foreach ( keys %$h );
    untie %$h;
    $self->lmLog( "SOAP request to store $args->{_session_id} ($args->{uid})",
        'debug' );
    return SOAP::Data->name( attributes => _buildSoapHash($args) );
}

## @method SOAP::Data deleteSession()
# Deletes an existing session
sub deleteSession {
    my ( $self, $id ) = @_;
    die('id parameter is required') unless ($id);
    my $h = $self->getApacheSession($id);
    return 0 if ($@);
    $self->lmLog( "SOAP request to delete session $id", 'debug' );
    return $self->_deleteSession($h);
}

##@method SOAP::Data getConfig()
sub get_key_from_all_sessions {
    my $self = shift;
    shift;
    require Lemonldap::NG::Common::Apache::Session;

    #die $self->{globalStorage};
    my $tmp = $self->{globalStorage};
    no strict 'refs';
    return $self->{globalStorage}
      ->get_key_from_all_sessions( $self->{globalStorageOptions}, @_ );
    return &{"$tmp\::get_key_from_all_sessions"}( $self->{globalStorage},
        $self->{globalStorageOptions}, @_ );
}

1;

