##@file
# Access control library for lemonldap::ng portal

##@class
# Access control library for lemonldap::ng portal
package Lemonldap::NG::Portal::_LibAccess;

use strict;
use Lemonldap::NG::Common::Safelib;    #link protected safe Safe object
use Safe;
use constant SAFEWRAP => ( Safe->can("wrap_code_ref") ? 1 : 0 );

# Global variables
our ( $defaultCondition, $locationCondition, $locationRegexp, $cfgNum ) =
  ( undef, undef, undef, 0 );

## @method private boolean _grant(string uri)
# Check user's authorization for $uri.
# @param $uri URL string
# @return True if granted
sub _grant {
    my ( $self, $uri ) = splice @_;
    $uri =~ m{(\w+)://([^/:]+)(:\d+)?(/.*)?$} or return 0;
    my ( $protocol, $vhost, $port, $path );
    ( $protocol, $vhost, $port, $path ) = ( $1, $2, $3, $4 );
    $path ||= '/';
    $self->_compileRules()
      if ( $cfgNum != $self->{cfgNum} );
    return -1 unless ( defined( $defaultCondition->{$vhost} ) );

    if ( defined $locationRegexp->{$vhost} ) {    # Not just a default rule
        for ( my $i = 0 ; $i < @{ $locationRegexp->{$vhost} } ; $i++ ) {
            if ( $path =~ $locationRegexp->{$vhost}->[$i] ) {
                return &{ $locationCondition->{$vhost}->[$i] }($self);
            }
        }
    }
    unless ( $defaultCondition->{$vhost} ) {
        $self->lmLog(
            "Application $uri did not match any configured virtual host",
            'warn' );
        return 0;
    }
    return &{ $defaultCondition->{$vhost} }($self);
    return 1;
}

## @method private boolean _compileRules()
# Parse configured rules and compile them
# @return True
sub _compileRules {
    my $self = shift;
    foreach my $vhost ( keys %{ $self->{locationRules} } ) {
        my $i = 0;
        foreach ( keys %{ $self->{locationRules}->{$vhost} } ) {
            if ( $_ eq 'default' ) {
                $defaultCondition->{$vhost} =
                  $self->_conditionSub(
                    $self->{locationRules}->{$vhost}->{$_} );
            }
            else {
                $locationCondition->{$vhost}->[$i] =
                  $self->_conditionSub(
                    $self->{locationRules}->{$vhost}->{$_} );
                $locationRegexp->{$vhost}->[$i] = qr/$_/;
                $i++;
            }
        }

        # Default policy
        $defaultCondition->{$vhost} ||= $self->_conditionSub('accept');
    }
    $cfgNum = $self->{cfgNum};
    1;
}

## @method private CODE _conditionSub(string cond)
# Return subroutine giving authorization condition.
# @param $cond boolean expression
# @return Compiled routine
sub _conditionSub {
    my ( $self, $cond ) = splice @_;
    return sub { 1 }
      if ( $cond =~ /^(?:accept|unprotect)$/i );
    return sub { 0 }
      if ( $cond =~ /^(?:deny$|logout)/i );
    $cond =~ s/\$date/&POSIX::strftime("%Y%m%d%H%M%S",localtime())/e;
    $cond =~ s/\$(\w+)/\$self->{sessionInfo}->{$1}/g;
    my $sub = "sub {my \$self = shift; return ( $cond )}";
    $sub = (
        SAFEWRAP
        ? $self->safe->wrap_code_ref( $self->safe->reval($sub) )
        : $self->safe->reval($sub)
    );
    return $sub;
}

1;
