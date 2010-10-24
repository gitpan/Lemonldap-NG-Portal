##@file
# SMTP common functions

##@class
# SMTP common functions
package Lemonldap::NG::Portal::_SMTP;

use strict;
use String::Random;
use MIME::Lite;

our $VERSION = '0.992';

## @method string gen_password(string regexp)
# Generate a complex password based on a regular expression
# @param regexp regular expression
# @return complex password
sub gen_password {
    my $self   = shift;
    my $regexp = shift;

    my $random = new String::Random;
    return $random->randregex($regexp);
}

## @method int send_mail(string mail, string subject, string body, string html)
# Send mail
# @param mail recipient address
# @param subject mail subject
# @param body mail body
# @param html optional set content type to HTML
# @return boolean result
sub send_mail {
    my $self    = shift;
    my $mail    = shift;
    my $subject = shift;
    my $body    = shift;
    my $html    = shift;

    $self->lmLog( "SMTP From " . $self->{mailFrom}, 'debug' );
    $self->lmLog( "SMTP To " . $mail,               'debug' );
    $self->lmLog( "SMTP Subject " . $subject,       'debug' );
    $self->lmLog( "SMTP Body " . $body,             'debug' );
    $self->lmLog( "SMTP HTML flag " . ( $html ? "on" : "off" ), 'debug' );
    eval {
        my $message = MIME::Lite->new(
            From    => $self->{mailFrom},
            To      => $mail,
            Subject => $subject,
            Type    => "TEXT",
            Data    => $body,
        );
        $message->attr( "content-type" => "text/html; charset=utf-8" ) if $html;
        $self->{SMTPServer}
          ? $message->send( "smtp", $self->{SMTPServer} )
          : $message->send();
    };
    if ($@) {
        $self->lmLog( "Send message failed: $@", 'error' );
        return 0;
    }

    return 1;
}

1;
