##@file
# Notification system for Lemonldap::NG portal

##@class
# Notification system for Lemonldap::NG portal
package Lemonldap::NG::Portal::Notification;

use strict;
use utf8;
use Lemonldap::NG::Portal::SharedConf;
use XML::LibXML;
use XML::LibXSLT;
use CGI::Cookie;

#inherits Lemonldap::NG::Portal::Notification::DBI
#inherits Lemonldap::NG::Portal::Notification::File

our $VERSION = '0.992';
our ( $msg, $stylesheet, $parser );

BEGIN {
    my $xslt = XML::LibXSLT->new();
    $parser = XML::LibXML->new();
    my $style_doc = $parser->parse_string(
        q#<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
 <xsl:output method="html"
             encoding="UTF-8"/>
 <xsl:param name="start"/>
 <xsl:template match="/root/notification">
  <xsl:variable name="level" select="position()"/>
  <xsl:element name="input">
   <xsl:attribute name="type">hidden</xsl:attribute>
     <xsl:attribute name="name">reference<xsl:value-of select="$start"/>x<xsl:value-of select="$level"/></xsl:attribute>
   <xsl:attribute name="value"><xsl:value-of select="@reference"/></xsl:attribute>
  </xsl:element>
  <xsl:for-each select="text">
  <p class="notifText"><xsl:value-of select="."/></p>
  </xsl:for-each>
  <xsl:for-each select="check">
   <xsl:variable name="sublevel" select="position()"/>
   <p class="notifCheck">
    <xsl:element name="input">
     <xsl:attribute name="type">checkbox</xsl:attribute>
     <xsl:attribute name="name">check<xsl:value-of select="$start"/>x<xsl:value-of select="$level"/>x<xsl:value-of select="$sublevel"/></xsl:attribute>
     <xsl:attribute name="id">check<xsl:value-of select="$start"/>x<xsl:value-of select="$level"/>x<xsl:value-of select="$sublevel"/></xsl:attribute>
    </xsl:element>
    <xsl:value-of select="."/>
   </p>
  </xsl:for-each>
 </xsl:template>
</xsl:stylesheet>
#
    );
    $stylesheet = $xslt->parse_stylesheet($style_doc);
}

## @cmethod Lemonldap::NG::Portal::Notification new(hashref storage)
# Constructor.
# @param $storage same syntax as Lemonldap::NG::Common::Conf object
# @return Lemonldap::NG::Portal::Notification object
sub new {
    my ( $class, $storage ) = splice @_;
    my $self = bless {}, $class;
    (%$self) = (%$storage);
    unless ( $self->{p} ) {
        $msg = "p=>portal is required";
        return 0;
    }
    my $type = $self->{type};
    $self->{type} = "Lemonldap::NG::Portal::Notification::$self->{type}"
      unless ( $self->{type} =~ /::/ );
    eval "require $self->{type}";
    if ($@) {
        $msg = "Error: unknown storage type $type";
        return 0;
    }
    unless ( $self->_prereq ) {
        return 0;
    }
    return $self;
}

## @method protected void lmLog(string mess, string level)
# Log subroutine. Call Lemonldap::NG::Portal::lmLog().
# @param $mess Text to log
# @param $level Level (debug|info|notice|error)
sub lmLog {
    my ( $self, $mess, $level ) = splice @_;
    $self->{p}->lmLog( "[Notification] $mess", $level );
}

## @method string getNotification(Lemonldap::NG::Portal portal)
# Check if notification(s) are available for the connected user.
# If it is, encrypt cookies and generate HTML form content.
# @param $portal Lemonldap::NG::Portal object that call
# @return HTML fragment containing form content
sub getNotification {
    my ( $self, $portal ) = splice @_;
    my ( @notifs, $form );

    # Get user datas,
    my $uid = $portal->{notificationField} || $portal->{whatToTrace} || 'uid';
    $uid =~ s/\$//g;
    $uid = $portal->{sessionInfo}->{$uid};

    # Check if some notifications have to be done
    my $n = $self->_get($uid);

    # Return 0 if no notifications were found
    return 0 unless ($n);

    # Prepare HTML code
    @notifs = map { $n->{$_} } sort keys %$n;
    my $i = 0;    # Notification count
    foreach my $notif (@notifs) {
        $i++;
        eval {
            my $xml = $parser->parse_string($notif);
            my $results = $stylesheet->transform( $xml, start => $i );
            $form .= $stylesheet->output_string($results);
        };
        if ($@) {
            $self->lmLog(
                "Bad XML file: a notification for $uid was not done ($@)",
                'warn' );
            return 0;
        }
    }

    # Now a notification has to be done. Replace cookies by hidden fields
    $i = 0;
    while ( my $tmp = shift @{ $portal->{cookie} } ) {
        $i++;
        my $t = $portal->{cipher}->encrypt( $tmp->value );
        unless ( defined($t) ) {
            $self->lmLog(
"Notification for $uid was not done : $Lemonldap::NG::Common::Crypto::msg",
                'warn'
            );
            return 0;
        }
        $tmp->value($t);
        $form .= qq{<input type="hidden" id="cookie$i" name="cookie$i" value="}
          . $tmp->as_string . '" />';
    }
    $form .=
        '<input type="hidden" name="type" value="notification"/>'
      . '<input type="hidden" name="url" value="'
      . $portal->param('url') . '" />';
    return $form;
}

## @method boolean checkNotification(Lemonldap::NG::Portal portal)
# Check if notifications have been displayed and accepted.
# @param $portal Lemonldap::NG::Portal object that call
# @return true if all checkboxes have been checked
sub checkNotification {
    my ( $self, $portal ) = splice @_, 0, 2;
    my ( $refs, $checks );

    # First, rebuild environment (cookies,...)
    foreach ( $portal->param() ) {
        if (/^cookie/) {
            my @tmp   = split /(?:=|;\s+)/, $portal->param($_);
            my %tmp   = @tmp;
            my $value = $portal->{cipher}->decrypt( $tmp[1] );
            unless ( defined($value) ) {
                $self->lmLog( "Unable to decrypt cookie", 'warn' );
                return 0;
            }
            push @{ $portal->{cookie} },
              $portal->cookie(
                -name   => $tmp[0],
                -value  => $value,
                -domain => $tmp{domain},
                -path   => "/",
                -secure => ( grep( /^secure$/, @tmp ) ? 1 : 0 ),
                @_,
              );
            if ( $tmp[0] eq $portal->{cookieName} ) {
                my $tmp = $portal->{existingSession};
                $portal->{existingSession} = sub { 0 };
                $portal->controlExistingSession($value);
                $portal->{existingSession} = $tmp;
            }
        }
        elsif (s/^reference//) {
            $refs->{$_} = $portal->param("reference$_");
        }
        elsif ( s/^check// and /^(\d+x\d+)x(\d+)$/ ) {
            push @{ $checks->{$1} }, $2;
        }
    }
    $portal->controlExistingSession() unless ( $portal->{sessionInfo} );
    unless ( $portal->{sessionInfo} ) {
        $self->lmLog( "Invalid session", 'warn' );
        return 0;
    }
    my $result = 1;
    foreach my $ref ( keys %$refs ) {
        my $uid =
             $portal->{notificationField}
          || $portal->{whatToTrace}
          || 'uid';
        $uid =~ s/\$//g;
        $uid = $portal->{sessionInfo}->{$uid};
        my $files = $self->_get( $uid, $refs->{$ref} );

        unless ($files) {
            $self->lmLog( "Can find notification $refs->{$ref} for $uid",
                'error' );
            next;
        }
        foreach my $file ( keys %$files ) {
            my $xml;
            eval { $xml = $parser->parse_string( $files->{$file} ) };
            if ($@) {
                $self->lmLog( "Bad XML notification for $uid", 'error' );
                next;
            }
            foreach my $notif (
                $xml->documentElement->getElementsByTagName('notification') )
            {
                my $reference  = $notif->getAttribute('reference');
                my @tmp        = $notif->getElementsByTagName('check');
                my $checkCount = @tmp;
                if ( $checkCount == 0
                    or
                    ( $checks->{$ref} and $checkCount == @{ $checks->{$ref} } )
                  )
                {
                    if ( $self->_delete($file) ) {
                        $self->lmLog(
                            "$uid has accepted notification $refs->{$ref}",
                            'notice' );
                    }
                    else {
                        $self->lmLog(
"Unable to delete notification $refs->{$ref} for $uid",
                            'error'
                        );
                    }
                }
                else {
                    $self->lmLog(
                        "$uid has not accepted notification $refs->{$ref}",
                        'notice' );
                    $result = 0;
                }
            }
        }
    }
    return $result;
}

## @method int newNotification(string xml)
# Check XML datas and insert new notifications.
# @param $xml XML string containing notification
# @return number of notifications done
sub newNotification {
    my ( $self, $xml ) = splice @_;
    eval { $xml = $parser->parse_string($xml); };
    if ($@) {
        $self->lmLog( "Unable to read XML file : $@", 'error' );
        return 0;
    }
    my @notifs;
    my ( $version, $encoding ) = ( $xml->version(), $xml->encoding() );
    foreach
      my $notif ( $xml->documentElement->getElementsByTagName('notification') )
    {
        my @datas = ();
        foreach (qw(date uid reference)) {
            my $tmp;
            unless ( $tmp = $notif->getAttribute($_) ) {
                $self->lmLog( "Attribute $_ is missing", 'error' );
                return 0;
            }
            push @datas, $tmp;
        }
        my $result = XML::LibXML::Document->new( $version, $encoding );
        my $root = XML::LibXML::Element->new('root');
        $root->appendChild($notif);
        $result->setDocumentElement($root);
        push @notifs, [ @datas, $result ];
    }
    my $tmp = $self->{type};
    my $count;
    foreach (@notifs) {
        $count++;
        my ( $r, $err ) = $self->_newNotif(@$_);
        die "$err" unless ($r);
    }
    return $count;
}

## @method hashref getAll()
# Return all messages not notified. Wrapper for storage module getAll()
# @return hashref where keys are internal reference and values are hashref with
# keys date, uid and ref.
sub getAll {
    no strict 'refs';
    return &{ $_[0]->{type} . '::getAll' }(@_);
}

## @method hashref getDone()
# Returns a list of notification that have been done. Wrapper for storage module
# getDone().
# @return hashref where keys are internal reference and values are hashref with
# keys notified, uid and ref.
sub getDone {
    no strict 'refs';
    return &{ $_[0]->{type} . '::getDone' }(@_);
}

## @method boolean purge(string myref)
# Purge notification (really delete record). Wrapper for storage module purge()
# @param $myref identifier returned by get or getAll
# @return true if something was deleted
sub purge {
    no strict 'refs';
    return &{ $_[0]->{type} . '::purge' }(@_);
}

## @method private hashref _get(string uid,string ref)
# Returns notifications corresponding to the user $uid. Wrapper for storage
# module get().
# If $ref is set, returns only notification corresponding to this reference.
# @param $uid UID
# @param $ref Notification reference
# @return hashref where keys are internal reference and values are XML strings
sub _get {
    no strict 'refs';
    my $self = $_[0];
    die ref($self)
      unless ( ref($self) eq 'Lemonldap::NG::Portal::Notification' );
    return &{ $_[0]->{type} . '::get' }(@_);
}

## @method private boolean _delete(string myref)
# Mark a notification as done. Wrapper for storage module delete()
# @param $myref identifier returned by get() or getAll()
sub _delete {
    no strict 'refs';
    return &{ $_[0]->{type} . '::delete' }(@_);
}

## @method private boolean _prereq()
# Check if storage module parameters are set. Wrapper for storage module
# prereq()
# @return true if all is OK
sub _prereq {
    no strict 'refs';
    return &{ $_[0]->{type} . '::prereq' }(@_);
}

## @method private boolean _newNotif(string date, string uid, string ref, string xml)
# Insert a new notification. Wrapper for storage module newNotif()
# @param date Date
# @param uid UID
# @param ref Reference of the notification
# @param xml XML notification
# @return true if succeed
sub _newNotif {
    no strict 'refs';
    return &{ $_[0]->{type} . '::newNotif' }(@_);
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::Notification - Provides notification messages system.

=head1 SYNOPSIS

    use Lemonldap::NG::Portal;

=head1 DESCRIPTION

Lemonldap::NG::Portal::Notification.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>,

=head1 AUTHOR

Xavier Guimard E<lt>x.guimard@free.frE<gt>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://forge.objectweb.org/tracker/?group_id=274>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2007, 2010 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut


