#!/usr/bin/perl

use Lemonldap::NG::Portal::SharedConf;
use Lemonldap::NG::Common::Conf::SAML::Metadata;
use strict;

my $portal = Lemonldap::NG::Portal::SharedConf->new(
    {

        # ACCESS TO CONFIGURATION
        # By default, Lemonldap::NG uses the default lemonldap-ng.ini file to
        # know where to find its configuration
        # (generaly /etc/lemonldap-ng/lemonldap-ng.ini)
        # You can specify by yourself this file :
        #configStorage => { confFile => '/path/to/my/file' },
        # or set explicitely parameters :
        #configStorage => {
        #  type => 'File',
        #  dirName => '/usr/local/lemonldap-ng/data//conf'
        #},
        # Note that YOU HAVE TO SET configStorage here if you've declared this
        # portal as SOAP configuration server in the manager

        # OTHERS
        # You can also overload any parameter issued from manager
        # configuration. Example:
        #globalStorage => 'Apache::Session::File',
        #globalStorageOptions => {
        #  'Directory' => '/var/lib/lemonldap-ng/sessions/',
        #  'LockDirectory' => '/var/lib/lemonldap-ng/sessions/lock/',
        #},
        # Note that YOU HAVE TO SET globalStorage here if you've declared this
        # portal as SOAP session server in the manager
    }
);

my $skin      = 'common';
my $skin_dir  = $portal->getApacheHtdocsPath() . '/skins';
my $skin_file = 'saml2-metadata.tpl';
my $metadata  = Lemonldap::NG::Common::Conf::SAML::Metadata->new();
print $portal->header('text/xml; charset=utf-8');
print $metadata->serviceToXML( $skin_dir . '/' . $skin . '/' . $skin_file,
    $portal );

