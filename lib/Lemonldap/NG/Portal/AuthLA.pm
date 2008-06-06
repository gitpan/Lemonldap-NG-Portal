
#===============================================================================
# Liberty Alliance Authentication for LemonLDAP.
#-------------------------------------------------------------------------------
#
# This file is part of the LemonLDAP project and released under GPL.
#
#-------------------------------------------------------------------------------
# CHANGELOGS
#-------------------------------------------------------------------------------
# 2008-03-25 - Version 0.3
# Author(s) : Thomas CHEMINEAU
#   - Fixe some bugs into logout process from IDP or SP ;
#   - Add some checks into general algorithm ;
#
#===============================================================================

package Lemonldap::NG::Portal::AuthLA;

use strict;

use Lemonldap::NG::Portal::SharedConf qw(:all);
use lasso;
use CGI::Cookie;
use CGI::Session;
use HTTP::Request;
use HTTP::Response;
use LWP::UserAgent;
use MIME::Base64;
use XML::Simple;
use UNIVERSAL qw( isa can VERSION );

*EXPORT_OK   = *Lemonldap::NG::Portal::SharedConf::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::SharedConf::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::SharedConf::EXPORT;

our $VERSION = '0.31';
our @ISA     = qw(Lemonldap::NG::Portal::SharedConf) ;

#===============================================================================
# Global Constants
#===============================================================================

use constant {
        PE_LA_FAILED        => 11 ,
        PE_LA_ARTFAILED     => 12 ,
        PE_LA_DEFEDFAILED   => 13 ,
        PE_LA_QUERYEMPTY    => 14 ,
        PE_LA_SOAPFAILED    => 15 ,
        PE_LA_SLOFAILED     => 16 ,
        PE_LA_SSOFAILED     => 17 ,
        PE_LA_SSOINITFAILED => 18 ,
        PE_LA_SESSIONERROR  => 19 ,
        PE_LA_SEPFAILED     => 20 ,

        PC_LA_URLAC  => '/liberty/assertionConsumer.pl' ,
        PC_LA_URLFT  => '/liberty/federationTermination.pl' ,
        PC_LA_URLFTR => '/liberty/federationTerminationReturn.pl' ,
        PC_LA_URLSL  => '/liberty/singleLogout.pl' ,
        PC_LA_URLSLR => '/liberty/singleLogoutReturn.pl' ,
        PC_LA_URLSC  => '/liberty/soapCall.pl' ,
        PC_LA_URLSE  => '/liberty/soapEndpoint.pl' ,
};

#===============================================================================
#===============================================================================
#
# TODO
# ------------------------------------------------------------------------------
# - category / function : comments
# ------------------------------------------------------------------------------
# - association / store : Replace files by hastable or DBI implementation
# - security / process : Check if URL figures in locationRules
# - security / libertyFederationTermination : Implementation
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
    #   $self->_debug("parameter : $_ = " . $self->param($_)) ;
    # }
    # while(my($k,$v) = each(%ENV)) {
    #        $self->_debug("env : $k = $v") ;
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
        $self->updateStatus;
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

        # OK : $self->{urldc} is fixed at the end of this process.
        $self->_debug( "Logout user = '" . $self->{user} . "'" );

    # singleLogoutReturn
    }
    elsif ( $urldir eq $self->PC_LA_URLSLR ) {

        $self->{error} =
          $self->_subProcess(qw( libertySingleLogoutReturn log ));

    # soapCall
    }
    elsif ( $urldir eq $self->PC_LA_URLSC ) {

        $self->{error} = $self->_subProcess(qw( libertySoapCall log ));

    # soapEndpoint
    }
    elsif ( $urldir eq $self->PC_LA_URLSE ) {

        $self->{error} =
          $self->_subProcess(qw( libertySoapEndpoint log ));

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

    if ( $self->{error} ) {
        $self->updateStatus;
        return 0
    }

    # Liberty Process OK -> do Lemonldap::NG process.
    # TODO Warning, PE_OK==0 and process returns 0 if an error occurs!
    # my $err = $self->SUPER::process(@_);
    #return $err unless( $err != PE_OK );
    # TODO: Why ? log and  autoRedirect are executed with SUPER::process
    #$err = $self->_subProcess(qw( log autoRedirect ))
    #  if ( $self->{urldc} );
    #return $err;
    # So I think we have just to write this
    return $self->SUPER::process(@_);
}

#===============================================================================
# setSessionInfo
#===============================================================================
#
# After a valid auth assertion consumption, this function is called to init
# session info. If ID-WSF is enabled, get attributes from WebServices, else
# use the standard setSessionInfo (attributes read from LDAP).
#
# TODO: implement ID-WSF support
#
#===============================================================================

sub setSessionInfo {
    my $self = shift;

    # If ID-WSF enabled, use WebService 
    # TODO    

    # Else use SUPER::setSessionInfo
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

    return $err
      if ( $err != PE_OK or not $self->{isLibertyProcess} );

    return PE_LA_SESSIONERROR
      unless defined $self->{userNameIdentifier} ;

    return $self->_assertionSessionStore($self->{userNameIdentifier}) ;
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
            $refLocalStorage->purge();
        }
        else {
            $self->_debug("Deleting apache session failed");
        }
    }

    # Deleting association file, which is created when asserting consumer,
    # in store function.

    if ( $self->{sessionInfo}->{'laNameIdentifier'} )
    {
        return $self->_assertionSessionDelete(
                $self->{sessionInfo}->{'laNameIdentifier'}
            ) ;
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
# TODO
#
#===============================================================================

sub libertyFederationTermination {
    my $self = shift;

    # $self->_debug("Processing federation termination...");

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

        # $self->_debug("lassoDefederation->processNotificationMsg... OK");

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
# TODO 
#
#===============================================================================

sub libertyFederationTerminationReturn {
    my $self = @_;

    # $self->_debug("The Return of the federation termination...");
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

    # To retrieve current Liberty session, there is one way :
    #   - We have a query string that contains the userNameIdentifier.
    #     Then, we could retrieve apache session from cache files.

    return PE_LA_SESSIONERROR
      unless ( defined $self->{laStorageOptions}->{Directory} );

    return PE_OK
      unless ( defined $self->param('NameIdentifier') ) ;

    # Retrieve the Apache session ID.
    # It should not return any errors when trying to retrieve assertions.

    my $err = $self->_assertionSessionRetrieve($self->param('NameIdentifier')) ;

    # return PE_LA_SESSIONERROR
    #   unless $err == 0 ;

    # We can not rebuild factice cookie for Lemonldap::NG retrieving itself the
    # session. So, we retrieve here directly the session. This is the
    # Lemonldap::NG::Simple code of controlExistingSession function.

    my %h;
    eval {
        tie %h,
            $self->{globalStorage},
            $self->{id},
            $self->{globalStorageOptions} ;
    };

    if ( $@ or not tied(%h) ) {
        print STDERR
          "Session " . $self->{id} . " isn't yet available ($ENV{REMOTE_ADDR})\n";
        return PE_OK ;
    }

    %{ $self->{datas} } = %h ;
    untie(%h);

    my $r ;
    if ( $self->{existingSession} ) {
        $r = &{ $self->{existingSession} }(
                $self,
                $self->{id},
                $self->{datas}
            );
    }
    else {
        $r = $self->existingSession(
                $self->{id},
                $self->{datas}
            );
    }

    if ($r == PE_OK)
    {
        print STDERR "No existing liberty session found\n" ;
        return PE_OK ;
    }

    while ( my ( $k, $v ) = each( %{ $self->{datas} } ) )
    {
        $self->{sessionInfo}->{$k} = $v ;
    }

    if (defined $self->{sessionInfo}->{$self->{laLdapLoginAttribute}})
    {
        $self->{user} = $self->{sessionInfo}->{$self->{laLdapLoginAttribute}} ;
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

    $self->{userNameIdentifier} = $lassoLogin->{nameIdentifier}->{content} ;
    $self->{password}           = 'none' ;

    # Try to retrieve uid in SAML response form assertion statement.
    # For the moment, uid have to be unique in LDAP directory.

    my @uidValues =
      $self->_getAttributeValuesOfSamlAssertion(
        $lassoLogin->{response},
        $self->{laLdapLoginAttribute}
      ) ;

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
#         * Portal or applications requiere singleLogout -> SP request ;
#         * IDP requiere singleLogout -> IDP request with $ENV{'QUERY_STRING'}
#           specified.
#
# This function one optional parameter that specifies if the portal is called
# through a SOAP call.
#
#===============================================================================

sub libertySingleLogout {
    my $self = shift ;
    my $soap = shift ;

    my $lassoLogout = lasso::Logout->new( $self->{laServer} );
    return PE_LA_FAILED
      unless ( $lassoLogout
        and defined($lassoLogout)
        and defined $ENV{'QUERY_STRING'} );

    if ( lasso::isLibertyQuery($ENV{'QUERY_STRING'}) ) {

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

        # Confirm logout by soap request, only if portal is not already called
        # itself by a SOAP request.
        if ( defined $lassoLogout->{msgBody} && !$soap ) {
            my $soapResponseMsg = $self->_soapRequest( $lassoLogout->{msgUrl},
                $lassoLogout->{msgBody} ) ;
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
# TODO: Modify redirect to call handler logout configured in location directive
# (dedicated portal or handler, nor more relaystate need)
#
#
#===============================================================================

sub libertySingleLogoutReturn {
    my $self = shift;

    # Original code from Unwind :
    #
    # 8<--------
    #    logout = lasso.Logout(misc.get_lasso_server())
    #    try:
    #        logout.processResponseMsg(get_request().get_query())
    #    except lasso.Error, error:
    #        if error[0] == lasso.PROFILE_ERROR_INVALID_QUERY:
    #            raise AccessError()
    #        if error[0] == lasso.DS_ERROR_INVALID_SIGNATURE:
    #            return error_page(_('Failed to check single logout request signature.'))
    #        if hasattr(lasso, 'LOGOUT_ERROR_REQUEST_DENIED') and \
    #                error[0] == lasso.LOGOUT_ERROR_REQUEST_DENIED:
    #            # ignore silently
    #            return redirect(get_request().environ['SCRIPT_NAME'] + '/')
    #        elif error[0] == lasso.ERROR_UNDEFINED:
    #            # XXX: unknown status; ignoring for now.
    #            return redirect(get_request().environ['SCRIPT_NAME'] + '/')
    #        raise
    #    return redirect(get_request().environ['SCRIPT_NAME'] + '/')
    # 8<--------
    #
    # Normaly, if we are here, assertion and session should have been removed
    # in a previous request.

    $self->{lassoLogout} = lasso::Logout->new($self->{laServer}) ;

    return PE_LA_SLOFAILED
      unless $self->{lassoLogout} and defined($self->{lassoLogout}) ;

    if (my $error = $self->{lassoLogout}->processResponseMsg($ENV{'QUERY_STRING'}))
    {
        $self->_debug( "Process response message error = $error" ) ;
        return PE_LA_SLOFAILED ;
    }

    # Test if Lemonldap::NG cookie is available. If it is the case, the
    # corresponding session should be previously deleted.

    return PE_OK ;
}

#===============================================================================
# libertySoapCall
#===============================================================================
#
# IDP request defederation by SOAP calls.
#
# TODO
#
#===============================================================================

sub libertySoapCall {
    my $self = shift;

    $self->_debug("Soap call processing...");

    my $contentType = $ENV{'CONTENT_TYPE'};
    my $soapMsg     = $ENV{'QUERY_STRING'};

    return PE_LA_SOAPFAILED
      unless ( $contentType and $soapMsg and $contentType eq 'text/xml' );

    #$self->_debug("contentType: $contentType");
    #$self->_debug("soapMsg: $soapMsg");

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

    # $self->_debug("SoapEndpoint processing...");

    my $soapRequest = $self->param('POSTDATA');
    return PE_LA_SEPFAILED
      unless $soapRequest;

    my $soapRequestType = lasso::getRequestTypeFromSoapMsg($soapRequest);

    # $self->_debug("RequestType = $soapRequestType");

    # Logout SOAP request
    if ( $soapRequestType == $lasso::REQUEST_TYPE_LOGOUT ) {
        $ENV{'QUERY_STRING'} = $soapRequest;
        return $self->libertySingleLogout(1) ;

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
# _assertionSessionDelete
#===============================================================================
#
# Delete liberty assertion session.
# This function takes one parameter : the assertion identifier.
#
#===============================================================================

sub _assertionSessionDelete {
    my $self = shift ;
    my $assertionId = shift ;

    return PE_LA_SESSIONERROR
      unless (
        defined $self->{laStorage}
        and defined $self->{laStorageOptions} ) ;

    my $session = new CGI::Session(
            "driver:" . $self->{laStorage} . ";id:STATIC" ,
            $assertionId ,
            $self->{laStorageOptions}
        ) ;

    if ( defined $session )
    {
        $session->delete() ;
        $session->flush() ;
    }
    else
    {
        $self->_debug("Unable to delete assertion file\n") ;
        return PE_LA_SESSIONERROR ;
    }

    return PE_OK ;
}

#===============================================================================
# _assertionSessionRetrieve
#===============================================================================
#
# Get the Apache Session Identifier from the liberty assertion session. The
# result will be stored into the $self->{id} parameter, when PE_OK returned.
# This function takes one parameter : the assertion identifier.
#
#===============================================================================

sub _assertionSessionRetrieve {
    my $self = shift ;
    my $assertionId = shift ;

    return PE_LA_SESSIONERROR
      unless (
        defined $self->{laStorage}
        and defined $self->{laStorageOptions} ) ;

    my $session = new CGI::Session(
            "driver:" . $self->{laStorage} . ";id:STATIC" ,
            $assertionId ,
            $self->{laStorageOptions}
        ) ;

    if ( defined $session and defined $session->param('id') )
    {
        $self->{id} = $session->param('id') ;
    }
    else
    {
        $self->_debug("Unable to retrieve assertion file\n") ;
        return PE_LA_SESSIONERROR ;
    }

    return PE_OK ;
}

#===============================================================================
# _assertionSessionStore
#===============================================================================
#
# Store liberty assertion session.
# This function takes one parameter : the assertion identifier.
#
# We have to store association between Apache Session Identifier and Liberty
# Session Identifier. There is several solutions. A simple way will be to create
# a file named by userNameIdentifier from IDP, which contains session ID from
# Apache. The advanced one, which is used, is to manage simple CGI::Session to
# store the association.
#
#===============================================================================

sub _assertionSessionStore {
    my $self = shift ;
    my $assertionId = shift ;

    return PE_LA_SESSIONERROR
      unless (
        defined $self->{laStorage}
        and defined $self->{laStorageOptions} ) ;

    my $session = new CGI::Session(
            "driver:" . $self->{laStorage} . ";id:STATIC" ,
            $assertionId ,
            $self->{laStorageOptions}
        ) ;

    if ( defined $session and defined $self->{id} )
    {
        $session->param('id', $self->{id}) ;
        $session->flush() ;
    }
    else
    {
        $self->_debug("Unable to store assertion file\n") ;
        return PE_LA_SESSIONERROR ;
    }

    return PE_OK ;
}

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
    my $self          = shift ;
    my $samlp         = shift ;
    my $attributeName = shift ;
    my @tab = () ;

    # This function is in version alpha. The structure of the SAML assertion
    # depends of the source application. So, we decide to catch possible
    # exception due to parsing errors. So, if an error occurs, we just return
    # an empty table. BUT, the error has been logged.

    eval
    {
        # Search the specific attribute.

        my $attribute = undef ;

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

        # Then get values for this attribute.
        # Values are only lasso::MiscTextNode type.

        if (defined $attribute)
        {
            for (
                my $k = 0 ;
                $k < lasso::NodeList::length( $attribute->{attributeValue} ) ;
                $k++
              )
            {
                my $attributeValue =
                  lasso::NodeList::getItem( $attribute->{attributeValue}, $k );
                my $valueList = $attributeValue->{any};

                for ( my $l = 0 ; $l < lasso::NodeList::length($valueList) ; $l++ )
                {
                    my $value = lasso::NodeList::getItem( $valueList, $l );
                    push @tab, $value->{content}
                      if ( isa( $value, "lasso::MiscTextNode" ) );
                }
            }
        }

    } ; # end eval

    if ($@) {
        $self->_debug("SAML parsing errors : could not retrieve values for $attributeName attribute") ;
    }

    return @tab ;
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
Mikael Ates, E<lt>mikael.ates@univ-st-etienne.frE<gt>
Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

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

