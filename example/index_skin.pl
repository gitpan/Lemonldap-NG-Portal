#!/usr/bin/perl

use Lemonldap::NG::Portal::SharedConf;
use HTML::Template;

# Skin configuration
my $skin = "default";
my $skin_dir = "__SKINDIR__";

my $portal = Lemonldap::NG::Portal::SharedConf->new(
    {
        configStorage => {
            type    => 'File',
            dirName => '__CONFDIR__',
        },
    }
);

# Template common variables
my $template = HTML::Template->new(filename => "$skin_dir/$skin/index.tpl");
$template->param(AUTH_TITLE => "LemonLDAP::NG Portal");
$template->param(CSS_FILE => "skins/$skin/default.css");

if ( $portal->process() ) {
    print $portal->header('text/html; charset=utf8');

    # Get sites
    my @sites = ();
    foreach ($portal->getProtectedSites) {
        my %row_data;
        $row_data{SITE_NAME} = $_;
        push (@sites, \%row_data);
    }
    @sites = sort {$a cmp $b} @sites ;
    $template->param(AUTH_SITES => \@sites);
    $template->param(AUTH_ERROR => $portal->error);

    # Logout
    $template->param(LOGOUT_URL => "$ENV{SCRIPT_NAME}?logout=1");

    print $template->output;
} else {
    print $portal->header('text/html; charset=utf8');
    $template->param(AUTH_ERROR => $portal->error);
    $template->param(AUTH_URL => $portal->param('url'));
    print $template->output;
}

