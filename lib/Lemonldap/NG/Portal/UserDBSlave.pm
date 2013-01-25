## @file
# Slave userDB mechanism

## @class
# Slave userDB mechanism class
package Lemonldap::NG::Portal::UserDBSlave;

use strict;
use Lemonldap::NG::Portal::_Slave;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::UserDBNull;

our $VERSION = '1.2.2_01';
our @ISA     = qw(Lemonldap::NG::Portal::UserDBNull);

## @apmethod int setSessionInfo()
# Search exportedVars values in HTTP headers.
# @return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my $self = shift;

    return PE_FORBIDDENIP
      unless ( $self->checkIP );

    while ( my ( $k, $v ) = each %{ $self->{exportedVars} } ) {
        $v = 'HTTP_' . uc($v);
        $v =~ s/\-/_/g;
        $self->{sessionInfo}->{$k} = $ENV{$v};
    }

    return PE_OK;
}

1;

