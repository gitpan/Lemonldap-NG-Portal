#!/usr/bin/perl

use strict;
use warnings;

use HTML::Template;
use Lemonldap::NG::Portal::AuthLA;

# Local parameter to set the installation directory

my $portal = Lemonldap::NG::Portal::AuthLA->new(
    {

        # Liberty Parameters
        laSp => {
            certificate => "__DIR__/ressources/lemonsp-key-public.pem",
            metadata    => "__DIR__/ressources/lemonsp-metadata.xml",
            privkey     => "__DIR__/ressources/lemonsp-key-private.pem",
            secretkey   => "__DIR__/ressources/lemonsp-key-private.pem",
        },
        laIdpsFile           => "__DIR__/idps.xml",
        laDebug              => 0,
        laLdapLoginAttribute => "uid",

        # Liberty Storage Options are now generic CGI::Session options
        laStorage        => "File",
        laStorageOptions => { Directory => "__DIR__/var/assertion", },

        # Parameters that permit to access lemonldap::NG::Handler local cache
        localStorage        => 'Cache::FileCache',
        localStorageOptions => {},
    }
);

if ( $portal->process() ) {

    print $portal->header('text/html; charset=utf8');
    my $template = HTML::Template->new( filename => "__DIR__/tpl/menu.tpl" );

    my @sites = ();
    foreach ( $portal->getProtectedSites ) {
        my %row_data;
        $row_data{SITE_NAME} = $_;
        push( @sites, \%row_data );
    }
    @sites = sort { $a cmp $b } @sites;
    $template->param( AUTH_SITES => \@sites );

    print $template->output;

}
else {

    # Retrieve IDP list.

    my @idps = ();
    foreach ( $portal->getIdpIDs ) {
        my %row_data;
        $row_data{IDPNAME} = $_;
        push( @idps, \%row_data );
    }
    @idps = sort { $a cmp $b } @idps;

    # Print template

    print $portal->header;
    my $template = HTML::Template->new( filename => "__DIR__/tpl/auth.tpl" );
    $template->param( AUTH_ERROR => $portal->error );
    $template->param( AUTH_URL   => $portal->param('url') );
    $template->param( AUTH_IDPS  => \@idps );
    print $template->output;

}

