#==============================================================================
# Liberty Alliance Authentication for LemonLDAP.
#
# This file is part of the LemonLDAP project and released under GPL.
#==============================================================================

package Lemonldap::NG::Portal::AuthLA;

use strict;
use warnings;

use Lemonldap::NG::Portal::SharedConf qw(:all);
use lasso;

*EXPORT_OK   = *Lemonldap::NG::Portal::SharedConf::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::SharedConf::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::SharedConf::EXPORT;

our $VERSION = '0.1';

our @ISA = qw(Lemonldap::NG::Portal::SharedConf);

#==============================================================================
# Overloaded methods
#==============================================================================

# Main process as described in Portal::Simple module

# 1. Retrieve source URL
# Not overloaded

# 2. Control existing sessions
# Not overloaded

# 3. Retrieve user credentials
# Test here if the user was authenticated by IdP
sub extractFormInfo {
	my $self = shift;
	&_lasso_init();
	my $libertyFilesDir = $self->{libertyFilesDir} ;
	my $server = &_lasso_create_server($libertyFilesDir);
	my $login = &_lasso_create_authnrequest($server);

	print STDERR $server->dump();
	print STDERR $login->dump();

	return PE_OK;
}

# 4. LDAP format filter for attributes reading
# We must retrive user DN in SAML response
# Or use WSF to retrieve attributes
sub formateFilter {
	my $self = shift;

	# Get DN in SAML response (TODO)
	my $dn = "uid=clement,ou=personnes,dc=linagora,dc=com";

	# Explode DN to build RDN
	my @rdn = split /,/ , $dn;
	
	$self->{filter}="(".shift(@rdn).")";

	return PE_OK;
}

# 5. LDAP connection
# Overload only if WSF is used to retrieve attributes
#sub connectLDAP {
#    return PE_OK;
#}

# 6. LDAP bind (with Directory Manager or anonymous)
# Overload only if WSF is used to retrieve attributes
#sub bind {
#    return PE_OK;
#}


# 7. Search the DN
# Overload only if WSF is used to retrieve attributes
#sub search {
#	return PE_OK;
#}

# 8. Load parameters 
# Overload only if WSF is used to retrieve attributes
#sub setSessionInfo {
#	# Use WSF to get "exprotedVars"
#	return PE_OK;
#}

# 9. Set macros
# Not overloaded

# 10. Set groups
# Not overloaded

# 11. LDAP unbind
# Overload only if WSF is used to retrieve attributes
#sub unbind {
#    return PE_OK;
#}

# 12. Authentication
# Authentication is done by IdP, so we disable this step
sub authenticate {
	return PE_OK;
}

# 13. Store parameters in session
# Not overloaded

# 14. Build cookie
# Not overloaded

# 15. Log
# Not overloaded

# 16. Redirection
# Not overloaded

#==============================================================================
# Liberty Alliance methods
#==============================================================================
# Lasso intialisation
sub _lasso_init {
	lasso::init;
}

# Create server object
sub _lasso_create_server {

	# TODO: file names in global configuration
	
	my $libertyFilesDir = shift;	

	my $server = lasso::Server->new(
		"$libertyFilesDir/lemonldapng-metadata.xml",
		"private-key.pem",
		undef, undef);
	
	$server->addProvider(
		$lasso::PROVIDER_ROLE_IDP,
		"$libertyFilesDir/idp-http-authentic.demo.interldap.org-liberty-metadata-metadata.xml",
		"$libertyFilesDir/idp-http-authentic.demo.interldap.org-liberty-metadata-publickey.pem",
		undef);

	return $server;
}

# Create AuthnRequest
sub _lasso_create_authnrequest {

	my $server = shift;

	my $login = lasso::Login->new($server);

	return $login;
}


1;
__END__

=head1 NAME

Lemonldap::NG::Portal::AuthLA - Provide Liberty Alliance Authentication

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

L<Lemonldap::NG::Portal::SharedConf>, L<Lemonldap::NG::Portal>,
L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Manager>,
http://wiki.lemonldap.objectweb.org/xwiki/bin/view/NG/Presentation

=head1 AUTHOR

Clement Oudot, E<lt>coudot@linagora.comE<gt>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://forge.objectweb.org/tracker/?group_id=274>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Clement Oudot, E<lt>coudot@linagora.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
