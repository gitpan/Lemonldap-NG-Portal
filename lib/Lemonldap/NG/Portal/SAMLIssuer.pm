## @file
# SAML Issuer skeleton

## @class
# SAML Issuer skeleton
package Lemonldap::NG::Portal::SAMLIssuer;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '0.01';

## @method void SAMLIssuerInit()
# TODO
# Load and check SAML Issuer configuration
sub SAMLIssuerInit {
    my $self = shift;
    $self->abort('This feature is not released');
    return PE_OK;
}

## @apmethod int SAMLForUnAuthUser()
# TODO
# Check if there is an SAML authentication request.
# Called only for unauthenticated users, it store SAML request in
# $self->{url}
# @return Lemonldap::NG::Portal error code
sub SAMLForUnAuthUser {
    my $self = shift;
    PE_OK;
}

## @apmethod int SAMLForAuthUser()
# TODO
# Check if there is an SAML authentication request for an authenticated user
# and build assertions
# @return Lemonldap::NG::Portal error code
sub SAMLForAuthUser {
    my $self = shift;
    PE_OK;
}

## @method void SAMLLogout()
# TODO
sub SAMLLogout {
    my $self = shift;
}

1;
__END__

=head1 NAME

Lemonldap::NG::Portal::SAMLIssuer - TODO

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SAMLIssuer;
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
