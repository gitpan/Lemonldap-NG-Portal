#!/usr/bin/perl

use Lemonldap::NG::Portal::MailReset;
use HTML::Template;
use strict;

# Load portal module
my $portal = Lemonldap::NG::Portal::MailReset->new();

my $skin       = $portal->{portalSkin};
my $skin_dir   = $ENV{DOCUMENT_ROOT} . "/skins";
my $portal_url = $portal->{portal};

# Process
$portal->process();

# Template creation
my $template = HTML::Template->new(
    filename          => "$skin_dir/$skin/mail.tpl",
    die_on_bad_params => 0,
    cache             => 0,
    filter            => sub { $portal->translate_template(@_) }
);

$template->param( PORTAL_URL      => "$portal_url" );
$template->param( SKIN            => "$skin" );
$template->param( AUTH_ERROR      => $portal->error );
$template->param( AUTH_ERROR_TYPE => $portal->error_type );

# Display form the first time
$template->param( DISPLAY_FORM => 1 )
  if ( $portal->{error} == PE_MAILFORMEMPTY
    or ( $portal->{error} == PE_BADCREDENTIALS and !$portal->{mail_token} ) );

print $portal->header('text/html; charset=utf8');
print $template->output;

