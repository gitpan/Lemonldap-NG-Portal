package Lemonldap::NG::Portal::SharedConf;

use strict;
use Lemonldap::NG::Portal::Simple qw(:all);
use Lemonldap::NG::Manager::Conf;
use Safe;

*EXPORT_OK   = *Lemonldap::NG::Portal::Simple::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::Simple::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::Simple::EXPORT;

our $VERSION = "0.42";
our @ISA     = qw(Lemonldap::NG::Portal::Simple);

# Secure jail
our $safe = new Safe;

##################
# OVERLOADED SUB #
##################

# getConf: all parameters returned by the Lemonldap::NG::Manager::Conf object
#          are copied in $self
#          See Lemonldap::NG::Manager::Conf(3) for more
sub getConf {
    my $self = shift;
    my %args;
    if ( ref( $_[0] ) ) {
        %args = %{ $_[0] };
    }
    else {
        %args = @_;
    }
    %$self = ( %$self, %args );
    $self->{lmConf} =
      Lemonldap::NG::Manager::Conf->new( $self->{configStorage} )
      unless $self->{lmConf};
    return 0 unless ( ref( $self->{lmConf} ) );
    my $tmp = $self->{lmConf}->getConf;
    return 0 unless $tmp;
    # Local configuration prepends global
    $self->{$_} = $args{$_} || $tmp->{$_} foreach ( keys %$tmp );
    1;
}

# Here is implemented the 'macro' mechanism.
our $self; # Safe cannot share a variable declared with my
sub setMacros {
    local $self = shift;
    die __PACKAGE__ . ": Unable to get configuration"
      unless ( $self->getConf(@_) );
    while ( my($n, $e) = each ( %{ $self->{macros} } ) ) {
        $e =~ s/\$(\w+)/\$self->{sessionInfo}->{$1}/g;
        $safe->share( '$self', '&encode_base64' );
        $self->{sessionInfo}->{$n} = $safe->reval($e);
    }
    PE_OK;
}

# Here is implemented the 'groups' mechanism. See Lemonldap::NG::Portal for
# more.
sub setGroups {
    local $self = shift;
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
            print STDERR $mesg->error . "\n$filter\n";
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

# Internal sub used to replace Perl expressions in 'groups' rules.
sub scanexpr {
    my $self = shift;
    local $_ = shift;
    my $result;

    # Perl expressions
    if ( s/^{(.*)}$/$1/ or $_ !~ /^\(.*\)$/ ) {
        s/\$(\w+)/\$self->{sessionInfo}->{$1}/g;
        $safe->share( '$self', '&encode_base64'  );
        $result = $safe->reval($_);
        return $result ? "1" : "0";
    }

    # Simple LDAP expression
    unless (/[^\\][\({]/) {
        return $_;
    }

    # Node
    my $brackets  = 0;
    my $exprCount = 0;
    my $tmp;
    my $subexpr;
    my $esc = 0;
    $result = "";
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
        unless ($brackets) {
            $subexpr = $self->scanexpr($subexpr);
            if ( $subexpr eq "1" ) {
                return "1" if ($or);
            }
            elsif ( $subexpr eq "0" ) {
                return "0" unless ($or);
            }
            else {
                $exprCount++;
                $result .= $subexpr;
            }
            $subexpr = '';
        }
    }
    die "Incorrect expression" if $brackets;
    return $result if ( $result eq "0" or $result eq "1" );
    return $result if ( $exprCount == 1 );
    return "($cond$result)";
}

1;
__END__

=head1 NAME

Lemonldap::NG::Portal::SharedConf - Module for building Lemonldap::NG
compatible portals using a central configuration database.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::SharedConf( {
         configStorage => {
             type        => 'DBI',
             dbiChain    => "dbi:mysql:...",
             dbiUser     => "lemonldap",
             dbiPassword => "password",
             dbiTable    => "lmConfig",
         },
    } );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header; # DON'T FORGET THIS (see L<CGI(3)>)
    print "...";

    # or redirect the user to the menu
    print $portal->redirect( -uri => 'https://portal/menu');
  }
  else {
    # Write here the html form used to authenticate with CGI methods.
    # $portal->error returns the error message if athentification failed
    # Warning: by defaut, input names are "user" and "password"
    print $portal->header; # DON'T FORGET THIS (see L<CGI(3)>)
    print "...";
    print '<form method="POST">';
    # In your form, the following value is required for redirection
    print '<input type="hidden" name="url" value="'.$portal->param('url').'">';
    # Next, login and password
    print 'Login : <input name="user"><br>';
    print 'Password : <input name="password" type="password" autocomplete="off">';
    print '<input type="submit" value="go" />';
    print '</form>';
  }

=head1 DESCRIPTION

Lemonldap::NG::Portal::SharedConf is the base module for building Lemonldap::NG
compatible portals using a central database configuration. You have to use by
inheritance.

See L<Lemonldap::NG::Portal::SharedConf> for a complete example.

=head1 METHODS

Same as L<Lemonldap::NG::Portal::Simple>, but Lemonldap::NG::Portal::SharedConf
adds a new sub:

=over

=item * scanexpr: used by setGroups to read combined LDAP and Perl expressions.
See L<Lemonldap::NG::Portal> for more.

=back

=head3 Args

Lemonldap::NG::Portal::SharedConf use the same arguments than
L<Lemonldap::NG::Portal::Simple>, but you can set them either using local
variables passed to C<new()> or using variables issued from the database.

=head2 EXPORT

=head3 Constants

Same as L<Lemonldap::NG::Portal::Simple>.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::SharedConf>,
L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Manager>

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
