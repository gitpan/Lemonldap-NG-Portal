package Lemonldap::NG::Portal::AuthApache;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '0.1';

sub authInit {
}

# By default, authentication is valid if REMOTE_USER environment
# variable is present. Change formateFilter if this does not match with
# UID.
sub extractFormInfo {
    my $self = shift;
    unless ( $self->{user} = $ENV{REMOTE_USER} ) {
        print STDERR "Apache is not configured to authenticate users !";
        return PE_ERROR;
    }

    # This is needed for Kerberos authentication
    $self->{user} =~ s/^(.*)@.*$/$1/g;
    PE_OK;
}

# Authentication is made by Apache.
sub authenticate {
    PE_OK;
}

1;
__END__

=head1 NAME

Lemonldap::NG::Portal::Apache - Perl extension for building Lemonldap::NG
compatible portals with Apache authentication.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'Apache',
    );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header('text/html; charset=utf8'); # DON'T FORGET THIS (see CGI(3))
    print "...";

    # or redirect the user to the menu
    print $portal->redirect( -uri => 'https://portal/menu');
  }
  else {
    # If the user enters here, IT MEANS THAT CAS REDIRECTION DOES NOT WORK
    print $portal->header('text/html; charset=utf8'); # DON'T FORGET THIS (see CGI(3))
    print "<html><body><h1>Unable to work</h1>";
    print "This server isn't well configured. Contact your administrator.";
    print "</body></html>";
  }

and of course, configure Apache to protect the portal.

=head1 DESCRIPTION

This library just overload few methods of Lemonldap::NG::Portal::Simple to use
Apache authentication mechanism: we've just try to get REMOTE_USER environment
variable.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
http://wiki.lemonldap.objectweb.org/xwiki/bin/view/NG/Presentation

=head1 AUTHOR

Thomas Chemineau, E<lt>thomas.chemineau@linagora.comE<gt>,
Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://forge.objectweb.org/tracker/?group_id=274>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Thomas Chemineau,
E<lt>thomas.chemineau@linagora.comE<gt> and
Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

