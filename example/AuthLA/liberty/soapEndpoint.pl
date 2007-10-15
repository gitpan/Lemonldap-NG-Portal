#!/usr/bin/perl

use strict ;
use warnings ;

use HTML::Template ;
use Lemonldap::NG::Portal::AuthLA;



my $portal = Lemonldap::NG::Portal::AuthLA->new({
	configStorage => {
		type	=> 'File' ,
		dirName	=> '/var/lib/lemonldap-ng/config' ,
	} ,

	# Liberty Parameters
	laSp => {
		certificate	=> '/var/lib/lemonldap-ng/web/portal/ressources/lemonsp-key-public.pem' ,
		metadata	=> '/var/lib/lemonldap-ng/web/portal/ressources/lemonsp-metadata.xml' ,
		privkey		=> '/var/lib/lemonldap-ng/web/portal/ressources/lemonsp-key-private.pem' ,
		secretkey	=> '/var/lib/lemonldap-ng/web/portal/ressources/lemonsp-key-private.pem' ,
	} ,
	laIdpsFile => '/var/lib/lemonldap-ng/web/portal/idps.xml' ,
	laStorage => 'Apache::Session::File',
	laStorageOptions => {
		Directory	=> '/var/lib/lemonldap-ng/var/assertion' ,
		LockDirectory	=> '/var/lib/lemonldap-ng/var/lock' ,
	} ,
	laDebug => 1 ,
	laLdapLoginAttribute => 'uid' ,

	# Parameters that permit to access lemonldap::NG::Handler local cache
        localStorage            => 'Cache::FileCache' ,
        localStorageOptions     => {} ,
});



if( $portal->process() ) {

	# Print protected URLs

	print $portal->header ;
	print "<a href=\"http://$_\"> $_</a><br/>"
		foreach ($portal->getProtectedURLs) ;

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
	my $template = HTML::Template->new( filename => '/var/lib/lemonldap-ng/web/portal/tpl/auth.tpl' ) ;
	$template->param( AUTH_ERROR => $portal->error ) ;
	$template->param( AUTH_URL => $portal->param('url') ) ;
	$template->param( AUTH_IDPS => \@idps ) ;
	print $template->output ;

}

