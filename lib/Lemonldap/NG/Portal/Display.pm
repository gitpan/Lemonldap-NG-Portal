## @file
# Display functions for LemonLDAP::NG Portal

## @class
# Display functions for LemonLDAP::NG Portal
package Lemonldap::NG::Portal::Display;

use strict;
use Lemonldap::NG::Portal::Simple;
use utf8;

our $VERSION = '0.991';

## @method array display()
# Call portal process and set template parameters
# @return template name and template parameters
sub display {
    my $self = shift;

    my $skin     = $self->{portalSkin};
    my $skin_dir = $ENV{DOCUMENT_ROOT} . "/skins";
    my ( $skinfile, %templateParams );
    my $http_error = $self->param('lmError');

    # 0. Display error page
    if ($http_error) {

        $skinfile = 'error.tpl';

        # Error code
        my $error500 = 1 if ( $http_error eq "500" );
        my $error403 = 1 if ( $http_error eq "403" );

        # Check URL
        $self->_sub('controlUrlOrigin');

        %templateParams = (
            PORTAL_URL => $self->{portal},
            LOGOUT_URL => $self->{portal} . "?logout=1",
            URL        => $self->{urldc},
            SKIN       => $self->{portalSkin},
            ERROR403   => $error403,
            ERROR500   => $error500,
        );

    }

    # 1. Good authentication
    elsif ( $self->process() ) {

        # 1.1 Image mode
        if ( $self->{error} == PE_IMG_OK || $self->{error} == PE_IMG_NOK ) {
            $skinfile = "$skin_dir/common/"
              . (
                $self->{error} == PE_IMG_OK
                ? 'ok.png'
                : 'warning.png'
              );
            $self->printImage( $skinfile, 'image/png' );
            exit;
        }

        # 1.2 Case : there is a message to display
        elsif ( my $info = $self->info() ) {
            $skinfile       = 'info.tpl';
            %templateParams = (
                AUTH_ERROR_TYPE => $self->error_type,
                MSG             => $info,
                SKIN            => $skin,
                URL             => $self->{urldc},
                HIDDEN_INPUTS   => $self->buildHiddenForm(),
                ACTIVE_TIMER    => $self->{activeTimer},
                FORM_METHOD     => $self->{infoFormMethod},
            );
        }

        # 1.3 Case : display menu
        else {

            # Initialize menu elements
            $self->_sub('menuInit');

            $skinfile = 'menu.tpl';
            my $auth_user = $self->{sessionInfo}->{ $self->{portalUserAttr} };
            utf8::decode($auth_user);

            %templateParams = (
                AUTH_USER       => $auth_user,
                AUTOCOMPLETE    => $self->{portalAutocomplete},
                SKIN            => $skin,
                AUTH_ERROR      => $self->error( undef, $self->{menuError} ),
                AUTH_ERROR_TYPE => $self->error_type( $self->{menuError} ),
                DISPLAY_TAB     => $self->{menuDisplayTab},
                LOGOUT_URL      => "$ENV{SCRIPT_NAME}?logout=1",
                REQUIRE_OLDPASSWORD => $self->{portalRequireOldPassword},
                DISPLAY_MODULES     => $self->{menuDisplayModules},
                APPSLIST_MENU => $self->{menuAppslistMenu},  # For old templates
                APPSLIST_DESC => $self->{menuAppslistDesc},  # For old templates
            );

        }
    }

    # 2. Authentication not complete

 # 2.1 A notification has to be done (session is created but hidden and unusable
 #     until the user has accept the message)
    elsif ( my $notif = $self->notification ) {
        $skinfile       = 'notification.tpl';
        %templateParams = (
            AUTH_ERROR_TYPE => $self->error_type,
            NOTIFICATION    => $notif,
            SKIN            => $skin,
            HIDDEN_INPUTS   => $self->buildHiddenForm(),
            AUTH_URL        => $self->get_url,
        );
    }

    # 2.2 An authentication (or userDB) module needs to ask a question
    #     before processing to the request
    elsif ( $self->{error} == PE_CONFIRM ) {
        $skinfile       = 'confirm.tpl';
        %templateParams = (
            AUTH_ERROR      => $self->error,
            AUTH_ERROR_TYPE => $self->error_type,
            AUTH_URL        => $self->get_url,
            MSG             => $self->info(),
            SKIN            => $skin,
            HIDDEN_INPUTS   => $self->buildHiddenForm(),
            ACTIVE_TIMER    => $self->{activeTimer},
            FORM_METHOD     => $self->{confirmFormMethod},
            CHOICE_PARAM    => $self->{authChoiceParam},
            CHOICE_VALUE    => $self->{_authChoice},
            CONFIRMKEY      => $self->stamp(),
        );
    }

    # 2.3 There is a message to display
    elsif ( my $info = $self->info() ) {
        $skinfile       = 'info.tpl';
        %templateParams = (
            AUTH_ERROR      => $self->error,
            AUTH_ERROR_TYPE => $self->error_type,
            MSG             => $info,
            SKIN            => $skin,
            URL             => $self->{urldc},
            HIDDEN_INPUTS   => $self->buildHiddenForm(),
            ACTIVE_TIMER    => $self->{activeTimer},
            FORM_METHOD     => $self->{infoFormMethod},
            CHOICE_PARAM    => $self->{authChoiceParam},
            CHOICE_VALUE    => $self->{_authChoice},
        );
    }

    # 2.4 OpenID menu page
    elsif ($self->{error} == PE_OPENID_EMPTY
        or $self->{error} == PE_OPENID_BADID )
    {
        $skinfile = 'openid.tpl';
        my $p = $self->{portal} . $self->{issuerDBOpenIDPath};
        $p =~ s#(?<!:)/\^?/#/#g;
        %templateParams = (
            AUTH_ERROR      => $self->error,
            AUTH_ERROR_TYPE => $self->error_type,
            SKIN            => $skin,
            PROVIDERURI     => $p,
            ID              => $self->{_openidPortal}
              . $self->{sessionInfo}
              ->{ $self->{openIdAttr} || $self->{whatToTrace} },
            PORTAL_URL => $self->{portal},
            MSG        => $self->info(),
        );
    }

    # 2.5 Authentication has been refused OR this is the first access
    else {
        $skinfile       = 'login.tpl';
        %templateParams = (
            AUTH_ERROR            => $self->error,
            AUTH_ERROR_TYPE       => $self->error_type,
            AUTH_URL              => $self->get_url,
            LOGIN                 => $self->get_user,
            AUTOCOMPLETE          => $self->{portalAutocomplete},
            SKIN                  => $skin,
            DISPLAY_RESETPASSWORD => $self->{portalDisplayResetPassword},
            DISPLAY_FORM          => 1,
            MAIL_URL              => $self->{mailUrl},
            HIDDEN_INPUTS         => $self->buildHiddenForm(),
            LOGIN_INFO            => $self->loginInfo(),
        );

        # Authentication loop
        if ( $self->{authLoop} ) {
            %templateParams = (
                %templateParams,
                AUTH_LOOP           => $self->{authLoop},
                CHOICE_PARAM        => $self->{authChoiceParam},
                CHOICE_VALUE        => $self->{_authChoice},
                DISPLAY_FORM        => 0,
                DISPLAY_OPENID_FORM => 0,
            );
        }

        # Adapt template if password policy error
        if (
            $self->{portalDisplayChangePassword}
            and (  $self->{error} == PE_PP_CHANGE_AFTER_RESET
                or $self->{error} == PE_PP_MUST_SUPPLY_OLD_PASSWORD
                or $self->{error} == PE_PP_INSUFFICIENT_PASSWORD_QUALITY
                or $self->{error} == PE_PP_PASSWORD_TOO_SHORT
                or $self->{error} == PE_PP_PASSWORD_TOO_YOUNG
                or $self->{error} == PE_PP_PASSWORD_IN_HISTORY
                or $self->{error} == PE_PASSWORD_MISMATCH
                or $self->{error} == PE_BADOLDPASSWORD )
          )
        {
            %templateParams = (
                %templateParams,
                REQUIRE_OLDPASSWORD   => 1,
                DISPLAY_PASSWORD      => 1,
                DISPLAY_RESETPASSWORD => 0,
                DISPLAY_FORM          => 0
            );
        }

        # Adapt template for OpenID
        if ( $self->get_module("auth") =~ /openid/i and !$self->{authLoop} ) {
            %templateParams = (
                %templateParams,
                DISPLAY_RESETPASSWORD => 0,
                DISPLAY_FORM          => 0,
                DISPLAY_OPENID_FORM   => 1,
            );
        }

        # Adapt template if external authentication error
        # or logout is OK
        if (   $self->{error} == PE_BADCERTIFICATE
            or $self->{error} == PE_CERTIFICATEREQUIRED
            or $self->{error} == PE_ERROR
            or $self->{error} == PE_SAML_ERROR
            or $self->{error} == PE_SAML_LOAD_SERVICE_ERROR
            or $self->{error} == PE_SAML_LOAD_IDP_ERROR
            or $self->{error} == PE_SAML_SSO_ERROR
            or $self->{error} == PE_SAML_UNKNOWN_ENTITY
            or $self->{error} == PE_SAML_DESTINATION_ERROR
            or $self->{error} == PE_SAML_CONDITIONS_ERROR
            or $self->{error} == PE_SAML_IDPSSOINITIATED_NOTALLOWED
            or $self->{error} == PE_SAML_SLO_ERROR
            or $self->{error} == PE_SAML_SIGNATURE_ERROR
            or $self->{error} == PE_SAML_ART_ERROR
            or $self->{error} == PE_SAML_SESSION_ERROR
            or $self->{error} == PE_SAML_LOAD_SP_ERROR
            or $self->{error} == PE_SAML_ATTR_ERROR
            or $self->{error} == PE_LOGOUT_OK )
        {
            %templateParams = (
                %templateParams,
                DISPLAY_RESETPASSWORD => 0,
                DISPLAY_FORM          => 0,
                DISPLAY_OPENID_FORM   => 0,
                AUTH_LOOP             => [],
                PORTAL_URL            => $self->{portal},
                MSG                   => $self->info(),
            );
        }
    }

    return ( "$skin_dir/$skin/$skinfile", %templateParams );

}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::Display - Display functions for LemonLDAP::NG Portal

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  use HTML::Template;

  my $portal = Lemonldap::NG::Portal::SharedConf->new();

  my($templateName,%templateParams) = $portal->display();

  my $template = HTML::Template->new(
    filename => $templateName,
    die_on_bad_params => 0,
    cache => 0,
    global_vars => 1,
    filter => sub { $portal->translate_template(@_) }
  );
  while ( my ( $k, $v ) = each %templateParams ) { $template->param( $k, $v ); }

  print $portal->header('text/html; charset=utf-8');
  print $template->output;

=head1 DESCRIPTION

This module is used to build all templates parameters to display
LemonLDAP::NG Portal

=head1 SEE ALSO

L<Lemonldap::NG::Portal>

=head1 AUTHOR

Clement Oudot, E<lt>clement@oodo.netE<gt>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2010 by Xavier Guimard E<lt>x.guimard@free.frE<gt>,
Clement Oudot E<lt>clement@oodo.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

