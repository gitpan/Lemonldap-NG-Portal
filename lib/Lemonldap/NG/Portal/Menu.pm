package Lemonldap::NG::Portal::Menu;

use strict;
use warnings;
use Lemonldap::NG::Portal::SharedConf;
use Lemonldap::NG::Portal::_LDAP;
use XML::LibXML;
use Safe;

our $VERSION = '0.01';

### ACCESS CONTROL DISPLAY SYSTEM

our ( $defaultCondition, $locationCondition, $locationRegexp, $cfgNum, $path ) =
  ( undef, undef, undef, 0 );

sub _safe {
    my $self = shift;
    return $self->{_safe} if ( $self->{_safe} );
    $self->{_safe} = new Safe;
    $self->{customFunctions} ||= $self->{portalObject}->{customFunctions};
    my @t =
      $self->{customFunctions} ? split( /\s+/, $self->{customFunctions} ) : ();
    foreach (@t) {
        my $sub = $_;
        unless (/::/) {
            $sub = "$self->{caller}::$_";
        }
        else {
            s/^.*:://;
        }
        next if ( __PACKAGE__->can($_) );
        eval "sub $_ {
            return $sub(\$path,\@_);
        }";
        print STDERR "$@\n" if ($@);
    }
    $self->{_safe}->share( '&encode_base64', @t );
    return $self->{_safe};
}

my $catlevel = 0;

# CONSTRUCTOR
sub new {
    my $class = shift;
    my $self  = {};
    bless( $self, $class );

    # Get configuration
    $self->Lemonldap::NG::Portal::Simple::getConf(@_)
      or $self->abort("Unable to get configuration");

    # Portal is required
    $self->abort("Portal object required") unless ( $self->{portalObject} );

    # Fill sessionInfo
    &Lemonldap::NG::Portal::Simple::getSessionInfo( $self->{portalObject} );

    # Default values
    $self->{apps}->{xmlfile} ||= 'apps-list.xml';
    $self->{apps}->{imgpath} ||= 'apps/';
    $self->{modules}->{appslist} = 0
      unless defined $self->{modules}->{appslist};
    $self->{modules}->{password} = 0
      unless defined $self->{modules}->{password};
    $self->{modules}->{logout} = 1 unless defined $self->{modules}->{logout};
    $self->{'caller'} = caller;

    # Set error to 0 by default
    $self->{error} = PE_OK;

    # Print Ppolicy warning messages
    ( $self->{error}, $self->{error_value} ) = $self->_ppolicyWarning;

    # Gest POST data
    my ( $newpassword, $confirmpassword, $oldpassword ) = (
        $self->{portalObject}->param('newpassword'),
        $self->{portalObject}->param('confirmpassword'),
        $self->{portalObject}->param('oldpassword')
    );

    # Change password (only if newpassword submitted)
    $self->{error} =
      $self->_changePassword( $newpassword, $confirmpassword, $oldpassword )
      if $newpassword;

    return $self;
}

sub ldap {
    my $self = shift;
    unless ( ref( $self->{ldap} ) ) {
        my $mesg = $self->{ldap}->bind
          if ( $self->{ldap} = Lemonldap::NG::Portal::_LDAP->new($self) );
        if ( $mesg->code != 0 ) {
            return 0;
        }
    }
    return $self->{ldap};
}

sub error {

    # Copied from Simple.pm
    # Add a value possibility (stored in $self->{error_value}
    my $self = shift;
    my $error_string;
    $error_string .= $self->{error_value} if defined $self->{error_value};
    $error_string .=
      &Lemonldap::NG::Portal::_i18n::error( $self->{error},
        shift || $ENV{HTTP_ACCEPT_LANGUAGE} );
    return $error_string;
}

sub error_type {
    my $self = shift;
    return &Lemonldap::NG::Portal::Simple::error_type($self);
}

# displayModule($modulename)
# Return true if the user can see the module
# Use for HTML::Template variable
sub displayModule {
    my $self = shift;
    my ($modulename) = @_;

    # Manage "0" and "1" rules
    return 1 if ( $self->{modules}->{$modulename} eq "1" );
    return 0 if ( $self->{modules}->{$modulename} eq "0" );

    # Else parse display condition
    my $cond = $self->{modules}->{$modulename};
    $cond =~ s/\$(\w+)/$self->{portalObject}->{sessionInfo}->{$1}/g;
    return $self->_safe->reval("sub {return ( $cond )}");
    return 0;
}

# displayTab
# Tells which tab should be selected
# Design for Jquery tabs
sub displayTab {
    my $self = shift;

    # Display password tab if password change is needed or failed
    return "password"
      if (
        (
            scalar(
                grep { /^$self->{error}$/ } (
                    25,    #PE_PP_CHANGE_AFTER_RESET
                    27,    #PE_PP_MUST_SUPPLY_OLD_PASSWORD
                    28,    #PE_PP_INSUFFICIENT_PASSWORD_QUALITY
                    29,    #PE_PP_PASSWORD_TOO_SHORT
                    30,    #PE_PP_PASSWORD_TOO_YOUNG
                    31,    #PE_PP_PASSWORD_IN_HISTORY
                    32,    #PE_PP_GRACE
                    33,    #PE_PP_EXP_WARNING
                    34,    #PE_PASSWORD_MISMATCH
                )
            )
        )
        && $self->displayModule("password")
      );

    return "appslist" if ( $self->displayModule("appslist") );
    return "logout";
}

# appslistMenu
# HTML code for application list menu
sub appslistMenu {
    my $self = shift;
    my $root = $self->_getXML;

    # Display all categories and applications
    return $self->_displayCategory( $root, $catlevel );
}

# appslistDescription
# HTML code for application description
sub appslistDescription {
    my $self = shift;
    my $root = $self->_getXML;

    # Display application description
    return $self->_displayDescription($root);
}

# _getXML
# return XML root element object
sub _getXML {
    my $self = shift;

    # Parse XML file
    my $parser = XML::LibXML->new();
    $parser->validation('1');
    my $xml;
    eval {
        $xml = $parser->parse_file( $self->{apps}->{xmlfile} );
    };
    $self->{portalObject}->abort("Bad XML file", $@) if($@);
    my $root = $xml->documentElement;

    # Filter XML file with user's authorizations
    $self->_filterXML($root);

    return $root;
}

# _displayCategory
# Create HTML code for a category
sub _displayCategory {
    my $self = shift;
    my ( $cat, $catlevel ) = @_;
    my $html;
    my $catname;

    # Category name
    if ( $catlevel > 0 ) { $catname = $cat->getAttribute('name') || " "; }
    else                 { $catname = "Menu"; }

    # Init HTML list
    $html .= "<ul class=\"category cat-level-$catlevel\">\n";
    $html .= "<li class=\"catname\"><span>$catname</span>\n";

    # Display applications first
    my @appnodes = $cat->findnodes("application");
    $html .= "<ul>" if scalar @appnodes;
    foreach (@appnodes) {
        $html .= $self->_displayApplication($_);
    }
    $html .= "</ul>" if scalar @appnodes;

    # Display subcategories
    my @catnodes = $cat->findnodes("category");
    $catlevel++;
    foreach (@catnodes) {
        $html .= $self->_displayCategory( $_, $catlevel );
    }

    # Close HTML list
    $html .= "</li>\n</ul>\n";

    return $html;
}

sub _userParam {
    my ( $self, $arg ) = @_;
    $arg =~ s/\$([\w]+)/$self->{portalObject}->{sessionInfo}->{$1}/g;
    return $arg;
}

# _displayApplication
# Create HTML code for an application
sub _displayApplication {
    my $self = shift;
    my ($app) = @_;
    my $html;

    # Get application items
    my $appid   = $app->getAttribute('id');
    my $appname = $app->getElementsByTagName('name')->string_value() || $appid;
    my $appuri =
      $self->_userParam( $app->getElementsByTagName('uri')->string_value()
          || "#" );

    # Display application
    $html .=
"<li title=\"$appid\" class=\"appname\"><span><a href=\"$appuri\">$appname</a></span></li>\n";

    return $html;
}

# _displayDescription
# Create HTML code for application description
sub _displayDescription {
    my $self = shift;
    my ($root) = @_;
    my $html;

    my @apps = $root->getElementsByTagName('application');
    foreach (@apps) {

        # Get application items
        my $appid   = $_->getAttribute('id');
        my $appname = $_->getElementsByTagName('name')->string_value();
        my $appuri =
          $self->_userParam( $_->getElementsByTagName('uri')->string_value()
              || "#" );
        my $appdesc = $_->getElementsByTagName('description')->string_value();
        my $applogofile = $_->getElementsByTagName('logo')->string_value();
        my $applogo     = $self->{apps}->{imgpath} . $applogofile;

        # Display application
        $html .= "<div id=\"$appid\" class=\"appsdesc\">\n";
        $html .=
"<a href=\"$appuri\"><img src=\"$applogo\" alt=\"$appid logo\" /></a>\n"
          if $applogofile;
        $html .= "<p class=\"appname\">$appname</p>\n" if defined $appname;
        $html .= "<p class=\"appdesc\">$appdesc</p>\n" if defined $appdesc;
        $html .= "</div>\n";
    }

    return $html;
}

# _filterXML
# Remove unauthorized nodes
sub _filterXML {
    my $self = shift;
    my ($root) = @_;

    my @apps = $root->getElementsByTagName('application');
    foreach (@apps) {
        my $appdisplay = $_->getElementsByTagName('display')->string_value();
        my $appuri =
          $self->_userParam( $_->getElementsByTagName('uri')->string_value() );

        # Remove node if display is "no"
        $_->unbindNode if ( $appdisplay eq "no" );

        # Keep node if display is "yes"
        next if ( $appdisplay eq "yes" );

        # Check grant function if display is "auto" (this is the default)
        $_->unbindNode unless ( $self->_grant($appuri) );

    }

    # Hide empty categories
    $self->_hideEmptyCategory($root);

    return;
}

# _hideEmptyCategory
#
sub _hideEmptyCategory {
    my $self = shift;
    my ($cat) = @_;

    # Check subnodes
    my @catnodes = $cat->findnodes("category");
    my @appnodes = $cat->findnodes("application");

    # Check each subcategory
    foreach (@catnodes) {
        $self->_hideEmptyCategory($_);
    }

    # Update node list
    @catnodes = $cat->findnodes("category");

    # Remove the node if it contains no category or no application
    unless ( scalar(@catnodes) || scalar(@appnodes) ) {
        $cat->unbindNode;
        return;
    }

    return;
}

# _changePassword
# Change user's password
# TODO: Check used Auth module and change password for LDAP or DBI
sub _changePassword {
    my $self = shift;
    my ( $newpassword, $confirmpassword, $oldpassword ) = @_;
    my $err;

    # Verify confirmation password matching
    return PE_PASSWORD_MISMATCH unless ( $newpassword eq $confirmpassword );

    # Connect to LDAP
    unless ( $self->{portalObject}->ldap ) {
        return PE_LDAPCONNECTFAILED;
    }

    my $ldap = $self->{portalObject}->{ldap};
    my $dn   = $self->{portalObject}->{sessionInfo}->{"dn"};

    # First case: no ppolicy
    if ( !$self->{portalObject}->{ldapPpolicyControl} ) {

        my $mesg =
          $ldap->modify( $dn, replace => { userPassword => $newpassword } );

        return PE_WRONGMANAGERACCOUNT
          if ( $mesg->code == 50 || $mesg->code == 8 );
        return PE_LDAPERROR unless ( $mesg->code == 0 );
        $self->_storePassword($newpassword);
        return PE_PASSWORD_OK;
    }
    else {

        # require Perl module
        eval 'require Net::LDAP::Control::PasswordPolicy';
        if ($@) {
            print STDERR
              "Module Net::LDAP::Control::PasswordPolicy not found in @INC\n";
            return PE_LDAPERROR;
        }
        no strict 'subs';

        # Create Control object
        my $pp = Net::LDAP::Control::PasswordPolicy->new;

        my $mesg = $ldap->modify(
            $dn,
            replace => { userPassword => $newpassword },
            control => [$pp]
        );

        # TODO: use setPassword with oldpassword if needed

        # Get server control response
        my ($resp) = $mesg->control("1.3.6.1.4.1.42.2.27.8.5.1");

        return PE_WRONGMANAGERACCOUNT
          if ( $mesg->code == 50 || $mesg->code == 8 );
        $self->_storePassword($newpassword) && return PE_PASSWORD_OK
          if ( $mesg->code == 0 );

        if ( defined $resp ) {
            my $pp_error = $resp->pp_error;
            if ( defined $pp_error ) {
                return [
                    PE_PP_PASSWORD_EXPIRED,
                    PE_PP_ACCOUNT_LOCKED,
                    PE_PP_CHANGE_AFTER_RESET,
                    PE_PP_PASSWORD_MOD_NOT_ALLOWED,
                    PE_PP_MUST_SUPPLY_OLD_PASSWORD,
                    PE_PP_INSUFFICIENT_PASSWORD_QUALITY,
                    PE_PP_PASSWORD_TOO_SHORT,
                    PE_PP_PASSWORD_TOO_YOUNG,
                    PE_PP_PASSWORD_IN_HISTORY,
                ]->[$pp_error];
            }
        }
        else {
            return PE_LDAPERROR;
        }
    }
}

# _storePassword
# Store new password in session if storePassword parameter is set
sub _storePassword {
    my $self = shift;
    my ($password) = @_;
    if ( $self->{portalObject}->{storePassword} ) {
        $self->{portalObject}->{sessionInfo}->{_password} = $password;

        # Update session
        &Lemonldap::NG::Portal::Simple::updateSession( $self->{portalObject},
            { _password => $password } );
    }
    return 1;
}

# _ppolicyWarning
# Return ppolicy warnings get in AuthLDAP.pm
sub _ppolicyWarning {
    my $self = shift;

    # Grace
    if (
        defined $self->{portalObject}->{ppolicy}
        ->{grace_authentications_remaining} )
    {
        return ( PE_PP_GRACE,
            $self->{portalObject}->{ppolicy}
              ->{grace_authentications_remaining} );
    }

    # Expiration warning
    if ( defined $self->{portalObject}->{ppolicy}->{time_before_expiration} ) {
        return ( PE_PP_EXP_WARNING,
            $self->{portalObject}->{ppolicy}->{time_before_expiration} );
    }

    # Return PE_OK
    return ( PE_OK, undef );
}

# _grant
# Check user's authorization
sub _grant {
    my $self = shift;
    my ($uri) = @_;
    $uri =~ m{(\w+)://([^/:]+)(:\d+)?(/.*)?$};
    my ( $protocol, $vhost, $port );
    ( $protocol, $vhost, $port, $path ) = ( $1, $2, $3, $4 );
    $path ||= '/';
    $self->_compileRules() if ( $cfgNum != $self->{portalObject}->{cfgNum} );
    return -1 unless ( defined( $defaultCondition->{$vhost} ) );

    if ( defined $locationRegexp->{$vhost} ) {    # Not just a default rule
        for ( my $i = 0 ; $i < @{ $locationRegexp->{$vhost} } ; $i++ ) {
            if ( $path =~ $locationRegexp->{$vhost}->[$i] ) {
                return &{ $locationCondition->{$vhost}->[$i] }($self);
            }
        }
    }
    unless ( $defaultCondition->{$vhost} ) {
        print STDERR
          "Application $uri did not match any configured virtual host\n";
        return 0;
    }
    return &{ $defaultCondition->{$vhost} }($self);
    return 1;
}

# _compileRules
# Parse configured rules
sub _compileRules {
    my $self = shift;
    foreach my $vhost ( keys %{ $self->{portalObject}->{locationRules} } ) {
        my $i = 0;
        foreach ( keys %{ $self->{portalObject}->{locationRules}->{$vhost} } ) {
            if ( $_ eq 'default' ) {
                $defaultCondition->{$vhost} =
                  $self->_conditionSub(
                    $self->{portalObject}->{locationRules}->{$vhost}->{$_} );
            }
            else {
                $locationCondition->{$vhost}->[$i] =
                  $self->_conditionSub(
                    $self->{portalObject}->{locationRules}->{$vhost}->{$_} );
                $locationRegexp->{$vhost}->[$i] = qr/$_/;
                $i++;
            }
        }

        # Default policy
        $defaultCondition->{$vhost} ||= $self->_conditionSub('accept');
    }
    $cfgNum = $self->{portalObject}->{cfgNum};
    1;
}

# _conditionSub
# Return subroutine giving authorization condition
sub _conditionSub {
    my $self = shift;
    my ($cond) = @_;
    return sub { 1 }
      if ( $cond =~ /^accept$/i );
    return sub { 0 }
      if ( $cond =~ /^(?:deny$|logout)/i );
    $cond =~ s/\$date/&POSIX::strftime("%Y%m%d%H%M%S",localtime())/e;
    $cond =~ s/\$(\w+)/\$self->{portalObject}->{sessionInfo}->{$1}/g;
    my $sub;
    $sub = $self->_safe->reval("sub {my \$self = shift; return ( $cond )}");
    return $sub;
}

1;

__END__

=head1 NAME

Lemonldap::NG::Portal::Menu - Enhanced menu to display to authenticated users

=head1 SYNOPSIS

    use Lemonldap::NG::Portal::Menu;
    my $menu = Lemonldap::NG::Portal::Menu->new(
      {
        portalObject => $portal,
        apps => {
            xmlfile => "/var/lib/lemonldap-ng/conf/apps-list.xml",
            imgpath => "apps/",
        },
        modules => {
            appslist => 1,
            password => 1,
            logout => 1,
        },
      }
    );

    # Print HTML code of authorized applications list
    print $menu->appslistMenu;

=head1 DESCRIPTION

Lemonldap::NG::Portal::Menu provides these web modules:

=over

=item * Application list: display a full menu with all authorized applications

=item * Password: allow the user to change its password (with LDAP auth only)

=item * Logout: display a simple logout confirmation page

=back

These web modules are designed to be used in HTML::Template, with the help of 
Jquery scripts. Without that, this will only output raw HTML code.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>,
http://wiki.lemonldap.objectweb.org/xwiki/bin/view/NG/EnhancedMenu
http://wiki.lemonldap.objectweb.org/xwiki/bin/view/NG/Presentation

=head1 AUTHOR

Clement OUDOT E<lt>clement@oodo.netE<gt> E<lt>coudot@linagora.comE<gt>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://forge.objectweb.org/tracker/?group_id=274>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut


