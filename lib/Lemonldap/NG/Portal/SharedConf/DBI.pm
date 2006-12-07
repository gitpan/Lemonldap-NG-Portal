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

our $VERSION = '0.2';

our @ISA = qw(Lemonldap::NG::Portal::SharedConf);

our ( $dbh, $cfgNum ) = ( undef, 0 );

sub getConf {
    my $self = shift;
    $self->SUPER::getConf(@_);
    our $cfgNum = 0;
    $self->{dbiTable} ||= "lmConfig";
    die "No DBI chain found" unless ( $self->{dbiChain} );
    $dbh = DBI->connect_cached( $self->{dbiChain}, $self->{dbiUser}, $self->{dbiPassword}, { RaiseError => 1 } );
    my $sth = $dbh->prepare("SELECT max(cfgNum) from lmConfig");
    $sth->execute();
    my $row = $sth->fetchrow_arrayref or return 0;

    if ( $cfgNum != $row->[0] ) {
        $cfgNum = $row->[0];
        my $sth =
          $dbh->prepare( "select groups, globalStorage, globalStorageOptions, "
              . "exportedVars, domain, ldapServer, ldapPort, securedCookie, "
              . "cookieName, authentication from "
              . $self->{dbiTable}
              . " where(cfgNum=$cfgNum)" );
        $sth->execute();
        $row = $sth->fetchrow_hashref;
        foreach (qw(groups globalStorageOptions exportedVars)) {
            $self->{$_} = thaw( decode_base64( $row->{$_} ) ) if ( $row->{$_} );
        }
        foreach (qw(globalStorage domain ldapServer ldapPort securedCookie cookieName authentication)) {
            $self->{$_} = $row->{$_} if ( $row->{$_} );
        }
    }
    return 1;
}

1;
__END__

=head1 NAME

Lemonldap::NG::Portal::SharedConf::DBI - Module for building Lemonldap::NG
compatible portals using a central configuration database using L<DBI>.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf::DBI;
  my $portal = new Lemonldap::NG::Portal::SharedConf::DBI(
	 dbiChain    => "dbi:mysql:database=lemonldap;host=127.0.0.1",
	 dbiUser     => "lemonldap",
	 dbiPassword => "password",
	 dbiTable    => "lmConfig",
    );

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

Lemonldap::NG::Portal::SharedConf::DBI is an implementation of
L<Lemonldap::NG::Portal::SharedConf> system.

=head1 METHODS

Same as L<Lemonldap::NG::Portal::SharedConf>.

=head2 Arguments

Lemonldap::NG::Portal::SharedConf::DBI introduces 4 new arguments to the
constructor C<new()>:

=over

=item * B<dbiChain>: the string to use to connect to the database. Ex:
"dbi:mysql:database:sso_config:host:127.0.0.1",

=item * B<dbiUser>: the name of the user to use to connect to the database if
needed,

=item * B<dbiPassword>: the password to use to connect to the database if needed,

=item * B<dbiTable>: the table where to find configuration (default: C<lmConfig>).

=back

=head1 EXPORT

Same as L<Lemonldap::NG::Portal::SharedConf>.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Manager>

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
