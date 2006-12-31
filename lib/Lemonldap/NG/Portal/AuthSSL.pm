package Lemonldap::NG::Portal::AuthSSL;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '0.03';

# Authentication is made here before searching the LDAP Directory
our $OVERRIDE = {
    extractFormInfo => sub {
        my $self = shift;
        $self->{user} = $self->https('SSL_CLIENT_S_DN_Email');
        return PE_BADCREDENTIALS unless ( $self->{user} );
        PE_OK;
    },

    formateFilter => sub {
        my $self = shift;
        $self->{filter} = "(&(mail=" . $self->{user} . ")(objectClass=person))";
        PE_OK;
    },

    authenticate => sub {
        PE_OK;
    },
};

1;
__END__

=head1 NAME

Lemonldap::NG::Portal::AuthSSL - Perl extension for building Lemonldap::NG
compatible portals with SSL authentication.

=head1 SYNOPSIS

With Lemonldap::NG::Portal::SharedConf::DBI, set authentication field to "SSL".

With Lemonldap::NG::Portal::Simple:

  use Lemonldap::NG::Portal::Simple;
  my $portal = new Lemonldap::NG::Portal::Simple(
	 domain         => 'gendarmerie.defense.gouv.fr',
         globalStorage  => 'Apache::Session::MySQL',
	 globalStorageOptions => {
	   DataSource   => 'dbi:mysql:database',
	   UserName     => 'db_user',
	   Password     => 'db_password',
	   TableName    => 'sessions',
	 },
	 ldapServer     => 'ldap.domaine.com',
	 securedCookie  => 1,
	 authentication => 'SSL',
    );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header; # DON'T FORGET THIS (see CGI(3))
    print "...";

    # or redirect the user to the menu
    print $portal->redirect( -uri => 'https://portal/menu');
  }
  else {
    # If the user enters here, IT MEANS THAT YOUR SSL PARAMETERS ARE BAD
    print $portal->header; # DON'T FORGET THIS (see CGI(3))
    print "<html><body><h1>Unable to work</h1>";
    print "This server isn't well configured. Contact your administrator.";
    print "</body></html>";
  }

Modify your httpd.conf:

  <Location /My/File>
    SSLVerifyClient require
    SSLOptions +ExportCertData +CompatEnvVars +StdEnvVars
  </Location>

=head1 DESCRIPTION

This library just overload few methods of Lemonldap::NG::Portal::Simple to use
Apache SSLv3 mechanism: we've just to verify that
C<$ENV{SSL_CLIENT_S_DN_Email}> exists. So remenber to export SSL variables
to CGI.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

