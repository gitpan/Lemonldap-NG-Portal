# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Lemonldap::NG::Portal::Menu') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$ENV{REQUEST_METHOD} = 'GET';

# Build portal
my $p = Lemonldap::NG::Portal::Simple->new(
    {
        globalStorage   => 'Apache::Session::File',
        domain          => 'example.com',
        error           => 0,
        applicationList => {},
    }
);

# Init menu
$p->menuInit();

ok( ref $p->{menuDisplayModules} eq 'ARRAY', 'Modules displayed' );

