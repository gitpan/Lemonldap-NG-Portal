#!/usr/bin/perl

use Lemonldap::NG::Portal::MailReset;
use HTML::Template;
use strict;

# Load portal module
my $portal = Lemonldap::NG::Portal::MailReset->new();

my $skin       = $portal->{portalSkin};
my $skin_dir   = $portal->getApacheHtdocsPath() . "/skins";
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
$template->param( CHOICE_PARAM    => $portal->{authChoiceParam} );
$template->param( CHOICE_VALUE    => $portal->{_authChoice} );
$template->param(
    MAIL => $portal->checkXSSAttack( 'mail', $portal->{mail} )
    ? ""
    : $portal->{mail}
);
$template->param(
    MAIL_TOKEN => $portal->checkXSSAttack( 'mail_token', $portal->{mail_token} )
    ? ""
    : $portal->{mail_token}
);

# Display form the first time
if (
    (
           $portal->{error} == PE_MAILFORMEMPTY
        or $portal->{error} == PE_BADCREDENTIALS
    )
    and !$portal->{mail_token}
  )
{

    $template->param( DISPLAY_FORM          => 1 );
    $template->param( DISPLAY_RESEND_FORM   => 0 );
    $template->param( DISPLAY_PASSWORD_FORM => 0 );
}

# Display mail confirmation resent form
if ( $portal->{error} == PE_MAILCONFIRMATION_ALREADY_SENT ) {
    $template->param( DISPLAY_FORM          => 0 );
    $template->param( DISPLAY_RESEND_FORM   => 1 );
    $template->param( DISPLAY_PASSWORD_FORM => 0 );
}

if ( $portal->{mail_token}
    and ( $portal->{error} != PE_MAILERROR and $portal->{error} != PE_MAILOK ) )
{
    $template->param( DISPLAY_FORM          => 0 );
    $template->param( DISPLAY_RESEND_FORM   => 0 );
    $template->param( DISPLAY_PASSWORD_FORM => 1 );
}

print $portal->header('text/html; charset=utf8');
print $template->output;

