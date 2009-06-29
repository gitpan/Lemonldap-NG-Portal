# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;

BEGIN { use_ok( 'Lemonldap::NG::Portal::Simple', ':all' ) }

SKIP: {
    eval { require Net::LDAP::Control::PasswordPolicy };
    skip
"Net::LDAP Password Policy Control is not installed (perl-ldap >= 0.35), so Password Policy will not be usable",
      1
      if ($@);
    use_ok('Net::LDAP::Control::PasswordPolicy');
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $p;

# CGI Environment
$ENV{SCRIPT_NAME}     = '/test.pl';
$ENV{SCRIPT_FILENAME} = '/tmp/test.pl';
$ENV{REQUEST_METHOD}  = 'GET';
$ENV{REQUEST_URI}     = '/';
$ENV{QUERY_STRING}    = '';

ok(
    $p = Lemonldap::NG::Portal::Simple->new(
        {
            globalStorage  => 'Apache::Session::File',
            domain         => 'example.com',
            authentication => 'LDAP test=1',
	    user           => '',
	    password       => '',
        }
    ),
    'Portal object'
);

# Arg test passed
ok( $p->{test}, 'Authentication arguments' );

# Process test: first access
ok( $p->process == 0,              'No user' );
ok( $p->{error} == PE_FIRSTACCESS, 'Error code: first access' );

# Process test: user without password
$ENV{REQUEST_URI}  = '/?user=test&password=';
$ENV{QUERY_STRING} = 'user=test&password=';
$p                 = Lemonldap::NG::Portal::Simple->new(
    {
        globalStorage => 'Apache::Session::File',
        domain        => 'example.com',
    }
);

ok( $p->process == 0,            'User without password' );
ok( $p->{error} == PE_FORMEMPTY, 'Error code: missing password' );

# Process test without LDAP
# No ldap
$p->{extractFormInfo} = sub {
    my $self = shift;
    $self->{user}        = 'user';
    $self->{password}    = '';
    PE_OK;
};

$p->{connectLDAP}    = sub { PE_OK };
$p->{bind}           = sub { PE_OK };
$p->{search}         = sub { PE_OK };
$p->{setSessionInfo} = sub { PE_OK };
$p->{unbind}         = sub { PE_OK };
$p->{store}          = sub { PE_OK };
$p->{authenticate}   = sub { PE_OK };
ok( $p->process > 0, 'User OK' );

# Cookie test
$p->{id} = 1;
ok( $p->buildCookie == PE_OK, 'Cookie build' );
ok(
    (
        ref( $p->{cookie} ) eq 'ARRAY' and $p->{cookie}->[0]->isa('CGI::Cookie')
    ),
    'Valid cookie'
);
ok( $p->{cookie}->[0]->value eq '1', 'Cookie value' );

