# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Lemonldap::NG::Portal::Simple', ':all') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $p;
ok( $p = Lemonldap::NG::Portal::Simple->new( {
		globalStorage => 'Apache::Session::File',
		domain => 'example.com',
} ) );

ok( $p->process == 0 );
ok( $p->{error} == PE_FIRSTACCESS );
$p->{id} = 1;
ok( $p->buildCookie == PE_OK );

