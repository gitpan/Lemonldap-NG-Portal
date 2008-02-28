#!/usr/bin/perl

use HTML::Template;
use CGI;
use MIME::Base64;

my $tpl_dir = "/var/lib/lemonldap-ng/web/portal/tpl" ;
my $page = CGI->new() ;

my $url = $page->url(-base => 1);
my $logout_url = "$url?url=".encode_base64($url)."&logout=1";

my $template = HTML::Template->new( filename => "$tpl_dir/menu.tpl");
$template->param( AUTH_ERROR => "Access forbidden by WebSSO rules");
$template->param( LOGOUT_URL => "$logout_url" );

print $page->header();
print $template->output;
