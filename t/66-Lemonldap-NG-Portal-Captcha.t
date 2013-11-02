use Test::More tests => 5;

BEGIN {
    use_ok("Lemonldap::NG::Portal::Simple");
    use_ok("Lemonldap::NG::Portal::_WebForm");
}

# build Lemonldap::NG::Portal::Simple object
my $p = Lemonldap::NG::Portal::Simple->new(
    {
        globalStorage   => 'Apache::Session::File',
        domain          => 'example.com',
        error           => 0,
        applicationList => {},
        locationRules   => {
            'test.example.com' => {
                'default' => "deny",
                '^/ok'    => '$uid eq "kharec"',
                '^/nok'   => '$uid eq "toto"',
            },
        },
        cfgNum      => 42,
        sessionInfo => { uid => "kharec" },

    }
);

## Overload captcha_output and captcha_data
mkdir "./tmp";
$p->{captcha_output} = "./tmp/output";
$p->{captcha_data}   = "./tmp/data";

# create dir
mkdir $p->{captcha_output};
mkdir $p->{captcha_data};

ok( ref($p) eq "Lemonldap::NG::Portal::Simple" );

# try to init a captcha
$p->initCaptcha;
ok( $p->{captcha_img}, "Generation of captcha image" );

# try a wrong values to check checkCaptcha method
my $captcha_result = $p->checkCaptcha( "12D3EO", $p->{captcha_code} );
ok( 1 ne $captcha_result, "Verification of captcha" );

END {
    system("rm -rf ./tmp");
}

