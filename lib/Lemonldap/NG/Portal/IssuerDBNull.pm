## @file
# Null Issuer file

## @class
# Null Issuer class
package Lemonldap::NG::Portal::IssuerDBNull;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.2.2_01';

## @method void issuerDBInit()
# Do nothing
# @return Lemonldap::NG::Portal error code
sub issuerDBInit {
    return PE_OK;
}

## @apmethod int issuerForUnAuthUser()
# Do nothing
# @return Lemonldap::NG::Portal error code
sub issuerForUnAuthUser {
    PE_OK;
}

## @apmethod int issuerForAuthUser()
# Do nothing
# @return Lemonldap::NG::Portal error code
sub issuerForAuthUser {
    PE_OK;
}

## @apmethod int issuerLogout()
# Do nothing
# @return Lemonldap::NG::Portal error code
sub issuerLogout {
    PE_OK;
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::IssuerDBNull - Fake IssuerDB for Lemonldap::NG

=head1 DESCRIPTION

This is a fake module for Issuer implementation in LemonLDAP::NG

=head1 SEE ALSO

L<Lemonldap::NG::Portal>

=head1 AUTHOR

Clément Oudot, E<lt>coudot@linagora.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, 2010 by Clement Oudot

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
