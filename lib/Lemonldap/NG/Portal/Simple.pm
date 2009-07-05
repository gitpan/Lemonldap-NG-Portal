##@file
# Base package for Lemonldap::NG portal

##@class Lemonldap::NG::Portal::Simple
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
use Lemonldap::NG::Portal::_i18n;      #inherits
use Lemonldap::NG::Common::Safelib;    #link protected safe Safe object
use Safe;

# Special comments for doxygen
#inherits Lemonldap::NG::Portal::_SOAP
#inherits Lemonldap::NG::Portal::AuthApache
#inherits Lemonldap::NG::Portal::AuthCAS
#inherits Lemonldap::NG::Portal::AuthLDAP
#inherits Lemonldap::NG::Portal::AuthRemote
#inherits Lemonldap::NG::Portal::AuthSSL
#inherits Lemonldap::NG::Portal::Menu
#link Lemonldap::NG::Portal::Notification protected notification
#inherits Lemonldap::NG::Portal::UserDBLDAP
#inherits Lemonldap::NG::Portal::UserDBRemote
#inherits Lemonldap::NG::Portal::PasswordDBLDAP
#inherits Apache::Session
#link Lemonldap::NG::Common::Apache::Session::SOAP protected globalStorage

our $VERSION = '0.89';

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
    PE_NOSCHEME                         => 38,
    PE_BADOLDPASSWORD                   => 39,
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
  PE_PASSWORD_MISMATCH PE_PASSWORD_OK PE_NOTIFICATION PE_BADURL
  PE_NOSCHEME PE_BADOLDPASSWORD);
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
    $self->{_url} = '';
    $self->getConf(@_)
      or $self->abort( "Configuration error",
        "Unable to get configuration: $Lemonldap::NG::Common::Conf::msg" );
    $self->setDefaultValues();
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
    my $domain = $self->{domain};
    $self->{domain} =~ s/^([^\.])/.$1/;
    $self->{securedCookie}  ||= 0;
    $self->{cookieName}     ||= "lemonldap";
    $self->{authentication} ||= 'LDAP';
    $self->{userDB}         ||= 'LDAP';
    $self->{passwordDB}     ||= 'LDAP';
    $self->{authentication} =~ s/^ldap/LDAP/;
    $self->{mustRedirect} = (
        ( $ENV{REQUEST_METHOD} eq 'POST' and not $self->param('newpassword') )
          or $self->param('logout')
    ) ? 1 : 0;
    $self->{SMTPServer}     ||= 'localhost';
    $self->{mailLDAPFilter} ||= '(&(mail=$mail)(objectClass=inetOrgPerson))';
    $self->{randomPasswordRegexp} ||= '[A-Z]{3}[a-z]{5}.\d{2}';
    $self->{mailFrom}             ||= "noreply@" . $domain;
    $self->{mailSubject}          ||= "Change password request";
    $self->{mailBody}             ||= 'Your new password is $password';

    # Authentication and userDB module are required and have to be in @ISA
    foreach (qw(authentication userDB passwordDB)) {
        my $tmp =
          'Lemonldap::NG::Portal::'
          . ( $_ eq 'userDB'
            ? 'UserDB'
            : ( $_ eq 'passwordDB' ? 'PasswordDB' : 'Auth' ) )
          . $self->{$_};
        $tmp =~ s/\s.*$//;
        eval "require $tmp";
        $self->abort( "Configuration error", $@ ) if ($@);
        push @ISA, $tmp;

        # $self->{authentication} and $self->{userDB} can contains arguments
        # (key1 = scalar_value; key2 = ...)
        unless ( $self->{$_} =~ /^Multi/ ) {
            $tmp = $self->{$_};
            $tmp =~ s/^\w+\s*//;
            my %h = split( /\s*[=;]\s*/, $tmp ) if ($tmp);
            %$self = ( %h, %$self );
        }
    }
    if ( $self->{SAMLIssuer} ) {
        require Lemonldap::NG::Portal::SAMLIssuer;
        push @ISA, 'Lemonldap::NG::Portal::SAMLIssuer';
        $self->SAMLIssuerInit();
    }
    if ( $self->{notification} ) {
        require Lemonldap::NG::Portal::Notification;
        my $tmp;
        if ( $self->{notificationStorage} ) {
            $tmp = $self->{notificationStorage};
        }
        else {
            (%$tmp) = ( %{ $self->{lmConf} } );
            $self->abort( "notificationStorage not defined",
                "This parameter is required to use notification system" )
              unless ( ref($tmp) );
            $tmp->{type} =~ s/.*:://;
            $tmp->{table} = 'notifications';
        }
        $tmp->{p}            = $self;
        $self->{notifObject} = Lemonldap::NG::Portal::Notification->new($tmp);
        $self->abort($Lemonldap::NG::Portal::Notification::msg)
          unless ( $self->{notifObject} );
    }
    if (    $self->{notification}
        and $ENV{PATH_INFO}
        and $ENV{PATH_INFO} =~ m#^/notification# )
    {
        require SOAP::Lite;
        $self->soapTest( 'newNotification', $self->{notifObject} );
        $self->abort( 'Bad request',
            'Only SOAP requests are accepted with "/notification"' );
    }
    if ( $self->{Soap} or $self->{soap} ) {
        require Lemonldap::NG::Portal::_SOAP;
        push @ISA, 'Lemonldap::NG::Portal::_SOAP';
        $self->startSoapServices();
    }
    unless ( defined( $self->{trustedDomains} ) ) {
        $self->{trustedDomains} = $self->{domain};
    }
    if ( $self->{trustedDomains} ) {
        $self->{trustedDomains} = '|(?:[^/]*)?' . join '|',
          map { s/\./\\\./g; $_ } split /\s+/, $self->{trustedDomains};
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

##@method protected void setDefaultValues()
# Set default values.
sub setDefaultValues {
    my $self = shift;
    $self->{whatToTrace} ||= 'uid';
    $self->{whatToTrace} =~ s/^\$//;
}

=begin WSDL

_IN lang $string Language
_IN code $int Error code
_RETURN $string Error string

=end WSDL

=cut

##@method string error(string lang)
# error calls Portal/_i18n.pm to display error in the wanted language.
#@param $lang optional (browser language is used instead)
#@return error message
sub error {
    my $self = shift;
    my $lang = shift || $ENV{HTTP_ACCEPT_LANGUAGE};
    my $code = shift || $self->{error};
    my $tmp  = &Lemonldap::NG::Portal::_i18n::error( $code, $lang );
    return (
        $ENV{HTTP_SOAPACTION}
        ? SOAP::Data->name( result => $tmp )->type('string')
        : $tmp
    );
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

## @method protected hashref getApacheSession(string id)
# Try to recover the session corresponding to id and return session datas.
# If $id is set to undef, return a new session.
# @param $id session reference
sub getApacheSession {
    my ( $self, $id, $noInfo ) = @_;
    my %h;

    # Trying to recover session from global session storage
    eval { tie %h, $self->{globalStorage}, $id, $self->{globalStorageOptions}; };
    if ( $@ or not tied(%h) ) {

        # Session not available (expired ?)
        if ($id) {
            $self->lmLog( "Session $id isn't yet available ($ENV{REMOTE_ADDR})",
                'info' );
        }
        else {
            $self->lmLog( "Unable to create new session: $@", 'error' );
        }
        return 0;
    }
    $self->setApacheUser( $h{ $self->{whatToTrace} } )
      if ( $id and not $noInfo );
    $self->{id} = $h{_session_id};
    return \%h;
}

##@method void updateSession(hashRef infos)
# Update session stored.
# If lemonldap cookie exists, reads it and search session. If the session is
# available, update datas with $info.
#@param $infos hash
sub updateSession {

    # TODO: update all caches
    my $self    = shift;
    my ($infos) = @_;
    my %cookies = fetch CGI::Cookie;

    # Test if Lemonldap::NG cookie is available
    if ( $cookies{ $self->{cookieName} }
        and my $id = $cookies{ $self->{cookieName} }->value )
    {
        my $h = $self->getApacheSession($id) or return undef;

        # Store/update session values
        foreach ( keys %$infos ) {
            $h->{$_} = $infos->{$_};
        }

        untie %$h;
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
        last if ( $err = $self->_sub($sub) );
    }
    return $err;
}
##@method protected void updateStatus()
# Inform status mechanism module.
# If an handler is launched on the same server with "status=>1", inform the
# status module with the result (portal error).
sub updateStatus {
    my $self = shift;
    print $Lemonldap::NG::Handler::Simple::statusPipe (
        $self->{user} ? $self->{user} : $ENV{REMOTE_ADDR} )
      . " => $ENV{SERVER_NAME}$ENV{SCRIPT_NAME} "
      . $self->{error} . "\n"
      if ($Lemonldap::NG::Handler::Simple::statusPipe);
}

##@method protected string notification()
#@return Notification stored by checkNotification()
sub notification {
    my $self = shift;
    return $self->{_notification};
}

##@method protected string get_url()
# Return url parameter
# @return url parameter if good, nothing else.
sub get_url {
    my $self = shift;
    return $self->{_url};
}

##@method protected string get_user()
# Return user parameter
# @return user parameter if good, nothing else.
sub get_user {
    my $self = shift;
    return "" unless $self->{user};
    return $self->{user}
      unless ( $self->{user} =~ m/(?:\0|<|'|"|`|\%(?:00|25|3C|22|27|2C))/ );
    $self->lmLog(
        "XSS attack detected (param: user | value: " . $self->{user} . ")",
        "warn" );
    return "";
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
        $self->lmLog( $@, 'error' ) if ($@);
    }
    $safe->share_from( 'main', ['%ENV'] );
    $safe->share_from( 'Lemonldap::NG::Common::Safelib',
        $Lemonldap::NG::Common::Safelib::functions );
    $safe->share( '&encode_base64', @t );
    return $safe;
}

##@method private boolean _deleteSession(Apache::Session* h)
# Delete an existing session
# @param $h tied Apache::Session object
sub _deleteSession {
    my ( $self, $h ) = @_;
    if ( my $id2 = $h->{_httpSession} ) {
        my $h2 = $self->getApacheSession($id2);
        tied(%$h2)->delete();

        # Delete cookie
        push @{ $self->{cookie} },
          $self->cookie(
            -name    => $self->{cookieName} . 'http',
            -value   => 0,
            -domain  => $self->{domain},
            -path    => "/",
            -secure  => 0,
            -expires => '-1d',
            @_,
          );
    }
    my $r = tied(%$h)->delete();

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
    return $r;
}

###############################################################
# MAIN subroutine: call all steps until one returns something #
#                  different than PE_OK                       #
###############################################################

##@method boolean process()
# Main method.
# process() call functions issued from :
#  - itself : controlUrlOrigin, controlExistingSession, setMacros, setLocalGroups, store, buildCookie, log, autoredirect
#  - authentication module    : extractFormInfo, setAuthSessionInfo, authenticate
#  - user database module     : getUser, setSessionInfo, setGroups
#  - password database module : modifyPassword, resetPasswordByMail
#@return 1 if user is all is OK, 0 if session isn't created or a notification has to be done
sub process {
    my ($self) = @_;
    $self->{error} = PE_OK;
    $self->{error} = $self->_subProcess(
        qw(controlUrlOrigin checkNotifBack controlExistingSession
          SAMLForUnAuthUser authInit extractFormInfo userDBInit getUser
          setAuthSessionInfo passwordDBInit modifyPassword setSessionInfo
          resetPasswordByMail setMacros setLocalGroups setGroups authenticate
          store buildCookie checkNotification SAMLForAuthUser autoRedirect)
    );
    $self->updateStatus;
    return ( ( $self->{error} > 0 ) ? 0 : 1 );
}

##@apmethod int controlUrlOrigin()
# 1) If the user was redirected here, loads 'url' parameter.
#@return Lemonldap::NG::Portal constant
sub controlUrlOrigin {
    my $self = shift;
    $self->{_url} ||= '';
    if ( my $url = $self->param('url') ) {

        # REJECT NON BASE64 URL
        if ( $url =~ m#[^A-Za-z0-9\+/=]# ) {
            $self->lmLog( "XSS attack detected (param: url | value: $url)",
                "warn" );
            return PE_BADURL;
        }

        $self->{urldc} = decode_base64($url);
        $self->{urldc} =~ s/[\r\n]//sg;

        # REJECT [\0<'"`] in URL or encoded '%' and non protected hosts
        if (
            $self->{urldc} =~ /(?:\0|<|'|"|`|\%(?:00|25|3C|22|27|2C))/
            or ( $self->{urldc} !~
m#^https?://(?:$self->{reVHosts}$self->{trustedDomains})(?::\d+)?(?:/.*)?$#o
                and not $self->param('logout') )
          )
        {
            $self->lmLog(
                "XSS attack detected (param: urldc | value: "
                  . $self->{urldc} . ")",
                "warn"
            );
            delete $self->{urldc};
            return PE_BADURL;
        }
        $self->{_url} = $url;
    }
    PE_OK;
}

##@apmethod int checkNotifBack()
# 2) Checks if a message has been notified to the connected user.
# Call Lemonldap::NG::Portal::Notification::checkNotification()
#@return Lemonldap::NG::Portal error code
sub checkNotifBack {
    my $self = shift;
    if ( $self->{notification} and grep( /^reference/, $self->param() ) ) {
        unless ( $self->{notifObject}->checkNotification($self) ) {
            $self->{_notification} =
              $self->{notifObject}->getNotification($self);
            return PE_NOTIFICATION;
        }
        else {
            $self->{error} = $self->_subProcess(
                qw(checkNotification SAMLForAuthUser autoRedirect));
            return $self->{error} || PE_DONE;
        }
    }
    PE_OK;
}

##@apmethod int SAMLForUnAuthUser()
# Load Lemonldap::NG::Portal::SAMLIssuer::SAMLForUnAuthUser() if
# $self->{SAMLIssuer} is set.
#@return Lemonldap::NG::Portal constant
sub SAMLForUnAuthUser {
    return $self->SUPER::SAMLForUnAuthUser(@_) if ( $self->{SAMLIssuer} );
    PE_OK;
}

##@apmethod int controlExistingSession(string id)
# 3) Control existing sessions.
# To overload to control what to do with existing sessions.
# what to do with existing sessions ?
#       - nothing: user is authenticated and process returns true (default)
#       - delete and create a new session (not implemented)
#       - re-authentication (set existingSession => sub{PE_OK})
#@param $id optional value of the session-id else cookies are examinated.
#@return Lemonldap::NG::Portal constant
sub controlExistingSession {
    my ( $self, $id ) = @_;
    my %cookies;
    %cookies = fetch CGI::Cookie unless ($id);

    # Test if Lemonldap::NG cookie is available
    if (
        $id
        or (    $cookies{ $self->{cookieName} }
            and $id = $cookies{ $self->{cookieName} }->value )
      )
    {
        my $h = $self->getApacheSession($id) or return PE_OK;
        %{ $self->{sessionInfo} } = %$h;

        # Logout if required
        if ( $self->param('logout') ) {

            # Delete session in global storage
            $self->_deleteSession($h);
            $self->{error} = PE_REDIRECT;
            $self->SAMLLogout() if ( $self->{SAMLIssuer} );
            $self->_sub( 'userNotice',
                $self->{sessionInfo}->{ $self->{whatToTrace} }
                  . " has been disconnected" );
            eval { $self->_sub('authLogout') };
            $self->_subProcess(qw(autoRedirect));
            return PE_FIRSTACCESS;
        }
        untie %$h;
        $self->{id} = $id;

        # A session has been find => calling &existingSession
        my $r = $self->_sub( 'existingSession', $id, $self->{sessionInfo} );
        if ( $r == PE_DONE ) {
            $self->{error} =
              $self->_subProcess(qw(checkNotification autoRedirect));
            return $self->{error} || PE_DONE;
        }
        else {
            return $r;
        }
    }
    PE_OK;
}

## @method int existingSession()
# Launched by controlExistingSession() to know what to do with existing
# sessions.
# Can return :
# - PE_DONE : session is unchanged and process() return true
# - PE_OK : process() return false to display the form
#@return Lemonldap::NG::Portal constant
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

#  . passwordDBInit() : must be implemented in PasswordDB* module

#  . modifyPassword() : must be implemented in PasswordDB* module

##@apmethod int setSessionInfo()
# 9) Call setSessionInfo() in User* module and set ipAddr and startTime
#@return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my $self = shift;

    # Store IP address and start time
    $self->{sessionInfo}->{ipAddr} = $ENV{REMOTE_ADDR};

    # Extract client IP from X-FORWARDED-FOR header
    my $xheader = $ENV{HTTP_X_FORWARDED_FOR};
    $xheader =~ s/(.*?)(\,)+.*/$1/ if $xheader;
    $self->{sessionInfo}->{xForwardedForAddr} = $xheader || $ENV{REMOTE_ADDR};
    $self->{sessionInfo}->{startTime} =
      &POSIX::strftime( "%Y%m%d%H%M%S", localtime() );
    $self->lmLog(
        "Store ipAddr: " . $self->{sessionInfo}->{ipAddr} . " in session",
        'debug' );
    $self->lmLog(
        "Store xForwardedForAddr: "
          . $self->{sessionInfo}->{xForwardedForAddr}
          . " in session",
        'debug'
    );
    $self->lmLog(
        "Store startTime: " . $self->{sessionInfo}->{startTime} . " in session",
        'debug'
    );
    return $self->SUPER::setSessionInfo();
}

#  . resetPasswordByMail() : must be implemented in PasswordDB* module

##@apmethod int setMacro()
# 10) macro mechanism.
#                  * store macro results in $self->{sessionInfo}
#@return Lemonldap::NG::Portal constant
sub setMacros {
    local $self = shift;
    $self->safe->share('$self');
    while ( my ( $n, $e ) = each( %{ $self->{macros} } ) ) {
        $e =~ s/\$(\w+)/\$self->{sessionInfo}->{$1}/g;
        $self->{sessionInfo}->{$n} = $self->safe->reval($e);
    }
    PE_OK;
}

##@apmethod int setLocalGroups()
# 11) groups mechanism.
#                    * store all groups name that the user match in
#                      $self->{sessionInfo}->{groups}
#@return Lemonldap::NG::Portal constant
sub setLocalGroups {
    local $self = shift;
    my $groups;
    $self->safe->share('$self');
    while ( my ( $group, $expr ) = each %{ $self->{groups} } ) {
        $expr =~ s/\$(\w+)/\$self->{sessionInfo}->{$1}/g;
        $groups .= "$group; " if ( $self->safe->reval($expr) );
    }
    $self->{sessionInfo}->{groups} = $groups;
    PE_OK;
}

#  . setGroups() : must be implemented in UserDB* module

##@apmethod int authenticate()
# 12. Call authenticate() in Auth* module and call userNotice().
#@return Lemonldap::NG::Portal constant
sub authenticate {
    my $self = shift;
    my $tmp;
    return $tmp if ( $tmp = $self->SUPER::authenticate() );
    $self->_sub( 'userNotice',
        "Good authentication for "
          . $self->{sessionInfo}->{ $self->{whatToTrace} } );
    PE_OK;
}

##@apmethod int store()
# 13) Store user's datas in sessions database.
#     Now, the user is known, authenticated and session variable are evaluated.
#     It's time to store his parameters with Apache::Session::* module
#@return Lemonldap::NG::Portal constant
sub store {
    my ($self) = @_;

    # Now, user is authenticated => inform Apache
    $self->setApacheUser( $self->{sessionInfo}->{ $self->{whatToTrace} } );

    $self->{sessionInfo}->{_utime} = time();
    if ( $self->{securedCookie} == 2 ) {
        my $h2 = $self->getApacheSession(undef);
        $h2->{$_} = $self->{sessionInfo}->{$_}
          foreach ( keys %{ $self->{sessionInfo} } );
        $self->{sessionInfo}->{_httpSession} = $h2->{_session_id};
        $h2->{_httpSessionType} = 1;
        untie %$h2;
    }
    my $h = $self->getApacheSession(undef) or return PE_APACHESESSIONERROR;
    $h->{$_} = $self->{sessionInfo}->{$_}
      foreach ( keys %{ $self->{sessionInfo} } );
    untie %$h;
    PE_OK;
}

##@apmethod int buildCookie()
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
    if ( $self->{securedCookie} == 2 ) {
        push @{ $self->{cookie} },
          $self->cookie(
            -name   => $self->{cookieName} . "http",
            -value  => $self->{sessionInfo}->{_httpSession},
            -domain => $self->{domain},
            -path   => "/",
            -secure => 0,
            @_,
          );
    }
    PE_OK;
}

##@apmethod int checkNotification()
# 15) Check if messages has to be notified.
# Call Lemonldap::NG::Portal::Notification::getNotification().
#@return Lemonldap::NG::Portal constant
sub checkNotification {
    my $self = shift;
    if (    $self->{notification}
        and $self->{_notification} =
        $self->{notifObject}->getNotification($self) )
    {
        return PE_NOTIFICATION;
    }
    return PE_OK;
}

##@apmethod int SAMLForAuthUser()
# Load Lemonldap::NG::Portal::SAMLIssuer::SAMLForAuthUser() if
# $self->{SAMLIssuer} is set.
#@return Lemonldap::NG::Portal constant
sub SAMLForAuthUser {
    return $self->SUPER::SAMLForAuthUser(@_) if ( $self->{SAMLIssuer} );
    PE_OK;
}

##@apmethod int autoRedirect()
# 16) If the user was redirected to the portal, we will now redirect him
#     to the requested URL.
#@return Lemonldap::NG::Portal constant
sub autoRedirect {
    my $self = shift;

    # default redirection URL
    $self->{urldc} ||= $self->{portal} if ( $self->{mustRedirect} );

    # Redirection should be made if
    #  - urldc defined
    #  - no warnings on ppolicy
    if (    $self->{urldc}
        and !$self->{ppolicy}->{time_before_expiration}
        and !$self->{ppolicy}->{grace_authentications_remaining} )
    {

        # Cross-domain mechanism
        if (    $self->{cda}
            and $self->{id}
            and $self->{urldc} !~ m#^https?://[^/]*$self->{domain}/#oi )
        {
            $self->lmLog( 'CDA request', 'debug' );
            $self->{urldc} .=
                ( $self->{urldc} =~ /\?/ ? '&' : '?' )
              . $self->{cookieName} . "="
              . $self->{id};
        }
        $self->updateStatus;
        print $self->SUPER::redirect(
            -uri    => $self->{urldc},
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
    ->uri('urn:/Lemonldap::NG::Common::CGI::SOAPService');
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

If $self->{AuthLDAPFilter} is set, it is used instead of this. This is used by
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
