#!/usr/bin/perl

use Lemonldap::NG::Portal::SharedConf;
use HTML::Template;

# Menu configuration
my $skin        = "pastel";
my $skin_dir    = "__SKINDIR__";
my $appsxmlfile = "__APPSXMLFILE__";
my $appsimgpath = "apps/";
my $user_attr   = "_user";

# Menu configuration
use constant USER_CAN_CHANGE_PASSWORD => 1;
use constant REQUIRE_OLDPASSWORD      => 0;
use constant DISPLAY_LOGOUT           => 1;
use constant AUTOCOMPLETE             => "on";
use constant DISPLAY_RESETPASSWORD    => "1";

my $portal = Lemonldap::NG::Portal::SharedConf->new(
    {

        # ACCESS TO CONFIGURATION
        # By default, Lemonldap::NG uses the default storage.conf file to know
        # where to find its configuration
        # (generaly /etc/lemonldap-ng/storage.conf)
        # You can specify by yourself this file :
        #configStorage => { confFile => '/path/to/my/file' },
        # or set explicitely parameters :
        #configStorage => {
        #  Type => 'File',
        #  dirName => '/path/to/config/dir/'
        #},
        # Note that YOU HAVE TO SET configStorage here if you've declared this
        # portal as SOAP configuration server in the manager

        # LOG
        # By default, all is logged in Apache file. To log user actions by
        # syslog, just set syslog facility here:
        #syslog => 'auth',

        # SOAP FUNCTIONS
        # Remove comment to activate SOAP Functions getCookies(user,pwd) and
        # error(language, code)
        Soap => 1,
        # Note that getAttibutes() will be activated but on a different URI
        # (http://auth.example.com/index.pl/sessions)
        # You can also restrict attributes and macros exported by getAttributes
        #exportedAttr => 'uid mail',

        # PASSWORD POLICY
        # Remove comment to use LDAP Password Policy
        #ldapPpolicyControl => 1,

        # Remove comment to store password in session (use with caution)
        #storePassword      => 1,

        # Remove comment to use LDAP modify password extension
        # (beware of compatibility with LDAP Password Policy)
        #ldapSetPassword    => 1,

        # RESET PASSWORD BY MAIL
        # SMTP server (default to localhost), set to '' to use default mail
        # service
        #SMTPServer => "localhost",

        # Mail From address
        #mailFrom => "noreply@test.com",

        # Mail subject
        #mailSubject => "Password reset",

        # Mail body (can use $password for generated password, and other session infos,
        # like $cn)
        #mailBody => 'Hello $cn,\n\nYour new password is $password',

        # LDAP filter to use
        #mailLDAPFilter => '(&(mail=$mail)(objectClass=inetOrgPerson))',

        # Random regexp
        #randomPasswordRegexp => '[A-Z]{3}[a-z]{5}.\d{2}',

        # LDAP GROUPS
        # Set the base DN of your groups branch
        #ldapGroupBase => 'ou=groups,dc=example,dc=com',
        # Objectclass used by groups
        #ldapGroupObjectClass => 'groupOfUniqueNames',
        # Attribute used by groups to store member
        #ldapGroupAttributeName => 'uniqueMember',
        # Attribute used by user to link to groups
        #ldapGroupAttributeNameUser => 'dn',
        # Attribute used to identify a group. The group will be displayed as
        # cn|mail|status, where cn, mail and status will be replaced by their
        # values.
        #ldapGroupAttributeNameSearch => ['cn'],

        # CUSTOM FUNCTION
        # If you want to create customFunctions in rules, declare them here:
        #customFunctions    => 'function1 function2',
        #customFunctions    => 'Package::func1 Package::func2',

        # NOTIFICATIONS SERVICE
        # Use it to be able to notify messages during authentication
        #notification => 1,
        # Note that the SOAP function newNotification will be activated on
        # http://auth.example.com/index.pl/notification
        # If you want to hide this, just protect "/index.pl/notification" in
        # your Apache configuration file

        # CROSS-DOMAIN
        # If you have some handlers that are not registered on the main domain,
        # uncomment this
        #cda => 1,

        # XSS protection bypass
        # By default, the portal refuse redirections that comes from sites not
        # registered in the configuration (manager) except for those coming
        # from trusted domains. By default, trustedDomains contains the domain
        # declared in the manager. You can set trustedDomains to empty value so
        # that, undeclared sites will be rejected. You can also set here a list
        # of trusted domains or hosts separated by spaces. This is usefull if
        # your website use Lemonldap::NG without handler with SOAP functions.
        # Exemples :
        #trustedDomains => 'my.trusted.host example2.com',
        #trustedDomains => '',

        # OTHERS
        # You can also overload any parameter issued from manager
        # configuration. Example:
        #globalStorage => 'Apache::Session::File',
        #globalStorageOptions => {
        #  'Directory' => '/var/lib/lemonldap-ng/sessions/'
        #  'LockDirectory' => '/var/lib/lemonldap-ng/sessions/lock/'
        #}
        # Note that YOU HAVE TO SET globalStorage here if you've declared this
        # portal as SOAP session server in the manager
        #},
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
                password => USER_CAN_CHANGE_PASSWORD,
                logout   => DISPLAY_LOGOUT,
            },
        }
    );

    $template->param( AUTH_USER           => $portal->{sessionInfo}->{$user_attr} );
    $template->param( AUTOCOMPLETE        => AUTOCOMPLETE );
    $template->param( SKIN                => $skin );
    $template->param( AUTH_ERROR          => $menu->error );
    $template->param( AUTH_ERROR_TYPE     => $menu->error_type );
    $template->param( DISPLAY_APPSLIST    => $menu->displayModule("appslist") );
    $template->param( DISPLAY_PASSWORD    => $menu->displayModule("password") );
    $template->param( DISPLAY_LOGOUT      => $menu->displayModule("logout") );
    $template->param( DISPLAY_TAB         => $menu->displayTab );
    $template->param( LOGOUT_URL          => "$ENV{SCRIPT_NAME}?logout=1" );
    $template->param( REQUIRE_OLDPASSWORD => REQUIRE_OLDPASSWORD );
    if ( $menu->displayModule("appslist") ) {
        $template->param( APPSLIST_MENU => $menu->appslistMenu );
        $template->param( APPSLIST_DESC => $menu->appslistDescription );
    }

    print $portal->header('text/html; charset=utf-8');
    print $template->output;
}
elsif ( my $notif = $portal->notification ) {

    # HTML::Template object creation
    my $template = HTML::Template->new(
        filename          => "$skin_dir/$skin/notification.tpl",
        die_on_bad_params => 0,
        cache             => 0,
        filter            => sub { $portal->translate_template(@_) }
    );

    $template->param( AUTH_ERROR      => $portal->error );
    $template->param( AUTH_ERROR_TYPE => $portal->error_type );
    $template->param( NOTIFICATION    => $notif );
    $template->param( SKIN            => $skin );

    print $portal->header('text/html; charset=utf-8');
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
    $template->param( LOGIN           => $portal->get_user );
    $template->param( AUTOCOMPLETE    => AUTOCOMPLETE );
    $template->param( SKIN            => $skin );

    if (
        USER_CAN_CHANGE_PASSWORD
        and (  $portal->{error} == PE_PP_CHANGE_AFTER_RESET
            or $portal->{error} == PE_PP_MUST_SUPPLY_OLD_PASSWORD
            or $portal->{error} == PE_PP_INSUFFICIENT_PASSWORD_QUALITY
            or $portal->{error} == PE_PP_PASSWORD_TOO_SHORT
            or $portal->{error} == PE_PP_PASSWORD_TOO_YOUNG
            or $portal->{error} == PE_PP_PASSWORD_IN_HISTORY
            or $portal->{error} == PE_PASSWORD_MISMATCH
            or $portal->{error} == PE_BADOLDPASSWORD )
      )
    {
        $template->param( REQUIRE_OLDPASSWORD => 1 );
        $template->param( DISPLAY_PASSWORD    => 1 );
    }
    else {
        $template->param( DISPLAY_FORM          => 1 );
        $template->param( DISPLAY_RESETPASSWORD => 1 );
    }

    print $portal->header('text/html; charset=utf-8');
    print $template->output;
}

