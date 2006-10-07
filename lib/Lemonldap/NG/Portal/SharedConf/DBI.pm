package Lemonldap::NG::Portal::SharedConf::DBI;

use 5.006;
use strict;
use warnings;

use Lemonldap::NG::Portal::SharedConf qw(:all);
use Sys::Syslog;
use DBI;
use Storable qw(thaw);
use MIME::Base64;

*EXPORT_OK = *Lemonldap::NG::Portal::SharedConf::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::SharedConf::EXPORT_TAGS;
*EXPORT = *Lemonldap::NG::Portal::SharedConf::EXPORT;

our $VERSION = '0.1';

our @ISA = qw(Lemonldap::NG::Portal::SharedConf);

$| = 1;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    die "No DBI chain found" unless ( $self->{dbiChain} );
    return $self;
}

our ( $dbh, $cfgNum ) = ( undef, 0 );

sub getConf {
    my $self = shift;
    our $cfgNum = 0;
    $dbh = DBI->connect_cached(
        $self->{dbiChain}, $self->{dbiUser},
        $self->{dbiPassword}, { RaiseError => 1 }
    );
    my $sth = $dbh->prepare("SELECT max(cfgNum) from config");
    $sth->execute();
    my @row = $sth->fetchrow_array;
    if ( $cfgNum != $row[0] ) {
        $cfgNum = $row[0];
        my $sth =
          $dbh->prepare(
            "select groupRules from config where(cfgNum=$cfgNum)");
        $sth->execute();
        @row = $sth->fetchrow_array;
        $self->{groups} = thaw( decode_base64( $row[0] ) );
    }
    PE_OK;
}

1;
__END__

=head1 NAME

SsoGendarmerie::Portal - Portail SSO Gendarmerie

=head1 SYNOPSIS

  use SsoGendarmerie::Portal;
  blah blah blah

=head1 DESCRIPTION

Déclinaison du portail du SSO Lemonldap pour la gendarmerie.

=head1 SEE ALSO

Lemonldap::NG::Portal(3)

=head1 AUTHOR

CDT Guimard, E<lt>xavier.guimard@gendarmerie.defense.gouv.frE<gt>

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
