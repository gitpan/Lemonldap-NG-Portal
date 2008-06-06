use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lemonldap::NG::Portal',
    VERSION_FROM      => 'lib/Lemonldap/NG/Portal.pm',
    PREREQ_PM         => {
        'Apache::Session'        => 0,
        'Net::LDAP'              => 0,
        'CGI'                    => 3.08,
        'CGI::Session'           => 0,
        'HTML::Template'         => 0,
        'Lemonldap::NG::Manager' => 0.4,
        },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lemonldap/NG/Portal.pm', # retrieve abstract from module
       AUTHOR         => 'Xavier Guimard <x.guimard@free.fr>') : ()),
);
