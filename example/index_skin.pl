#!/usr/bin/perl

use Lemonldap::NG::Portal::SharedConf;
use HTML::Template;

# Path configuration
my $skin        = "pastel";
my $skin_dir    = "__SKINDIR__";
my $appsxmlfile = "__APPSXMLFILE__";
my $appsimgpath = "apps/";

my $portal = Lemonldap::NG::Portal::SharedConf->new(
    {
        #ldapPpolicyControl => 1,               # Remove comment to use LDAP Password Policy
        #storePassword      => 1,               # Remove comment to store password in session (use with caution)
        #Soap => 1,                             # Remove comment to activate SOAP Function getCookies(user,pwd)
    }
);

if ( $portal->process() ) {

    # HTML::Template object creation
    my $template = HTML::Template->new(
        filename          => "$skin_dir/$skin/menu.tpl",
        die_on_bad_params => 0,
        cache             => 0,
        filter            => sub { $portal->translate_template(@_) }
    );

    # Menu creation
    use Lemonldap::NG::Portal::Menu;
    my $menu = Lemonldap::NG::Portal::Menu->new(
        {
            portalObject => $portal,
            apps         => {
                xmlfile => "$appsxmlfile",
                imgpath => "$appsimgpath",
            },
            modules => {
                appslist => 1,
                password => 1,
                logout   => 1,
            },
            # CUSTOM FUNCTION : if you want to create customFunctions in rules, declare them here
            #customFunctions    => 'function1 function2',
        }
    );

    $template->param( AUTH_ERROR       => $menu->error );
    $template->param( AUTH_ERROR_TYPE  => $menu->error_type );
    $template->param( DISPLAY_APPSLIST => $menu->displayModule("appslist") );
    $template->param( DISPLAY_PASSWORD => $menu->displayModule("password") );
    $template->param( DISPLAY_LOGOUT   => $menu->displayModule("logout") );
    $template->param( DISPLAY_TAB      => $menu->displayTab );
    $template->param( LOGOUT_URL       => "$ENV{SCRIPT_NAME}?logout=1" );
    if ( $menu->displayModule("appslist") ) {
        $template->param( APPSLIST_MENU => $menu->appslistMenu );
        $template->param( APPSLIST_DESC => $menu->appslistDescription );
    }

    print $portal->header('text/html; charset=utf8');
    print $template->output;
}
else {

    # HTML::Template object creation
    my $template = HTML::Template->new(
        filename          => "$skin_dir/$skin/login.tpl",
        die_on_bad_params => 0,
        cache             => 0,
        filter            => sub { $portal->translate_template(@_) }
    );

    $template->param( AUTH_ERROR      => $portal->error );
    $template->param( AUTH_ERROR_TYPE => $portal->error_type );
    $template->param( AUTH_URL        => $portal->get_url );
    $template->param( DISPLAY_FORM    => 1 );

    print $portal->header('text/html; charset=utf8');
    print $template->output;
}

