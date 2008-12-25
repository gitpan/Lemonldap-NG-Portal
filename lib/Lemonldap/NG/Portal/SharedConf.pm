## @file
# Main portal for Lemonldap::NG portal
#
# @copy 2005, 2006, 2007, 2008, Xavier Guimard &lt;x.guimard@free.fr&gt;

## @class
# Main portal for Lemonldap::NG portal
package Lemonldap::NG::Portal::SharedConf;

use strict;
use Lemonldap::NG::Portal::Simple qw(:all);
use Lemonldap::NG::Common::Conf;

*EXPORT_OK   = *Lemonldap::NG::Portal::Simple::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::Simple::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::Simple::EXPORT;

our $VERSION = "0.5";
use base qw(Lemonldap::NG::Portal::Simple);

##################
# OVERLOADED SUB #
##################

# getConf: all parameters returned by the Lemonldap::NG::Common::Conf object
#          are copied in $self
#          See Lemonldap::NG::Common::Conf(3) for more
sub getConf {
    my $self = shift;
    my %args;
    if ( ref( $_[0] ) ) {
        %args = %{ $_[0] };
    }
    else {
        %args = @_;
    }
    %$self = ( %$self, %args );

    # For better performance the Portal can use the configuration stored in
    # the local file system by the handlers. This can be used when
    # configuration is not local (type DBI or SOAP)
    my $tmp = 0;
    if ( $self->{useLocalCachedConf} and $self->{localStorage} ) {
        $tmp = $self->localGetConf();
    }
    unless ($tmp) {
        $self->{lmConf} =
          Lemonldap::NG::Common::Conf->new( $self->{configStorage} )
          unless $self->{lmConf};
        return 0 unless ( ref( $self->{lmConf} ) );
        $tmp = $self->{lmConf}->getConf;
        return 0 unless $tmp;
    }

    # Local configuration prepends global
    $self->{$_} = $args{$_} || $tmp->{$_} foreach ( keys %$tmp );
    1;
}

sub localGetConf {
    my $self = shift;
    $self->{_refLocalStorage} ||= $self->localStorageObject;
    return $self->{_refLocalStorage}->get('conf');
}

sub localStorageObject {
    my $self = shift;
    eval "use " . $self->{localStorage};
    if ($@) {
        print STDERR "Unable to load "
          . $self->{localStorage}
          . ", local configuration cache is disabled: $@\n";
        return 0;
    }
    my $refLocalStorage;
    eval '$refLocalStorage = new '
      . $self->{localStorage}
      . '($self->{localStorageOptions});';
    if ($@) {
        print STDERR "Unable to access to local configuration storage : $@\n";
        return 0;
    }
    return $refLocalStorage;
}

# With SharedConf, $locationRules contains a hash table with virtual hosts as
# keys. So we can use it to know all protected virtual hosts.
sub getProtectedSites {
    my $self = shift;
    my @tab  = ();
    return ( keys %{ $self->{locationRules} } )
      if ( ref $self->{locationRules} );
    return ();
}

1;
__END__

=head1 NAME

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
    ->uri('urn:/Lemonldap::NG::Portal::SharedConf');
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
