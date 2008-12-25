#!/usr/bin/perl

use Lemonldap::NG::Portal::SharedConf;

my $portal = Lemonldap::NG::Portal::SharedConf->new(
    {
        #ldapPpolicyControl => 1,               # Remove comment to use LDAP Password Policy
        #storePassword      => 1,               # Remove comment to store password in session (use with caution)
        #Soap => 1,                             # Remove comment to activate SOAP Function getCookies(user,pwd)
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

