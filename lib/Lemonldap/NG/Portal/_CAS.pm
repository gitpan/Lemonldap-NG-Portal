## @file
# Common CAS functions

## @class
# Common CAS functions
package Lemonldap::NG::Portal::_CAS;

use strict;
use LWP::UserAgent;

our $VERSION = '0.99';

## @method hashref getCasSession(string id)
# Try to recover the CAS session corresponding to id and return session datas
# If id is set to undef, return a new session
# @param id session reference
# @return session datas
sub getCasSession {
    my ( $self, $id ) = splice @_;
    my %h;

    # Trying to recover session from CAS session storage
    eval { tie %h, $self->{casStorage}, $id, $self->{casStorageOptions}; };
    if ( $@ or not tied(%h) ) {

        # Session not available
        if ($id) {
            $self->lmLog( "CAS session $id isn't yet available", 'info' );
        }
        else {
            $self->lmLog( "Unable to create new CAS session: $@", 'error' );
        }
        return 0;
    }

    return \%h;
}

## @method void returnCasValidateError()
# Return an error for CAS VALIDATE request
# @return nothing
sub returnCasValidateError {
    my ($self) = splice @_;

    $self->lmLog( "Return CAS validate error", 'debug' );

    print $self->header();
    print "no\n\n";

    $self->quit();
}

## @method void returnCasValidateSuccess(string username)
# Return success for CAS VALIDATE request
# @param username User name
# @return nothing
sub returnCasValidateSuccess {
    my ( $self, $username ) = splice @_;

    $self->lmLog( "Return CAS validate success with username $username",
        'debug' );

    print $self->header();
    print "yes\n$username\n";

    $self->quit();
}

## @method void returnCasServiceValidateError(string code, string text)
# Return an error for CAS SERVICE VALIDATE request
# @param code CAS error code
# @param text Error text
# @return nothing
sub returnCasServiceValidateError {
    my ( $self, $code, $text ) = splice @_;

    $code ||= 'INTERNAL_ERROR';
    $text ||= 'No description provided';

    $self->lmLog( "Return CAS service validate error $code ($text)", 'debug' );

    print $self->header( -type => 'application/xml' );
    print "<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>\n";
    print "\t<cas:authenticationFailure code=\"$code\">\n";
    print "\t\t$text\n";
    print "\t</cas:authenticationFailure>\n";
    print "</cas:serviceResponse>\n";

    $self->quit();
}

## @method void returnCasServiceValidateSuccess(string username, string pgtIou, string proxies)
# Return success for CAS SERVICE VALIDATE request
# @param username User name
# @param pgtIou Proxy granting ticket IOU
# @param proxies List of used CAS proxies
# @return nothing
sub returnCasServiceValidateSuccess {
    my ( $self, $username, $pgtIou, $proxies ) = splice @_;

    $self->lmLog( "Return CAS service validate success with username $username",
        'debug' );

    print $self->header( -type => 'application/xml' );
    print "<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>\n";
    print "\t<cas:authenticationSuccess>\n";
    print "\t\t<cas:user>$username</cas:user>\n";
    if ( defined $pgtIou ) {
        $self->lmLog( "Add proxy granting ticket $pgtIou in response",
            'debug' );
        print
          "\t\t<cas:proxyGrantingTicket>$pgtIou</cas:proxyGrantingTicket>\n";
    }
    if ($proxies) {
        $self->lmLog( "Add proxies $proxies in response", 'debug' );
        print "\t\t<cas:proxies>\n";
        print "\t\t\t<cas:proxy>$_</cas:proxy>\n"
          foreach ( split( /$self->{multiValuesSeparator}/, $proxies ) );
        print "\t\t</cas:proxies>\n";
    }
    print "\t</cas:authenticationSuccess>\n";
    print "</cas:serviceResponse>\n";

    $self->quit();
}

## @method void returnCasProxyError(string code, string text)
# Return an error for CAS PROXY request
# @param code CAS error code
# @param text Error text
# @return nothing
sub returnCasProxyError {
    my ( $self, $code, $text ) = splice @_;

    $code ||= 'INTERNAL_ERROR';
    $text ||= 'No description provided';

    $self->lmLog( "Return CAS proxy error $code ($text)", 'debug' );

    print $self->header( -type => 'application/xml' );
    print "<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>\n";
    print "\t<cas:proxyFailure code=\"$code\">\n";
    print "\t\t$text\n";
    print "\t</cas:proxyFailure>\n";
    print "</cas:serviceResponse>\n";

    $self->quit();
}

## @method void returnCasProxySuccess(string ticket)
# Return success for CAS PROXY request
# @param ticket Proxy ticket
# @return nothing
sub returnCasProxySuccess {
    my ( $self, $ticket ) = splice @_;

    $self->lmLog( "Return CAS proxy success with ticket $ticket", 'debug' );

    print $self->header( -type => 'application/xml' );
    print "<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>\n";
    print "\t<cas:proxySuccess>\n";
    print "\t\t<cas:proxyTicket>$ticket</cas:proxyTicket>\n";
    print "\t</cas:proxySuccess>\n";
    print "</cas:serviceResponse>\n";

    $self->quit();
}
## @method boolean deleteCasSecondarySessions(string session_id)
# Find and delete CAS sessions bounded to a primary session
# @param session_id Primary session ID
# @return result
sub deleteCasSecondarySessions {
    my ( $self, $session_id ) = splice @_;
    my $result = 1;

    # Find CAS sessions
    my $cas_sessions =
      $self->{casStorage}
      ->searchOn( $self->{casStorageOptions}, "_cas_id", $session_id );

    if ( my @cas_sessions_keys = keys %$cas_sessions ) {

        foreach my $cas_session (@cas_sessions_keys) {

            # Get session
            $self->lmLog( "Retrieve CAS session $cas_session", 'debug' );

            my $casSessionInfo = $self->getCasSession($cas_session);

            # Delete session
            $result = $self->deleteCasSession($casSessionInfo);
        }
    }
    else {
        $self->lmLog( "No CAS session found for session $session_id ",
            'debug' );
    }

    return $result;

}

## @method boolean deleteCasSession(hashref session)
# Delete an opened CAS session
# @param session Tied session object
# @return result
sub deleteCasSession {
    my ( $self, $session ) = splice @_;

    # Check session object
    unless ( ref($session) eq 'HASH' ) {
        $self->lmLog( "Provided session is not a HASH reference", 'error' );
        return 0;
    }

    # Get session_id
    my $session_id = $session->{_session_id};

    # Delete session
    eval { tied(%$session)->delete() };

    if ($@) {
        $self->lmLog( "Unable to delete CAS session $session_id: $@", 'error' );
        return 0;
    }

    $self->lmLog( "CAS session $session_id deleted", 'debug' );

    return 1;
}

## @method boolean callPgtUrl(string pgtUrl, string pgtIou, string pgtId)
# Call proxy granting URL on CAS client
# @param pgtUrl Proxy granting URL
# @param pgtIou Proxy granting ticket IOU
# @param pgtId Proxy granting ticket
# @return result
sub callPgtUrl {
    my ( $self, $pgtUrl, $pgtIou, $pgtId ) = splice @_;

    # LWP User Agent
    my $ua = new LWP::UserAgent;
    push @{ $ua->requests_redirectable }, 'POST';
    $ua->env_proxy();

    # Build URL
    my $url = $pgtUrl;
    $url .= ( $pgtUrl =~ /\?/ ? '&' : '?' );
    $url .= "pgtIou=$pgtIou&pgtId=$pgtId";

    $self->lmLog( "Call URL $url", 'debug' );

    # GET URL
    my $response = $ua->get($url);

    # Return result
    return $response->is_success();

}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::_CAS - Common CAS functions

=head1 SYNOPSIS

use Lemonldap::NG::Portal::_CAS;

=head1 DESCRIPTION

This module contains common methods for CAS

=head1 METHODS

=head2 getCasSession

Try to recover the CAS session corresponding to id and return session datas
If id is set to undef, return a new session

=head2 returnCasValidateError

Return an error for CAS VALIDATE request

=head2 returnCasValidateSuccess

Return success for CAS VALIDATE request

=head2 deleteCasSecondarySessions

Find and delete CAS sessions bounded to a primary session

=head2 returnCasServiceValidateError

Return an error for CAS SERVICE VALIDATE request

=head2 returnCasServiceValidateSuccess

Return success for CAS SERVICE VALIDATE request

=head2 returnCasProxyError

Return an error for CAS PROXY request

=head2 returnCasProxySuccess

Return success for CAS PROXY request

=head2 deleteCasSession

Delete an opened CAS session

=head2 callPgtUrl

Call proxy granting URL on CAS client

=head1 SEE ALSO

L<Lemonldap::NG::Portal::IssuerDBCAS>

=head1 AUTHOR

Clement Oudot, E<lt>coudot@linagora.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Clement Oudot

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

