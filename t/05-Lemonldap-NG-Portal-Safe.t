# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;

BEGIN { use_ok( 'Lemonldap::NG::Portal::Simple', ':all' ) }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.



# Create portal object with Safe jail (the default)
my $p;
$ENV{REQUEST_METHOD} = "GET";
ok(
    $p = Lemonldap::NG::Portal::Simple->new(
        {
            globalStorage  => 'Apache::Session::File',
            domain         => 'example.com',
        }
    ),
    'Portal object'
);

# Fake data
my $sessionData = "coudot";
$p->{sessionInfo}->{uid} = $sessionData;
my $envData = "127.0.0.1";
$ENV{REMOTE_ADDR} = $envData;

# Real Safe jail
ok( $p->{useSafeJail} == 1, 'Safe jail on' );
ok( $p->safe->reval('$uid') eq $sessionData, 'Safe jail on - session data' );
ok( $p->safe->reval('$ENV{REMOTE_ADDR}') eq $envData, 'Safe jail on - env data' );

# Fake Safe jail
$p->{useSafeJail} = 0;
ok( $p->{useSafeJail} == 0, 'Safe jail off' );
ok( $p->safe->reval('$uid') eq $sessionData, 'Safe jail off - session data' );
ok( $p->safe->reval('$ENV{REMOTE_ADDR}') eq $envData, 'Safe jail off - env data' );


