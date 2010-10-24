## @file
# Proxy authentication module

## @class
# Proxy authentication module: It simply call another Lemonldap::NG portal by
# SOAP using credentials
package Lemonldap::NG::Portal::AuthProxy;

use strict;
use Lemonldap::NG::Portal::_Proxy;
use Lemonldap::NG::Portal::_WebForm;
use Lemonldap::NG::Portal::Simple;
use base qw(Lemonldap::NG::Portal::_WebForm Lemonldap::NG::Portal::_Proxy);

our $VERSION = '0.992';

## @apmethod int authInit()
# Call Lemonldap::NG::Portal::_Proxy::proxyInit();
# @return Lemonldap::NG::Portal constant
*authInit = *Lemonldap::NG::Portal::_Proxy::proxyInit;

## @apmethod int authenticate()
# Call Lemonldap::NG::Portal::_Proxy::proxyQuery()
# @return Lemonldap::NG::Portal constant
*authenticate = *Lemonldap::NG::Portal::_Proxy::proxyQuery;

## @apmethod int setAuthSessionInfo()
# Call Lemonldap::NG::Portal::_Proxy::setSessionInfo()
# @return Lemonldap::NG::Portal constant
*setAuthSessionInfo = *Lemonldap::NG::Portal::_Proxy::setSessionInfo;

## @apmethod int authFinish()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authFinish {
    PE_OK;
}

## @apmethod int authLogout()
# Does nothing
# @return Lemonldap::NG::Portal constant
sub authLogout {
    PE_OK;
}

## @apmethod boolean authForce()
# Does nothing
# @return result
sub authForce {
    return 0;
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::AuthProxy - Authentication module for Lemonldap::NG
that delegates authentication to a remote Lemonldap::NG portal.

The difference with Remote authentication module is that the client will never
be redirect to the main Lemonldap::NG portal. This configuration is usable if
you want to expose your internal SSO to another network (DMZ).

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::SharedConf(
         
         # REQUIRED PARAMETERS
         authentication      => 'Proxy', 
         userDB          => 'Proxy',
         soapAuthService => 'https://auth.internal.network/',
  
         # OTHER PARAMETERS
         # remoteCookieName (default: same name)
         remoteCookieName => 'lemonldap',
         # soapSessionService (default ${soapAuthService}index.pl/sessions)
         soapSessionService =>
            'https://auth2.internal.network/index.pl/sessions',
    );

=head1 DESCRIPTION

Authentication module for Lemonldap::NG portal that forward credentials to a
remote Lemonldap::NGportal using SOAP request. Note that the remote portal must
accept SOAP requests ("Soap=>1").

=head1 SEE ALSO

L<http://lemonldap.objectweb.org/>
L<http://wiki.lemonldap.objectweb.org/xwiki/bin/view/NG/AuthProxy>

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, 2010 by Xavier Guimard

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
