## @file
# Module for password reset by mail

## @class Lemonldap::NG::Portal::MailReset
# Module for password reset by mail
package Lemonldap::NG::Portal::MailReset;

use strict;
use warnings;

our $VERSION = '1.0.0';

use Lemonldap::NG::Portal::Simple qw(:all);
use base qw(Lemonldap::NG::Portal::SharedConf Exporter);
use HTML::Template;

#inherits Lemonldap::NG::Portal::_SMTP

*EXPORT_OK   = *Lemonldap::NG::Portal::Simple::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::Simple::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::Simple::EXPORT;

## @method boolean process()
# Call functions to handle password reset by mail issued from
# - itself:
#   - smtpInit
#   - extractMailInfo
#   - storeMailSession
#   - sendConfirmationMail
#   - sendPasswordMail
# - portal core module:
#   - setMacros
#   - setLocalGroups
#   - setGroups
# - userDB module:
#   - userDBInit
#   - getUser
#   - setSessionInfo
# - passwordDB module:
#   - passwordDBInit
#   - resetPassword
# @return 1 if all is OK
sub process {
    my ($self) = splice @_;

    # Process subroutines
    $self->{error} = PE_OK;

    $self->{error} = $self->_subProcess(
        qw(smtpInit userDBInit passwordDBInit extractMailInfo
          getUser setSessionInfo setMacros setLocalGroups setGroups setPersistentSessionInfo
          storeMailSession sendConfirmationMail resetPassword sendPasswordMail)
    );

    return (
        (
                 $self->{error} <= 0
              or $self->{error} == PE_PASSWORD_OK
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

    return PE_MAILFORMEMPTY
      unless ( $self->param('mail') || $self->param('mail_token') );

    $self->{mail_token} = $self->param('mail_token');

    # If a mail token is present, find the corresponding mail
    if ( $self->{mail_token} ) {

        $self->lmLog( "Token given for password reset: " . $self->{mail_token},
            'debug' );

        # Get the corresponding session
        my $h = $self->getApacheSession( $self->{mail_token} );

        if ( ref $h ) {
            $self->{mail} = $h->{ $self->{mailSessionKey} };
            $self->lmLog( "Mail associated to token: " . $self->{mail},
                'debug' );
        }

        # Mail token can be used only one time, delete the session
        tied(%$h)->delete() if ref $h;

        return PE_BADMAILTOKEN unless ( $self->{mail} );
    }
    else {

        # Use submitted value
        $self->{mail} = $self->param('mail');
    }

    PE_OK;
}

## @method int storeMailSession
# Create mail session and store token
# @return Lemonldap::NG::Portal constant
sub storeMailSession {
    my ($self) = splice @_;

    # Skip this step if confirmation was already sent
    return PE_OK if $self->{mail_token};

    # Create a new session
    my $h = $self->getApacheSession();

    # Set _utime for session autoremove
    $h->{_utime} = time();

    # Store mail
    $h->{ $self->{mailSessionKey} } = $self->{mail};

    # Untie session
    untie %$h;

    PE_OK;
}

## @method int sendConfirmationMail
# Send confirmation mail
# @return Lemonldap::NG::Portal constant
sub sendConfirmationMail {
    my ($self) = splice @_;

    # Skip this step if confirmation was already sent
    return PE_OK if $self->{mail_token};

    # Build confirmation url
    my $url = $self->{mailUrl} . "?mail_token=" . $self->{id};

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
        my $template = HTML::Template->new(
            filename => $ENV{DOCUMENT_ROOT} . "skins/common/mail_confirm.tpl",
            filter   => sub { $self->translate_template(@_) }
        );
        $body = $template->output();
        $html = 1;
    }

    # Replace variables in body
    $body =~ s/\$url/$url/g;
    $body =~ s/\$(\w+)/$self->{sessionInfo}->{$1}/g;

    # Send mail
    return PE_MAILERROR
      unless $self->send_mail( $self->{mail}, $subject, $body, $html );

    PE_MAILOK;
}

## @method int sendPasswordMail
# Send mail containing the new password
# @return Lemonldap::NG::Portal constant
sub sendPasswordMail {
    my ($self) = splice @_;

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
        my $template = HTML::Template->new(
            filename => $ENV{DOCUMENT_ROOT} . "skins/common/mail_password.tpl",
            filter   => sub { $self->translate_template(@_) }
        );
        $body = $template->output();
        $html = 1;
    }

    # Replace variables in body
    my $password = $self->{reset_password};
    $body =~ s/\$password/$password/g;
    $body =~ s/\$(\w+)/$self->{sessionInfo}->{$1}/g;

    # Send mail
    return PE_MAILERROR
      unless $self->send_mail( $self->{mail}, $subject, $body, $html );

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
