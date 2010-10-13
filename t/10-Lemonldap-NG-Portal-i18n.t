# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

BEGIN {
    our %tr_err = (
        fr => 'French',
        ro => 'Romanian',
    );
    our %tr_msg = ( fr => 'French', );
}

use Test::More tests => 7 + ( keys(%tr_err) * 2 ) + ( keys(%tr_msg) * 2 );

BEGIN { use_ok('Lemonldap::NG::Portal::Simple') }

ok( my @en = @{&Lemonldap::NG::Portal::_i18n::error_en},
    'English translation' );
ok( $#en > 21, 'Translation count' );

foreach ( keys %tr_err ) {
    my @tmp;
    ok( @tmp = @{ &{"Lemonldap::NG::Portal::_i18n::error_$_"} },
        "$tr_err{$_} translation" );
    ok( $#tmp == $#en, "$tr_err{$_} translation count" );
}

my $p = bless {}, 'Lemonldap::NG::Portal::Simple';
$p->{error} = 10;
$ENV{HTTP_ACCEPT_LANGUAGE} = 'fr';

ok( $p->error() eq $p->error('fr'), 'HTTP_ACCEPT_LANGUAGE mechanism 1' );
ok( $p->error() ne $p->error('ro'), 'HTTP_ACCEPT_LANGUAGE mechanism 2' );

ok( @en = @{&Lemonldap::NG::Portal::_i18n::msg_en},
    'English messages translation' );
ok( $#en > 19, 'Messages translation count' );

foreach ( keys %tr_msg ) {
    my @tmp;
    ok( @tmp = @{ &{"Lemonldap::NG::Portal::_i18n::msg_$_"} },
        "$tr_msg{$_} messages translation" );
    ok( $#tmp == $#en, "$tr_msg{$_} messages translation count" );
}
