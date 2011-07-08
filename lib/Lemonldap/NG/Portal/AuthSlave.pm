##@file
# Slave authentication backend file

##@class
# Slave authentication backend class
package Lemonldap::NG::Portal::AuthSlave;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::AuthNull;

our $VERSION = '1.1.0';
our @ISA     = qw(Lemonldap::NG::Portal::AuthNull);

## @apmethod int extractFormInfo()
# Read username in a specific header.
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;

    my $user_header = $self->{slaveUserHeader};
    $user_header = 'HTTP_' . uc($user_header);
    $user_header =~ s/\-/_/g;

    unless ( $self->{user} = $ENV{$user_header} ) {
        $self->lmLog( "No header " . $self->{slaveUserHeader} . " found",
            'error' );
        return PE_USERNOTFOUND;
    }

    PE_OK;
}

## @apmethod int setAuthSessionInfo()
# Set _user value to 'anonymous' and authenticationLevel to 0
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    # Store user submitted login for basic rules
    $self->{sessionInfo}->{'_user'} = $self->{'user'};

    $self->{sessionInfo}->{authenticationLevel} = $self->{slaveAuthnLevel};

    PE_OK;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::AuthSlave - Perl extension for building Lemonldap::NG
compatible portals with Apache authentication.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'Slave',
    );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header('text/html; charset=utf8'); # DON'T FORGET THIS (see CGI(3))
    print "...";

    # or redirect the user to the menu
    print $portal->redirect( -uri => 'https://portal/menu');
  }
  else {
    print $portal->header('text/html; charset=utf8'); # DON'T FORGET THIS (see CGI(3))
    print "<html><body><h1>Unable to work</h1>";
    print "This server isn't well configured. Contact your administrator.";
    print "</body></html>";
  }

=head1 DESCRIPTION

This library just overload few methods of Lemonldap::NG::Portal::Simple to 
create sessions for anonymous users.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
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

Copyright (C) 2010 by Clement Oudot

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

