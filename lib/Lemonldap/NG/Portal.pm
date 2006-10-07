package Lemonldap::NG::Portal;

use 5.008004;
use strict;
use warnings;
use Carp;

use Exporter 'import';

use Net::LDAP;
use warnings;
use MIME::Base64;
use CGI;

our $VERSION = '0.1';

our @ISA = qw(CGI Exporter);

# Constants
sub PE_OK                  { 0 }
sub PE_SESSIONEXPIRED      { 1 }
sub PE_FORMEMPTY           { 2 }
sub PE_WRONGMANAGERACCOUNT { 3 }
sub PE_USERNOTFOUND        { 4 }
sub PE_BADCREDENTIALS      { 5 }
sub PE_LDAPCONNECTFAILED   { 6 }
sub PE_LDAPERROR           { 7 }
sub PE_APACHESESSIONERROR  { 8 }
sub PE_FIRSTACCESS         { 9 }
sub PE_BADCERTIFICATE      { 10 }

our %EXPORT_TAGS = (
    'all' => [
        qw( PE_OK PE_SESSIONEXPIRED PE_FORMEMPTY PE_WRONGMANAGERACCOUNT PE_USERNOTFOUND PE_BADCREDENTIALS
          PE_LDAPCONNECTFAILED PE_LDAPERROR PE_APACHESESSIONERROR PE_FIRSTACCESS PE_BADCERTIFICATE import
	  )
    ],
    'constants' => [
        qw( PE_OK PE_SESSIONEXPIRED PE_FORMEMPTY PE_WRONGMANAGERACCOUNT PE_USERNOTFOUND PE_BADCREDENTIALS
	  PE_LDAPCONNECTFAILED PE_LDAPERROR PE_APACHESESSIONERROR PE_FIRSTACCESS PE_BADCERTIFICATE )
    ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT =
  qw( PE_OK PE_SESSIONEXPIRED PE_FORMEMPTY PE_WRONGMANAGERACCOUNT PE_USERNOTFOUND PE_BADCREDENTIALS
  PE_LDAPCONNECTFAILED PE_LDAPERROR PE_APACHESESSIONERROR PE_FIRSTACCESS PE_BADCERTIFICATE import);

sub new {
    my $class = shift;
    my %args;
    if ( ref( $_[0] ) ) {
        %args = %{ $_[0] };
    }
    else {
        %args = @_;
    }
    my $self = $class->SUPER::new();
    %$self = ( %$self, %args );
    die("You've to indicate a an Apache::Session storage module !")
      unless ( $self->{storageModule} );
    eval "require " . $self->{storageModule};
    die( "Module " . $self->{storageModule} . " not found in \@INC" ) if ($@);
    $self->{domain} =~ s/^([^\.])/.$1/;
    $self->{ldapServer}    ||= 'localhost';
    $self->{ldapPort}      ||= 389;
    $self->{cookie_secure} ||= 0;
    $self->{cookie_name}   ||= "lemon";
    return $self;
}

sub error {
    my $self    = shift;
    my @message = (
        'Everything is OK',
        'Your connection has expired; You must to be authentified once again',
        'User and password fields must be filled',
        'Wrong directory manager account or password',
        'User not found in directory',
        'Wrong credentials',
        'Unable to connect to LDAP server',
        'Abnormal error from LDAP server',
        'Apache::Session module failed',
        'Authentication required',
    );
    return $message[ $self->{error} ];
}

sub process {
    my ($self) = @_;
    $self->{error} = PE_OK;
    foreach my $sub 
        qw(controlUrlOrigin extractFormInfo formateParams formateFilter
        connectLDAP bind search setSessionInfo setGroups authenticate store unbind
        buildCookie log autoRedirect)
    {
        if ( $self->{$sub} ) {
            last if ( $self->{error} = &{ $self->{$sub} }($self) );
        }
        else {
            last if ( $self->{error} = $self->$sub );
        }
    }
    return ( $self->{error} ? 0 : 1 );
}

sub _bind {
    my ( $ldap, $dn, $password ) = @_;
    my $mesg;
    if ( $dn and $password ) {    #named bind
        $mesg = $ldap->bind( $dn, password => $password );
    }
    else {                        # anonymous bind
        $mesg = $ldap->bind();
    }
    if ( $mesg->code() != 0 ) {
        return 0;
    }
    return 1;
}

sub header {
    my $self = shift;
    if ( $self->{cookie} ) {
        $self->SUPER::header( @_, -cookie => $self->{cookie} );
    }
    else {
        $self->SUPER::header(@_);
    }
}

sub redirect {
    if ( $_[0]->{cookie} ) {
        SUPER::redirect( @_, -cookie => $_[0]->{cookie} );
    }
    else {
        SUPER::redirect(@_);
    }
}

sub controlUrlOrigin {
    my $self = shift;
    if ( $self->param('url') ) {
        $self->{urldc} = decode_base64( $self->param('url') );
    }
    PE_OK;
}

# TODO: control existing sessions and TimeOut
sub controlExistingSession {
    my $self = shift;

    return PE_SESSIONEXPIRED if ( $self->param('op') eq 't' );
    PE_OK;
}

sub extractFormInfo {
    my $self = shift;
    return PE_OK if ( $self->{id} );
    return PE_FIRSTACCESS
      unless ( $self->param('user') );
    return PE_FORMEMPTY
      unless ( length( $self->{'user'} = $self->param('user') ) > 0
        && length( $self->{'password'} = $self->param('password') ) > 0 );
    PE_OK;
}

sub formateParams() {
    PE_OK;
}

sub formateFilter {
    my $self = shift;
    $self->{filter} = "(&(uid=" . $self->{user} . ")(objectClass=person))";
    PE_OK;
}

sub connectLDAP {
    my $self = shift;
    return PE_LDAPCONNECTFAILED
      unless (
        $self->{ldap}
        or $self->{ldap} = Net::LDAP->new(
            $self->{ldapServer},
            port    => $self->{ldapPort},
            onerror => undef,
        )
      );
    PE_OK;
}

sub bind {
    my $self = shift;
    $self->connectLDAP unless ( $self->{ldap} );
    return PE_WRONGMANAGERACCOUNT
      unless (
        &_bind( $self->{ldap}, $self->{managerDn}, $self->{managerPassword} ) );
    PE_OK;
}

sub search {
    my $self = shift;
    my $mesg = $self->{ldap}->search(
        base   => $self->{ldapBase},
        scope  => 'sub',
        filter => $self->{filter},
    );
    if ( $mesg->code() != 0 ) {
	print STDERR $mesg->error."\n";
        return PE_LDAPERROR;
    }
    return PE_USERNOTFOUND unless ( $self->{entry} = $mesg->entry(0) );
    $self->{dn} = $self->{entry}->dn();
    PE_OK;
}

sub setSessionInfo {
    my ($self) = @_;
    $self->{sessionInfo}->{dn} = $self->{dn};
    unless ( $self->{exported_vars} ) {
        foreach (qw(uid cn mail)) {
            $self->{sessionInfo}->{$_} = $self->{entry}->get_value($_);
        }
    }
    elsif ( ref( $self->{exported_vars} ) eq 'HASH' ) {
        foreach ( keys %{ $self->{exported_vars} } ) {
            $self->{sessionInfo}->{$_} =
              $self->{entry}->get_value( $self->{exported_vars}->{$_} );
        }
    }
    else {
        foreach ( @{ $self->{exported_vars} } ) {
            $self->{sessionInfo}->{$_} = $self->{entry}->get_value($_);
        }
    }
    PE_OK;
}

sub setGroups {
    PE_OK;
}

sub unbind {
    my $self = shift;
    $self->{ldap}->unbind if $self->{ldap};
    delete $self->{ldap};
    PE_OK;
}

sub authenticate {
    my $self = shift;
    return PE_OK if ( $self->{id} );
    $self->unbind();
    my $err;
    return $err unless ( ( $err = $self->connectLDAP ) == PE_OK );
    return PE_BADCREDENTIALS
      unless ( &_bind( $self->{ldap}, $self->{dn}, $self->{password} ) );
    PE_OK;
}

sub store {
    my ($self) = @_;
    my %h;

    # TODO: reuse old session
    eval { tie %h, $self->{storageModule}, undef, $self->{storageOptions}; };
    return PE_APACHESESSIONERROR if ($@);
    $self->{id} = $h{_session_id};
    $h{$_} = $self->{sessionInfo}->{$_}
      foreach ( keys %{ $self->{sessionInfo} } );
    $h{_utime} = time();
    untie %h;
    PE_OK;
}

sub buildCookie {
    my $self = shift;
    $self->{cookie} = $self->cookie(
        -name   => $self->{cookie_name},
        -value  => $self->{id},
        -domain => $self->{domain},
        -path   => "/",
        -secure => $self->{cookie_secure},
        @_,
    );
    PE_OK;
}

sub autoRedirect {
    my $self = shift;
    if ( my $u = $self->{urldc} ) {
        print $self->SUPER::redirect(
            -uri           => $u,
            -cookie        => $self->{cookie},
            -type          => 'text/html',
            -cache_control => 'private',
            -nph           => 1,
        );
        print << "EOF";
<html>
<head>
<script language="Javascript">
function redirect() {
	document.location.href='$u';
}
</script>
</head>
<body onload="redirect();">
	<h2>The document has moved <a href="$u">HERE</a></h2>
</body>
</html>
EOF
        exit;
    }
    PE_OK;
}

sub log {
    PE_OK;
}

1;

__END__

=head1 NAME

Lemonldap::NG::Portal - Perl extension for building Lemonldap compatible portals

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

See L<Lemonldap::NG::Portal::SharedConf::DBI> for a complete example of use of
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
