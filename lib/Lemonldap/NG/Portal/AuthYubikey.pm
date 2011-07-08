##@file
# Yubkikey authentication backend file

##@class
# Yublikey authentication backend class
package Lemonldap::NG::Portal::AuthYubikey;

use strict;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.1.0';
our $yubikeyInitDone;

BEGIN {
    eval {
        require threads::shared;
        threads::shared::share($yubikeyInitDone);
    };
}

## @apmethod int authInit()
# Try to load Yubikey perl module
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;
    return PE_OK if ($yubikeyInitDone);

    # Require Perl module
    eval { require Auth::Yubikey_WebClient };
    if ($@) {
        $self->lmLog( $@, 'error' );
        return PE_ERROR;
    }

    # Check mandatory parameters
    unless ( $self->{yubikeyClientID} and $self->{yubikeySecretKey} ) {
        $self->lmLog( "Missing mandatory parameters (Client ID and secret key)",
            'error' );
        return PE_ERROR;
    }

    $yubikeyInitDone = 1;
    PE_OK;
}

## @apmethod int extractFormInfo()
# Read Yubikey OTP
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;
    $self->{yubikeyPublicIDSize} ||= 12;

    # Get OTP
    my $otp = $self->param("yubikeyOTP");
    return PE_FORMEMPTY unless $otp;

    $self->lmLog( "Received Yubikey OTP $otp", 'debug' );

    # Verify OTP
    my $result = Auth::Yubikey_WebClient::yubikey_webclient(
        $otp,
        $self->{yubikeyClientID},
        $self->{yubikeySecretKey}
    );

    $self->lmLog( "OTP verification result: $result", 'debug' );

    if ( $result =~ /^ERR/ ) {
        $self->lmLog( "OTP verification failed: $result", 'error' );
        return PE_ERROR;
    }

    # Store user, which is the public ID part of the OTP
    $self->{user} = substr( $otp, 0, $self->{yubikeyPublicIDSize} );

    PE_OK;
}

## @apmethod int setAuthSessionInfo()
# Set _user and authenticationLevel.
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    # Store user submitted login for basic rules
    $self->{sessionInfo}->{'_user'} = $self->{'user'};

    $self->{sessionInfo}->{authenticationLevel} = $self->{yubikeyAuthnLevel};

    PE_OK;
}

## @apmethod int authenticate()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authenticate {
    PE_OK;
}

## @apmethod int authFinish()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authFinish {
    PE_OK;
}

## @apmethod int authLogout()
# Does nothing.
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

Lemonldap::NG::Portal::AuthYubikey - Yubikey authentication module

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::Simple(
         configStorage     => {...}, # See Lemonldap::NG::Portal
         authentication    => 'Yubikey',
	 # Get following parameters on https://upgrade.yubico.com/getapikey/
	 yubikeyClientID   => 'ABCD',
	 yubikeySecretKey  => '1234',
    );

=head1 DESCRIPTION

This library get Tubikey OTP and valid it against Yubico server.

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
L<http://lemonldap-ng.org/>, L<http://www.yubico.com>

=head1 AUTHOR

Clement OUDOT, E<lt>clem.oudot@gmail.comE<gt>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Clement OUDOT E<lt>clem.oudot@gmail.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

