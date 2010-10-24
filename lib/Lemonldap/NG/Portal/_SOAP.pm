## @file
# SOAP methods for Lemonldap::NG portal

## @class
# Add SOAP methods to the Lemonldap::NG portal.
package Lemonldap::NG::Portal::_SOAP;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_LibAccess;
require SOAP::Lite;
use Safe;
use constant SAFEWRAP => ( Safe->can("wrap_code_ref") ? 1 : 0 );
use base qw(Lemonldap::NG::Portal::_LibAccess);

our $VERSION = '0.992';

## @method void startSoapServices()
# Check the URI requested (PATH_INFO environment variable) and launch the
# corresponding SOAP methods using soapTest().
# If "soapOnly" is set, reject other request. Else, simply return.
sub startSoapServices {
    my $self = shift;

    # Load SOAP services
    $self->{CustomSOAPServices} ||= {};
    if (
        $ENV{PATH_INFO}
        and my $tmp = {
            %{ $self->{CustomSOAPServices} },
            '/sessions' =>
              'getCookies getAttributes isAuthorizedURI getMenuApplications',
            '/adminSessions' => 'getAttributes setAttributes isAuthorizedURI '
              . 'newSession deleteSession get_key_from_all_sessions',
            '/config' => 'getConfig lastCfg'
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

##@method SOAP::Data getCookies(string user,string password, string sessionid)
# Called in SOAP context, returns cookies in an array.
# This subroutine works only for portals working with user and password
#@param user uid
#@param password password
#@param sessionid optional session identifier
#@return session => { error => code , cookies => { cookieName1 => value ,... } }
sub getCookies {
    my ( $self, $user, $password, $sessionid ) = splice @_;
    $self->{user}     = $user;
    $self->{password} = $password;
    $self->{id}       = $sessionid if ( defined($sessionid) && $sessionid );
    $self->{error}    = PE_OK;
    $self->lmLog( "SOAP authentication request for $self->{user}", 'debug' );
    unless ( $self->{user} && $self->{password} ) {
        $self->{error} = PE_FORMEMPTY;
    }
    else {
        $self->{error} = $self->_subProcess(
            qw(authInit userDBInit getUser setAuthSessionInfo setSessionInfo
              setMacros setLocalGroups setGroups setPersistentSessionInfo authenticate
              removeOther grantSession store authFinish buildCookie)
        );
        $self->updateSession();
    }
    my @tmp = ();
    push @tmp, SOAP::Data->name( error => $self->{error} );
    my @cookies = ();
    unless ( $self->{error} ) {
        foreach ( @{ $self->{cookie} } ) {
            push @cookies, SOAP::Data->name( $_->name, $_->value );
        }
        push @cookies,
          SOAP::Data->name( $self->{cookieName} . 'update', time() );
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
    my ( $self, $id ) = splice @_;
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
    my ( $self, $id, $args ) = splice @_;
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

## @method SOAP::Data newSession(hashref args)
# Store a new session.
# @return Session datas
sub newSession {
    my ( $self, $args ) = splice @_;
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
    my ( $self, $id ) = splice @_;
    die('id parameter is required') unless ($id);
    my $h = $self->getApacheSession($id);
    return 0 if ($@);
    $self->lmLog( "SOAP request to delete session $id", 'debug' );
    return $self->_deleteSession($h);
}

##@method SOAP::Data get_key_from_all_sessions
# Returns key from all sessions
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

=begin WSDL

_IN id $string Cookie value
_IN uri $string URI to test
_RETURN $isAuthorizedURIResponse Response

=end WSDL

=cut

## @method boolean isAuthorizedURI (string id, string uri)
# Check user's authorization for uri.
# @param $id Id of the session
# @param $uri URL string
# @return True if granted
sub isAuthorizedURI {
    my $self = shift;
    my ( $id, $uri ) = @_;
    die 'id is required'  unless ($id);
    die 'uri is required' unless ($uri);

    # Get user session.
    my $h = $self->getApacheSession( $id, 1 );
    unless ($h) {
        $self->lmLog( "Session $id does not exists ($@)", 'warn' );
        return 0;
    }
    $self->{sessionInfo} = $h;
    my $r = $self->_grant($uri);
    untie %$h;
    return $r;
}

=begin WSDL

_IN id $string Cookie value
_RETURN $getMenuApplicationsResponse Response

=end WSDL

=cut

##@method SOAP::Data getMenuApplications(string id)
# @param $id Id of the session
#@return SOAP::Data
sub getMenuApplications {
    my ( $self, $id ) = splice @_;
    die 'id is required' unless ($id);

    $self->lmLog( "SOAP getMenuApplications request for id $id", 'debug' );

    # Get user session.
    my $h = $self->getApacheSession( $id, 1 );
    unless ($h) {
        $self->lmLog( "Session $id does not exists ($@)", 'warn' );
        return 0;
    }

    $self->{sessionInfo} = $h;
    return _buildSoapHash( { menu => $self->appslist() } );

}

#######################
# Private subroutines #
#######################

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

1;

