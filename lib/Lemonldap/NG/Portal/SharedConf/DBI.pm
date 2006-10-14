package Lemonldap::NG::Portal::SharedConf::DBI;

use 5.006;
use strict;
use warnings;

use Lemonldap::NG::Portal::SharedConf qw(:all);
use Sys::Syslog;
use DBI;
use Storable qw(thaw);
use MIME::Base64;

*EXPORT_OK = *Lemonldap::NG::Portal::SharedConf::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::SharedConf::EXPORT_TAGS;
*EXPORT = *Lemonldap::NG::Portal::SharedConf::EXPORT;

our $VERSION = '0.11';

our @ISA = qw(Lemonldap::NG::Portal::SharedConf);

$| = 1;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    die "No DBI chain found" unless ( $self->{dbiChain} );
    return $self;
}

our ( $dbh, $cfgNum ) = ( undef, 0 );

sub getConf {
    my $self = shift;
    our $cfgNum = 0;
    $dbh = DBI->connect_cached(
        $self->{dbiChain}, $self->{dbiUser},
        $self->{dbiPassword}, { RaiseError => 1 }
    );
    my $sth = $dbh->prepare("SELECT max(cfgNum) from lmConfig");
    $sth->execute();
    my @row = $sth->fetchrow_array;
    if ( $cfgNum != $row[0] ) {
        $cfgNum = $row[0];
        my $sth =
          $dbh->prepare(
            "select groupRules from lmConfig where(cfgNum=$cfgNum)");
        $sth->execute();
        @row = $sth->fetchrow_array;
        $self->{groups} = thaw( decode_base64( $row[0] ) );
    }
    PE_OK;
}

1;
__END__

=head1 NAME

Lemonldap::NG::Portal::SharedConf::DBI - Perl extension for building
Lemonldap-NG compatible portals using a single configuration stored in a 
database

=head1 SYNOPSIS

  use Lemonldap::NG::Portal;
  my $portal = new Lemonldap::NG::Portal(
	 domain         => 'gendarmerie.defense.gouv.fr',
         storageModule  => 'Apache::Session::MySQL',
	 storageOptions => {
	   DataSource   => 'dbi:mysql:database=dbname;host=127.0.0.1',
	   UserName     => 'db_user',
	   Password     => 'db_password',
	   TableName    => 'sessions',
	   LockDataSource   => 'dbi:mysql:database=dbname;host=127.0.0.1',
	   LockUserName     => 'db_user',
	   LockPassword     => 'db_password',
	 },
	 ldapServer     => 'ldap.domaine.com',
	 cookie_secure  => 1,
	 exported_vars  => ["uid","cn","mail","appli"],
	 dbiChain       => "dbi:mysql:database=lemon;host=localhost",
	 dbiUser        => "lemonldap-ng",
	 dbiPassword    => "mypassword",
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
    print 'Password : <input name="pasword" type="password" autocomplete="off">';
    print '</form>';
  }

=head1 DESCRIPTION

Lemonldap is a simple Web-SSO based on L<Apache::Session> modules. It simplifies
the build of a protected area with a few changes in the application (they just
have to read some headers for accounting).

It manages both authentication and authorization and provides headers for
accounting. So you can have a full AAA protection for your web space. There are
two ways to build a cross domain authentication:

=over

=item * Cross domain authentication itself (L<Lemonldap::Portal::Cda> I<(not yet implemented in Lemonldap::NG)>)

=item * B<Liberty Alliance> (See L<Lemonldap::ServiceProvider> and
L<Lemonldap::IdentityProvider>)

=back

This library is a way to build Lemonldap compatible portals. You can use it
either by inheritance or by writing anonymous methods like in the example
above.

See L<Lemonldap::NG::Portal>
Lemonldap::Portal::* libraries.

=head1 METHODS

=head2 Constructor (new)

=head3 Args

=over 5

=item * ldapServer: server used to retrive session informations and to valid
credentials (localhost by default).

=item * ldapPort: tcp port used by ldap server.

=item * managerDn: dn to used to connect to ldap server. By default, anonymous
bind is used.

=item * managerPassword: password to used to connect to ldap server. By
default, anonymous bind is used.

=item * ldapBase: base of the ldap directory.

=item * cookie_secure: set it to 1 if you want to protect user cookies

=item * coolie_name: name of the cookie used by Lemonldap (lemon by default)

=item * domain: cookie domain. You may have to give it else the SSO will work
only on your server.

=item * storageModule: required: L<Apache::Session> library to used to store
session informations

=item * storageOptions: parameters to bind to L<Apache::Session> module

=back

=head2 Methods that can be overloaded

All the functions above can be overloaded to adapt Lemonldap to your
environment. They MUST return one of the exported constants (see above)
and are called in this order by process().

=head3 controlUrlOrigin

If the user was redirected by a Lemonldap NG handler, stores the url that will be
used to redirect the user after authentication.

=head3 controlExistingSession

Controls if a previous session is always available.

=head3 extractFormInfo

Converts form input into object variables ($self->{user} and
$self->{password}).

=head3 formateParams

Does nothing. To be overloaded if needed.

=head3 formateFilter

Creates the ldap filter using $self->{user}. By default :

  $self->{filter} = "(&(uid=" . $self->{user} . ")(objectClass=person))";

=head3 connectLDAP

Connects to LDAP server.

=head3 bind

Binds to the LDAP server using $self->{managerDn} and $self->{managerPassword}
if exist. Anonymous bind is provided else.

=head3 search

Retrives the LDAP entry corresponding to the user using $self->{filter}.

=head3 setSessionInfo

Prepares variables to store in central cache (stored temporarily in
$self->{sessionInfo}). It use exported_vars entry (passed to the new sub) if
defined to know what to store else it stores uid, cn and mail attributes.

=head3 authenticate

Authenticates the user by rebinding to the LDAP server using the dn retrived
with search() and the password.

=head3 store

Stores the informations collected by setSessionInfo into the central cache.
The portal connects the cache using the L<Apache::Session> module passed by
the storageModule parameters (see constructor).

=head3 unbind

Disconnects from the LDAP server.

=head3 buildCookie

Creates the Lemonldap cookie.

=head3 autoRedirect

Redirects the user to the url stored by controlUrlOrigin().

=head3 log

Does nothing. To be overloaded if wanted.

=head2 Other methods

=head3 process

Main method.

=head3 error

Returns the error message corresponding to the error returned by the methods
described above

=head3 _bind( $ldap, $dn, $password )

Non-object method used to bind to the ldap server.

=head3 header

Overloads the CGI::header method to add Lemonldap cookie.

=head3 redirect

Overloads the CGI::redirect method to add Lemonldap cookie.

=head2 EXPORT

=head3 Constants

=over 5

=item * B<PE_OK>: all is good

=item * B<PE_SESSIONEXPIRED>: the user session has expired

=item * B<PE_FORMEMPTY>: Nothing was entered in the login form

=item * B<PE_USERNOTFOUND>: the user was not found in the (ldap) directory

=item * B<PE_WRONGMANAGERACCOUNT>: the account used to bind to LDAP server in order to
find the user distinguished name (dn) was refused by the server

=item * B<PE_BADCREDENTIALS>: bad login or password

=item * B<PE_LDAPERROR>: abnormal error from ldap

=item * B<PE_APACHESESSIONERROR>: abnormal error from Apache::Session

=item * B<PE_FIRSTACCESS>: First access to the portal

=item * B<PE_BADCERTIFICATE>: Wrong certificate

=back

=head2 AUTHENTICATION-AUTHORIZATION-ACCOUNTING

This section presents Lemonldap characteristics from the point-of-vue of
AAA.

=head3 B<Authentication>

If a user isn't authenticated and attemps to connect to an area protected by a
Lemonldap compatible handler, he is redirected to the portal. The portal
authenticates user with a ldap bind by default, but you can also use another
authentication sheme like using x509 user certificates (see
L<Lemonldap::NG::Portal::AuthSsl> for more).

Lemonldap use session cookies generated by L<Apache::Session> so as secure as a
128-bit random cookie. You may use the C<cookie_secure> options of
L<Lemonldap::NG::Portal> to avoid session hijacking.

You have to manage life of sessions by yourself since Lemonldap knows nothing
about the L<Apache::Session> module you've choose, but it's very easy using a
simple cron script because L<Lemonldap::NG::Portal> stores the start time in the
C<_utime> field.

=head3 B<Authorization>

Authorization is controled only by handlers because the portal knows nothing
about the way the user will choose. L<Lemonldap::NG::Portal> is designed to help
you to store all the user datas you wants to use to manage authorization.

When initializing an handler, you have to describe what you want to protect and
who can connect to. This is done by the C<locationRules> parameters of C<init>
method. It is a reference to a hash who contains entries where:

=over 4

=item * B<keys> are regular expression who are compiled by C<init> using
C<qr()> B<or> the keyword C<default> who points to the default police.

=item * B<values> are conditional expressions B<or> the keyword C<accept> B<or>
the keyword C<deny>:

=over

=item * Conditional expressions are converted into subroutines. You can use the
variables stored in the global store by calling them C<$E<lt>varnameE<gt>>.

Exemple:

  '^/rh/.*$' => '$ou =~ /brh/'

=item * Keyword B<deny> denies any access while keyword B<accept> allows all
authenticated users.

Exemple:

  'default'  => 'accept'

=back

=back

=head3 B<Accounting>

=head4 I<Logging portal access>

L<Lemonldap::NG::Portal> doesn't log anything by default, but it's easy to overload
C<log> method for normal portal access or using C<error> method to know what
was wrong if C<process> method has failed.

=head4 I<Logging application access>

Because an handler knows nothing about the protected application, it can't do
more than logging URL. As Apache does this fine, L<Lemonldap::NG::Handler> gives it
the name to used in logs. The C<whatToTrace> parameters indicates which
variable Apache has to use (C<$uid> by default).

The real accounting has to be done by the application itself which knows the
result of SQL transaction for example.

Lemonldap can export http headers either using a proxy or protecting directly
the application. By default, the C<User-Auth> field is used but you can change
it using the C<exportedHeaders> parameters of the C<init> method. It is a
reference to a hash where:

=over

=item * B<keys> are the names of the choosen headers

=item * B<values> are perl expressions where you can use user datas stored in
the global store by calling them C<$E<lt>varnameE<gt>>.

=back

=head1 SEE ALSO

L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Portal::SharedConf::DBI>, L<CGI>

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
