#==============================================================================
# Liberty Alliance Authentication for LemonLDAP.
#
# This file is part of the LemonLDAP project and released under GPL.
#==============================================================================

package Lemonldap::NG::Portal::AuthLA;

use strict;
use warnings;

use Lemonldap::NG::Portal::SharedConf qw(:all);
use lasso;

*EXPORT_OK   = *Lemonldap::NG::Portal::SharedConf::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::SharedConf::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::SharedConf::EXPORT;

our $VERSION = '0.1';

our @ISA = qw(Lemonldap::NG::Portal::SharedConf);

#==============================================================================
# Overloaded methods
#==============================================================================

sub extractFormInfo {
# extraction des données du XML s'il est présent, sinon
# on appelle la routine normale. Si on est pas en LA,
# toutes les routines suivantes doivent lancer le
# procédé normal ($self->SUPER::extractFormInfo)
}

sub formateFilter {
    # If user is authenticated with LA, it's OK
    return PE_OK;
}

sub connectLDAP {
    # If user is authenticated with LA, abort LDAP connection
    return PE_OK;
}

sub bind {
    # No need to bind
    return PE_OK;
}

sub search {
# vérifie la chaîne de confiance LA
}

sub setSessionInfo {
    # We have to get user information here
    # Use disco service with attribute provider ?
}

sub unbind {
    # No need to unbind
    return PE_OK;
}

1;
__END__

=head1 NAME

Lemonldap::NG::Portal::SharedConf::LA - Provide Liberty Alliance Authentication

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

L<Lemonldap::NG::Portal::SharedConf>, L<Lemonldap::NG::Portal>,
L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Manager>

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
