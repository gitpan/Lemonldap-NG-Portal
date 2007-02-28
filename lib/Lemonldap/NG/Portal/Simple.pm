package Lemonldap::NG::Portal::Simple;

use strict;
use warnings;

use Exporter 'import';

use Net::LDAP;
use warnings;
use MIME::Base64;
use CGI;
use CGI::Cookie;

our $VERSION = '0.62';

our @ISA = qw(CGI Exporter);

# Constants
sub PE_DONE                { -1 }
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

# EXPORTER PARAMETERS
our %EXPORT_TAGS = (
    'all' => [
        qw( PE_DONE PE_OK PE_SESSIONEXPIRED PE_FORMEMPTY PE_WRONGMANAGERACCOUNT PE_USERNOTFOUND PE_BADCREDENTIALS
          PE_LDAPCONNECTFAILED PE_LDAPERROR PE_APACHESESSIONERROR PE_FIRSTACCESS PE_BADCERTIFICATE import )
    ],
    'constants' => [
        qw( PE_DONE PE_OK PE_SESSIONEXPIRED PE_FORMEMPTY PE_WRONGMANAGERACCOUNT PE_USERNOTFOUND PE_BADCREDENTIALS
          PE_LDAPCONNECTFAILED PE_LDAPERROR PE_APACHESESSIONERROR PE_FIRSTACCESS PE_BADCERTIFICATE )
    ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT =
  qw( PE_DONE PE_OK PE_SESSIONEXPIRED PE_FORMEMPTY PE_WRONGMANAGERACCOUNT PE_USERNOTFOUND PE_BADCREDENTIALS
  PE_LDAPCONNECTFAILED PE_LDAPERROR PE_APACHESESSIONERROR PE_FIRSTACCESS PE_BADCERTIFICATE import );

# CONSTRUCTOR
sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    $self->getConf(@_) or die "Unable to get configuration";
    die("You've to indicate a an Apache::Session storage module !")
      unless ( $self->{globalStorage} );
    eval "require " . $self->{globalStorage};
    die( "Module " . $self->{globalStorage} . " not found in \@INC" ) if ($@);
    die("You've to indicate a domain for cookies") unless ( $self->{domain} );
    $self->{domain} =~ s/^([^\.])/.$1/;
    $self->{ldapServer}    ||= 'localhost';
    $self->{ldapPort}      ||= 389;
    $self->{securedCookie} ||= 0;
    $self->{cookieName}    ||= "lemonldap";

    if ( $self->{authentication} eq "SSL" ) {
        require Lemonldap::NG::Portal::AuthSSL;
        # $Lemonldap::NG::Portal::AuthSSL::OVERRIDE does not overload $self
        # variables: if the administrator has defined a sub, we respect it
        %$self = ( %$Lemonldap::NG::Portal::AuthSSL::OVERRIDE, %$self );
    }
    return $self;
}

# getConf basic, copy all parameters in $self. Overloaded in SharedConf.pm
sub getConf {
    my ($self) = shift;
    my %args;
    if ( ref( $_[0] ) ) {
        %args = %{ $_[0] };
    }
    else {
        %args = @_;
    }
    %$self = ( %$self, %args );
    1;
}

# TODO: create an _i18n.pm like in Lemonldap::NG::Manager
sub error {
    my $self = shift;
    my $lang = shift;
    my @message;
    if ( $lang eq "fr" ) {
        @message = (
            'Tout est bon',
            'Votre session a expiré, vous devez vous réauthentifier',
            'login ou mot de passe non renseigné',
            "Compte ou mot de passe LDAP de l'application incorrect",
            'Utilisateur inexistant',
            'mot de passe ou login incorrect',
            'Connexion impossible au serveur LDAP',
            'Erreur anormale du serveur LDAP',
            'Erreur du module Apache::Session choisi',
            'Authentification exigée',
        );
    }
    else {
        @message = (
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
    }
    return $message[ $self->{error} ];
}

# Private sub used to bind to LDAP server both with Lemonldap account and user
# credentials if LDAP authentication is used
sub _bind {
    my ( $ldap, $dn, $password ) = @_;
    my $mesg;
    if ( $dn and $password ) {    # named bind
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

# CGI.pm overload to add Lemonldap::NG cookie
sub header {
    my $self = shift;
    if ( $self->{cookie} ) {
        $self->SUPER::header( @_, -cookie => $self->{cookie} );
    }
    else {
        $self->SUPER::header(@_);
    }
}

# CGI.pm overload to add Lemonldap::NG cookie
sub redirect {
    my $self = shift;
    if ( $_[0]->{cookie} ) {
        $self->SUPER::redirect( @_, -cookie => $_[0]->{cookie} );
    }
    else {
        $self->SUPER::redirect(@_);
    }
}

###############################################################
# MAIN subroutine: call all steps until one returns something #
#                  different than PE_OK                       #
###############################################################
sub process {
    my ($self) = @_;
    $self->{error} = PE_OK;
    foreach my $sub
      qw(controlUrlOrigin extractFormInfo formateParams formateFilter
      connectLDAP bind search setSessionInfo setMacros setGroups authenticate
      store unbind buildCookie log autoRedirect) {
        if ( $self->{$sub} )
        {
            last if ( $self->{error} = &{ $self->{$sub} }($self) );
        }
        else {
            last if ( $self->{error} = $self->$sub );
        }
      }
      return ( ( $self->{error} > 0 ) ? 0 : 1 );
}

# 1. If the user was redirected here, we have to load 'url' parameter
sub controlUrlOrigin {
    my $self = shift;
    if ( $self->param('url') ) {
        $self->{urldc} = decode_base64( $self->param('url') );
    }
    PE_OK;
}

# 2. Control existing sessions
# what to do with existing sessions ?
#       - delete and create a new session (default)
#       - re-authentication (actual scheme)
#       - nothing: user is authenticated and process
#                  returns true
sub controlExistingSession {
    my $self = shift;
    my %cookies = fetch CGI::Cookie;
    # Test if Lemonldap::NG cookie is available
    if ( my $id = $cookies{$self->{cookieName}}) {
        my $h;
        # Trying to recover session from global session storage
        eval {
            tie $h, $self->{globalStorage}, $id, $self->{globalStorageOptions};
        };
        if ( $@ or not tied($h) ) {
            # Session not available (expired ?)
            print STDERR "Session $id isn't yet available ($ENV{REMOTE_ADDR})";
            return PE_OK;
        }
        # A session has been find => calling &existingSession
        my $r;
        if ( $self->{existingSession} ) {
            $r = &{ $self->{existingSession} }($self, $id, \$h)
        }
        else {
            $r = $self->existingSession($id, \$h);
        }
        if ( $r == PE_DONE) {
            for my $sub qw(log autoRedirect) {
                if ( $self->{$sub} ) {
                    last if ( $self->{error} = &{ $self->{$sub} }($self) );
                }
                else {
                    last if ( $self->{error} = $self->$sub );
                }
            }
            return $self->{error} || PE_DONE;
        }
        else {
            return $r;
        }
    }
    PE_OK;
}

sub existingSession {
    my ($self, $id, $datas) = @_;
    PE_OK;
}

# 3. In ldap authentication scheme, we load here user and password from HTML
#    form
sub extractFormInfo {
    my $self = shift;
    return PE_FIRSTACCESS
      unless ( $self->param('user') );
    return PE_FORMEMPTY
      unless ( length( $self->{'user'} = $self->param('user') ) > 0
        && length( $self->{'password'} = $self->param('password') ) > 0 );
    PE_OK;
}

# Unused. You can overload if you have to modify user and password before
# authentication
sub formateParams() {
    PE_OK;
}

# 4. By default, the user is searched in the LDAP server with its UID. To use
#    it with Active Directory, overload it to use CN instead of UID.
sub formateFilter {
    my $self = shift;
    $self->{filter} = "(&(uid=" . $self->{user} . ")(objectClass=person))";
    PE_OK;
}

# 5. First LDAP connexion used to find user DN with the filter defined before.
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

# 6. LDAP bind with Lemonldap account or anonymous unless defined
sub bind {
    my $self = shift;
    $self->connectLDAP unless ( $self->{ldap} );
    return PE_WRONGMANAGERACCOUNT
      unless (
        &_bind( $self->{ldap}, $self->{managerDn}, $self->{managerPassword} ) );
    PE_OK;
}

# 7. Search the DN
sub search {
    my $self = shift;
    my $mesg = $self->{ldap}->search(
        base   => $self->{ldapBase},
        scope  => 'sub',
        filter => $self->{filter},
    );
    if ( $mesg->code() != 0 ) {
        print STDERR $mesg->error . "\n";
        return PE_LDAPERROR;
    }
    return PE_USERNOTFOUND unless ( $self->{entry} = $mesg->entry(0) );
    $self->{dn} = $self->{entry}->dn();
    PE_OK;
}

# 8. Load all parameters included in exportedVars parameter.
#    Multi-value parameters are loaded in a single string with
#    '; ' separator
sub setSessionInfo {
    my ($self) = @_;
    $self->{sessionInfo}->{dn} = $self->{dn};
    unless ( $self->{exportedVars} ) {
        foreach (qw(uid cn mail)) {
            $self->{sessionInfo}->{$_} = join( '; ', $self->{entry}->get_value($_) || ("") );
        }
    }
    elsif ( ref( $self->{exportedVars} ) eq 'HASH' ) {
        foreach ( keys %{ $self->{exportedVars} } ) {
            $self->{sessionInfo}->{$_} = join( '; ', $self->{entry}->get_value( $self->{exportedVars}->{$_} ) || ("") );
        }
    }
    else {
        foreach ( @{ $self->{exportedVars} } ) {
            $self->{sessionInfo}->{$_} = join( '; ', $self->{entry}->get_value($_) || ("") );
        }
    }
    PE_OK;
}

# 9. Unused here, but overloaded in SharedConf.pm
sub setMacros {
    PE_OK;
}

# 10. Unused here, but overloaded in SharedConf.pm
sub setGroups {
    PE_OK;
}

# 11. Now, LDAP will not be used by Lemonldap except for LDAP
#     authentication scheme
sub unbind {
    my $self = shift;
    $self->{ldap}->unbind if $self->{ldap};
    delete $self->{ldap};
    PE_OK;
}

# 12. Default authentication: LDAP bind with user credentials
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

# 13. Now, the user is authenticated. It's time to store his parameters with
#     Apache::Session::* module
sub store {
    my ($self) = @_;
    my %h;
    eval {
        tie %h, $self->{globalStorage}, undef, $self->{globalStorageOptions};
    };
    return PE_APACHESESSIONERROR if ($@);
    $self->{id} = $h{_session_id};
    $h{$_} = $self->{sessionInfo}->{$_}
      foreach ( keys %{ $self->{sessionInfo} } );
    $h{_utime} = time();
    untie %h;
    PE_OK;
}

# 14. If all is done, we build the Lemonldap::NG cookie
sub buildCookie {
    my $self = shift;
    $self->{cookie} = $self->cookie(
        -name   => $self->{cookieName},
        -value  => $self->{id},
        -domain => $self->{domain},
        -path   => "/",
        -secure => $self->{securedCookie},
        @_,
    );
    PE_OK;
}

# 15. By default, nothing is logged. Users actions are logged on applications.
#     It's easy to override this in the contructor :
#       my $portal = new Lemonldap::NG::Portal ( {
#                    ...
#                    log => sub {use Sys::Syslog; syslog;
#                                openlog("Portal $$", 'ndelay', 'auth');
#                                syslog('notice', 'User '.$self->{user}.' is authenticated');
#                               },
#                   ...
#                 } );
sub log {
    PE_OK;
}

# 16. If the user was redirected to the portal, we will now redirect him
#     to the requested URL
sub autoRedirect {
    my $self = shift;
    if ( my $u = $self->{urldc} ) {
        print $self->SUPER::redirect(
            -uri    => $u,
            -cookie => $self->{cookie},
            -status => '302 Moved Temporary'
        );

        # Remove this lines if your browsers does not support redirections
        #        print << "EOF";
        #<html>
        #<head>
        #<script language="Javascript">
        #function redirect() {
        #        document.location.href='$u';
        #}
        #</script>
        #</head>
        #<body onload="redirect();">
        #        <h2>The document has moved <a href="$u">HERE</a></h2>
        #</body>
        #</html>
        #EOF
        exit;
    }
    PE_OK;
}

1;

__END__

=head1 NAME

Lemonldap::NG::Portal::Simple - Base module for building Lemonldap::NG compatible portals

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::Simple;
  my $portal = new Lemonldap::NG::Portal::Simple(
         domain         => 'gendarmerie.defense.gouv.fr',
         globalStorage  => 'Apache::Session::MySQL',
         globalStorageOptions => {
           DataSource   => 'dbi:mysql:database=dbname;host=127.0.0.1',
           UserName     => 'db_user',
           Password     => 'db_password',
           TableName    => 'sessions',
           LockDataSource   => 'dbi:mysql:database=dbname;host=127.0.0.1',
           LockUserName     => 'db_user',
           LockPassword     => 'db_password',
         },
         ldapServer     => 'ldap.domaine.com',
         securedCookie  => 1,
         exportedVars  => ["uid","cn","mail","appli"],
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
    print '<input type="submit" value="go" />';
    print '</form>';
  }

=head1 DESCRIPTION

Lemonldap::NG::Portal::Simple is the base module for building Lemonldap::NG
compatible portals. You can use it either by inheritance or by writing
anonymous methods like in the example above.

See L<Lemonldap::NG::Portal::SharedConf> for a complete example of use of
Lemonldap::Portal::* libraries.

=head1 METHODS

=head2 Constructor (new)

=head3 Args

=over

=item * ldapServer: server used to retrive session informations and to valid
credentials (localhost by default).

=item * ldapPort: tcp port used by ldap server.

=item * ldapBase: base of the ldap directory.

=item * managerDn: dn to used to connect to ldap server. By default, anonymous
bind is used.

=item * managerPassword: password to used to connect to ldap server. By
default, anonymous bind is used.

=item * securedCookie: set it to 1 if you want to protect user cookies

=item * cookieName: name of the cookie used by Lemonldap (lemon by default)

=item * domain: cookie domain. You may have to give it else the SSO will work
only on your server.

=item * globalStorage: required: L<Apache::Session> library to used to store
session informations

=item * globalStorageOptions: parameters to bind to L<Apache::Session> module

=item * authentication: sheme to authenticate users (default: "ldap"). It can
be set to:

=over

=item * B<SSL>: See L<Lemonldap::NG::Portal::AuthSSL>.

=back

=back

=head2 Methods that can be overloaded

All the functions above can be overloaded to adapt Lemonldap to your
environment. They MUST return one of the exported constants (see above)
and are called in this order by process().

=head3 controlUrlOrigin

If the user was redirected by a Lemonldap NG handler, stores the url that will be
used to redirect the user after authentication.

=head3 controlExistingSession

Controls if a previous session is always available. If true, it call the sub
C<existingSession> with two parameters: id and a scalar tied on Apache::Session
module choosed to store sessions. See bellow

=head3 existingSession

This sub is called only if a previous session exists and is available. By
defaults, it returns PE_OK so user is re-authenticated. You can overload it:
for example if existingSession just returns PE_DONE: authenticated users are
not re-authenticated and C<>process> returns true.

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
C<$self->{sessionInfo}>). It use C<exportedVars> entry (passed to the new sub)
if defined to know what to store else it stores uid, cn and mail attributes.

=head3 setGroups

Does nothing by default.

=head3 authenticate

Authenticates the user by rebinding to the LDAP server using the dn retrived
with search() and the password.

=head3 store

Stores the informations collected by setSessionInfo into the central cache.
The portal connects the cache using the L<Apache::Session> module passed by
the globalStorage parameters (see constructor).

=head3 unbind

Disconnects from the LDAP server.

=head3 buildCookie

Creates the Lemonldap cookie.

=head3 log

Does nothing. To be overloaded if wanted.

=head3 autoRedirect

Redirects the user to the url stored by controlUrlOrigin().

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

=head1 SEE ALSO

L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Portal::SharedConf>, L<CGI>

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
