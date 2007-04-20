#!/usr/bin/perl

use Lemonldap::NG::Portal::SharedConf;

my $portal = Lemonldap::NG::Portal::SharedConf->new(
    {
        configStorage => {
            type    => 'File',
            dirName => '__DIR__/conf/',
        }
    }
);

if ( $portal->process() ) {
    print $portal->header;
    print $portal->start_html;
    print "<h1>Your well authenticated !</h1>";
    print "Click <a href=\"$ENV{SCRIPT_NAME}?logout=1\">here</a> to logout";
    print $portal->end_html;
}
else {
    print $portal->header;
    print $portal->start_html;
    print 'Error: ' . $portal->error . '<br>';
    print '<form method="POST">';
    print '<input type="hidden" name="url" value="'
      . $portal->param('url') . '">';
    print 'Login : <input name="user"><br>';
    print 'Password : <input name="password" type="password" autocomplete="off"><br>';
    print '<input type=submit value="OK">';
    print $portal->end_html;
}

