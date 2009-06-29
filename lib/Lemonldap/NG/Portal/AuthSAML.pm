## @file
# SAML Consumer skeleton

## @class
# SAML Consumer skeleton
package Lemonldap::NG::Portal::AuthSAML;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '0.1';

## @apmethod int authInit()
# TODO
# Check SAML Consumer configuration.
# @return Lemonldap::NG::Portal error code
sub authInit {
    my $self = shift;
    $self->lmLog( 'This module is not yet usable', 'error' );
    PE_ERROR;
}

## @apmethod int extractFormInfo()
# TODO
# @return Lemonldap::NG::Portal error code
sub extractFormInfo {
    PE_OK;
}

## @apmethod int setAuthSessionInfo()
# TODO
# @return Lemonldap::NG::Portal error code
sub setAuthSessionInfo {
    PE_OK;
}

## @apmethod int authenticate()
# Does nothing here
# @return PE_OK
sub authenticate {
    PE_OK;
}

## @apmethod void authLogout()
# TODO
sub authLogout {
}

## @apmethod array SAMLIssuerLinks()
# TODO
# @return 2 arrays: HTTP links and SAML issuer names
sub SAMLIssuerLinks {
}

1;
__END__

=head1 NAME

Lemonldap::NG::Portal::AuthSAML - TODO

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::AuthSAML;
  #TODO

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<Lemonldap::NG::Portal>

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Xavier Guimard

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
