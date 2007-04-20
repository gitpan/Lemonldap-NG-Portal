# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 34;
BEGIN { use_ok( 'Lemonldap::NG::Portal::Simple', ':all' ) }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $p = bless {}, 'Lemonldap::NG::Portal::Simple';

foreach my $i ( 0 .. 10 ) {
    $p->{error} = $i;
    ok( $p->error('fr') );
    ok( $p->error('en') );
    ok( $p->error('') );
}

