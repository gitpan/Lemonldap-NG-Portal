## @file
# Main portal for Lemonldap::NG portal

## @class
# Main portal for Lemonldap::NG portal
package Lemonldap::NG::Portal::SharedConf;

use strict;
use Lemonldap::NG::Portal::Simple qw(:all);
use Lemonldap::NG::Common::Conf;            #link protected lmConf Configuration
use Lemonldap::NG::Common::Conf::Constants; #inherits

*EXPORT_OK   = *Lemonldap::NG::Portal::Simple::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::Simple::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::Simple::EXPORT;

our $VERSION = '0.99.1';
use base qw(Lemonldap::NG::Portal::Simple);
our $confCached;

##################
# OVERLOADED SUB #
##################

## @method protected boolean getConf(hashRef args)
# Copy all parameters returned by the Lemonldap::NG::Common::Conf object in $self.
# @param args hash
# @return True
sub getConf {
    my $self = shift;
    my %args;
    if ( ref( $_[0] ) ) {
        %args = %{ $_[0] };
    }
    else {
        %args = @_;
    }

    my $num = $self->__lmConf->lastCfg;
    unless ( $confCached and $confCached->{cfgNum} == $num ) {
        %$confCached = (
            %{ $self->__lmConf->getConf( cfgNum => $num ) },
            %{ $self->__lmConf->getLocalConf(PORTALSECTION) },
        );
    }
    %$self = ( %$self, %$confCached, %args, );
    1;
}

## @method list getProtectedSites()
# With SharedConf, $locationRules contains a hash table with virtual hosts as
# keys. So we can use it to know all protected virtual hosts.
# @return list list of protected virtual hosts.
sub getProtectedSites {
    my $self = shift;
    my @tab  = ();
    return ( keys %{ $self->{locationRules} } )
      if ( ref $self->{locationRules} );
    return ();
}

sub __lmConf {
    my $self = shift;
    return $self->{lmConf} if ( $self->{lmConf} );
    my $r = Lemonldap::NG::Common::Conf->new( $self->{configStorage} );
    $self->abort(
        "Cannot create configuration object",
        $Lemonldap::NG::Common::Conf::msg
    ) unless ( ref($r) );
    $self->{lmConf} = $r;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::SharedConf - Module for building Lemonldap::NG
compatible portals using a central configuration database.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::SharedConf( {
         configStorage => {
             type        => 'DBI',
             dbiChain    => "dbi:mysql:...",
             dbiUser     => "lemonldap",
             dbiPassword => "password",
             dbiTable    => "lmConfig",
         },
         # Activate SOAP service
         Soap           => 1
    } );

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

Lemonldap::NG::Portal::SharedConf is the base module for building Lemonldap::NG
compatible portals using a central database configuration. You have to use by
inheritance.

See L<Lemonldap::NG::Portal::SharedConf> for a complete example.

=head1 METHODS

Same as L<Lemonldap::NG::Portal::Simple>, but Lemonldap::NG::Portal::SharedConf
adds a new sub:

=over

=item * scanexpr: used by setGroups to read combined LDAP and Perl expressions.
See L<Lemonldap::NG::Portal> for more.

=back

=head3 Args

Lemonldap::NG::Portal::SharedConf use the same arguments than
L<Lemonldap::NG::Portal::Simple>, but you can set them either using local
variables passed to C<new()> or using variables issued from the database.

=head2 EXPORT

=head3 Constants

Same as L<Lemonldap::NG::Portal::Simple>.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::SharedConf>,
L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Manager>,
http://wiki.lemonldap.objectweb.org/xwiki/bin/view/NG/Presentation

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>,
Thomas Chemineau, E<lt>thomas.chemineau@linagora.comE<gt>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://forge.objectweb.org/tracker/?group_id=274>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by Xavier Guimard E<lt>x.guimard@free.frE<gt> and
Thomas Chemineau, E<lt>thomas.chemineau@linagora.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
