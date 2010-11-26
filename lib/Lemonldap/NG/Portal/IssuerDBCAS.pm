## @file
# CAS Issuer file

## @class
# CAS Issuer class
package Lemonldap::NG::Portal::IssuerDBCAS;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_CAS;
use base qw(Lemonldap::NG::Portal::_CAS);

our $VERSION = '1.0.0';

## @method void issuerDBInit()
# Nothing to do
# @return Lemonldap::NG::Portal error code
sub issuerDBInit {
    my $self = shift;

    return PE_OK;
}

## @apmethod int issuerForUnAuthUser()
# Manage CAS request for unauthenticated user
# @return Lemonldap::NG::Portal error code
sub issuerForUnAuthUser {
    my $self = shift;

    my $portal = $self->{portal};
    $portal =~ s/\/$//;

    # CAS URLs
    my $cas_login_url           = $portal . '/cas/login';
    my $cas_logout_url          = $portal . '/cas/logout';
    my $cas_validate_url        = $portal . '/cas/validate';
    my $cas_serviceValidate_url = $portal . '/cas/serviceValidate';
    my $cas_proxyValidate_url   = $portal . '/cas/proxyValidate';
    my $cas_proxy_url           = $portal . '/cas/proxy';

    # Called URL
    my $url = $self->url();

    # 1. LOGIN
    if ( $url =~ /\Q$cas_login_url\E/io ) {

        $self->lmLog( "URL $url detected as an CAS LOGIN URL", 'debug' );

        # GET parameters
        my $service = $self->getHiddenFormValue('service')
          || $self->param('service');
        my $renew = $self->getHiddenFormValue('renew') || $self->param('renew');
        my $gateway = $self->getHiddenFormValue('gateway')
          || $self->param('gateway');

        # Keep values in hidden fields
        $self->setHiddenFormValue( 'service', $service );
        $self->setHiddenFormValue( 'renew',   $renew );
        $self->setHiddenFormValue( 'gateway', $gateway );

        # Gateway
        if ( $gateway eq 'true' ) {

            # User should already be authenticated
            $self->lmLog(
                "Gateway authentication requested, but user is not logged in",
                'error' );

            # Redirect user to the service
            $self->lmLog( "Redirect user to $service", 'debug' );

            $self->{urldc} = $service;

            return $self->_subProcess(qw(autoRedirect));

        }

    }

    # 2. LOGOUT
    if ( $url =~ /\Q$cas_logout_url\E/io ) {

        $self->lmLog( "URL $url detected as an CAS LOGOUT URL", 'debug' );

        # GET parameters
        my $logout_url = $self->param('url');

        if ($logout_url) {

            # Display a link to the provided URL
            $self->lmLog( "Logout URL $logout_url will be displayed", 'debug' );

            $self->info(
                "<h3>"
                  . &Lemonldap::NG::Portal::_i18n::msg( PM_BACKTOCASURL,
                    $ENV{HTTP_ACCEPT_LANGUAGE} )
                  . "</h3>"
            );
            $self->info("<p><a href=\"$logout_url\">$logout_url</a></p>");
            $self->{activeTimer} = 0;

            return PE_CONFIRM;
        }

        return PE_LOGOUT_OK;

    }

    # 3. VALIDATE [CAS 1.0]
    if ( $url =~ /\Q$cas_validate_url\E/io ) {

        $self->lmLog( "URL $url detected as an CAS VALIDATE URL", 'debug' );

        # GET parameters
        my $service = $self->param('service');
        my $ticket  = $self->param('ticket');
        my $renew   = $self->param('renew');

        # Required parameters: service and ticket
        unless ( $service and $ticket ) {
            $self->lmLog( "Service and Ticket parameters required", 'error' );
            $self->returnCasValidateError();
        }

        $self->lmLog(
            "Get validate request with ticket $ticket for service $service",
            'debug' );

        my $casServiceSession = $self->getCasSession($ticket);

        unless ($casServiceSession) {
            $self->lmLog( "Service ticket session $ticket not found", 'error' );
            $self->returnCasValidateError();
        }

        $self->lmLog( "Service ticket session $ticket found", 'debug' );

        # Check service
        unless ( $service eq $casServiceSession->{service} ) {
            $self->lmLog(
                "Submitted service $service does not match initial service "
                  . $casServiceSession->{service},
                'error'
            );
            untie %$casServiceSession;
            $self->returnCasValidateError();
        }

        $self->lmLog( "Submitted service $service math initial servce",
            'debug' );

        # Check renew
        if ( $renew eq 'true' ) {

            # We should check the ST was delivered with primary credentials
            $self->lmLog( "Renew flag detected ", 'debug' );

            unless ( $casServiceSession->{renew} ) {
                $self->lmLog(
"Authentication renew requested, but not done in former authentication process",
                    'error'
                );
                untie %$casServiceSession;
                $self->returnCasValidateError();
            }
        }

        # Open local session
        my $localSession =
          $self->getApacheSession( $casServiceSession->{_cas_id}, 1 );

        unless ($localSession) {
            $self->lmLog(
                "Local session " . $casServiceSession->{_cas_id} . " notfound",
                'error'
            );
            untie %$casServiceSession;
            $self->returnCasValidateError();
        }

        # Get username
        my $username =
          $localSession->{ $self->{casAttr} || $self->{whatToTrace} };

        $self->lmLog( "Get username $username", 'debug' );

        # Close sessions
        untie %$casServiceSession;
        untie %$localSession;

        # Return success message
        $self->returnCasValidateSuccess($username);

        # We should not be there
        return PE_ERROR;
    }

    # 4. SERVICE VALIDATE [CAS 2.0]
    # 5. PROXY VALIDATE [CAS 2.0]
    if ( $url =~ /(\Q$cas_serviceValidate_url\E|\Q$cas_proxyValidate_url\E)/io )
    {

        my $urlType =
          ( $url =~ /\Q$cas_serviceValidate_url\E/ ? 'SERVICE' : 'PROXY' );

        $self->lmLog( "URL $url detected as an CAS $urlType VALIDATE URL",
            'debug' );

        # GET parameters
        my $service = $self->param('service');
        my $ticket  = $self->param('ticket');
        my $pgtUrl  = $self->param('pgtUrl');
        my $renew   = $self->param('renew');

        # PGTIOU
        my $casProxyGrantingTicketIOU;

        # Required parameters: service and ticket
        unless ( $service and $ticket ) {
            $self->lmLog( "Service and Ticket parameters required", 'error' );
            $self->returnCasServiceValidateError( 'INVALID_REQUEST',
                'Missing mandatory parameters (service, ticket)' );
        }

        $self->lmLog(
            "Get "
              . lc($urlType)
              . " validate request with ticket $ticket for service $service",
            'debug'
        );

        # Get CAS session corresponding to ticket
        if ( $urlType eq 'SERVICE' and !( $ticket =~ s/^ST-// ) ) {
            $self->lmLog( "Provided ticket is not a service ticket (ST)",
                'error' );
            $self->returnCasServiceValidateError( 'INVALID_TICKET',
                'Provided ticket is not a service ticket' );
        }
        elsif ( $urlType eq 'PROXY' and !( $ticket =~ s/^(P|S)T-// ) ) {
            $self->lmLog(
                "Provided ticket is not a service or proxy ticket ($1T)",
                'error' );
            $self->returnCasServiceValidateError( 'INVALID_TICKET',
                'Provided ticket is not a service or proxy ticket' );
        }

        my $casServiceSession = $self->getCasSession($ticket);

        unless ($casServiceSession) {
            $self->lmLog( "$urlType ticket session $ticket not found",
                'error' );
            $self->returnCasServiceValidateError( 'INVALID_TICKET',
                'Ticket not found' );
        }

        $self->lmLog( "$urlType ticket session $ticket found", 'debug' );

        # Check service
        unless ( $service eq $casServiceSession->{service} ) {
            $self->lmLog(
                "Submitted service $service does not match initial service "
                  . $casServiceSession->{service},
                'error'
            );

            # CAS protocol: invalidate ticket if service is invalid
            $self->deleteCasSession($casServiceSession);

            $self->returnCasServiceValidateError( 'INVALID_SERVICE',
                'Submitted service does not match initial service' );
        }

        $self->lmLog( "Submitted service $service match initial servce",
            'debug' );

        # Check renew
        if ( $renew eq 'true' ) {

            # We should check the ST was delivered with primary credentials
            $self->lmLog( "Renew flag detected ", 'debug' );

            unless ( $casServiceSession->{renew} ) {
                $self->lmLog(
"Authentication renew requested, but not done in former authentication process",
                    'error'
                );
                untie %$casServiceSession;
                $self->returnCasValidateError();
            }

        }

        # Proxies (for PROXY VALIDATE only)
        my $proxies = $casServiceSession->{proxies};

        # Proxy granting ticket
        if ($pgtUrl) {

            # Create a proxy granting ticket
            $self->lmLog(
                "Create a CAS proxy granting ticket for service $service",
                'debug' );

            my $casProxyGrantingSession = $self->getCasSession();

            if ($casProxyGrantingSession) {

                # PGT session
                $casProxyGrantingSession->{type}    = 'casProxyGranting';
                $casProxyGrantingSession->{service} = $service;
                $casProxyGrantingSession->{_cas_id} =
                  $casServiceSession->{_cas_id};
                $casProxyGrantingSession->{_utime} =
                  $casServiceSession->{_utime};

                # Trace proxies
                $casProxyGrantingSession->{proxies} = (
                      $proxies
                    ? $proxies . $self->{multiValuesSeparator} . $pgtUrl
                    : $pgtUrl
                );

                my $casProxyGrantingSessionID =
                  $casProxyGrantingSession->{_session_id};
                my $casProxyGrantingTicket =
                  "PGT-" . $casProxyGrantingSessionID;

                untie %$casProxyGrantingSession;

                $self->lmLog(
"CAS proxy granting session $casProxyGrantingSessionID created",
                    'debug'
                );

                # Generate the proxy granting ticket IOU
                my $tmpCasSession = $self->getCasSession();

                if ($tmpCasSession) {

                    $casProxyGrantingTicketIOU =
                      "PGTIOU-" . $tmpCasSession->{_session_id};
                    $self->deleteCasSession($tmpCasSession);
                    $self->lmLog(
"Generate proxy granting ticket IOU $casProxyGrantingTicketIOU",
                        'debug'
                    );

                    # Request pgtUrl
                    if (
                        $self->callPgtUrl(
                            $pgtUrl,
                            $casProxyGrantingTicketIOU,
                            $casProxyGrantingTicket
                        )
                      )
                    {
                        $self->lmLog(
                            "Proxy granting URL $pgtUrl called with success",
                            'debug' );
                    }
                    else {
                        $self->lmLog(
                            "Error calling proxy granting URL $pgtUrl",
                            'warn' );
                        $casProxyGrantingTicketIOU = undef;
                    }
                }

            }
            else {
                $self->lmLog(
                    "Error in proxy granting ticket management, bypass it",
                    'warn' );
            }
        }

        # Open local session
        my $localSession =
          $self->getApacheSession( $casServiceSession->{_cas_id}, 1 );

        unless ($localSession) {
            $self->lmLog(
                "Local session " . $casServiceSession->{_cas_id} . " notfound",
                'error'
            );
            untie %$casServiceSession;
            $self->returnCasServiceValidateError( 'INTERNAL_ERROR',
                'No session associated to ticket' );
        }

        # Get username
        my $username =
          $localSession->{ $self->{casAttr} || $self->{whatToTrace} };

        $self->lmLog( "Get username $username", 'debug' );

        # Close sessions
        untie %$casServiceSession;
        untie %$localSession;

        # Return success message
        $self->returnCasServiceValidateSuccess( $username,
            $casProxyGrantingTicketIOU, $proxies );

        # We should not be there
        return PE_ERROR;
    }

    # 6. PROXY [CAS 2.0]
    if ( $url =~ /\Q$cas_proxy_url\E/io ) {

        $self->lmLog( "URL $url detected as an CAS PROXY URL", 'debug' );

        # GET parameters
        my $pgt           = $self->param('pgt');
        my $targetService = $self->param('targetService');

        # Required parameters: pgt and targetService
        unless ( $pgt and $targetService ) {
            $self->lmLog( "Pgt and TargetService parameters required",
                'error' );
            $self->returnCasProxyError( 'INVALID_REQUEST',
                'Missing mandatory parameters (pgt, targetService)' );
        }

        $self->lmLog(
            "Get proxy request with ticket $pgt for service $targetService",
            'debug' );

        # Get CAS session corresponding to ticket
        unless ( $pgt =~ s/^PGT-// ) {
            $self->lmLog(
                "Provided ticket is not a proxy granting ticket (PGT)",
                'error' );
            $self->returnCasProxyError( 'BAD_PGT',
                'Provided ticket is not a proxy granting ticket' );
        }

        my $casProxyGrantingSession = $self->getCasSession($pgt);

        unless ($casProxyGrantingSession) {
            $self->lmLog( "Proxy granting ticket session $pgt not found",
                'error' );
            $self->returnCasProxyError( 'BAD_PGT', 'Ticket not found' );
        }

        $self->lmLog( "Proxy granting session $pgt found", 'debug' );

        # Create a proxy ticket
        $self->lmLog( "Create a CAS proxy ticket for service $targetService",
            'debug' );

        my $casProxySession = $self->getCasSession();

        unless ($casProxySession) {
            $self->lmLog( "Unable to create CAS proxy session", 'error' );
            $self->returnCasProxyError( 'INTERNAL_ERROR',
                'Error in proxy session management' );
        }

        $casProxySession->{type}    = 'casProxy';
        $casProxySession->{service} = $targetService;
        $casProxySession->{_cas_id} = $casProxyGrantingSession->{_cas_id};
        $casProxySession->{_utime}  = $casProxyGrantingSession->{_utime};
        $casProxySession->{proxies} = $casProxyGrantingSession->{proxies};

        my $casProxySessionID = $casProxySession->{_session_id};
        my $casProxyTicket    = "PT-" . $casProxySessionID;

        # Close sessions
        untie %$casProxySession;
        untie %$casProxyGrantingSession;

        $self->lmLog( "CAS proxy session $casProxySessionID created", 'debug' );

        # Return success message
        $self->returnCasProxySuccess($casProxyTicket);

        # We should not be there
        return PE_ERROR;
    }

    return PE_OK;
}

## @apmethod int issuerForAuthUser()
# Manage CAS request for unauthenticated user
# @return Lemonldap::NG::Portal error code
sub issuerForAuthUser {
    my $self = shift;

    my $portal = $self->{portal};
    $portal =~ s/\/$//;

    # CAS URLs
    my $cas_login_url           = $portal . '/cas/login';
    my $cas_logout_url          = $portal . '/cas/logout';
    my $cas_validate_url        = $portal . '/cas/validate';
    my $cas_serviceValidate_url = $portal . '/cas/serviceValidate';
    my $cas_proxyValidate_url   = $portal . '/cas/proxyValidate';
    my $cas_proxy_url           = $portal . '/cas/proxy';

    # Called URL
    my $url = $self->url();

    # Session ID
    my $session_id = $self->{sessionInfo}->{_session_id} || $self->{id};

    # Session creation timestamp
    my $time = $self->{sessionInfo}->{_utime} || time();

    # 1. LOGIN
    if ( $url =~ /\Q$cas_login_url\E/io ) {

        $self->lmLog( "URL $url detected as an CAS LOGIN URL", 'debug' );

        # GET parameters
        my $service = $self->getHiddenFormValue('service')
          || $self->param('service');
        my $renew = $self->getHiddenFormValue('renew') || $self->param('renew');
        my $gateway = $self->getHiddenFormValue('gateway')
          || $self->param('gateway');

        # Renew
        if ( $renew eq 'true' ) {

            # Authentication must be replayed
            $self->lmLog( "Authentication renew requested", 'debug' );
            $self->{updateSession} = 1;
            $self->{error}         = $self->_subProcess(
                qw(issuerDBInit authInit issuerForUnAuthUser extractFormInfo
                  userDBInit getUser setAuthSessionInfo setSessionInfo
                  setMacros setLocalGroups setGroups setPersistentSessionInfo
                  authenticate store authFinish)
            );

            # Return error if any
            if ( $self->{error} > 0 ) {
                $self->lmLog( "Error in authentication renew process",
                    'error' );
                return $self->{error};
            }
        }

        # If no service defined, exit
        unless ( defined $service ) {
            $self->lmLog( "No service defined in CAS URL", 'debug' );
            return PE_OK;
        }

        # Check last authentication time to decide if
        # the authentication is recent or not
        my $casRenewFlag = 0;
        my $last_authn_utime = $self->{sessionInfo}->{_lastAuthnUTime} || 0;
        if ( time() - $last_authn_utime < $self->{portalForceAuthnInterval} ) {
            $self->lmLog(
                "Authentication is recent, will set CAS renew flag to true",
                'debug' );
            $casRenewFlag = 1;
        }

        # Create a service ticket
        $self->lmLog( "Create a CAS service ticket for service $service",
            'debug' );

        my $casServiceSession = $self->getCasSession();

        unless ($casServiceSession) {
            $self->lmLog( "Unable to create CAS session", 'error' );
            return PE_ERROR;
        }

        $casServiceSession->{type}    = 'casService';
        $casServiceSession->{service} = $service;
        $casServiceSession->{renew}   = $casRenewFlag;
        $casServiceSession->{_cas_id} = $session_id;
        $casServiceSession->{_utime}  = $time;

        my $casServiceSessionID = $casServiceSession->{_session_id};
        my $casServiceTicket    = "ST-" . $casServiceSessionID;

        untie %$casServiceSession;

        $self->lmLog( "CAS service session $casServiceSessionID created",
            'debug' );

        # Redirect to service
        my $service_url = $service;
        $service_url .= (
            $service =~ /\?/
            ? '&ticket=' . $casServiceTicket
            : '?ticket=' . $casServiceTicket
        );

        $self->lmLog( "Redirect user to $service_url", 'debug' );

        $self->{urldc} = $service_url;

        return $self->_subProcess(qw(autoRedirect));
    }

    # 2. LOGOUT
    if ( $url =~ /\Q$cas_logout_url\E/io ) {

        $self->lmLog( "URL $url detected as an CAS LOGOUT URL", 'debug' );

        # GET parameters
        my $logout_url = $self->param('url');

        # Delete linked CAS sessions
        $self->deleteCasSecondarySessions($session_id);

        # Delete local session
        unless (
            $self->_deleteSession( $self->getApacheSession( $session_id, 1 ) ) )
        {
            $self->lmLog( "Fail to delete session $session_id ", 'error' );
        }

        if ($logout_url) {

            # Display a link to the provided URL
            $self->lmLog( "Logout URL $logout_url will be displayed", 'debug' );

            $self->info(
                "<h3>"
                  . &Lemonldap::NG::Portal::_i18n::msg( PM_BACKTOCASURL,
                    $ENV{HTTP_ACCEPT_LANGUAGE} )
                  . "</h3>"
            );
            $self->info("<p><a href=\"$logout_url\">$logout_url</a></p>");
            $self->{activeTimer} = 0;

            return PE_CONFIRM;
        }

        return PE_LOGOUT_OK;

    }

    # 3. VALIDATE [CAS 1.0]
    if ( $url =~ /\Q$cas_validate_url\E/io ) {

        $self->lmLog( "URL $url detected as an CAS VALIDATE URL", 'debug' );

        # This URL must not be called by authenticated users
        $self->lmLog(
            "CAS VALIDATE URL called by authenticated user, ignore it",
            'info' );

        return PE_OK;
    }

    # 4. SERVICE VALIDATE [CAS 2.0]
    if ( $url =~ /\Q$cas_serviceValidate_url\E/io ) {

        $self->lmLog( "URL $url detected as an CAS SERVICE VALIDATE URL",
            'debug' );

        # This URL must not be called by authenticated users
        $self->lmLog(
            "CAS SERVICE VALIDATE URL called by authenticated user, ignore it",
            'info'
        );

        return PE_OK;
    }

    # 5. PROXY VALIDATE [CAS 2.0]
    if ( $url =~ /\Q$cas_proxyValidate_url\E/io ) {

        $self->lmLog( "URL $url detected as an CAS PROXY VALIDATE URL",
            'debug' );

        # This URL must not be called by authenticated users
        $self->lmLog(
            "CAS PROXY VALIDATE URL called by authenticated user, ignore it",
            'info' );

        return PE_OK;
    }

    # 6. PROXY [CAS 2.0]
    if ( $url =~ /\Q$cas_proxy_url\E/io ) {

        $self->lmLog( "URL $url detected as an CAS PROXY URL", 'debug' );

        # This URL must not be called by authenticated users
        $self->lmLog( "CAS PROXY URL called by authenticated user, ignore it",
            'info' );

        return PE_OK;
    }

    return PE_OK;
}

## @apmethod int issuerLogout()
# Destroy linked CAS sessions
# @return Lemonldap::NG::Portal error code
sub issuerLogout {
    my $self = shift;

    # Session ID
    my $session_id = $self->{sessionInfo}->{_session_id} || $self->{id};

    # Delete linked CAS sessions
    $self->deleteCasSecondarySessions($session_id);

    return PE_OK;
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::IssuerDBCAS - CAS IssuerDB for LemonLDAP::NG

=head1 DESCRIPTION

CAS Issuer implementation in LemonLDAP::NG

=head1 SEE ALSO

L<Lemonldap::NG::Portal>,
L<http://www.jasig.org/cas/protocol>

=head1 AUTHOR

Clement OUDOT, E<lt>clement@oodo.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Clement OUDOT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
