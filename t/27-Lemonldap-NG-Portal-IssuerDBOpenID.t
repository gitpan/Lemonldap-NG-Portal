use Test::More tests => 2;

SKIP: {
    eval { require Net::OpenID::Server; };
    skip "Net::OpenID::Consumer is not installed, so "
      . "Lemonldap::NG::Portal::AuthOpenID will not be useable", 2
      if ($@);
    use_ok('Lemonldap::NG::Portal::OpenID::Server');
    use_ok('Lemonldap::NG::Portal::IssuerDBOpenID');
}
