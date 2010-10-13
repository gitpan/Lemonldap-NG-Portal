## @file
# Deprecated: use "cda" parameter instead

## @class
# Deprecated: use "cda" parameter instead
package Lemonldap::NG::Portal::CDA;

use strict;
use Lemonldap::NG::Portal::SharedConf qw(:all);

our $VERSION = '0.99';
use base ('Lemonldap::NG::Portal::SharedConf');

*EXPORT_OK   = *Lemonldap::NG::Portal::SharedConf::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::SharedConf::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::SharedConf::EXPORT;

##################
# OVERLOADED SUB #
##################

## @cmethod Lemonldap::NG::Portal::CDA new(array params)
# Call Lemonldap::NG::Portal::SharedConf::new() with "cda" parameter set to 1
# @param params Lemonldap::NG::Portal::SharedConf::new() parameters
# @return New Lemonldap::NG::Portal::CDA object
sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{cda} = 1;
    return $self;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::CDA - Perl extension for building Lemonldap::NG
compatible portals with Cross Domain Authentication.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::SharedConf( {
         cda => 1,
         configStorage => {
             type        => 'DBI',
             dbiChain    => "dbi:mysql:...",
             dbiUser     => "lemonldap",
             dbiPassword => "password",
             dbiTable    => "lmConfig",
         },
    } );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header('text/html; charset=utf8'); # DON'T FORGET THIS (see L<CGI(3)>)
    print "...";

    # or redirect the user to the menu
    print $portal->redirect( -uri => 'https://portal/menu');
  }
  else {
    # Write here the html form used to authenticate with CGI methods.
    # $portal->error returns the error message if athentification failed
    # Warning: by defaut, input names are "user" and "password"
    print $portal->header('text/html; charset=utf8'); # DON'T FORGET THIS (see L<CGI(3)>)
    print "...";
    print '<form method="POST">';
    # In your form, the following value is required for redirection
    print '<input type="hidden" name="url" value="'.$portal->param('url').'">';
    # Next, login and password
    print 'Login : <input name="user"><br>';
    print 'Password : <input name="password" type="password" autocomplete="off">';
    print '<input type="submit" value="go" />';
    print '</form>';
  }

Modify your httpd.conf:

  <Location /My/File>
    SSLVerifyClient require
    SSLOptions +ExportCertData +CompatEnvVars +StdEnvVars
  </Location>

=head1 DESCRIPTION

This file is maintened only for compatibility. Now set "cda => 1" in the
portal.

=head1 SEE ALSO

L<Lemonldap::NG::SharedConf>, L<Lemonldap::NG::Handler>,
L<Lemonldap::NG::Handler::CDA>,
http://wiki.lemonldap.objectweb.org/xwiki/bin/view/NG/Presentation

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://forge.objectweb.org/tracker/?group_id=274>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

