##@file
# Choice authentication backend file

##@class
# Choice authentication backend class
package Lemonldap::NG::Portal::AuthChoice;

use strict;
use Lemonldap::NG::Portal::_Choice;
use Lemonldap::NG::Portal::Simple;

#inherits Lemonldap::NG::Portal::_Choice

our $VERSION = '0.99.1';

## @apmethod int authInit()
# Build authentication loop
# Check authChoice parameter
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;

    # Build authLoop
    $self->{authLoop} = $self->_buildAuthLoop();

    # Get authentication choice
    $self->{_authChoice} = $self->param( $self->{authChoiceParam} );

    # Check XSS Attack
    $self->{_authChoice} = ""
      if (  $self->{_authChoice}
        and
        $self->checkXSSAttack( $self->{authChoiceParam}, $self->{_authChoice} )
      );

    $self->lmLog( "Authentication choice found: " . $self->{_authChoice},
        'debug' )
      if $self->{_authChoice};

    return $self->_choice->try( 'authInit', 0 );
}

## @apmethod int setAuthSessionInfo()
# Remember authChoice in session
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    $self->{sessionInfo}->{_authChoice} = $self->{_authChoice};

    return $self->_choice->try( 'setAuthSessionInfo', 0 );
}

## @apmethod int extractFormInfo()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;
    return $self->_choice->try( 'extractFormInfo', 0 );
}

## @apmethod int authenticate()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authenticate {
    my $self = shift;
    return $self->_choice->try( 'authenticate', 0 );
}

## @apmethod int authFinish()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authFinish {
    my $self = shift;
    return $self->_choice->try( 'authFinish', 0 );
}

## @apmethod int authLogout()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub authLogout {
    my $self = shift;
    return $self->_choice->try( 'authLogout', 0 );
}

## @apmethod boolean authForce()
# Does nothing
# @return result
sub authForce {
    my $self = shift;
    return $self->_choice->try( 'authForce', 0 );
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::AuthChoice - Perl extension for building LemonLDAP::NG
compatible portals with authentication choice.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'Choice',
	 authChoiceModules => { '1Local' => 'LDAP|LDAP|LDAP', '2OpenID' => 'OpenID|Null|Null' },
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
prompt for authentication choice.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
http://wiki.lemonldap.objectweb.org/xwiki/bin/view/NG/Presentation

=head1 AUTHOR

Clement Oudot, E<lt>clement@oodo.netE<gt>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://forge.objectweb.org/tracker/?group_id=274>

=head1 DOWNLOAD

LemonLDAP::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Clement Oudot

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

