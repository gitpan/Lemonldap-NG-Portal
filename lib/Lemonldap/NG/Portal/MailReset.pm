## @file
# Module for password reset by mail

## @class Lemonldap::NG::Portal::MailReset
# Module for password reset by mail
package Lemonldap::NG::Portal::MailReset;

use strict;
use warnings;

our $VERSION = '1.2.2';

use Lemonldap::NG::Portal::Simple qw(:all);
use base qw(Lemonldap::NG::Portal::SharedConf Exporter);
use HTML::Template;
use Encode;
use POSIX qw(strftime);

#inherits Lemonldap::NG::Portal::_SMTP

*EXPORT_OK   = *Lemonldap::NG::Portal::Simple::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::Simple::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::Simple::EXPORT;

## @method boolean process()
# Call functions to handle password reset by mail issued from
# - itself:
#   - smtpInit
#   - extractMailInfo
#   - getMailUser
#   - storeMailSession
#   - sendConfirmationMail
#   - changePassword
#   - sendPasswordMail
# - portal core module:
#   - setMacros
#   - setLocalGroups
#   - setGroups
# - userDB module:
#   - userDBInit
#   - setSessionInfo
# - passwordDB module:
#   - passwordDBInit
# @return 1 if all is OK
sub process {
    my ($self) = splice @_;

    # Process subroutines
    $self->{error} = PE_OK;

    $self->{error} = $self->_subProcess(
        qw(smtpInit userDBInit passwordDBInit extractMailInfo
          getMailUser setSessionInfo setMacros setGroups
          setPersistentSessionInfo setLocalGroups storeMailSession
          sendConfirmationMail changePassword sendPasswordMail)
    );

    return (
        (
                 $self->{error} <= 0
              or $self->{error} == PE_PASSWORD_OK
              or $self->{error} == PE_MAILCONFIRMOK
              or $self->{error} == PE_MAILOK
        ) ? 0 : 1
    );
}

## @method int smtpInit()
# Load SMTP methods
# @return Lemonldap::NG::Portal constant
sub smtpInit {
    my ($self) = splice @_;

    eval { use base qw(Lemonldap::NG::Portal::_SMTP) };

    if ($@) {
        $self->lmLog( "Unable to load SMTP functions ($@)", 'error' );
        return PE_ERROR;
    }

    PE_OK;
}

## @method int extractMailInfo
# Get mail from form or from mail_token
# @return Lemonldap::NG::Portal constant
sub extractMailInfo {
    my ($self) = splice @_;

    unless ( $self->param('mail') || $self->param('mail_token') ) {
        return PE_MAILFIRSTACCESS if ( $self->request_method =~ /GET/ );
        return PE_MAILFORMEMPTY;
    }

    $self->{mail_token}      = $self->param('mail_token');
    $self->{newpassword}     = $self->param('newpassword');
    $self->{confirmpassword} = $self->param('confirmpassword');

    # If a mail token is present, find the corresponding mail
    if ( $self->{mail_token} ) {

        $self->lmLog( "Token given for password reset: " . $self->{mail_token},
            'debug' );

        # Get the corresponding session
        my $h = $self->getApacheSession( $self->{mail_token} );

        if ( ref $h ) {
            $self->{mail}        = $h->{user};
            $self->{mailAddress} = $h->{ $self->{mailSessionKey} };
            $self->lmLog( "User associated to token: " . $self->{mail},
                'debug' );

            # Close session, it will be deleted after password change success
            untie %$h;

        }

        return PE_BADMAILTOKEN unless ( $self->{mail} );
    }
    else {

        # Use submitted value
        $self->{mail} = $self->param('mail');
    }

    $self->{userControl} ||= '^[\w\.\-@]+$';

    # Check mail
    return PE_MALFORMEDUSER unless ( $self->{mail} =~ /$self->{userControl}/o );

    PE_OK;
}

## @method int getMailUser
# Search for user using UserDB module
# @return Lemonldap::NG::Portal constant
sub getMailUser {
    my ($self) = splice @_;

    my $error = $self->getUser();

    if ( $error == PE_USERNOTFOUND or $error == PE_BADCREDENTIALS ) {
        return PE_MAILNOTFOUND;
    }

    return $error;
}

## @method int storeMailSession
# Create mail session and store token
# @return Lemonldap::NG::Portal constant
sub storeMailSession {
    my ($self) = splice @_;

    # Skip this step if confirmation was already sent
    return PE_OK
      if ( $self->{mail_token} or $self->getMailSession( $self->{mail} ) );

    # Create a new session
    my $h = $self->getApacheSession();

    # Set _utime for session autoremove
    # Use default session timeout and mail session timeout to compute it
    my $time        = time();
    my $timeout     = $self->{timeout};
    my $mailTimeout = $self->{mailTimeout} || $timeout;

    $h->{_utime} = $time + ( $mailTimeout - $timeout );

    # Store expiration timestamp for further use
    $h->{mailSessionTimeoutTimestamp}    = $time + $mailTimeout;
    $self->{mailSessionTimeoutTimestamp} = $time + $mailTimeout;

    # Store start timestamp for further use
    $h->{mailSessionStartTimestamp}    = $time;
    $self->{mailSessionStartTimestamp} = $time;

    # Store mail
    $h->{ $self->{mailSessionKey} } =
      $self->getFirstValue( $self->{sessionInfo}->{ $self->{mailSessionKey} } );

    # Store user
    $h->{user} = $self->{mail};

    # Store type
    $h->{_type} = "mail";

    # Untie session
    untie %$h;

    PE_OK;
}

## @method int sendConfirmationMail
# Send confirmation mail
# @return Lemonldap::NG::Portal constant
sub sendConfirmationMail {
    my ($self) = splice @_;

    # Skip this step if user clicked on the confirmation link
    return PE_OK if $self->{mail_token};

    # Check if confirmation mail has already been sent
    my $mail_session = $self->getMailSession( $self->{mail} );
    $self->{mail_already_sent} = ( $mail_session and !$self->{id} ) ? 1 : 0;

    # Read mail session to get creation and expiration dates
    $self->{id} = $mail_session unless $self->{id};

    $self->lmLog( "Mail session found: $mail_session", 'debug' );

    my $h = $self->getApacheSession( $mail_session, 1 );
    $self->{mailSessionTimeoutTimestamp} = $h->{mailSessionTimeoutTimestamp};
    $self->{mailSessionStartTimestamp}   = $h->{mailSessionStartTimestamp};
    untie %$h;

    # Mail session expiration date
    my $expTimestamp = $self->{mailSessionTimeoutTimestamp};

    $self->lmLog( "Mail expiration timestamp: $expTimestamp", 'debug' );

    $self->{expMailDate} = strftime( "%d/%m/%Y", localtime $expTimestamp );
    $self->{expMailTime} = strftime( "%H:%M",    localtime $expTimestamp );

    # Mail session start date
    my $startTimestamp = $self->{mailSessionStartTimestamp};

    $self->lmLog( "Mail start timestamp: $startTimestamp", 'debug' );

    $self->{startMailDate} = strftime( "%d/%m/%Y", localtime $startTimestamp );
    $self->{startMailTime} = strftime( "%H:%M",    localtime $startTimestamp );

    # Ask if user want another confirmation email
    if ( $self->{mail_already_sent} and !$self->param('resendconfirmation') ) {
        return PE_MAILCONFIRMATION_ALREADY_SENT;
    }

    # Get mail address
    unless ( $self->{mailAddress} ) {
        $self->{mailAddress} =
          $self->getFirstValue(
            $self->{sessionInfo}->{ $self->{mailSessionKey} } );
    }

    # Build confirmation url
    my $url = $self->{mailUrl} . "?mail_token=" . $self->{id};
    $url .= '&' . $self->{authChoiceParam} . '=' . $self->{_authChoice}
      if ( $self->{_authChoice} );

    # Build mail content
    my $subject = $self->{mailConfirmSubject};
    my $body;
    my $html;
    if ( $self->{mailConfirmBody} ) {

        # We use a specific text message, no html
        $body = $self->{mailConfirmBody};
    }
    else {

        # Use HTML template
        my $tplfile = $self->getApacheHtdocsPath
          . "/skins/$self->{portalSkin}/mail_confirm.tpl";
        $tplfile = $self->getApacheHtdocsPath . "/skins/common/mail_confirm.tpl"
          unless ( -e $tplfile );
        my $template = HTML::Template->new(
            filename => $tplfile,
            filter   => sub { $self->translate_template(@_) }
        );
        $body = $template->output();
        $html = 1;
    }

    # Replace variables in body
    $body =~ s/\$expMailDate/$self->{expMailDate}/g;
    $body =~ s/\$expMailTime/$self->{expMailTime}/g;
    $body =~ s/\$url/$url/g;
    $body =~ s/\$(\w+)/decode("utf8",$self->{sessionInfo}->{$1})/ge;

    # Send mail
    return PE_MAILERROR
      unless $self->send_mail( $self->{mailAddress}, $subject, $body, $html );

    PE_MAILCONFIRMOK;
}

## @method int changePassword
# Change the password or generate a new password
# @return Lemonldap::NG::Portal constant
sub changePassword {
    my ($self) = splice @_;

    # Check if user wants to generate the new password
    if ( $self->param('reset') ) {

        $self->lmLog(
            "Reset password request for " . $self->{sessionInfo}->{_user},
            'debug' );

        # Generate a complex password
        my $password = $self->gen_password( $self->{randomPasswordRegexp} );

        $self->lmLog( "Generated password: " . $password, 'debug' );

        $self->{newpassword}     = $password;
        $self->{confirmpassword} = $password;
        $self->{forceReset}      = 1;
    }

    # Else a password is required
    else {
        unless ( $self->{newpassword} && $self->{confirmpassword} ) {
            return PE_PASSWORDFIRSTACCESS if ( $self->request_method =~ /GET/ );
            return PE_PASSWORDFORMEMPTY;
        }
    }

    # Modify the password
    $self->{portalRequireOldPassword} = 0;
    my $result = $self->modifyPassword();

    # Mail token can be used only one time, delete the session if all is ok
    if ( $result == PE_PASSWORD_OK or $result == PE_OK ) {

        # Get the corresponding session
        my $h = $self->getApacheSession( $self->{mail_token} );

        if ( ref $h ) {

            $self->lmLog( "Delete mail session " . $self->{mail_token},
                'debug' );

            # Delete it
            tied(%$h)->delete();
        }
        else {
            $self->lmLog( "Mail session not found", 'warn' );
        }

        # Force result to PE_OK to continue the process
        $result = PE_OK;
    }

    return $result;
}

## @method int sendPasswordMail
# Send mail containing the new password
# @return Lemonldap::NG::Portal constant
sub sendPasswordMail {
    my ($self) = splice @_;

    # Get mail address
    unless ( $self->{mailAddress} ) {
        $self->{mailAddress} =
          $self->getFirstValue(
            $self->{sessionInfo}->{ $self->{mailSessionKey} } );
    }

    # Build mail content
    my $subject = $self->{mailSubject};
    my $body;
    my $html;
    if ( $self->{mailBody} ) {

        # We use a specific text message, no html
        $body = $self->{mailBody};
    }
    else {

        # Use HTML template
        my $tplfile = $self->getApacheHtdocsPath
          . "/skins/$self->{portalSkin}/mail_password.tpl";
        $tplfile =
          $self->getApacheHtdocsPath . "/skins/common/mail_password.tpl"
          unless ( -e $tplfile );
        my $template = HTML::Template->new(
            filename => $tplfile,
            filter   => sub { $self->translate_template(@_) }
        );
        $body = $template->output();
        $html = 1;
    }

    # Replace variables in body
    my $password = $self->{newpassword};
    $body =~ s/\$password/$password/g;
    $body =~ s/\$(\w+)/decode("utf8",$self->{sessionInfo}->{$1})/ge;

    # Send mail
    return PE_MAILERROR
      unless $self->send_mail( $self->{mailAddress}, $subject, $body, $html );

    PE_MAILOK;
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::MailReset - Manage password reset by mail

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::MailReset;
  
  my $portal = new Lemonldap::NG::Portal::MailReset();
 
  $portal->process();

  # Write here HTML to manage errors and confirmation messages

=head1 DESCRIPTION

Lemonldap::NG::Portal::MailReset enables password reset by mail

See L<Lemonldap::NG::Portal::SharedConf> for a complete example of use of
Lemonldap::Portal::* libraries.

=head1 METHODS

=head3 process

Main method.

=head1 SEE ALSO

L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Portal::SharedConf>, L<CGI>,
L<http://lemonldap-ng.org/>

=head1 AUTHOR

Clement Oudot, E<lt>clement@oodo.netE<gt>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2009, 2010 by Xavier Guimard E<lt>x.guimard@free.frE<gt> and
Clement Oudot, E<lt>clement@oodo.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
