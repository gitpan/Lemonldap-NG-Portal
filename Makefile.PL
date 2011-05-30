use 5.008;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Lemonldap::NG::Portal',
    VERSION_FROM => 'lib/Lemonldap/NG/Portal.pm',
    LICENSE      => 'gpl',
    META_MERGE   => {
        'recommends' => {
            'Convert::PEM'          => 0,
            'Crypt::OpenSSL::X509'  => 0,
            'Email::Date::Format'   => 0,
            'Lasso'                 => '2.3.0',
            'Net::OpenID::Consumer' => 0,
            'Net::OpenID::Server'   => 0,
            'Net::Twitter'          => 0,
        },
    },
    BUILD_REQUIRES => {
        'Crypt::OpenSSL::X509' => 0,
        'IO::String'           => 0,
        'SOAP::Lite'           => 0,
    },
    PREREQ_PM => {
        'Apache::Session'        => 0,
        'CGI'                    => 3.08,
        'File::Basename'         => 0,
        'HTML::Template'         => 0,
        'Lemonldap::NG::Common'  => '1.0.6',
        'Lemonldap::NG::Handler' => '1.0.6',
        'MIME::Lite'             => 0,
        'Net::LDAP'              => 0,
        'String::Random'         => 0,
        'XML::LibXML'            => 0,
        'XML::LibXSLT'           => 0,
        'Clone'                  => 0,
    },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Lemonldap/NG/Portal.pm',    # retrieve abstract from module
            AUTHOR => 'Xavier Guimard <x.guimard@free.fr>'
              . ', Clément Oudot <clement@oodo.net>'
              . ', Thomas Chemineau <thomas.chemineau@gmail.com>'
              . ', Mikael Ates <mikael.ates@univ-st-etienne.fr>'
          )
        : ()
    ),
);
