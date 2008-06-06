# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

BEGIN {
    our %translations = (
        fr => 'French',
        ro => 'Romanian'
    );
}

use Test::More tests => 5 + ( keys(%translations) * 2 );
BEGIN { use_ok('Lemonldap::NG::Portal::Simple') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok( my @en = @{&Lemonldap::NG::Portal::_i18n::error_en},
    'English translation' );
ok( $#en > 21, 'Translation count' );

foreach ( keys %translations ) {
    ok( my @tmp = @{ &{"Lemonldap::NG::Portal::_i18n::error_$_"} },
        "$translations{$_} translation" );
    ok( $#tmp == $#en, "$translations{$_} translation count" );
}

my $p = bless {}, 'Lemonldap::NG::Portal::Simple';
$p->{error} = 10;
$ENV{HTTP_ACCEPT_LANGUAGE} = 'fr';

ok( $p->error() eq $p->error('fr'), 'HTTP_ACCEPT_LANGUAGE mechanism 1' );
ok( $p->error() ne $p->error('ro'), 'HTTP_ACCEPT_LANGUAGE mechanism 2' );

