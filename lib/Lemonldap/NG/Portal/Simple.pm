##@file
# Base package for Lemonldap::NG portal

##@class
# Base class for Lemonldap::NG portal
package Lemonldap::NG::Portal::Simple;

use strict;
use warnings;

use Exporter 'import';

use warnings;
use MIME::Base64;
use Lemonldap::NG::Common::CGI;
use CGI::Cookie;
require POSIX;
use Lemonldap::NG::Portal::_i18n;
use Safe;

our $VERSION = '0.87';

use base qw(Lemonldap::NG::Common::CGI Exporter);
our @ISA;

# Constants
use constant {
    PE_REDIRECT                         => -2,
    PE_DONE                             => -1,
    PE_OK                               => 0,
    PE_SESSIONEXPIRED                   => 1,
    PE_FORMEMPTY                        => 2,
    PE_WRONGMANAGERACCOUNT              => 3,
    PE_USERNOTFOUND                     => 4,
    PE_BADCREDENTIALS                   => 5,
    PE_LDAPCONNECTFAILED                => 6,
    PE_LDAPERROR                        => 7,
    PE_APACHESESSIONERROR               => 8,
    PE_FIRSTACCESS                      => 9,
    PE_BADCERTIFICATE                   => 10,
    PE_PP_ACCOUNT_LOCKED                => 21,
    PE_PP_PASSWORD_EXPIRED              => 22,
    PE_CERTIFICATEREQUIRED              => 23,
    PE_ERROR                            => 24,
    PE_PP_CHANGE_AFTER_RESET            => 25,
    PE_PP_PASSWORD_MOD_NOT_ALLOWED      => 26,
    PE_PP_MUST_SUPPLY_OLD_PASSWORD      => 27,
    PE_PP_INSUFFICIENT_PASSWORD_QUALITY => 28,
    PE_PP_PASSWORD_TOO_SHORT            => 29,
    PE_PP_PASSWORD_TOO_YOUNG            => 30,
    PE_PP_PASSWORD_IN_HISTORY           => 31,
    PE_PP_GRACE                         => 32,
    PE_PP_EXP_WARNING                   => 33,
    PE_PASSWORD_MISMATCH                => 34,
    PE_PASSWORD_OK                      => 35,
    PE_NOTIFICATION                     => 36,
    PE_BADURL                           => 37,
};

# EXPORTER PARAMETERS
our @EXPORT =
  qw( PE_DONE PE_OK PE_SESSIONEXPIRED PE_FORMEMPTY PE_WRONGMANAGERACCOUNT
  PE_USERNOTFOUND PE_BADCREDENTIALS PE_LDAPCONNECTFAILED PE_LDAPERROR
  PE_APACHESESSIONERROR PE_FIRSTACCESS PE_BADCERTIFICATE PE_REDIRECT
  PE_PP_ACCOUNT_LOCKED PE_PP_PASSWORD_EXPIRED PE_CERTIFICATEREQUIRED
  PE_ERROR PE_PP_CHANGE_AFTER_RESET PE_PP_PASSWORD_MOD_NOT_ALLOWED
  PE_PP_MUST_SUPPLY_OLD_PASSWORD PE_PP_INSUFFICIENT_PASSWORD_QUALITY
  PE_PP_PASSWORD_TOO_SHORT PE_PP_PASSWORD_TOO_YOUNG
  PE_PP_PASSWORD_IN_HISTORY PE_PP_GRACE PE_PP_EXP_WARNING
  PE_PASSWORD_MISMATCH PE_PASSWORD_OK PE_NOTIFICATION PE_BADURL );
our %EXPORT_TAGS = ( 'all' => [ @EXPORT, 'import' ], );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# Secure jail
our $safe;
our $self;    # Safe cannot share a variable declared with my

##@cmethod Lemonldap::NG::Portal::Simple new(hashRef args)
# Class constructor.
#@param args hash reference
#@return Lemonldap::NG::Portal::Simple object
sub new {
    binmode( STDOUT, ":utf8" );
    my $class = shift;
    return $class if ( ref($class) );
    my $self = $class->SUPER::new();
    $self->getConf(@_)
      or $self->abort( "Configuration error",
        "Unable to get configuration: $Lemonldap::NG::Common::Conf::msg" );
    $self->abort( "Configuration error",
        "You've to indicate a an Apache::Session storage module !" )
      unless ( $self->{globalStorage} );
    eval "require " . $self->{globalStorage};
    $self->abort( "Configuration error",
        "Module " . $self->{globalStorage} . " not found in \@INC" )
      if ($@);
    $self->abort( "Configuration error",
        "You've to indicate a domain for cookies" )
      unless ( $self->{domain} );
    $self->{domain} =~ s/^([^\.])/.$1/;
    $self->{securedCookie}  ||= 0;
    $self->{cookieName}     ||= "lemonldap";
    $self->{authentication} ||= 'LDAP';
    $self->{userDB}         ||= 'LDAP';
    $self->{authentication} =~ s/^ldap/LDAP/;
    $self->{mustRedirect} = (
        ( $ENV{REQUEST_METHOD} eq 'POST' and not $self->param('newpassword') )
          or $self->param('logout')
    ) ? 1 : 0;

    # Authentication module is required and has to be in @ISA
    foreach (qw(authentication userDB)) {
        my $tmp =
            'Lemonldap::NG::Portal::'
          . ( $_ eq 'userDB' ? 'UserDB' : 'Auth' )
          . $self->{$_};
        $tmp =~ s/\s.*$//;
        eval "require $tmp";
        $self->abort( "Configuration error", $@ ) if ($@);
        push @ISA, $tmp;

        # $self->{authentication} and $self->{userDB} can contains arguments
        # (key1 = scalar_value; key2 = ...)
        $tmp = $self->{$_};
        $tmp =~ s/^\w+\s*//;
        my %h = split( /\s*[=;]\s*/, $tmp ) if ($tmp);
        %$self = ( %h, %$self );
    }
    if ( $self->{Soap} ) {
        require SOAP::Lite;
        $self->soapTest("${class}::getCookies ${class}::error");
    }
    return $self;
}

##@method protected boolean getConf(hashRef args)
# Copy all parameters in caller object.
#@param args hash-ref
#@return True
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

##@method string error(string lang)
# error calls Portal/_i18n.pm to display error in the wanted language.
#@param $lang optional (browser language is used instead)
#@return error message
sub error {
    my $self = shift;
    my $lang = shift || $ENV{HTTP_ACCEPT_LANGUAGE};
    my $code = shift || $self->{error};
    return &Lemonldap::NG::Portal::_i18n::error( $code, $lang );
}

##@method string error_type(int code)
# error_type tells if error is positive, warning or negative
# @param $code Lemonldap::NG error code
# @return "positive", "warning" or "negative"
sub error_type {
    my $self = shift;
    my $code = shift || $self->{error};

    # Positive errors
    return "positive"
      if (
        scalar(
            grep { /^$code$/ } (
                -2,    #PE_REDIRECT
                -1,    #PE_DONE,
                0,     #PE_OK
                35,    #PE_PASSWORD_OK
            )
        )
      );

    # Warning errors
    return "warning"
      if (
        scalar(
            grep { /^$code$/ } (
                1,     #PE_SESSIONEXPIRED
                2,     #PE_FORMEMPTY
                9,     #PE_FIRSTACCESS
                32,    #PE_PP_GRACE
                33,    #PE_PP_EXP_WARNING
                36,    #PE_NOTIFICATION
                37,    #PE_BADURL
            )
        )
      );

    # Negative errors (default)
    return "negative";
}

##@method void translate_template(string text_ref, string lang)
# translate_template is used as an HTML::Template filter to tranlate strings in
# the wanted language
#@param text_ref reference to the string to translate
#@param lang optionnal language wanted. Falls to browser language instead.
#@return
sub translate_template {
    my $self     = shift;
    my $text_ref = shift;
    my $lang     = shift || $ENV{HTTP_ACCEPT_LANGUAGE};

    # Get the lang code (2 letters)
    $lang = lc($lang);
    $lang =~ s/-/_/g;
    $lang =~ s/^(..).*$/$1/;

    # Test if a translation is available for the selected language
    # If not available, return the first translated string
    # <lang en="Please enter your credentials" fr="Merci de vous autentifier"/>
    if ( $$text_ref =~ m/$lang=\"(.*?)\"/ ) {
        $$text_ref =~ s/<lang.*$lang=\"(.*?)\".*?\/>/$1/gx;
    }
    else {
        $$text_ref =~ s/<lang\s+\w+=\"(.*?)\".*?\/>/$1/gx;
    }
}

##@method void header()
# Overload CGI::header() to add Lemonldap::NG cookie.
sub header {
    my $self = shift;
    if ( $self->{cookie} ) {
        $self->SUPER::header( @_, -cookie => $self->{cookie} );
    }
    else {
        $self->SUPER::header(@_);
    }
}

##@method void redirect()
# Overload CGI::redirect() to add Lemonldap::NG cookie.
sub redirect {
    my $self = shift;
    if ( $self->{cookie} ) {
        $self->SUPER::redirect( @_, -cookie => $self->{cookie} );
    }
    else {
        $self->SUPER::redirect(@_);
    }
}

##@method void getSessionInfo()
# Read cookie and set session info.
# If lemonldap cookie exists, reads it and search session. If the session is
# available, store it in $self->{sessionInfo}
sub getSessionInfo {
    my $self    = shift;
    my %cookies = fetch CGI::Cookie;

    # Test if Lemonldap::NG cookie is available
    if ( $cookies{ $self->{cookieName} }
        and my $id = $cookies{ $self->{cookieName} }->value )
    {
        my %h;

        # Trying to recover session from global session storage
        eval {
            tie %h, $self->{globalStorage}, $id, $self->{globalStorageOptions};
        };
        if ( $@ or not tied(%h) ) {

            # Session not available (expired ?)
            print STDERR
              "Session $id isn't yet available ($ENV{REMOTE_ADDR})\n";
            return undef;
        }

        # Store session values
        foreach ( keys %h ) {
            $self->{sessionInfo}->{$_} = $h{$_};
        }

        untie %h;
    }

}

##@method void updateSession(hashRef infos)
# Update session stored.
# If lemonldap cookie exists, reads it and search session. If the session is
# available, update datas with $info.
#@param $infos hash

# TODO: update all caches
sub updateSession {
    my $self    = shift;
    my ($infos) = @_;
    my %cookies = fetch CGI::Cookie;

    # Test if Lemonldap::NG cookie is available
    if ( $cookies{ $self->{cookieName} }
        and my $id = $cookies{ $self->{cookieName} }->value )
    {
        my %h;

        # Trying to recover session from global session storage
        eval {
            tie %h, $self->{globalStorage}, $id, $self->{globalStorageOptions};
        };
        if ( $@ or not tied(%h) ) {

            # Session not available (expired ?)
            print STDERR
              "Session $id isn't yet available ($ENV{REMOTE_ADDR})\n";
            return undef;
        }

        # Store/update session values
        foreach ( keys %$infos ) {
            $h{$_} = $infos->{$_};
        }

        untie %h;
    }

}

##@method protected int _subProcess(array @subs)
# Execute methods until an error is returned.
# If $self->{$sub} exists, launch it, else launch $self->$sub
#@param @subs array list of subroutines
#@return Lemonldap::NG::Portal error
sub _subProcess {
    my $self = shift;
    my @subs = @_;
    my $err  = undef;

    foreach my $sub (@subs) {

        #print STDERR "DEBUG : $sub\n";
        if ( $self->{$sub} ) {
            last if ( $err = &{ $self->{$sub} }($self) );
        }
        else {
            last if ( $err = $self->$sub );
        }
    }

    return $err;
}
##@method protected void updateStatus()
# Inform status mechanism module.
# If an handler is launched on the same server with "status=>1", inform the
# status module with the result (portal error).
sub updateStatus {
    my ($self) = @_;
    print $Lemonldap::NG::Handler::Simple::statusPipe (
        $self->{user} ? $self->{user} : $ENV{REMOTE_ADDR} )
      . " => $ENV{SERVER_NAME}$ENV{SCRIPT_NAME} "
      . $self->{error} . "\n"
      if ($Lemonldap::NG::Handler::Simple::statusPipe);
}

##@method protected Lemonldap::NG::Portal::Notification notification()
#@return Lemonldap::NG::Portal::Notification object
sub notification {
    my ($self) = @_;
    return $self->{_notification};
}

##@method string get_url()
# check url against XSS attacks
# @return url parameter if good, nothing else.
sub get_url {
    my ($self) = @_;
    return unless $self->param('url');
    return if ( $self->param('url') =~ m#[^A-Za-z0-9\+/=]# );
    return $self->param('url');
}

##@method private Safe safe()
# Provide the security jail.
#@return Safe object
sub safe {
    my $self = shift;
    return $safe if ($safe);
    $safe = new Safe;
    my @t =
      $self->{customFunctions} ? split( /\s+/, $self->{customFunctions} ) : ();
    foreach (@t) {
        my $sub = $_;
        unless (/::/) {
            $sub = ref($self) . "::$_";
        }
        else {
            s/^.*:://;
        }
        next if ( $self->can($_) );
        eval "sub $_ {
                return $sub( '$self->{portal}', \@_ );
            }";
        print STDERR $@ if ($@);
    }
    $safe->share( '&encode_base64', @t );
    return $safe;
}

####################
# SOAP subroutines #
####################

##@method SOAP::Data getCookies(string user,string password)
# Called in SOAP context, returns cookies in an array.
# This subroutine works only for portals working with user and password
#@param user uid
#@param password password
#@return session => { error => code , cookies => { cookieName1 => value ,... } }
sub getCookies {
    my $self = shift;
    $self->{error} = PE_OK;
    ( $self->{user}, $self->{password} ) = ( shift, shift );
    unless ( $self->{user} && $self->{password} ) {
        $self->{error} = PE_FORMEMPTY;
    }
    else {
        $self->{error} = $self->_subProcess(
            qw(authInit userDBInit getUser setAuthSessionInfo setSessionInfo
              setMacros setGroups authenticate store buildCookie log)
        );
    }
    my @tmp = ();
    push @tmp, SOAP::Data->name( error => $self->{error} );
    unless ( $self->{error} ) {
        push @tmp,
          SOAP::Data->name(
            cookies => \SOAP::Data->value(
                SOAP::Data->name( $self->{cookieName} => $self->{id} ),
            )
          );
    }
    my $res = SOAP::Data->name( session => \SOAP::Data->value(@tmp) );
    $self->updateStatus;
    return $res;
}

###############################################################
# MAIN subroutine: call all steps until one returns something #
#                  different than PE_OK                       #
###############################################################

##@method boolean process()
# Main method.
# process() call functions issued from :
#  - itself : controlUrlOrigin, controlExistingSession, setMacros, setGroups, store, buildCookie, log, autoredirect
#  - authentication module : extractFormInfo, setAuthSessionInfo, authenticate
#  - user database module  : getUser, setSessionInfo
#@return 1 if user is all is OK, 0 if session isn't created or a notification has to be done
sub process {
    my ($self) = @_;
    $self->{error} = PE_OK;
    $self->{error} = $self->_subProcess(
        qw(checkNotifBack controlUrlOrigin controlExistingSession authInit
          extractFormInfo userDBInit getUser setAuthSessionInfo setSessionInfo
          setMacros setGroups authenticate store buildCookie log
          checkNotification autoRedirect)
    );
    $self->updateStatus;
    return ( ( $self->{error} > 0 ) ? 0 : 1 );
}

##@method int checkNotifBack()
# 1) Checks if a message has to be notified to the connected user.
#@return Lemonldap::NG::Portal error code
sub checkNotifBack {
    my $self = shift;

    # TODO
    PE_OK;
}

##@method int controlUrlOrigin()
# 2) If the user was redirected here, loads 'url' parameter.
#@return Lemonldap::NG::Portal constant
sub controlUrlOrigin {
    my $self = shift;
    if ( $self->param('url') ) {

        # REJECT NON BASE64 URL
        return PE_BADURL if ( $self->param('url') =~ m#[^A-Za-z0-9\+/=]# );

        $self->{urldc} = decode_base64( $self->param('url') );
        $self->{urldc} =~ s/[\r\n]//sg;

        # REJECT [\0<'"`] in URL or encoded '%' and non protected hosts
        if (
            $self->{urldc} =~ /(?:\0|<|'|"|`|\%(?:00|25|3C|22|27|2C))/
            or ( $self->{urldc} !~
m#^https?://(?:$self->{reVHosts}|(?:[^/]*)?$self->{domain})(?::\d+)?(?:/.*)?$#
                and not $self->param('logout') )
          )
        {
            delete $self->{urldc};
            return PE_BADURL;
        }
    }
    elsif ( $self->{mustRedirect} ) {
        $self->{urldc} = $self->{portal};
    }
    PE_OK;
}

##@method int controlExistingSession()
# 3) Control existing sessions.
# To overload to control what to do with existing sessions.
# what to do with existing sessions ?
#       - nothing: user is authenticated and process returns true (default)
#       - delete and create a new session (not implemented)
#       - re-authentication (set existingSession => sub{PE_OK})
#@return Lemonldap::NG::Portal constant
sub controlExistingSession {
    my $self    = shift;
    my %cookies = fetch CGI::Cookie;

    # Store IP address
    $self->{sessionInfo}->{ipAddr} = $ENV{REMOTE_ADDR};

    # Test if Lemonldap::NG cookie is available
    if ( $cookies{ $self->{cookieName} }
        and my $id = $cookies{ $self->{cookieName} }->value )
    {
        my %h;

        # Trying to recover session from global session storage
        eval {
            tie %h, $self->{globalStorage}, $id, $self->{globalStorageOptions};
        };
        if ( $@ or not tied(%h) ) {

            # Session not available (expired ?)
            print STDERR
              "Session $id isn't yet available ($ENV{REMOTE_ADDR})\n";
            return PE_OK;
        }

        # Logout if required
        if ( $self->param('logout') ) {

            # Delete session in global storage
            tied(%h)->delete;

            # Delete cookie
            push @{ $self->{cookie} },
              $self->cookie(
                -name    => $self->{cookieName},
                -value   => 0,
                -domain  => $self->{domain},
                -path    => "/",
                -secure  => 0,
                -expires => '-1d',
                @_,
              );
            $self->{error} = PE_REDIRECT;
            $self->_subProcess(qw(log autoRedirect));
            return PE_FIRSTACCESS;
        }
        $self->{id} = $id;

        # A session has been find => calling &existingSession
        my ( $r, $datas );
        %$datas = %h;
        untie(%h);
        if ( $self->{existingSession} ) {
            $r = &{ $self->{existingSession} }( $self, $id, $datas );
        }
        else {
            $r = $self->existingSession( $id, $datas );
        }
        if ( $r == PE_DONE ) {
            $self->{error} = $self->_subProcess(qw(log autoRedirect));
            return $self->{error} || PE_DONE;
        }
        else {
            return $r;
        }
    }
    PE_OK;
}

sub existingSession {

    #my ( $self, $id, $datas ) = @_;
    PE_DONE;
}

# 4. authInit() : must be implemented in Auth* module

# 5. extractFormInfo() : must be implemented in Auth* module:
#                         * set $self->{user}
#                         * authenticate user if possible (or do it in 11.)

# 6. userDBInit() : must be implemented in User* module

# 7. getUser() : must be implemented in User* module

# 8. setAuthSessionInfo() : must be implemented in Auth* module:
#                            * store exported datas in $self->{sessionInfo}

# 9. setSessionInfo() : must be implemented in User* module:
#                            * store exported datas in $self->{sessionInfo}

##@method int setMacro()
# 10) macro mechanism.
#                  * store macro results in $self->{sessionInfo}
#@return Lemonldap::NG::Portal constant
sub setMacros {
    local $self = shift;
    $self->abort( __PACKAGE__ . ": Unable to get configuration" )
      unless ( $self->getConf(@_) );
    $self->safe->share('$self');
    while ( my ( $n, $e ) = each( %{ $self->{macros} } ) ) {
        $e =~ s/\$(\w+)/\$self->{sessionInfo}->{$1}/g;
        $self->{sessionInfo}->{$n} = $self->safe->reval($e);
    }
    PE_OK;
}

##@method int setGroups()
# 11) groups mechanism.
#                    * store all groups name that the user match in
#                      $self->{sessionInfo}->{groups}
#@return Lemonldap::NG::Portal constant
sub setGroups {
    local $self = shift;
    my $groups;
    $self->safe->share('$self');
    while ( my ( $group, $expr ) = each %{ $self->{groups} } ) {
        $expr =~ s/\$(\w+)/\$self->{sessionInfo}->{$1}/g;
        $groups .= "$group " if ( $self->safe->reval($expr) );
    }
    if ( $self->{ldapGroupBase} ) {
        my $mesg = $self->{ldap}->search(
            base   => $self->{ldapGroupBase},
            filter => "(|(member="
              . $self->{dn}
              . ")(uniqueMember="
              . $self->{dn} . "))",
            attrs => ["cn"],
        );
        if ( $mesg->code() == 0 ) {
            foreach my $entry ( $mesg->all_entries ) {
                my @values = $entry->get_value("cn");
                $groups .= $values[0] . " ";
            }
        }
    }
    $self->{sessionInfo}->{groups} = $groups;
    PE_OK;
}

# 12. authenticate() : must be implemented in Auth* module:
#                       * authenticate the user if not done before

##@method int store()
# 13) Store user's datas in sessions database.
#     Now, the user is known, authenticated and session variable are evaluated.
#     It's time to store his parameters with Apache::Session::* module
#@return Lemonldap::NG::Portal constant
sub store {
    my ($self) = @_;
    my %h;
    eval {
        tie %h, $self->{globalStorage}, undef, $self->{globalStorageOptions};
    };
    if ($@) {
        print STDERR "$@\n";
        return PE_APACHESESSIONERROR;
    }
    $self->{id} = $h{_session_id};
    $h{$_} = $self->{sessionInfo}->{$_}
      foreach ( keys %{ $self->{sessionInfo} } );
    $h{_utime} = time();
    untie %h;
    PE_OK;
}

##@method int buildCookie()
# 14) Build the Lemonldap::NG cookie.
#@return Lemonldap::NG::Portal constant
sub buildCookie {
    my $self = shift;
    push @{ $self->{cookie} },
      $self->cookie(
        -name   => $self->{cookieName},
        -value  => $self->{id},
        -domain => $self->{domain},
        -path   => "/",
        -secure => $self->{securedCookie},
        @_,
      );
    PE_OK;
}

##@method int log()
# 15) Log authentication action.
# By default, nothing is logged. Users actions are logged on applications.
# It's easy to override this in the contructor :
# my $portal = new Lemonldap::NG::Portal ( {
#                    ...
#                    log => sub {use Sys::Syslog; syslog;
#                                openlog("Portal $$", 'ndelay', 'auth');
#                                syslog('notice', 'User '.$self->{user}.' is authenticated');
#                               },
#                   ...
#                 } );
#@return Lemonldap::NG::Portal constant
sub log {
    PE_OK;
}

##@method int checkNotification()
# 16) Check if messages has to be notified.
#@return Lemonldap::NG::Portal constant
sub checkNotification {
    my $self = shift;
    if ( $self->{notification} ) {
        my $tmp;
        if ( ref( $self->{notification} ) ) {
            $tmp = $self->{notification};
        }
        else {
            $tmp = $self->{configStorage};
            $tmp->{dbiTable} = 'notifications';
        }
        if ( $self->{_notification} =
            Lemonldap::NG::Common::Notification->new($tmp)
            ->getNotification( $self->{user} ) )
        {
            return PE_NOTIFICATION;
        }
    }
    return PE_OK;
}

##@method int autoRedirect()
# 17) If the user was redirected to the portal, we will now redirect him
#     to the requested URL.
#@return Lemonldap::NG::Portal constant
sub autoRedirect {
    my $self = shift;
    if ( my $u = $self->{urldc} ) {
        $self->updateStatus;
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
         domain         => 'example.com',
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
         ldapServer     => 'ldap.domaine.com,ldap-backup.domaine.com',
         securedCookie  => 1,
         exportedVars  => {
           uid   => 'uid',
           cn    => 'cn',
           mail  => 'mail',
           appli => 'appli',
         },
         # Activate SOAP service
         Soap           => 1
    );
  
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

SOAP mode authentication (client) :

  #!/usr/bin/perl -l
  
  use SOAP::Lite;
  use Data::Dumper;
  
  my $soap =
    SOAP::Lite->proxy('http://auth.example.com/')
    ->uri('urn:/Lemonldap::NG::Common::::CGI::SOAPService');
  my $r = $soap->getCookies( 'user', 'password' );
  
  # Catch SOAP errors
  if ( $r->fault ) {
      print STDERR "SOAP Error: " . $r->fault->{faultstring};
  }
  else {
      my $res = $r->result();
  
      # If authentication failed, display error
      if ( $res->{error} ) {
          print STDERR "Error: " . $soap->error( 'fr', $res->{error} )->result();
      }
  
      # print session-ID
      else {
          print "Cookie: lemonldap=" . $res->{cookies}->{lemonldap};
      }
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

=item * ldapServer: server(s) used to retrive session informations and to valid
credentials (localhost by default). More than one server can be set here
separated by commas. The servers will be tested in the specifies order.
To use TLS, set "ldap+tls://server" and to use LDAPS, set "ldaps://server"
instead of server name. If you use TLS, you can set any of the
Net::LDAP->start_tls() sub like this:
  "ldap/tls://server/verify=none&capath=/etc/ssl"
You can also use caFile and caPath parameters.

=item * ldapPort: tcp port used by ldap server.

=item * ldapBase: base of the ldap directory.

=item * managerDn: dn to used to connect to ldap server. By default, anonymous
bind is used.

=item * managerPassword: password to used to connect to ldap server. By
default, anonymous bind is used.

=item * securedCookie: set it to 1 if you want to protect user cookies.

=item * cookieName: name of the cookie used by Lemonldap::NG (lemon by default).

=item * domain: cookie domain. You may have to give it else the SSO will work
only on your server.

=item * globalStorage: required: L<Apache::Session> library to used to store
session informations.

=item * globalStorageOptions: parameters to bind to L<Apache::Session> module

=item * authentication: sheme to authenticate users (default: "ldap"). It can
be set to:

=over

=item * B<SSL>: See L<Lemonldap::NG::Portal::AuthSSL>.

=back

=item * caPath, caFile: if you use ldap+tls you can overwrite cafile or capath
options with those parameters. This is usefull if you use a shared
configuration.

=item * ldapPpolicyControl: set it to 1 if you want to use LDAP Password Policy

=back

=head2 Methods that can be overloaded

All the functions above can be overloaded to adapt Lemonldap::NG to your
environment. They MUST return one of the exported constants (see above)
and are called in this order by process().

=head3 controlUrlOrigin

If the user was redirected by a Lemonldap::NG handler, stores the url that will be
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

Method implemented into Lemonldap::NG::Portal::Auth* modules. By default
(ldap bind), converts form input into object variables ($self->{user} and
$self->{password}).

=head3 formateParams

Does nothing. To be overloaded if needed.

=head3 formateFilter

Creates the ldap filter using $self->{user}. By default :

  $self->{filter} = "(&(uid=" . $self->{user} . ")(objectClass=inetOrgPerson))";

If $self->{authFilter} is set, it is used instead of this. This is used by
Lemonldap::NG::Portal::Auth* modules to overload filter.

=head3 connectLDAP

Connects to LDAP server.

=head3 bind

Binds to the LDAP server using $self->{managerDn} and $self->{managerPassword}
if exist. Anonymous bind is provided else.

=head3 search

Retrives the LDAP entry corresponding to the user using $self->{filter}.

=head3 setAuthSessionInfo

Same as setSessionInfo but implemented in Lemonldap::NG::Portal::Auth* modules.

=head3 setSessionInfo

Prepares variables to store in central cache (stored temporarily in
C<$self->{sessionInfo}>). It use C<exportedVars> entry (passed to the new sub)
if defined to know what to store else it stores uid, cn and mail attributes.

=head3 getSessionInfo

Pick up an information stored in session.

=head3 setGroups

Does nothing by default.

=head3 authenticate

Method implemented in Lemonldap::NG::Portal::Auth* modules. By default (ldap),
authenticates the user by rebinding to the LDAP server using the dn retrived
with search() and the password.

=head3 store

Stores the informations collected by setSessionInfo into the central cache.
The portal connects the cache using the L<Apache::Session> module passed by
the globalStorage parameters (see constructor).

=head3 unbind

Disconnects from the LDAP server.

=head3 buildCookie

Creates the Lemonldap::NG cookie.

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

=head3 error_type

Give the type of the error (positive, warning or positive)

=head3 translate_template

Define an HTML::Template filter to translate multilingual strings

=head3 _bind( $ldap, $dn, $password )

Method used to bind to the ldap server.

=head3 header

Overloads the CGI::header method to add Lemonldap::NG cookie.

=head3 redirect

Overloads the CGI::redirect method to add Lemonldap::NG cookie.

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

=item * PE_PP_ACCOUNT_LOCKED: account locked

=item * PE_PP_PASSWORD_EXPIRED: password axpired

=item * PE_CERTIFICATEREQUIRED: certificate required

=item * PE_ERROR: unclassified error

=back

=head1 SEE ALSO

L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Portal::SharedConf>, L<CGI>,
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

Copyright (C) 2005-2007 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
