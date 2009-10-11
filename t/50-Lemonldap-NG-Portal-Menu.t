# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Lemonldap::NG::Portal::Menu') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $tmp;

my ( $m, $p );

$p = bless { cookieName => 'lemonldap', }, 'Lemonldap::NG::Portal::SharedConf';

ok( $m = Lemonldap::NG::Portal::Menu->new( { portalObject => $p } ),
    'constructor' );

ok( $m->isa('Lemonldap::NG::Portal::Menu'), 'object returned' );

