package Lemonldap::NG::Portal::AuthSsl;

use 5.008004;
use strict;
use warnings;
use Carp;

use warnings;
use CGI;
use Lemonldap::NG::Portal;

our $VERSION = '0.01';

our @ISA = qw(Lemonldap::NG::Portal);

# Authentication is made here before searching the LDAP Directory
sub extractFormInfo {
    my $self = shift;
    $self->{user} = $self->https('SSL_CLIENT_S_DN_Email');
    return PE_BADCREDENTIALS unless ( $self->{user} );
    PE_OK;
}

sub formateFilter {
    my $self = shift;
    $self->{filter} = "(&(mail=" . $self->{user} . ")(objectClass=person))";
    PE_OK;
}

sub authenticate {
    PE_OK;
}

1;
__END__

=head1 NAME

Lemonldap::NG::Portal::AuthSsl - Perl extension for building Lemonldap compatible
portals based on SSL v3 mechanisms.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::AuthSsl;
  my $portal = new Lemonldap::NG::Portal(
	 domain         => 'gendarmerie.defense.gouv.fr',
         storageModule  => 'Apache::Session::MySQL',
	 storageOptions => {
	   DataSource   => 'dbi:mysql:database',
	   UserName     => 'db_user',
	   Password     => 'db_password',
	   TableName    => 'sessions',
	 },
	 ldapServer     => 'ldap.domaine.com',
	 cookie_secure  => 1,
    );
  # Example of overloading: choose the LDAP variables to store
  $portal->{setSessionInfo} = sub {
    my ($self) = @_;
    foreach $_ qw(uid cn mail appli) {
        $self->{sessionInfo}->{$_} = $entry->get_value($_);
    }
    PE_OK;
  };

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header; # DON'T FORGET THIS (see CGI(3))
    print "...";

    # or redirect the user to the menu
    print $portal->redirect( -uri => 'https://portal/menu');
  }
  else {
    # Write here the html form used to authenticate with CGI methods.
    # $portal->error returns the error message if athentification failed
    # Warning: by defaut, input names are "user" and "password"
    print $portal->header; # DON'T FORGET THIS (see CGI(3))
    print "...";
    print '<form method="POST">';
    # In your form, the following value is required for redirection
    print '<input type="hidden" name="url" value="'.$portal->param('url').'">';
    # Next, login and password
    print 'Login : <input name="user"><br>';
    print 'Password : <input name="pasword" type="password" autocomplete="off">';
    print '</form>';
  }

Modify your httpd.conf:

  <Location /My/File>
    SSLVerifyClient require
    SSLOptions +ExportCertData +CompatEnvVars +StdEnvVars
  </Location>

=head1 DESCRIPTION

Lemonldap is a simple Web-SSO based on Apache::Session modules. It simplifies
the build of a protected area with a few changes in the application (they just
have to read some headers for accounting).

It manages both authentication and authorization and provides headers for
accounting. So you can have a full AAA protection for your web space. There are
two ways to build a cross domain authentication:

=over

=item * Cross domain authentication itself (Lemonldap::Portal::Cda I<(not yet
implemented in Lemonldap::NG)>)

=item * "Liberty Alliance" (Lemonldap::LibertyAlliance::*)

=back

This library just overload few methods of Lemonldap::NG::Portal to use
Apache SSLv3 mechanism: we've just to verify that
$ENV{SSL_CLIENT_S_DN_Email} exists. So remenber to export SSL variables
to CGI.

See Lemonldap::NG::Portal for usage and other methods.

=head1 SEE ALSO

Lemonldap::NG::Portal(3)

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

Lemonldap was originaly written by Eric german who decided to publish him in
2003 under the terms of the GNU General Public License version 2.
Lemonldap::NG is a complete rewrite of Lemonldap and is able to have different
policies in a same Apache virtual host.

=cut
