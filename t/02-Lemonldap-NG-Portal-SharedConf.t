# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal-SharedConf.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Lemonldap::NG::Portal::SharedConf') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $p = bless {}, 'Lemonldap::NG::Portal::SharedConf';
ok( !$p->scanexpr('1 == 0') );
ok( $p->scanexpr('1 == 1') );

