#!/usr/bin/perl

use Lemonldap::NG::Portal::SharedConf;

my $portal = Lemonldap::NG::Portal::SharedConf->new(
    {

        # ACCESS TO CONFIGURATION

        # By default, Lemonldap::NG uses the default storage.conf file to know
        # where to find is configuration
        # (generaly /etc/lemonldap-ng/storage.conf)
        # You can specify by yourself this file :
        #configStorage => { File => '/path/to/my/file' },

        # You can also specify directly the configuration
        # (see Lemonldap::NG::Handler::SharedConf(3))
        #configStorage => {
        #      type => 'File',
        #      directory => '/usr/local/lemonlda-ng/conf/'
        #},

        # SOAP FUNCTIONS
        # Remove comment to activate SOAP Functions getCookies(user,pwd) and
        # error(language, code)
        #Soap => 1,

        # PASSWORD POLICY
        # Remove comment to use LDAP Password Policy
        #ldapPpolicyControl => 1,

        # Remove comment to store password in session (use with caution)
        #storePassword      => 1,

        # CUSTOM FUNCTION
        # If you want to create customFunctions in rules, declare them here:
        #customFunctions    => 'function1 function2',
        #customFunctions    => 'Package::func1 Package::func2',

        # OTHERS
        # You can also overload any parameter issued from manager
        # configuration. Example:
        #globalStorage => 'Lemonldap::NG::Common::Apache::Session::SOAP',
        #globalStorageOptions => {
        #    proxy => 'http://manager.example.com/soapserver.pl',
        #    proxyOptions => {
        #        timeout => 5,
        #    },
        #    # If soapserver is protected by HTTP Basic:
        #    User     => 'http-user',
        #    Password => 'pass',
        #},
    }
);

if ( $portal->process() ) {
    print $portal->header('text/html; charset=utf8');
    print $portal->start_html;
    print "<h1>Your well authenticated !</h1>";
    print "Click <a href=\"$ENV{SCRIPT_NAME}?logout=1\">here</a> to logout";
    print $portal->end_html;
}
else {
    print $portal->header('text/html; charset=utf8');
    print $portal->start_html;
    print 'Error: ' . $portal->error . '<br />';
    print '<form method="post" action="' . $ENV{SCRIPTNAME} . '">';
    print '<input type="hidden" name="url" value="'
      . $portal->get_url . '" />';
    print 'Login : <input name="user" /><br />';
    print
'Password : <input name="password" type="password" autocomplete="off"><br>';
    print '<input type="submit" value="OK" />';
    print '</form>';
    print $portal->end_html;
}

