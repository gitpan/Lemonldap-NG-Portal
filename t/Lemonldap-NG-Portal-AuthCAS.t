# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Manager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# SOAP::Lite is not required, so Lemonldap::NG::Manager::Conf::SOAP may
# not run.
SKIP: {
    eval { require AuthCAS };
    skip "AuthCAS is not installed, so Lemonldap::NG::Portal::AuthCAS will not be useable", 1 if($@);
    use_ok('Lemonldap::NG::Portal::Simple');
    my $p;
    ok( $p = Lemonldap::NG::Portal::Simple->new( {
		globalStorage => 'Apache::Session::File',
		domain => 'example.com',
		authentication => 'CAS',
    } ) );
}
