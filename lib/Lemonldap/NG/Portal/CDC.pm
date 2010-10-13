## @file
# Module for SAML Common Domain Cookie Support

## @class Lemonldap::NG::Portal::CDC
# Class for SAML Common Domain Cookie Support
package Lemonldap::NG::Portal::CDC;

use strict;
use warnings;
use MIME::Base64;
use Lemonldap::NG::Portal::SharedConf;    # inherits
use Lemonldap::NG::Portal::_SAML;         # inherits

our $VERSION = '0.99';
our @ISA = qw(Lemonldap::NG::Portal::_SAML Lemonldap::NG::Portal::SharedConf);

## @method int process()
# Main method to process CDC requests
# @return portal error code
sub process {
    my $self       = shift;
    my $cdc_idp    = "";
    my $cdc_cookie = "";

    # Default values
    my $cdc_name   = $self->{samlCommonDomainCookieName}   || '_saml_idp';
    my $cdc_domain = $self->{samlCommonDomainCookieDomain} || $ENV{'HTTP_HOST'};

    $self->lmLog( "[CDC] Cookie name: $cdc_name",   'debug' );
    $self->lmLog( "[CDC] Domain name: $cdc_domain", 'debug' );

    # Request parameter
    my $action = $self->param('action') || "";    # What we do
    my $idp = $self->param('idp');                # IDP ID in write mode

    # Control URL
    my $control_url = $self->_sub('controlUrlOrigin');
    unless ( $control_url == PE_OK ) {
        $self->lmLog( "[CDC] Bad URL", 'error' );
        return $control_url;
    }

    # Get cookie
    my %cookies = fetch CGI::Cookie;
    $cdc_cookie = $cookies{$cdc_name} if %cookies;
    $cdc_cookie &&= $cdc_cookie->value;

    if ($cdc_cookie) {
        $self->lmLog( "[CDC] Cookie found with value $cdc_cookie", 'debug' );
    }

    # Write request
    # Called in an iFrame
    # Get or build common domain cookie
    # Append IDP to common domain cookie
    if ( $action eq 'write' ) {

        $self->lmLog( "[CDC] Write request detected", 'debug' );

        # Check IDP value
        unless ($idp) {
            $self->lmLog( "[CDC] No IDP given", 'error' );
            return PE_SAML_ERROR;
        }

        # Add IDP value
        $self->lmLog( "[CDC] Will add IDP $idp to IDP list", 'debug' );

        my $encoded_idp = encode_base64( $idp, '' );

        # Remove IDP value if already present
        $cdc_cookie =~ s/$encoded_idp(\s+)?//g;

        # Add a space separator
        $cdc_cookie .= ( $cdc_cookie ? " " : "" );
        $cdc_cookie .= $encoded_idp;

        $self->lmLog( "[CDC] Build cookie $cdc_name with value $cdc_cookie",
            'debug' );

        # Build cookie
        push @{ $self->{cookie} }, $self->cookie(
            -name     => $cdc_name,
            -value    => $cdc_cookie,
            -domain   => $cdc_domain,
            -path     => "/",                         # See SAML protocol
            -secure   => 1,                           # See SAML protocol
            -httponly => $self->{httpOnly},
            -expires  => $self->{cookieExpiration},
        );
    }

    # Read request
    # Get last IDP from domain cookie
    # Return on SP with idp as parameter

    elsif ( $action eq 'read' ) {

        $self->lmLog( "[CDC] Read request detected", 'debug' );

        # Get last IDP from cookie
        if ($cdc_cookie) {
            $cdc_idp = decode_base64( ( split /\s+/, $cdc_cookie )[-1] );
            $self->lmLog( "[CDC] Get value $cdc_idp", 'debug' );
        }
        else {
            $self->lmLog( "[CDC] No cookie, set a default value", 'debug' );
            $cdc_idp = 'notfound';
        }
    }

    # Redirect if needed
    if ( $self->{urldc} ) {

        # Add CDC IDP in return URL if needed
        # olStyleUrl can be set to 1 to use & instead of ;
        $self->{urldc} .= (
            $cdc_idp
            ? (
                $self->{urldc} =~ /\?/
                ? ( $self->{oldStyleUrl} ? '&' : ';' ) . 'idp=' . $cdc_idp
                : '?idp=' . $cdc_idp
              )
            : ''
        );

        # Redirect
        $self->_sub('autoRedirect');

    }

    if ($cdc_cookie) {

        # Parse cookie to display it if not redirected
        my @cdc_values =
          map( decode_base64($_), ( split( /\s+/, $cdc_cookie ) ) );
        $self->{cdc_values} = \@cdc_values;
    }

    return PE_OK;
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::CDC - Manage SAML Common Domain Cookie

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::CDC;
  
  my $portal = new Lemonldap::NG::Portal::CDC();
 
  $portal->process();

  # Write here HTML to manage errors and confirmation messages

=head1 DESCRIPTION

Lemonldap::NG::Portal::CDC - Manage SAML Common Domain Cookie

See L<Lemonldap::NG::Portal::SharedConf> for a complete example of use of
Lemonldap::Portal::* libraries.

=head1 METHODS

=head3 process

Main method.

=head1 SEE ALSO

L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Portal::SharedConf>, L<CGI>,
http://wiki.lemonldap.objectweb.org/xwiki/bin/view/NG/Presentation

=head1 AUTHOR

Clement Oudot, E<lt>clement@oodo.netE<gt>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://forge.objectweb.org/tracker/?group_id=274>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2009 by Xavier Guimard E<lt>x.guimard@free.frE<gt> and
Clement Oudot, E<lt>clement@oodo.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut