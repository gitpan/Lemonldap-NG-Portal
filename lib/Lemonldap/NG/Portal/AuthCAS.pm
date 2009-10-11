##@file
# CAS authentication backend file

##@class
# CAS authentication backend class
package Lemonldap::NG::Portal::AuthCAS;

use strict;
use Lemonldap::NG::Portal::Simple;
use AuthCAS;

our $VERSION = '0.11';

## @apmethod int authInit()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authInit {
    PE_OK;
}

## @apmethod int extractFormInfo()
# Read username return by CAS authentication system.
# If user isn't authenticated, redirect it to CAS portal.
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;
    my $cas  = new AuthCAS(
        casUrl => $self->{CAS_url},
        CAFile => $self->{CAS_CAFile},
    );
    my $login_url = $cas->getServerLoginURL( $self->{CAS_loginUrl} );

    my $ticket = $self->param('ticket');

    # Unless a ticket has been found, we redirect the user
    unless ( $self->{user} =
        $cas->validateST( $self->{CAS_validationUrl}, $ticket ) )
    {
        print $self->redirect(
            -uri    => $login_url,
            -status => '303 See Other'
        );
        exit;
    }
    PE_OK;
}

## @apmethod int setAuthSessionInfo()
# Does nothing here.
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    # Store user submitted login for basic rules
    $self->{sessionInfo}->{'_user'} = $self->{'user'};

    PE_OK;
}

## @apmethod int authenticate()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authenticate {
    PE_OK;
}

1;
__END__

=head1 NAME

Lemonldap::NG::Portal::AuthCAS - Perl extension for building Lemonldap::NG
compatible portals with CAS authentication. EXPERIMENTAL AND NOT FINISHED!

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'CAS',
         CAS_url           => 'https://cas.myserver',
         CAS_CAFile        => '/etc/httpd/conf/ssl.crt/ca-bundle.crt',
         CAS_loginUrl      => 'http://myserver/app.cgi',
         CAS_validationUrl => 'http://myserver/app.cgi',
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

=head1 DESCRIPTION

This library just overload few methods of Lemonldap::NG::Portal::Simple to use
CAS mechanism: we've just try to get CAS ticket.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
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

