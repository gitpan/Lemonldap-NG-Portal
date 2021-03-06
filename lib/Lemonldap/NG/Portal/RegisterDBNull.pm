##@file
# Null register backend file

##@class
# Null register backend class
package Lemonldap::NG::Portal::RegisterDBNull;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.4.0';

sub getLogin {
    my $self = splice @_;
    $self->{registerInfo}->{login} = "";
    return PE_OK;
}

sub createUser {
    return PE_OK;
}

sub registerDBFinish {
    return PE_OK;
}

1;
