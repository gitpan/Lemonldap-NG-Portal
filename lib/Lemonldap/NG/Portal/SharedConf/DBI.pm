package Lemonldap::NG::Portal::SharedConf::DBI;

use strict;
use warnings;

use Lemonldap::NG::Portal::SharedConf qw(:all);
use DBI;
use Storable qw(thaw);
use MIME::Base64;

*EXPORT_OK   = *Lemonldap::NG::Portal::SharedConf::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::SharedConf::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::SharedConf::EXPORT;

our $VERSION = '0.31';

our @ISA = qw(Lemonldap::NG::Portal::SharedConf);

sub getConf {
    my ( $self, $args ) = @_;
    $self->{configStorage} = {
        type        => "DBI",
        dbiChain    => $self->{dbiChain},
        dbiUser     => $self->{dbiUser},
        dbiPassword => $self->{dbiPassword},
        dbiTable    => $self->{dbiTable},
    };
    $self->SUPER::getConf(@_);
}

1;
__END__

=head1 NAME

Lemonldap::NG::Portal::SharedConf::DBI - This module is deprecated. See
L<Lemonldap::NG::Portal::SharedConf>.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::SharedConf( {
        configStorage => {
          dbiChain    => "dbi:mysql:database=lemonldap;host=127.0.0.1",
          dbiUser     => "lemonldap",
          dbiPassword => "password",
          dbiTable    => "lmConfig",
        },
     } );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header; # DON'T FORGET THIS (see L<CGI(3)>)
    print "...";

    # or redirect the user to the menu
    print $portal->redirect( -uri => 'https://portal/menu');
  }
  else {
    # Write here the html form used to authenticate with CGI methods.
    # $portal->error returns the error message if athentification failed
    # Warning: by defaut, input names are "user" and "password"
    print $portal->header; # DON'T FORGET THIS (see L<CGI(3)>)
    print "...";
    print '<form method="POST">';
    # In your form, the following value is required for redirection
    print '<input type="hidden" name="url" value="'.$portal->param('url').'">';
    # Next, login and password
    print 'Login : <input name="user"><br>';
    print 'Password : <input name="password" type="password" autocomplete="off">';
    print '<input type=submit value="OK">';
    print '</form>';
  }

=head1 DESCRIPTION

Lemonldap::NG::Portal::SharedConf::DBI is written for compatibility with old
versions of Lemonldap::NG. See now L<Lemonldap::NG::Portal::SharedConf>.

=head1 SEE ALSO

L<Lemonldap::NG::Portal::SharedConf>, L<Lemonldap::NG::Portal>,
L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Manager>

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
