# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Portal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

package My::Portal;
use strict;
use Test::More tests => 16;
BEGIN { use_ok( 'Lemonldap::NG::Portal::Simple', ':all' ) }

#use Lemonldap::NG::Portal::Simple;

our @ISA = 'Lemonldap::NG::Portal::Simple';
my ( $url, $result, $logout );
$logout = 0;
my @h = (

    '' => PE_OK, 'Empty',

    # http://test.example.com/
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb20v' => PE_OK, 'Protected virtual host',

    # http://test.example.com
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb20v' => PE_OK, 'Missing / in URL',

    # http://test.example.com:8000/test
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb206ODAwMC90ZXN0' => PE_OK, 'Non default port',

    # http://test.example.com:8000
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb206ODAwMA==' => PE_OK,
    'Non default port with missing /',

    # http://t.example2.com/test
    'aHR0cDovL3QuZXhhbXBsZTIuY29tL3Rlc3Q=' => PE_OK,
    'Undeclared virtual host in trusted domain',

    # http://t.example.com/test
    'aHR0cDovL3QuZXhhbXBsZS5jb20vdGVzdA==' => PE_BADURL,
    'Undeclared virtual host in (untrusted) protected domain',

    'http://test.com/' => PE_BADURL, 'Non base64 encoded characters',

    # http://test.example.com:8000V
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb206ODAwMFY=' => PE_BADURL,
    'Non number in port',

    # http://t.ex.com/test
    'aHR0cDovL3QuZXguY29tL3Rlc3Q=' => PE_BADURL,
    'Undeclared virtual host in an other domain',

    # http://test.example.com/%00
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb20vJTAw' => PE_BADURL, 'Base64 encoded \0',

    # http://test.example.com/test\0
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb20vdGVzdAA=' => PE_BADURL,
    'Base64 and url encoded \0',

    'XX%00' => PE_BADURL, 'Non base64 encoded \0 ',

    # http://test.example.com/test?<script>alert()</script>
    'aHR0cDovL3Rlc3QuZXhhbXBsZS5jb20vdGVzdD88c2NyaXB0PmFsZXJ0KCk8L3NjcmlwdD4='
      => PE_BADURL,
    'base64 encoded HTML tags',
);

sub param {
    shift;
    my $p = shift;
    if ( $p and $p eq 'url' ) {
        return $url;
    }
    else {
        return $logout;
    }
}

my $p;

# CGI Environment
$ENV{SCRIPT_NAME}     = '/test.pl';
$ENV{SCRIPT_FILENAME} = '/tmp/test.pl';
$ENV{REQUEST_METHOD}  = 'GET';
$ENV{REQUEST_URI}     = "/test.pl";
$ENV{QUERY_STRING}    = "";

ok(
    $p = My::Portal->new(
        {
            globalStorage  => 'Apache::Session::File',
            domain         => 'example.com',
            authentication => 'LDAP test=1',
            domain         => 'example.com',
            trustedDomains => 'example2.com',
        }
    ),
    'Portal object'
);

$p->{reVHosts} = '(?:test\.example\.com)';

while ( defined( $url = shift(@h) ) ) {
    $result = shift @h;
    my $text = shift @h;

    ok( $p->controlUrlOrigin() == $result, $text );

    #print ($p->controlUrlOrigin() == $result ? "OK" : "NOK");
    #print " $url\n";
}

