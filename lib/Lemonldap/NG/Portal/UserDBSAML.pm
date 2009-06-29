## @file
# UserDB SAML module

## @class
# UserDB SAML module
package Lemonldap::NG::Portal::UserDBSAML;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '0.01';

## @apmethod int userDBInit()
# Check if authentication module is SAML
# @return Lemonldap::NG::Portal error code
sub userDBInit {
    my $self = shift;
    if (   $self->{authentication} =~ /^SAML/
        or $self->{stack}->[0]->[0]->{m} =~ /^SAML/ )
    {
        return PE_OK;
    }
    else {
        return PE_ERROR;
    }
}

## @apmethod int getUser()
# Does nothing
# @return Lemonldap::NG::Portal error code
sub getUser {
    PE_OK;
}

## @apmethod int setSessionInfo()
# Does nothing
# @return Lemonldap::NG::Portal error code
sub setSessionInfo {
    PE_OK;
}

## @apmethod int setGroups()
# Does nothing
# @return Lemonldap::NG::Portal error code
sub setGroups {
    PE_OK;
}
1;
__END__

=head1 NAME

Lemonldap::NG::Portal::UserDBSAML - TODO

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::UserDBSAML;
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
