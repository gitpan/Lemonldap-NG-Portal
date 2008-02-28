#!/usr/bin/perl

use strict ;
use warnings ;

use HTML::Template ;
use Lemonldap::NG::Portal::AuthLA;

# Local parameter to set the installation directory
my $install_dir = "/var/lib/lemonldap-ng/web/portal";
my $var_dir = "/var/lib/lemonldap-ng/";

my $portal = Lemonldap::NG::Portal::AuthLA->new({
	configStorage => {
		type	=> "File" ,
		dirName	=> "$var_dir/config" ,
	} ,

	# Liberty Parameters
	laSp => {
		certificate	=> "$install_dir/ressources/lemonsp-key-public.pem" ,
		metadata	=> "$install_dir/ressources/lemonsp-metadata.xml" ,
		privkey		=> "$install_dir/ressources/lemonsp-key-private.pem" ,
		secretkey	=> "$install_dir/ressources/lemonsp-key-private.pem" ,
	} ,
	laIdpsFile => "$install_dir/idps.xml" ,
	laStorage => "Apache::Session::File",
	laStorageOptions => {
		Directory	=> "$var_dir/var/assertion" ,
		LockDirectory	=> "$var_dir/var/lock" ,
	} ,
	laDebug => 1 ,
	laLdapLoginAttribute => "uid" ,

	# Parameters that permit to access lemonldap::NG::Handler local cache
        localStorage            => 'Cache::FileCache' ,
        localStorageOptions     => {} ,
});



if( $portal->process() ) {

        print $portal->header;
        my $template = HTML::Template->new( filename => "$install_dir/tpl/menu.tpl");

	my @sites = ();
	foreach ($portal->getProtectedSites) {
		my %row_data ;
		$row_data{SITE_NAME} = $_ ;
		push (@sites, \%row_data) ;
	}
	@sites = sort {$a cmp $b} @sites ;
	$template->param( AUTH_SITES => \@sites );

	print $template->output;

} else {

	# Retrieve IDP list.

	my @idps = () ;
	foreach ($portal->getIdpIDs) {
		my %row_data ;
		$row_data{IDPNAME} = $_ ;
		push (@idps, \%row_data) ;
	}
	@idps = sort {$a cmp $b} @idps ;

	# Print template

	print $portal->header ;
	my $template = HTML::Template->new( filename => "$install_dir/tpl/auth.tpl" ) ;
	$template->param( AUTH_ERROR => $portal->error ) ;
	$template->param( AUTH_URL => $portal->param('url') ) ;
	$template->param( AUTH_IDPS => \@idps ) ;
	print $template->output ;

}

