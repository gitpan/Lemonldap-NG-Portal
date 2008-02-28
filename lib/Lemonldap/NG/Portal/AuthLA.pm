
#===============================================================================
# Liberty Alliance Authentication for LemonLDAP.
#
# This file is part of the LemonLDAP project and released under GPL.
#===============================================================================

package Lemonldap::NG::Portal::AuthLA;

use strict;

use Lemonldap::NG::Portal::SharedConf qw(:all);
use lasso;
use CGI::Cookie;
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;
use MIME::Base64;
use XML::Simple;
use UNIVERSAL qw( isa can VERSION );

*EXPORT_OK   = *Lemonldap::NG::Portal::SharedConf::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::SharedConf::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::SharedConf::EXPORT;

our $VERSION = '0.2';
our @ISA     = qw(Lemonldap::NG::Portal::SharedConf);

#===============================================================================
# Global Constants
#===============================================================================

sub PE_LA_FAILED        { 11 }
sub PE_LA_ARTFAILED     { 12 }
sub PE_LA_DEFEDFAILED   { 13 }
sub PE_LA_QUERYEMPTY    { 14 }
sub PE_LA_SOAPFAILED    { 15 }
sub PE_LA_SLOFAILED     { 16 }
sub PE_LA_SSOFAILED     { 17 }
sub PE_LA_SSOINITFAILED { 18 }
sub PE_LA_SESSIONERROR  { 19 }
sub PE_LA_SEPFAILED     { 20 }

sub PC_LA_URLAC  { '/liberty/assertionConsumer.pl' }
sub PC_LA_URLFT  { '/liberty/federationTermination.pl' }
sub PC_LA_URLFTR { '/liberty/federationTerminationReturn.pl' }
sub PC_LA_URLSL  { '/liberty/singleLogout.pl' }
sub PC_LA_URLSLR { '/liberty/singleLogoutReturn.pl' }
sub PC_LA_URLSC  { '/liberty/soapCall.pl' }
sub PC_LA_URLSE  { '/liberty/soapEndpoint.pl' }

#===============================================================================
#===============================================================================
#
# TODO
# ------------------------------------------------------------------------------
# - category / function : comments
# ------------------------------------------------------------------------------
# - association / store : Replace files by hastable or DBI implementation
# - optimization / libertySignOn : Catching error when retrieving $providerID
# - optimization / _getAttributeValuesOfSamlAssertion : Checking errors
# - security / process : Check if URL figures in locationRules
# - security / libertyFederationTermination : Implementation
# - security / libertySoapEndpoint : Does Lemonldap::NG do defederation ?
# - wsf / setSessionInfo : Code for getting informations via wsf protocol
#
#===============================================================================
#===============================================================================

################################################################################
################################################################################
##                                                                            ##
##                      Lemonldap::NG::Portal functions                       ##
##                                                                            ##
################################################################################
################################################################################

#===============================================================================
# new
#===============================================================================
#
# Instanciate this class. This constructor takes special parameters with
# classical Lemonldap::NG::SharedConf parameters.
#
#===============================================================================

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->{isLibertyProcess} = 1;
    $self->{laDebug} = 0 unless ( $self->{laDebug} );

    die('No Liberty Alliance Service Provider data defined')
      unless ( $self->{laSp} );
    die('No Liberty Alliance Identity Provider file defined')
      unless ( $self->{laIdpsFile} );
    die('No laStorage configuration defined')
      unless ( $self->{laStorage} );
    die('No laLdapLoginAttribute configuration defined')
      unless ( $self->{laLdapLoginAttribute} );
    die('No localStorage configuration defined')
      unless ( $self->{localStorage} and $self->{localStorageOptions} );

    bless( $self, $class );

    # Create LassoServer

    $self->{laServer} = lasso::Server->new(
        $self->{laSp}->{metadata},
        $self->{laSp}->{privkey},
        undef,    #$self->{laSp}->{secretkey} ,
        undef,    #$self->{laSp}->{certificate} ,
    );

    $self->_loadXmlIdpFile();
    return $self;
}

#===============================================================================
# authenticate
#===============================================================================
#
# User is authenticated automatically, no ldap authentication.
#
#===============================================================================

sub authenticate {
    my $self = shift;
    return $self->SUPER::authenticate()
      unless ( $self->{isLibertyProcess} );
    return PE_BADCREDENTIALS
      unless ( defined $self->{user} );
    return PE_OK;
}

#===============================================================================
# extractFormInfo
#===============================================================================
#
# This function is just override to do nothing.
# $self->{user} is already fixed in libertySetSessionInfo function.
#
#===============================================================================

sub extractFormInfo {
    my $self = shift;
    return $self->SUPER::extractFormInfo()
      unless ( $self->{isLibertyProcess} );
    return PE_OK;
}

#===============================================================================
# formateFilter
#===============================================================================
#
# By default, the user is searched in the LDAP server with its UID. Here,
# $self->{user} contains nameIdentifier of the user, which is already stored
# in LDAP directory.
#
#===============================================================================

sub formateFilter {
    my $self = shift;
    return $self->SUPER::formateFilter()
      unless ( $self->{isLibertyProcess} );
    $self->{filter} =
      "(&(uid=" . $self->{user} . ")(objectClass=inetOrgPerson))";
    return PE_OK;
}

#===============================================================================
# process
#===============================================================================
#
# Do portal Lemonldap::NG processing. Actions based on Lemonldap::NG structure
# and philosophy.
#
#===============================================================================

sub process {
    my $self = shift;
    $self->{error} = PE_OK;

    # Trace param()
    # my @params = $self->param() ;
    # foreach( @params ) {
    # 	$self->_debug("parameter : $_ = " . $self->param($_)) ;
    # }
    # while(my($k,$v) = each(%ENV)) {
    # 	$self->_debug("env : $k = $v") ;
    # }

    #--------
    # Nothing to do if user access to portal directly. We have to verify if
    # user was redirected from a protected host.
    #--------

    my $url = $self->url();
    my $urlr = $url . substr( $ENV{'SCRIPT_NAME'}, 1 );

    if ( not $self->param('url')
        and ( $url eq $self->{portal} or $urlr eq $self->{portal} ) )
    {

        # TODO Security tricks :
        # - Check if URL figures in locationRules
        $self->{error} = PE_DONE;
        return $self->{error};
    }

    #--------
    # Authentication process
    #--------

    my $urldir = $self->url( -absolute => 1 );

    # assertionCustomer
    if ( $urldir eq $self->PC_LA_URLAC ) {

        $self->{error} = $self->_subProcess(
            qw( libertyAssertionConsumer libertySetSessionInfo ));

        $self->_debug( "Login user = '" . $self->{user} . "'" );

        # federationTermination
    }
    elsif ( $urldir eq $self->PC_LA_URLFT ) {

        $self->{error} = $self->_subProcess(
            qw( libertyFederationTermination log autoRedirect ));

        # federationTerminationReturn
    }
    elsif ( $urldir eq $self->PC_LA_URLFTR ) {

        $self->{error} = $self->_subProcess(
            qw( libertyFederationTerminationReturn log
              autoRedirect )
        );

        # singleLogout : called when IDP request Logout.
    }
    elsif ( $urldir eq $self->PC_LA_URLSL ) {

        $self->{error} = $self->_subProcess(
            qw( libertyRetrieveExistingSession libertySingleLogout
              libertyDeletingExistingSession )
        );

        $self->_debug( "Logout user = '" . $self->{'dn'} . "'" );

        # OK : $self->{urldc} is fixed at the end of this process.

        # singleLogoutReturn
    }
    elsif ( $urldir eq $self->PC_LA_URLSLR ) {

        $self->{error} =
          $self->_subProcess(qw( libertySingleLogoutReturn log autoRedirect ));

        # soapCall
    }
    elsif ( $urldir eq $self->PC_LA_URLSC ) {

        $self->{error} = $self->_subProcess(qw( libertySoapCall log ));

        # soapEndpoint
    }
    elsif ( $urldir eq $self->PC_LA_URLSE ) {

        $self->{error} =
          $self->_subProcess(qw( libertySoapEndpoint log autoRedirect ));

        # Direct access or simple access -> main
        # WARNING : we permit authentication on service.
    }
    elsif ( not $self->param('user') and not $self->param('password') and not $self->param('logout')) {

        $self->{error} = $self->_subProcess(
            qw( libertyRetrieveExistingSession
              libertyExtractFormInfo libertySignOn log
              autoRedirect )
        );

        # Not in liberty authentication process.
    }
    else {
        $self->{isLibertyProcess} = 0;
    }

    return 0
      if ( $self->{error} );

    # Liberty Process OK -> do Lemonldap::NG process.
    my $err = $self->SUPER::process(@_);
    return $err unless( $err != PE_OK );
    $err = $self->_subProcess(qw( log autoRedirect ))
      if ( $self->{urldc} );
    return $err;
}

#===============================================================================
# setSessionInfo
#===============================================================================
#
# Après une consommation d'assertion d'auth valide cette fonction est appelée
# pour initialiser les infos de session dans le cas où c'est le wsf qui est
# choisi pour récup les infos du user (sera par défaut en ldap).
#
# TODO :
# 	* Faire de cette fonction un override de setSessionInfo avec par défaut
#         le comportement de l'ancienne version et si dans la conf recup
#         attribut par wsf... recup en wsf2.0.
#
#===============================================================================

sub setSessionInfo {
    my $self = shift;

    # Si configuration fixée à WSF
    # Alors
    # 	Traitement de récupération des informations par WSF
    # Sinon
    # 	Traitement de récupération des informations en appelant la fonction
    # 	SUPER::setSessionInfo.

    # $self->{sessionInfo}->{dn} = "cn=tutu,ou=people,dc=example,dc=com" ;
    # $self->{sessionInfo}->{cn} = "tutu" ;
    # $self->{sessionInfo}->{mail} = "tutu@example;com" ;
    # $self->{sessionInfo}->{uid} = "ttutu" ;

    return $self->SUPER::setSessionInfo;
}

#===============================================================================
# store
#===============================================================================
#
# This function store existing association between userNameIdentifier from IDP
# and Apache session ID of Lemonldap::NG.
#
#===============================================================================

sub store {
    my $self = shift;

    my $err = $self->SUPER::store();
    return $err if ( $err != PE_OK or not $self->{isLibertyProcess} );

    return PE_APACHESESSIONERROR
      unless ( defined $self->{laStorageOptions}->{Directory}
        and defined $self->{id} );

    my $dir = $self->{laStorageOptions}->{Directory};
    $dir =~ s/(.*)\/?$/$1/;

    # We have to store association.
    # Create a file named by userNameIdentifier from IDP, single, which
    # contains session ID from Apache.

    if ( defined $self->{userNameIdentifier} ) {

        #my %h;
        #eval {
        #	tie %h, $self->{laStorage},
        #		substr($self->{userNameIdentifier},1),
        #		$self->{laStorageOptions};
        #};
        #if ( $@ ) {
        #	$self->_debug("$@\n");
        #	return PE_APACHESESSIONERROR;
        #}
        #$h{id} = $self->{id} ;
        #$h{_utime} = time();
        #untie %h;

        my $file = $dir . '/' . $self->{userNameIdentifier};
        $self->_debug("$file already exists : override association")
          if ( -e $file );
        open( MYFILE, '> ' . $file );
        print MYFILE $self->{id};
        close MYFILE;

        # In other case, we considere that store action failed.
        # So, we have to delete Apache session file.

    }
    else {
        my $file = $dir . '/' . $self->{id};
        unlink $file;
        return PE_APACHESESSIONERROR;
    }

    return PE_OK;
}

#===============================================================================
#===============================================================================

################################################################################
################################################################################
##                                                                            ##
##                       Some Data Access functions                           ##
##                                                                            ##
################################################################################
################################################################################

#===============================================================================
# getIdpURLs
#===============================================================================
#
# Returns all IDP URLs
#
#===============================================================================

sub getIdpIDs {
    my $self = shift;
    my @tab  = ();

    if ( $self->{laIdps} ) {
        push @tab, $_ foreach ( keys %{ $self->{laIdps} } );
    }

    return @tab;
}

#===============================================================================
#===============================================================================

################################################################################
################################################################################
##                                                                            ##
##                       Liberty Alliance functions                           ##
##                                                                            ##
################################################################################
################################################################################

#===============================================================================
# libertyArtefactResolution
#===============================================================================
#
# This function do Liberty artefact resolution. Verification is already made
# if this function is called, normaly it is authorized.
#
#===============================================================================

sub libertyArtefactResolution {
    my $self = shift;

    my $lassoLogin = undef;
    my $lassoHttpMethod =
      ( defined( $ENV{'REQUEST_METHOD'} ) and $ENV{'REQUEST_METHOD'} eq 'GET' )
      ? $lasso::HTTP_METHOD_REDIRECT
      : $lasso::HTTP_METHOD_POST;

    # Retrieve or create lassoLogin.

    if ( $self->{laLogin} and defined( $self->{laLogin} ) ) {
        $lassoLogin = $self->{laLogin};
    }
    else {
        $lassoLogin = lasso::Login->new( $self->{laServer} );
    }

    # POST

    if (    $lassoHttpMethod == $lasso::HTTP_METHOD_POST
        and $self->param('LARES') )
    {

        my $formLares = $self->param('LARES');

        if ( my $error = $lassoLogin->processAuthnResponseMsg($formLares) ) {
            $self->_debug("lassoLogin->initRequest(...) : error = $error");
            return PE_LA_ARTFAILED;
        }

        if ( my $error = $lassoLogin->acceptSso() ) {
            $self->_debug("lassoLogin->acceptSso(...) : error = $error");
            return PE_LA_SSOFAILED;
        }

        # GET : artefact is in QUERY_STRING param

    }
    elsif ( $lassoHttpMethod == $lasso::HTTP_METHOD_REDIRECT
        and defined $ENV{'QUERY_STRING'} )
    {

        # NOTES :
        #   Documentation indicates that $formLareq is QUERY_STRING HTTP
        #   header. We should have
        #     $formLareq = $self->param('QUERY_STRING').
        #   But initRequest method on lassoLogin returns -502 error code
        #   (LASSO_PARAM_ERROR_INVALID_VALUE) when QUERY_STRING is like
        #   'SAMLart=...&RelayState=...'. So, $formLareq is rebuild so
        #   that it only contains 'SAMLart=...'.

        my $formLareq = $ENV{'QUERY_STRING'};
        if ( $self->param('SAMLart') ) {
            $formLareq = 'SAMLart=' . $self->param('SAMLart');
        }

        if ( my $error = $lassoLogin->initRequest( $formLareq, $lassoHttpMethod ) ) {
            $self->_debug( "libertyArtefactResolution : lassoLogin->initRequest(...) : error = $error");
            return PE_LA_ARTFAILED;
        }

        if ( my $error = $lassoLogin->buildRequestMsg() ) {
            $self->_debug( "libertyArtefactResolution : lassoLogin->buildRequestMsg(...) : error = $error");
            return PE_LA_ARTFAILED;
        }

        # Check if SSO is OK
        # Successed = $soapResponseMsg contains code 200.

        my $soapResponseMsg =
          $self->_soapRequest( $lassoLogin->{msgUrl}, $lassoLogin->{msgBody} );

        if ( my $error = $lassoLogin->processResponseMsg($soapResponseMsg) ) {
            $self->_debug( "libertyArtefactResolution : lassoLogin->processResponseMsg(...) : error = $error");
            return PE_LA_SOAPFAILED;
        }

        if ( my $error = $lassoLogin->acceptSso() ) {
            $self->_debug( "libertyArtefactResolution : lassoLogin->acceptSso(...) : error = $error");
            return PE_LA_SSOFAILED;
        }

    }
    else {
        return PE_LA_SSOFAILED;
    }

    # Backup $lassoLogin object
    $self->{laLogin} = $lassoLogin;

    # Save RelayState.

    if ( $self->param('RelayState') ) {
        $self->{urldc} = $self->param('RelayState');
    }

    return PE_OK;
}

#===============================================================================
# libertyAssertionConsumption
#===============================================================================
#
# Realize assertion.
#
#===============================================================================

sub libertyAssertionConsumer {
    my $self = shift;

    $self->{laLogin} = lasso::Login->new( $self->{laServer} );

    return PE_LA_SSOFAILED
      unless ( $self->{laLogin}
        and defined( $self->{laLogin} )
        and defined( $self->param('SAMLart') ) );

    return $self->libertyArtefactResolution(@_);
}

#===============================================================================
# libertyDeletingExistingSession
#===============================================================================
#
# Delete existing Apache session file and Apache session ID <-> nameIdentifier
# association file.
#
#===============================================================================

sub libertyDeletingExistingSession {
    my $self = shift;

    # Deleting local cache session shared by all Lemonldap::NG::Handler.

    if ( $self->{datas} ) {
        my $refLocalStorage     = undef;
        my $localStorage        = $self->{localStorage};
        my $localStorageOptions = {};
        $localStorageOptions->{namespace}          ||= "lemonldap";
        $localStorageOptions->{default_expires_in} ||= 600;

        eval "use $localStorage;";
        die("Unable to load $localStorage: $@") if ($@);

        eval '$refLocalStorage = new '
          . $localStorage
          . '($localStorageOptions);';
        if ( defined $refLocalStorage ) {
            $refLocalStorage->remove( ${ $self->{datas} }{_session_id} );

            #$refLocalStorage->remove(substr($self->{userNameIdentifier},1)) ;
            $refLocalStorage->purge();
            $self->_debug("Deleting apache session succeed");
        }
        else {
            $self->_debug("Deleting apache session failed");
        }
    }

    # Deleting association file, which is created when asserting consumer,
    # in store function.

    if (    $self->{sessionInfo}->{'laNameIdentifier'}
        and $self->{globalStorageOptions}->{Directory} )
    {
        my $dir = $self->{globalStorageOptions}->{Directory};
        $dir =~ s/(.*)\/?$/$1/;
        my $file = $dir . '/' . $self->{sessionInfo}->{'laNameIdentifier'};

        if ( not unlink $file ) {
            $self->_debug("Deleting liberty-apache association file failed");
        }
        else {
            $self->_debug("Deleting liberty-apache association file succeed");
        }
    }

    return PE_OK;
}

#===============================================================================
# libertyExtractFormInfo
#===============================================================================
#
# Verify that user has choose a IDP for authentication.
#
#===============================================================================

sub libertyExtractFormInfo {
    my $self = shift;

    # If only one IDP -> redirect automatically on this IDP
    my $idp;
    my @idps = keys %{ $self->{laIdps} };
    if ( $#idps >= 0 && $self->param('idpChoice') ) {
        $idp = $self->param('idpChoice');
    }
    return PE_FIRSTACCESS
      unless $idp;
    $self->{idp}->{id} = $idp;
    return PE_OK;
}

#===============================================================================
# libertyFederationTermination
#===============================================================================
#
# Terminate federation.
#
# TO BE DONE.
#
#===============================================================================

sub libertyFederationTermination {
    my $self = shift;

    $self->_debug("Processing federation termination...");

    my $query = $ENV{'QUERY_STRING'};
    return PE_LA_QUERYEMPTY
      unless $query;

    if ( lasso::isLibertyQuery($query) ) {
        $self->{lassoDefederation} =
          lasso::Defederation->new( $self->{laServer} );

        return PE_LA_DEFEDFAILED
          unless ( $self->{lassoDefederation}
            and defined( $self->{lassoDefederation} )
            and $self->{lassoDefederation}->processNotificationMsg($query) );

        $self->_debug("lassoDefederation->processNotificationMsg... OK");

        # TODO :
        #   $self->fedTerm();

        return PE_OK;
    }
    return PE_DONE;
}

#===============================================================================
# libertyFederationTerminationReturn
#===============================================================================
#
# Quand cet appel ce produit t'il?
#
# TO BE DONE.
#
#===============================================================================

sub libertyFederationTerminationReturn {
    my $self = @_;

    $self->_debug("The Return of the federation termination...");
    $self->{urldc} = $self->{portal};
    return PE_OK;
}

#===============================================================================
# libertyRetrieveExistingSession
#===============================================================================
#
# Try to restore session whithin userNameIdentifier.
#
#===============================================================================

sub libertyRetrieveExistingSession {
    my $self = shift;

    # To retrieve current Liberty session, there are two ways :
    #   - 1/ We have Lemonldap::NG cookie. Then we have lassoLoginDump ;
    #   - 2/ We have a query string that contains the userNameIdentifier.
    #     Then, we could retrieve apache session from cache files.

    return PE_LA_SESSIONERROR
      unless ( defined $self->{laStorageOptions}->{Directory} );

    # TODO :
    #   Retrieve NameIdentifier by catching and parsing $ENV{'QUERY_STRING'}

    # 2/

    if ( $self->param('NameIdentifier') ) {

        # Retrieve apache session id from userNameIdentifier.
        # $id contains apache session id.

        my $dir = $self->{laStorageOptions}->{Directory};
        $dir =~ s/(.*)\/?$/$1/;
        my $file = $dir . '/' . $self->param('NameIdentifier');

        return PE_LA_SESSIONERROR
          unless ( open( MYFILE, $file ) );

        my $id = readline(*MYFILE);
        chomp($id);
        close(MYFILE);

        # We can not rebuild factice cookie for Lemonldap::NG retrieving
        # itself the session. So, we retrieve here directly the session.
        # Lemonldap::NG::Simple code of controlExistingSession function.

        # Trying to recover session from global session storage
        my %h;
        eval {
            tie %h, $self->{globalStorage}, $id, $self->{globalStorageOptions};
        };
        if ( $@ or not tied(%h) ) {

            # Session not available (expired ?)
            print STDERR
              "Session $id isn't yet available ($ENV{REMOTE_ADDR})\n";
            return PE_OK;
        }
        $self->{id} = $id;

        # A session has been find => calling &existingSession
        my $r;
        %{ $self->{datas} } = %h;
        untie(%h);
        if ( $self->{existingSession} ) {
            $r = &{ $self->{existingSession} }( $self, $id, $self->{datas} );
        }
        else {
            $r = $self->existingSession( $id, $self->{datas} );
        }

        # Save datas in sessionInfo.
        while ( my ( $k, $v ) = each( %{ $self->{datas} } ) ) {
            $self->{sessionInfo}->{$k} = $v;
        }

        $self->_debug("No existing liberty session found")
          unless ( $r == PE_OK );
    }

    return PE_OK;
}

#===============================================================================
# libertySetSessionInfo
#===============================================================================
#
# This function store in session cache information retrieve from IDP. If
# ID-WSF option is specified, it also store ID-WSF-attributes.
# In all cases, it fixes username of user who is authenticated on IDP.
#
#===============================================================================

sub libertySetSessionInfo {
    my $self = shift;

    return PE_LA_FAILED
      unless ( defined $self->{laLogin} );

    my $lassoLogin = $self->{laLogin};

    # Store identity in LDAP Directory, if identity not exists. Good
    # opportunity to ask user some more informations.

    return PE_LA_FAILED
      unless (
        defined $lassoLogin->{session}

        # and defined $lassoLogin->{identity}
        and $lassoLogin->{nameIdentifier}->{content}
      );

    # Here, we store liberty identity and session in Apache session.
    # We just store informations in cache, then those are saved by
    # store function. Saved nameIdentifier too.

    # $self->{sessionInfo}->{laIdentityDump} = $lassoLogin->{identity}->dump() ;
    $self->{sessionInfo}->{laSessionDump} = $lassoLogin->{session}->dump();
    $self->{sessionInfo}->{laNameIdentifier} =
      $lassoLogin->{nameIdentifier}->{content};

    # Get username from assertion and restore it in param('user'). Be
    # carefull, IDP does not return username but an id for user assertion.
    # The Lemonldap::NG search consists to perform a search with a filter
    # using nameIdentifier, instead of username.

    $self->{userNameIdentifier} = $lassoLogin->{nameIdentifier}->{content};
    $self->{user}               = $self->{userNameIdentifier};
    $self->{password}           = 'none';

    # Try to retrieve uid in SAML response form assertion statement.
    # For the moment, uid have to be unique in LDAP directory.
    my @uidValues =
      $self->_getAttributeValuesOfSamlAssertion( $lassoLogin->{response},
        $self->{laLdapLoginAttribute} );
    $self->{user} = $uidValues[0]
      if (@uidValues);

    return PE_OK;
}

#===============================================================================
# libertySignOn
#===============================================================================
#
# Init SSO request. If successfull, $self->{urldc} contains Liberty IDP Url
# for redirection.
#
#===============================================================================

sub libertySignOn {
    my $self = shift;

    my $lassoLogin = lasso::Login->new( $self->{laServer} );

    return PE_LA_FAILED
      unless ( $lassoLogin and defined($lassoLogin) );

    # TODO :
    #   Catching error when retrieving $providerID.

    my $providerID = $self->{LAidps}->{ $self->{idp}->{id} }->{url};

    if (
        my $error = $lassoLogin->initAuthnRequest(
            $providerID, $lasso::HTTP_METHOD_REDIRECT
        )
      )
    {
        $self->_debug("lassoLogin->initAuthnRequest(...) : error = $error");
        return PE_LA_SSOINITFAILED;
    }

    # We do one time federation, IDP doe not have to store nameIdentifier.

    $lassoLogin->{request}->{consent} = $lasso::LIB_CONSENT_OBTAINED;
    $lassoLogin->{request}->{nameIdPolicy} =
      $lasso::LIB_NAMEID_POLICY_TYPE_ONE_TIME;

    #$lassoLogin->{request}->{nameIdPolicy} = $lasso::LIB_NAMEID_POLICY_TYPE_FEDERATED ;
    $lassoLogin->{request}->{isPassive} = 0;

    if ( $self->param('url') ) {
        my $url = decode_base64( $self->param('url') );
        chomp $url;
        $lassoLogin->{request}->{relayState} = $url;
    }

    if ( my $error = $lassoLogin->buildAuthnRequestMsg() ) {
        $self->_debug("lassoLogin->buildAuthnRequestMsg(..) : error = $error");
        return PE_LA_SSOINITFAILED;
    }

    $self->{urldc} = $lassoLogin->{msgUrl};
    return PE_OK;
}

#===============================================================================
# libertySingleLogout
#===============================================================================
#
# Two cases :
# 	* Portal or applications requiere singleLogout -> SP request ;
# 	* IDP requiere singleLogout -> IDP request with $ENV{'QUERY_STRING'}
# 	  specified.
#
#===============================================================================

sub libertySingleLogout {
    my $self = shift;

    my $lassoLogout = lasso::Logout->new( $self->{laServer} );
    return PE_LA_FAILED
      unless ( $lassoLogout
        and defined($lassoLogout)
        and defined $ENV{'QUERY_STRING'} );

    if ( lasso::isLibertyQuery( $ENV{'QUERY_STRING'} ) ) {

        # We retrieve query string and verify it.
        # If it is OK, we set lemonldap::ng logout parameter, so we can perform
        # it in Lemonldap::NG normal process. Then, we remove our stored liberty
        # association file.

        $self->param( 'logout' => '1' );

        if ( my $error = $lassoLogout->processRequestMsg( $ENV{'QUERY_STRING'} ) ) {
            $self->_debug( "lassoLogout->processRequestMsg(...) : error = $error");
            return PE_LA_SLOFAILED;
        }

        # my $lassoIdentity = lasso::Identity::newFromDump($self->{sessionInfo}->{laIdentityDump}) ;
        # $lassoLogout->{identity} = $lassoIdentity ;
        my $lassoSession =
          lasso::Session::newFromDump( $self->{sessionInfo}->{laSessionDump} );
        $lassoLogout->{session} = $lassoSession;

        # Logout by soap call could failed with those two errors.
        if ( my $error = $lassoLogout->validateRequest() ) {
            if (    $error != $lasso::PROFILE_ERROR_SESSION_NOT_FOUND
                and $error != $lasso::PROFILE_ERROR_IDENTITY_NOT_FOUND )
            {
                $self->_debug( "lassoLogout->validateRequest(...) : error = $error");
                return PE_LA_SLOFAILED;
            }
        }

        if ( my $error = $lassoLogout->buildResponseMsg() ) {
            $self->_debug( "lassoLogout->buildResponseMsg(...) : error = $error");
            return PE_LA_SLOFAILED;
        }

        # Confirm logout by soap request
        if ( defined $lassoLogout->{msgBody} ) {
            my $soapResponseMsg = $self->_soapRequest( $lassoLogout->{msgUrl},
                $lassoLogout->{msgBody} );
        }
    }

    # Fixes redirection.
    $self->{urldc} = $lassoLogout->{msgUrl};

    # If $self->{urldc} empty, then we try to use HTTP referer if it exists
    $self->{urldc} = $ENV{'HTTP_REFERER'}
      if ( not $self->{urldc} and $ENV{'HTTP_REFERER'} );

    return PE_OK;
}

#===============================================================================
# libertySingleLogoutReturn
#===============================================================================
#
# SP provides singleLogout, it calls IDP which has done Liberty logout. Then IDP
# requests http://portal/liberty/singleLogoutReturn.
# Here, as there is no more liberty session on IDP, we suppress liberty session
# on Lemon.
#
# TODO : Modifier le redirect pour appeler le handler logout configuré dans la
# directive location (portal ou handler dédié, plus besoin du relaystate).
#
# TO BE DONE.
#
#===============================================================================

sub libertySingleLogoutReturn {
    my $self = shift;

    $self->{lassoLogout} = lasso::Logout->new( $self->{laServer} );
    return PE_LA_SLOFAILED
      unless ( $self->{lassoLogout} and defined( $self->{lassoLogout} ) );

    $self->_debug("Processing single logout return...");

    # Test if Lemonldap::NG cookie is available
    my %cookies = fetch CGI::Cookie;
    if ( $cookies{ $self->{cookieName} } and my $id = $cookies{ $self->{cookieName} }->value ) {
        $self->{session_nb} = $cookies{ $self->{cookieName} };
        $self->_debug("Cookie: $self->{cookieName} found...");
        $self->_debug("session number: $self->{session_nb}");
        my $query = $ENV{'QUERY_STRING'};
        return PE_LA_QUERYEMPTY unless $query;

        $self->_debug("Processing response message...");
        return PE_LA_SLOFAILED
          unless ( $self->{lassoLogout}->processResponseMsg($query) );

        $self->_debug("lassoLogout->processResponseMsg... OK");
        $self->delLibertySession();
        $self->_debug("delete liberty session... OK");
        my $formRelayState = $self->param('RelayState');
        return PE_LA_SLOFAILED
          unless ( $formRelayState and defined($formRelayState) );

        $self->_debug("formRelayState: $formRelayState");
        $self->{urldc} = $formRelayState . '/logout';
        return PE_OK;
    }
    return PE_LA_SLOFAILED;
}

#===============================================================================
# libertySoapCall
#===============================================================================
#
# IDP request defederation by SOAP calls.
#
# TO BE DONE.
#
#===============================================================================

sub libertySoapCall {
    my $self = shift;

    $self->_debug("Soap call processing...");

    my $contentType = $ENV{'CONTENT_TYPE'};
    my $soapMsg     = $ENV{'QUERY_STRING'};

    return PE_LA_SOAPFAILED
      unless ( $contentType and $soapMsg and $contentType eq 'text/xml' );

    $self->_debug("contentType: $contentType");
    $self->_debug("soapMsg: $soapMsg");

    my $requestType = lasso::getRequestTypeFromSoapMsg($soapMsg);

    # Logout request
    return $self->libertySingleLogout
      if ( $requestType eq $lasso::REQUEST_TYPE_LOGOUT );

    # Defederation request
    return $self->libertyFederationTermination
      if ( $requestType eq $lasso::REQUEST_TYPE_DEFEDERATION );

    return PE_DONE;
}

#===============================================================================
# libertySoapEndpoint
#===============================================================================
#
# Requests arrive in SOAP. We MUST traited them.
# Work as process function : call other functions.
#
#===============================================================================

sub libertySoapEndpoint {
    my $self = shift;

    $self->_debug("SoapEndpoint processing...");

    my $soapRequest = $self->param('POSTDATA');
    return PE_LA_SEPFAILED
      unless $soapRequest;

    my $soapRequestType = lasso::getRequestTypeFromSoapMsg($soapRequest);

    $self->_debug("RequestType = $soapRequestType");

    # Logout SOAP request
    if ( $soapRequestType == $lasso::REQUEST_TYPE_LOGOUT ) {
        $ENV{'QUERY_STRING'} = $soapRequest;
        return $self->libertySingleLogout();

        # Defederation SOAP request
    }
    elsif ( $soapRequestType == $lasso::REQUEST_TYPE_DEFEDERATION ) {

        # TODO
        # Lemonldap do defederation ?
    }

    return PE_OK;
}

#===============================================================================
#===============================================================================

################################################################################
################################################################################
##                                                                            ##
##                              Private functions                             ##
##                                                                            ##
################################################################################
################################################################################

#===============================================================================
# _getAttributeValuesOfSamlAssertion
#===============================================================================
#
# Retrieve attribute value from a SAMLP response specified in first parameter.
# Return a table of values corresponding to the attribute name specified in
# second parameter.
#
#===============================================================================

sub _getAttributeValuesOfSamlAssertion {
    my $self          = shift;
    my $samlp         = shift;
    my $attributeName = shift;
    my @tab           = ();

    # Search the specific attribute.

    my $attribute = undef;

    for (
        my $i = 0 ;
        not defined $attribute
        and $i < lasso::NodeList::length( $samlp->{assertion} ) ;
        $i++
      )
    {
        my $assertion = lasso::NodeList::getItem( $samlp->{assertion}, $i );
        my $attributeStatement = $assertion->{attributeStatement};

        for (
            my $j = 0 ;
            not defined $attribute
            and $j <
            lasso::NodeList::length( $attributeStatement->{attribute} ) ;
            $j++
          )
        {
            my $attr =
              lasso::NodeList::getItem( $attributeStatement->{attribute}, $j );

            if ( $attr->{attributeName} eq $attributeName ) {
                $attribute = $attr;
            }
        }
    }

    return @tab
      unless ( defined $attribute );

    # Then get values
    # Values are only lasso::MiscTextNode type.

    for (
        my $k = 0 ;
        $k < lasso::NodeList::length( $attribute->{attributeValue} ) ;
        $k++
      )
    {
        my $attributeValue =
          lasso::NodeList::getItem( $attribute->{attributeValue}, $k );
        my $valueList = $attributeValue->{any};
        for ( my $l = 0 ; $l < lasso::NodeList::length($valueList) ; $l++ ) {
            my $value = lasso::NodeList::getItem( $valueList, $l );
            push @tab, $value->{content}
              if ( isa( $value, "lasso::MiscTextNode" ) );
        }
    }

    return @tab;
}

#===============================================================================
# _loadXMLIdpFile
#===============================================================================
#
# Load Identity Providers file.
# File is a XML file which contains providers definition.
# Only one service provider for multiple identity provider.
#
#===============================================================================

sub _loadXmlIdpFile {
    my $self = shift;
    my $file = shift;

    my $xml = XML::Simple::XMLin( $self->{laIdpsFile}, ForceArray => ['idp'] );
    $self->{laIdps} = $xml->{idp};

    # Adding all IDPs in laIdpsFile in laServer.
    # Have to be done one time -> no choice : in constructor.

    foreach ( keys %{ $self->{laIdps} } ) {
        my $hash = $self->{laIdps}->{$_};
        $self->{laServer}->addProvider(
            $lasso::PROVIDER_ROLE_IDP, $hash->{'metadata'},
            $hash->{'pubkey'},         $hash->{'certificate'},
        );
    }
}

#===============================================================================
# _soapRequest
#===============================================================================
#
# Do soap request with only two parameters :
# - URI string ;
# - Body string ;
# Thus function return body's response message.
#
#===============================================================================

sub _soapRequest {
    my $self = shift;
    my ( $uri, $body ) = @_;

    my $soapHeaders = new HTTP::Headers( Content_Type => "text/xml" );
    my $soapRequest = new HTTP::Request( "POST", $uri, $soapHeaders, $body );
    my $soapAgent = LWP::UserAgent->new( agent => 'Mozilla/5.0 [en]' );
    my $soapResponse = $soapAgent->request($soapRequest);

    return $soapResponse->content();
}

#===============================================================================
# _debug
#===============================================================================
#
# Private tracing function.
#
#===============================================================================

sub _debug {
    my $self = shift;
    my $str  = shift;
    my (
        $package,   $filename, $line,       $subroutine, $hasargs,
        $wantarray, $evaltext, $is_require, $hints,      $bitmask
    ) = caller(1);
    print STDERR $subroutine . " : " . $str . "\n";
}

#===============================================================================
#===============================================================================

################################################################################
################################################################################
##                                                                            ##
##                               Documentation                                ##
##                                                                            ##
################################################################################
################################################################################

1;
__END__

=head1 NAME

Lemonldap::NG::Portal::AuthLA - Provide Liberty Alliance Authentication for
FederID project.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::AuthLA;
  my $portal = Lemonldap::NG::Portal::AuthLA->new({
    configStorage => {
      type => 'DBI',
      dbiChain => "dbi:mysql:...",
      dbiUser => "lemonldap",
      dbiPassword => "password",
      dbiTable => "lmConfig",
    } ,

    # Liberty Parameters
    laSp => {
      certificate => '/path/to/public/key.pem' ,
      metadata => '/path/to/metadata.xml' ,
      privkey => '/path/to/private/key.pem' ,
      secretkey => '/path/to/private/key.pem' ,
    } ,
    laIdpsFile => '/path/to/idps/file.xml' ,
    laStorage => 'Apache::Session::File',
    laStorageOptions => {
      Directory => '/path/to/session/directory' ,
      LockDirectory => '/path/to/lockedsession/directory' ,
    } ,
    laDebug => 1 ,
    laLdapLoginAttribute => 'uid' ,

    # Parameters that permit to access lemonldap::NG::Handler local cache
    localStorage            => 'Cache::FileCache' ,
    localStorageOptions     => {} ,
  });

  if( $portal->process() ) {
    # Print protected URLs
    print $portal->header ;
    print "<a href=\"http://$_\"> $_</a><br/>"
      foreach ($portal->getProtectedSites) ;

  } else {
    print $portal->header ;
    print '...' ;

    # Print simple template
    print 'Simple Authentication<br/>' ;
    print '<input type="hidden" name="url" value="' . $portal->param('url') . '"/>' ;
    print 'Login :' ;
    if ($portal->param('user')) {
      print '<input type="hidden" name="user" value="' . $portal->param('user') . '"/>' ;
    } else {
      print '<input type="hidden" name="user"/>' ;
    }
    print 'Password : <input name="password" type="password" autocomplete="off">' ;

    # Retrieve IDP list.
    my @idps = () ;
    foreach ($portal->getIdpIDs) {
      my %row_data ;
      $row_data{IDPNAME} = $_ ;
      push (@idps, \%row_data) ;
    }
    @idps = sort {$a cmp $b} @idps ;

    # Print SSO template
    print 'SSO Authentication<br/>' ;
    print '<select name="idpChoice"><option value="null">Select IDP</option>' ;
    foreach (@idps) {
      print '<option value="' . $_ . '">' . $_ . '</option>' ;
    }

    print '<input type="submit" value="ok" />' ;
    print '</form>' ;
  }

=head1 DESCRIPTION

Lemonldap::NG::Portal::AuthLA is the base module for building Lemonldap::NG
compatible portals using a authentication mechanism based on Liberty Alliance.
You have to use by inheritance.

=head1 SEE ALSO

L<Lemonldap::NG::Portal::SharedConf>, L<Lemonldap::NG::Portal>,
L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Manager>,
http://wiki.lemonldap.objectweb.org/xwiki/bin/view/NG/Presentation

=head1 AUTHOR

Clement Oudot, E<lt>coudot@linagora.comE<gt>
Mikaël Ates, E<lt>mikael.ates@univ-st-etienne.frE<gt>
Thomas Chemineau, E<lt>tchemineau@linagora.comE<gt>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://forge.objectweb.org/tracker/?group_id=274>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by FederID Consortium, E<lt>mail@FederIDE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

