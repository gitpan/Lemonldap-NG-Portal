#!/usr/bin/perl

use Lemonldap::NG::Portal::SharedConf;

my $portal = Lemonldap::NG::Portal::SharedConf->new(
    {
        configStorage => {
            type    => 'File',
            dirName => '__CONFDIR__',
        },
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
    print '<form method="post" action="'.$ENV{SCRIPTNAME}.'">';
    print '<input type="hidden" name="url" value="'
      . $portal->param('url') . '" />';
    print 'Login : <input name="user" /><br />';
    print 'Password : <input name="password" type="password" autocomplete="off"><br>';
    print '<input type="submit" value="OK" />';
    print '</form>';
    print $portal->end_html;
}

