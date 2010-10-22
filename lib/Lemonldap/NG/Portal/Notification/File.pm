## @file
# File storage methods for notifications

## @class
# File storage methods for notifications
package Lemonldap::NG::Portal::Notification::File;

use strict;
use MIME::Base64;

our $VERSION = '0.991';

## @method boolean prereq()
# Check if parameters are set and if storage directory exists.
# @return true if all is OK
sub prereq {
    my $self = shift;
    unless ( $self->{dirName} ) {
        $Lemonldap::NG::Portal::Notification::msg =
          '"dirName" is required in "File" configuration type !';
        return 0;
    }
    if ( $self->{table} ) {
        $self->{dirName} =~ s/\/conf\/?$//;
        $self->{dirName} .= "/$self->{table}";
    }
    unless ( -d $self->{dirName} ) {
        $Lemonldap::NG::Portal::Notification::msg =
          "Directory \"$self->{dirName}\" does not exist !";
        return 0;
    }
    1;
}

## @method hashref get(string uid,string ref)
# Returns notifications corresponding to the user $uid.
# If $ref is set, returns only notification corresponding to this reference.
# @param $uid UID
# @param $ref Notification reference
# @return hashref where keys are filenames and values are XML strings
sub get {
    my ( $self, $uid, $ref ) = @_;
    return () unless ($uid);
    opendir D, $self->{dirName};
    my @notif;
    unless ($ref) {
        @notif = grep /^\d{8}_${uid}_\S*\.xml$/, readdir(D);
    }
    else {
        my $tmp = encode_base64( $ref, '' );
        @notif = grep /^\d{8}_${uid}_$tmp.xml$/, readdir(D);
    }
    close D;
    my $files;
    foreach my $file (@notif) {
        unless ( open F, $self->{dirName} . "/$file" ) {
            $self->lmLog( "Unable to read notification $self->{dirName}/$_",
                'error' );
            next;
        }
        $files->{$file} = join( '', <F> );
    }
    return $files;
}

## @method hashref getAll()
# Return all messages not notified.
# @return hashref where keys are internal reference and values are hashref with
# keys date, uid and ref.
sub getAll {
    my $self = shift;
    opendir D, $self->{dirName};
    my @notif;
    @notif = grep /^\S*\.xml$/, readdir(D);
    my %h = map {
        /^(\d{8})_([^\s_]+)_([^\s_]+)\.xml$/
          ? ( $_ => { date => $1, uid => $2, ref => $3 } )
          : ()
    } @notif;
    return \%h;
}

## @method boolean delete(string myref)
# Mark a notification as done.
# @param $myref identifier returned by get() or getAll()
sub delete {
    my ( $self, $myref ) = @_;
    my $new = ( $myref =~ /(.*?)(?:\.xml)$/ )[0] . '.done';
    return rename( $self->{dirName} . "/$myref", $self->{dirName} . "/$new" );
}

## @method boolean purge(string myref)
# Purge notification (really delete record)
# @param $myref identifier returned by get() or getAll()
# @return true if something was deleted
sub purge {
    my ( $self, $myref ) = @_;
    return unlink( $self->{dirName} . "/$myref" );
}

## @method boolean newNotif(string date, string uid, string ref, string xml)
# Insert a new notification
# @param date Date
# @param uid UID
# @param ref Reference of the notification
# @param xml XML notification
# @return true if succeed
sub newNotif {
    my ( $self, $date, $uid, $ref, $xml ) = @_;
    $date =~ s/-//g;
    return ( 0, "Bad date" ) unless ( $date =~ /^\d{8}/ );
    my $filename =
        $self->{dirName}
      . "/${date}_${uid}_"
      . encode_base64( $ref, '' ) . ".xml";
    return ( 0, 'This notification still exists' ) if ( -e $filename );
    my $old = ( $filename =~ /(.*?)(?:\.xml)$/ )[0] . '.done';
    return ( 0, 'This notification has been done' ) if ( -e $old );
    open my $F, ">$filename" or return ( 0, "Unable to create $filename ($!)" );
    binmode($F);
    $xml->toFH($F);
    return ( 0, "Unable to close $filename ($!)" ) unless ( close $F );
    return 1;
}

## @method hashref getDone()
# Returns a list of notification that have been done
# @return hashref where keys are internal reference and values are hashref with
# keys notified, uid and ref.
sub getDone {
    my ($self) = @_;
    opendir D, $self->{dirName};
    my @notif;
    @notif = grep /^\d{8}_\S*\.done$/, readdir(D);
    my $res;
    foreach my $file (@notif) {
        my ( $u, $r ) = ( $file =~ /^\d+_([^_]+)_([^_]+)\.done$/ );
        die unless ( -f "$self->{dirName}/$file" );
        my $time = ( stat("$self->{dirName}/$file") )[10];
        $res->{$file} = {
            'uid'      => $u,
            'ref'      => decode_base64($r),
            'notified' => $time,
        };
    }
    return $res;
}

1;

