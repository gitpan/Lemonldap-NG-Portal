#!/usr/bin/perl

# CAS sample client
use strict;
use CGI;
use AuthCAS;

# Configuration
my $cas_url        = 'https://auth.example.com/cas';
my $cas            = new AuthCAS( casUrl => $cas_url );
my $cgi            = new CGI;
my $pgtUrl         = $cgi->url() . "%3Fproxy%3D1";
my $pgtFile        = '/tmp/pgt.txt';
my $proxiedService = 'http://webmail';

# Act as a CAS proxy
$cas->proxyMode( pgtFile => '/tmp/pgt.txt', pgtCallbackUrl => $pgtUrl );

# CAS login URL
my $login_url = $cas->getServerLoginURL( $cgi->url() );

# Start HTTP response
print $cgi->header();

# Proxy URL for TGT validation
if ( $cgi->param('proxy') ) {

    # Store pgtId and pgtIou
    $cas->storePGT( $cgi->param('pgtIou'), $cgi->param('pgtId') );
}

else {

    print $cgi->start_html('CAS sample client');

    my $ticket = $cgi->param('ticket');

    # First time access
    unless ($ticket) {
        print $cgi->h1("Click below to use CAS");
        print $cgi->h2("<a href=\"$login_url\">Simple login</a>");
        print $cgi->h2("<a href=\"$login_url&renew=true\">Renew login</a>");
        print $cgi->h2("<a href=\"$login_url&gateway=true\">Gateway login</a>");
    }

    # Ticket receveived
    else {
        print $cgi->h1("CAS login done");
        print $cgi->h2("Service ticket: $ticket");

        # Get user
        my $user = $cas->validateST( $cgi->url(), $ticket );
        if ($user) {
            print $cgi->h2("Authenticated user: $user");
        }
        else {
            print $cgi->h2( "Error: " . &AuthCAS::get_errors() );
        }

        # Get proxy granting ticket
        my $pgtId = $cas->{pgtId};
        if ($pgtId) {
            print $cgi->h2("Proxy granting ticket: $pgtId");

            # Try to request proxy ticket
            my $pt = $cas->retrievePT($proxiedService);

            if ($pt) {

                print $cgi->h2("Proxy ticket: $pt");

                # Use proxy ticket
                my ( $puser, @proxies ) =
                  $cas->validatePT( $proxiedService, $pt );

                print $cgi->h2("Proxied user: $puser");
                print $cgi->h2("Proxies used: @proxies");

            }
            else {
                print $cgi->h2( "Error: " . &AuthCAS::get_errors() );
            }
        }
        else {
            print $cgi->h2("Error: Unable to get proxy granting ticket");
        }

        print $cgi->h2( "<a href=\"" . $cgi->url . "\">Home</a>" );

    }

    print $cgi->end_html();

    # Remove PGT file
    unlink $pgtFile;

}

exit;
