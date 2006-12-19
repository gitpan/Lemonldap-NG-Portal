use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lemonldap::NG::Portal',
    VERSION_FROM      => 'lib/Lemonldap/NG/Portal.pm',
    PREREQ_PM         => {
        'Apache::Session'        => 0,
	'Net::LDAP'              => 0,
	'MIME::Base64'           => 0,
	'CGI'                    => 3.08,
	'DBI'                    => 0,
	'Lemonldap::NG::Manager' => 0.03,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lemonldap/NG/Portal.pm', # retrieve abstract from module
       AUTHOR         => 'Xavier Guimard <x.guimard@free.fr>') : ()),
);
