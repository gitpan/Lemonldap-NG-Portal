##@file
# Access control library for lemonldap::ng portal

##@class
# Access control library for lemonldap::ng portal
package Lemonldap::NG::Portal::_LibAccess;

use strict;

our $VERSION = '1.2.0';

# Global variables
our ( $defaultCondition, $locationCondition, $locationRegexp, $cfgNum ) =
  ( undef, undef, undef, 0 );

BEGIN {
    eval {
        require threads::shared;
        threads::shared::share($defaultCondition);
        threads::shared::share($locationCondition);
        threads::shared::share($locationRegexp);
        threads::shared::share($cfgNum);
    };
}

## @method private boolean _grant(string uri)
# Check user's authorization for $uri.
# @param $uri URL string
# @return True if granted
sub _grant {
    my ( $self, $uri ) = splice @_;
    $self->lmLog( "Evaluate access right on $uri", 'debug' );
    $uri =~ m{(\w+)://([^/:]+)(:\d+)?(/.*)?$} or return 0;
    my ( $protocol, $vhost, $port, $path );
    ( $protocol, $vhost, $port, $path ) = ( $1, $2, $3, $4 );
    $path ||= '/';
    $self->lmLog( "Evaluation for vhost $vhost and path $path", 'debug' );

    # Check global maintenance mode
    return 0 if $self->{maintenance};

    # Check vhost maintenance mode
    return 0 if $self->{vhostOptions}->{$vhost}->{vhostMaintenance};

    $self->_compileRules()
      if ( $cfgNum != $self->{cfgNum} );

    if ( defined $locationRegexp->{$vhost} ) {    # Not just a default rule
        $self->lmLog( "Applying access rule from $vhost", 'debug' );
        for ( my $i = 0 ; $i < @{ $locationRegexp->{$vhost} } ; $i++ ) {
            if ( $path =~ $locationRegexp->{$vhost}->[$i] ) {
                $self->lmLog(
                    "Applying access rule "
                      . $locationCondition->{$vhost}->[$i]
                      . " for path $path",
                    'debug'
                );
                return &{ $locationCondition->{$vhost}->[$i] }($self);
            }
        }
    }
    else {
        $self->lmLog( "Applying default access rule from $vhost", 'debug' );
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
        $self->lmLog( "Compiling rules for $vhost", 'debug' );
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
      if ( $cond =~ /^(?:accept|unprotect|skip)$/i );
    return sub { 0 }
      if ( $cond =~ /^(?:deny$|logout)/i );
    my $sub = "sub {my \$self = shift; return ( $cond )}";
    return $self->safe->reval($sub);
}

1;
