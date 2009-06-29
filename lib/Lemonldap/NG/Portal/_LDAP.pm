##@file
# LDAP common functions

##@class
# LDAP common functions
package Lemonldap::NG::Portal::_LDAP;

require Net::LDAP; #inherits
use Exporter;
use base qw(Exporter Net::LDAP);
use Lemonldap::NG::Portal::Simple;
use strict;

our @EXPORT = qw(ldap);

our $VERSION = '0.2';

## @cmethod Lemonldap::NG::Portal::_LDAP new(Lemonldap::NG::Portal::Simple portal)
# Build a Net::LDAP object using parameters issued from $portal
# @return Lemonldap::NG::Portal::_LDAP object
sub new {
    my $class  = shift;
    my $portal = shift;
    my $self;
    unless ($portal) {
        $class->abort("$class : portal argument required !");
    }
    my $useTls = 0;
    my $tlsParam;
    my @servers = ();
    foreach my $server ( split /[\s,]+/, $portal->{ldapServer} ) {
        if ( $server =~ m{^ldap\+tls://([^/]+)/?\??(.*)$} ) {
            $useTls   = 1;
            $server   = $1;
            $tlsParam = $2 || "";
        }
        else {
            $useTls = 0;
        }
        push @servers, $server;
    }
    $self = Net::LDAP->new(
        \@servers,
            onerror => undef,
        ( $portal->{ldapPort} ? ( port => $portal->{ldapPort} ) : () ),
          );
    unless ($self) {
        $portal->lmLog( $@, 'error' );
        return 0;
    }
    bless $self, $class;
    if ($useTls) {
        my %h = split( /[&=]/, $tlsParam );
        $h{cafile} = $portal->{caFile} if ( $portal->{caFile} );
        $h{capath} = $portal->{caPath} if ( $portal->{caPath} );
        my $mesg = $self->start_tls(%h);
        if ( $mesg->code ) {
            $portal->lmLog( 'StartTLS failed', 'error' );
            return 0;
        }
    }
    $self->{portal} = $portal;
    return $self;
}

## @method Net::LDAP::Message bind(string dn, %args)
# Reimplementation of Net::LDAP::bind(). Connection is done :
# - with $dn and $args->{password} as dn/password if defined,
# - or with Lemonldap::NG account,
# - or with an anonymous bind.
# @param $dn LDAP distinguish name
# @param %args See Net::LDAP(3) manpage for more
# @return Net::LDAP::Message
sub bind {
    my $self = shift;
    my $mesg;
    my ( $dn, %args ) = @_;
    unless ($dn) {
        $dn = $self->{portal}->{managerDn};
        $args{password} = $self->{portal}->{managerPassword};
    }
    if ( $dn && $args{password} ) {
        $mesg = $self->SUPER::bind( $dn, %args );
    }
    else {
        $mesg = $self->SUPER::bind();
    }
    return $mesg;
}

our $ppLoaded = 0;

## @method private boolean loadPP ()
# Load Net::LDAP::Control::PasswordPolicy
# @return true if succeed.
sub loadPP {
    my $self = shift;
    return 1 if ($ppLoaded);

    # require Perl module
    eval {require Net::LDAP::Control::PasswordPolicy};
    if ($@) {
        $self->lmLog(
            "Module Net::LDAP::Control::PasswordPolicy not found in @INC",
            'error' );
        return 0;
    }
    $ppLoaded = 1;
}

## @method protected int userBind(string dn, %args)
# Call bind() with dn/password and return
# @param $dn LDAP distinguish name
# @param %args See Net::LDAP(3) manpage for more
# @return Lemonldap::NG portal error code
sub userBind {
    my $self = shift;
    if ( $self->{portal}->{ldapPpolicyControl} ) {

        # Create Control object
        my $pp = Net::LDAP::Control::PasswordPolicy->new();

        # Bind with user credentials
        my $mesg = $self->bind(
            @_,
            control  => [$pp]
        );

        # Get server control response
        my ($resp) = $mesg->control("1.3.6.1.4.1.42.2.27.8.5.1");
        return ( $mesg->code == 0 ? PE_OK : PE_LDAPERROR )
          unless ( defined $resp );

        # Get expiration warning and graces
        # 
        $self->{portal}->{mustRedirect} = 0 if($self->{portal}->{ppolicy}->{time_before_expiration} = $resp->time_before_expiration or $self->{portal}->{ppolicy}->{grace_authentications_remaining} = $resp->grace_authentications_remaining);

        my $pp_error = $resp->pp_error;
        if ( defined $pp_error ) {
            $self->{portal}->_sub( 'userError', "Password policy error $pp_error for $self->{portal}->{user}" );
            return [
                PE_PP_PASSWORD_EXPIRED,
                PE_PP_ACCOUNT_LOCKED,
                PE_PP_CHANGE_AFTER_RESET,
                PE_PP_PASSWORD_MOD_NOT_ALLOWED,
                PE_PP_MUST_SUPPLY_OLD_PASSWORD,
                PE_PP_INSUFFICIENT_PASSWORD_QUALITY,
                PE_PP_PASSWORD_TOO_SHORT,
                PE_PP_PASSWORD_TOO_YOUNG,
                PE_PP_PASSWORD_IN_HISTORY,
            ]->[$pp_error];
        }
        elsif ( $mesg->code == 0 ) {
            return PE_OK;
        }
    }
    else {
        my $mesg =
          $self->bind( @_ );
        if ( $mesg->code == 0 ) {
            return PE_OK;
        }
    }
    $self->{portal}->_sub( 'userError', "Bad password for $self->{portal}->{user}" );
    return PE_BADCREDENTIALS;
}

## @method private int _changePassword(string newpassword,string confirmpassword,string oldpassword)
# Change user's password.
# @param $newpassword New password
# @param $confirmpassword New password
# @param $oldpassword Current password
# @return Lemonldap::NG::Portal constant
sub userModifyPassword {

    my $self = shift;
    my ( $dn, $newpassword, $confirmpassword, $oldpassword ) = @_;
    my $err;
    my $mesg;

    # Verify confirmation password matching
    return PE_PASSWORD_MISMATCH unless ( $newpassword eq $confirmpassword );

    # First case: no ppolicy
    if ( !$self->{portal}->{ldapPpolicyControl} ) {
       
        if ( $self->{portal}->{ldapSetPassword} ) { 
            # Use SetPassword extended operation
            use Net::LDAP::Extension::SetPassword;
            $mesg = ( $oldpassword )
                ? $self->set_password( user => $dn,
                                       oldpasswd => $oldpassword,
                                       newpassword => $newpassword )
                : $self->set_password( user => $dn,
                                       newpassword => $newpassword );
            # Catch the "Unwilling to perform" error
            return PE_BADOLDPASSWORD if ( $mesg->code == 53 );
        } else {
            if ( $oldpassword ) {
                # Check old password with a bind
                $mesg = $self->bind ($dn, password => $oldpassword);
                return PE_BADOLDPASSWORD if ( $mesg->code != 0 );
                # Rebind as Manager
                $self->bind();
            }
            # Use standard modification
            $mesg = $self->modify( $dn,
                                   replace => { userPassword => $newpassword } );
        }

        return PE_WRONGMANAGERACCOUNT
          if ( $mesg->code == 50 || $mesg->code == 8 );
        return PE_LDAPERROR unless ( $mesg->code == 0 );
        $self->{portal}->_sub( 'userNotice', "Password changed $self->{portal}->{user}" );
        return PE_PASSWORD_OK;
    }
    else {
        # Create Control object
        my $pp = Net::LDAP::Control::PasswordPolicy->new;

        if ( $self->{portal}->{ldapSetPassword} ) { 
            # Use SetPassword extended operation
            # Warning: need a patch on Perl-LDAP
            # See http://groups.google.com/group/perl.ldap/browse_thread/thread/5703a41ccb17b221/377a68f872cc2bb4?lnk=gst&q=setpassword#377a68f872cc2bb4
            use Net::LDAP::Extension::SetPassword;
            $mesg = ( $oldpassword )
                ? $self->set_password( user => $dn,
                                       oldpasswd => $oldpassword,
                                       newpassword => $newpassword,
                                       control => [$pp] )
                : $self->set_password( user => $dn,
                                       newpassword => $newpassword,
                                       control => [$pp] );
            # Catch the "Unwilling to perform" error
            return PE_BADOLDPASSWORD if ( $mesg->code == 53 );
        } else { 
            if ( $oldpassword ) {
                # Check old password with a bind
                $mesg = $self->bind($dn, password => $oldpassword);
                return PE_BADOLDPASSWORD if ( $mesg->code != 0 );
                # Rebind as Manager
                $self->bind();
            }
            # Use standard modification
            $mesg = $self->modify( $dn,
                                   replace => { userPassword => $newpassword }, 
                                   control => [$pp] );
        }

        # Get server control response
        my ($resp) = $mesg->control("1.3.6.1.4.1.42.2.27.8.5.1");

        return PE_WRONGMANAGERACCOUNT
          if ( $mesg->code == 50 || $mesg->code == 8 );
        if ( $mesg->code == 0 ) {
            $self->{portal}->_sub( 'userNotice', "Password changed $self->{portal}->{user}" );
            return PE_PASSWORD_OK;
        }

        if ( defined $resp ) {
            my $pp_error = $resp->pp_error;
            if ( defined $pp_error ) {
            $self->{portal}->_sub( 'userError', "Password policy error $pp_error for $self->{portal}->{user}" );
                return [
                    PE_PP_PASSWORD_EXPIRED,
                    PE_PP_ACCOUNT_LOCKED,
                    PE_PP_CHANGE_AFTER_RESET,
                    PE_PP_PASSWORD_MOD_NOT_ALLOWED,
                    PE_PP_MUST_SUPPLY_OLD_PASSWORD,
                    PE_PP_INSUFFICIENT_PASSWORD_QUALITY,
                    PE_PP_PASSWORD_TOO_SHORT,
                    PE_PP_PASSWORD_TOO_YOUNG,
                    PE_PP_PASSWORD_IN_HISTORY,
                ]->[$pp_error];
            }
        }
        else {
            return PE_LDAPERROR;
        }
    }
}

## @method protected Lemonldap::NG::Portal::_LDAP ldap()
# @return Lemonldap::NG::Portal::_LDAP object
sub ldap {
    my $self = shift;
    return $self->{ldap} if ( ref( $self->{ldap} ) );
    if ( $self->{ldap} = Lemonldap::NG::Portal::_LDAP->new($self)
        and my $mesg = $self->{ldap}->bind )
    {
        return $self->{ldap} if ( $mesg->code == 0 );
        $self->lmLog( "LDAP error: " . $mesg->error, 'error' );
    }
    else {
        $self->lmLog( "LDAP error: $@", 'error' );
    }
    return 0;
}

1;
