package Lemonldap::NG::Portal::SharedConf;

use strict;
use Lemonldap::NG::Portal qw(:all);

*EXPORT_OK = *Lemonldap::NG::Portal::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::EXPORT_TAGS;
*EXPORT = *Lemonldap::NG::Portal::EXPORT;

our $VERSION = "0.1";
our @ISA = qw(Lemonldap::NG::Portal);

sub setGroups {
    my $self = shift;
    die __PACKAGE__.": Unable to get configuration" unless ( $self->getConf(@_) == PE_OK );
    my $groups;
    foreach ( keys %{ $self->{groups} } ) {
        my $filter = $self->scanexpr( $self->{groups}->{$_} );
        next if ( $filter eq "0" );
        if ( $filter eq "1" ) {
            $groups .= "$_ ";
            next;
        }
        else {
            $filter = "(&(uid=" . $self->{user} . ")$filter)";
        }
        my $mesg = $self->{ldap}->search(
            base   => $self->{ldapBase},
            filter => $filter,
            attrs  => ["uid"],
        );
        if ( $mesg->code() != 0 ) {
	    print STDERR $mesg->error."\n$filter\n";
            return PE_LDAPERROR;
        }
        my $entry = $mesg->entry(0);
        if ($entry) {
            $groups .= "$_ ";
        }
    }
    $self->{sessionInfo}->{groups} = $groups;
    PE_OK;
}

sub getConf {

    # MUST BE OVERLOADED
    PE_OK;
}

sub scanexpr {
    my $self = shift;
    local $_ = shift;
    my $r;

    # Perl expressions
    if (s/^{(.*)}$/$1/) {
        s/\$(\w+)/\$self->{sessionInfo}->{$1}/g;
        eval "\$r=($_);";
        die "Incorrect Perl expression: $_ ($@)" if $@;
        return "1"                      if ($r);
        return "0";
    }

    # Simple LDAP expression
    unless (/[^\\][\({]/) {
        return $_;
    }

    # Node
    die "Incorrect expression $_" unless /^\(.*\)$/;
    my @r;
    my $brackets  = 0;
    my $exprCount = 0;
    my $tmp;
    my $subexpr;
    my $esc = 0;
    $r = "";
    my $cond = substr $_, 1, 1;
    my $or = ( $cond eq '|' );

    for ( my $i = 2 ; $i < ( length($_) - 1 ) ; $i++ ) {
        $tmp = substr $_, $i, 1;
        $subexpr .= $tmp;
        if ($esc) {
            $esc = 0;
            next;
        }
        $esc++ if ( $tmp eq "\\" );
        $brackets++ if ( $tmp =~ /^[\({]$/ );
        $brackets-- if ( $tmp =~ /^[\)}]$/ );
        unless ( $brackets ) {
            $subexpr = $self->scanexpr($subexpr);
            if ( $subexpr eq "1" ) {
                return "1" if ($or);
            }
            elsif ( $subexpr eq "0" ) {
                return "0" unless ($or);
            }
            else {
                $exprCount++;
                $r .= $subexpr;
            }
            $subexpr = '';
        }
    }
    die "Incorrect expression" if $brackets;
    return $r if ( $r eq "0" or $r eq "1" );
    return $r if ( $exprCount == 1 );
    return "($cond$r)";
}

1;
__END__
