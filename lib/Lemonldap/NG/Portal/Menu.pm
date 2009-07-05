##@file
# Menu for Lemonldap::NG portal

##@class
# Menu class for Lemonldap::NG portal
package Lemonldap::NG::Portal::Menu;

use strict;
use warnings;
require Lemonldap::NG::Common::CGI;
use Lemonldap::NG::Portal::SharedConf;
use Lemonldap::NG::Portal::_LDAP 'ldap';    #link protected ldap Object used to change passwords only
use XML::LibXML;
use Lemonldap::NG::Common::Safelib;    #link protected safe Safe object
use Safe;
use Lemonldap::NG::Portal::PasswordDBLDAP; #inherits

#inherits Net::LDAP::Control::PasswordPolicy

*_modifyPassword = *Lemonldap::NG::Portal::PasswordDBLDAP::modifyPassword;
*_passwordDBInit = *Lemonldap::NG::Portal::PasswordDBLDAP::passwordDBInit;

our $VERSION = '0.11';

### ACCESS CONTROL DISPLAY SYSTEM

our ( $defaultCondition, $locationCondition, $locationRegexp, $cfgNum, $path ) =
  ( undef, undef, undef, 0 );

## @method private Safe _safe()
# Build and returns security jail.
# Includes custom functions
# @return Safe object
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
        $self->{portalObject}->lmLog( $@, 'error' ) if ($@);
    }
    $self->{_safe}->share_from( 'main', ['%ENV'] );
    $self->{_safe}->share_from( 'Lemonldap::NG::Common::Safelib',
        $Lemonldap::NG::Common::Safelib::functions );
    $self->{_safe}->share( '&encode_base64', @t );
    return $self->{_safe};
}

my $catlevel = 0;

##@cmethod Lemonldap::NG::Portal::Menu new(hashRef args)
# Constructor.
# $args->{portalObject} is required.
#@param $args hash reference
#@return new object
sub new {
    my $class = shift;
    my $self  = {};
    bless( $self, $class );

    # Get configuration
    $self->Lemonldap::NG::Portal::Simple::getConf(@_)
      or Lemonldap::NG::Common::CGI->abort(
        "Unable to read $class->new() parameters");

    # Portal is required
    Lemonldap::NG::Common::CGI->abort("Portal object required")
      unless ( $self->{portalObject} );

    # Fill sessionInfo (yet done in portal...)
    #&Lemonldap::NG::Portal::Simple::getSessionInfo( $self->{portalObject} );

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

    # Store POST data in $self->{portalObject}
    $self->{portalObject}->{'newpassword'} =
      $self->{portalObject}->param('newpassword');
    $self->{portalObject}->{'confirmpassword'} =
      $self->{portalObject}->param('confirmpassword');
    $self->{portalObject}->{'oldpassword'} =
      $self->{portalObject}->param('oldpassword');
    $self->{portalObject}->{'dn'} =
      $self->{portalObject}->{sessionInfo}->{'dn'};
    $self->{portalObject}->{'user'} =
      $self->{portalObject}->{sessionInfo}->{'_user'};

    # Change password (only if newpassword submitted)
    $self->{error} = &_passwordDBInit( $self->{portalObject} )
      if $self->{portalObject}->{'newpassword'};
    $self->{error} = &_modifyPassword( $self->{portalObject} )
      if $self->{portalObject}->{'newpassword'};

    return $self;
}

## @method string error(string language)
# Return error string
# @param $language optional language to use. Default: browser accepted languages
# @return error string
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

*error_type = \&Lemonldap::NG::Portal::Simple::error_type;

## @method boolean displayModule(string modulename)
# Return true if the user can see the module.
# Use for HTML::Template variable.
# @param $modulename string
# @return boolean
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

## @method string displayTab()
# Tells which tab should be selected.
# Design for Jquery tabs.
# @return password, appslist or logout
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

## @method string appslistMenu()
# Returns HTML code for application list menu.
# @return HTML string
sub appslistMenu {
    my $self = shift;
    my $root = $self->_getXML;

    # Display all categories and applications
    return $self->_displayCategory( $root, $catlevel );
}

## @method string appslistDescription()
# Returns HTML code for application description.
# @return HTML string
sub appslistDescription {
    my $self = shift;
    my $root = $self->_getXML;

    # Display application description
    return $self->_displayDescription($root);
}

## @method private XML::LibXML::Document _getXML()
# @return XML root element object
sub _getXML {
    my $self = shift;
    return $self->{_xml} if($self->{_xml});

    # Parse XML file
    my $parser = XML::LibXML->new();
    $parser->validation('1');
    my $xml;
    eval { $xml = $parser->parse_file( $self->{apps}->{xmlfile} ); };
    $self->{portalObject}->abort( "Bad XML file", $@ ) if ($@);
    my $root = $xml->documentElement;

    # Filter XML file with user's authorizations
    $self->_filterXML($root);

    return $self->{_xml} = $root;
}

## @method string _displayCategory()
# Creates and returns HTML code for a category.
# @return HTML string
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
    if (@appnodes) {
        $html .= "<ul>";
        foreach (@appnodes) {
            $html .= $self->_displayApplication($_);
        }
        $html .= "</ul>";
    }

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

## @method private string _userParam(string arg)
# Returns value of $arg variable stored in session.
# @param $arg string to modify
# @return string modified
sub _userParam {
    my ( $self, $arg ) = @_;
    $arg =~ s/\$([\w]+)/$self->{portalObject}->{sessionInfo}->{$1}/g;
    return $arg;
}

## @method private string _displayApplication(XML::LibXML::Element app)
# Creates HTML code for an application.
# @param $app XML applications element
# @return HTML string
sub _displayApplication {
    my $self = shift;
    my ($app) = @_;
    my $html;

    # Get application items
    my $appid = $app->getAttribute('id');
    my $appname = $app->getChildrenByTagName('name')->string_value() || $appid;
    my $appuri =
      $self->_userParam( $app->getChildrenByTagName('uri')->string_value()
          || "" );

    # Display application
    $html .= "<li title=\"$appid\" class=\"appname\"><span>"
     . ($appuri ? "<a href=\"$appuri\">$appname</a>" : "<a>$appname</a>")
     . "</span>\n";
    my @appnodes = $app->findnodes("application");
    if (@appnodes) {
        $html .= "<ul>";
        foreach (@appnodes) {
            $html .= $self->_displayApplication($_);
        }
        $html .= "</ul>";
    }
    $html .= "</li>";
    return $html;
}

## @method private string _displayDescription(XML::LibXML::Document root)
# Create HTML code for application description.
# @param $root XML root element
# @return HTML_string
sub _displayDescription {
    my $self = shift;
    my ($root) = @_;
    my $html;

    my @apps = $root->getElementsByTagName('application');
    foreach (@apps) {

        # Get application items
        my $appid   = $_->getAttribute('id');
        my $appname = $_->getChildrenByTagName('name')->string_value();
        my $appuri =
          $self->_userParam( $_->getChildrenByTagName('uri')->string_value()
              || "#" );
        my $appdesc = $_->getChildrenByTagName('description')->string_value();
        my $applogofile = $_->getChildrenByTagName('logo')->string_value();
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

## @method private string _filterXML(XML::LibXML::Document root)
# Remove unauthorized nodes.
# @param $root XML root element
# @return XML_string
sub _filterXML {
    my $self = shift;
    my ($root) = @_;

    my @apps = $root->getElementsByTagName('application');
    foreach (@apps) {
        my $appdisplay = $_->getChildrenByTagName('display')->string_value();
        my $appuri =
          $self->_userParam( $_->getChildrenByTagName('uri')->string_value() );

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

## @method private void _hideEmptyCategory(XML::LibXML::Element cat)
# Hides empty categories for _filterXML().
# Return nothing $cat is modified directly
# @param $cat XML element
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

## @method private int function _ppolicyWarning()
# Return ppolicy warnings get in AuthLDAP.pm
# @return Lemonldap::NG::Portal constant
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

## @method private boolean _grant(string uri)
# Check user's authorization for $uri.
# @param $uri URL string
# @return True if granted
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
        $self->{portalObject}
          ->lmLog( "Application $uri did not match any configured virtual host",
            'warn' );
        return 0;
    }
    return &{ $defaultCondition->{$vhost} }($self);
    return 1;
}

## @method private boolean _compileRules()
# Parse configured rules and compile them
# @return True
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

## @method private CODE _conditionSub(string cond)
# Return subroutine giving authorization condition.
# @param $cond boolean expression
# @return Compiled routine
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

Copyright (C) 2005-2007 by Clement OUDOT E<lt>clement@oodo.netE<gt>
E<lt>coudot@linagora.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut


