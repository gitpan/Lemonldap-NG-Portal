##@file
# SSL authentication backend file

##@class
# SSL authentication backend class
package Lemonldap::NG::Portal::AuthSSL;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::AuthNull;

our $VERSION = '1.2.2';
our @ISA     = qw(Lemonldap::NG::Portal::AuthNull);

*authenticate = *extractFormInfo;

## @apmethod int authInit()
# Check if SSL environment variables are set.
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;
    $self->{SSLVar} ||= 'SSL_CLIENT_S_DN_Email';
    PE_OK;
}

## @apmethod int extractFormInfo()
# Read username in SSL environment variables, or return an error
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;
    my $user = $self->https ? $ENV{ $self->{SSLVar} } : 0;
    if ($user) {
        $self->{user} = $user;
        return PE_OK;
    }
    else {
        $self->_sub( 'userError',
            "No certificate found for $ENV{REMOTE_ADDR}" );
        return PE_CERTIFICATEREQUIRED;
    }
}

## @apmethod int setAuthSessionInfo()
# Set _user and authenticationLevel.
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    # Store user certificate login for basic rules
    $self->{sessionInfo}->{'_user'} = $self->{'user'};

    $self->{sessionInfo}->{authenticationLevel} = $self->{SSLAuthnLevel};
    PE_OK;
}

## @method string getDisplayType
# @return display type
sub getDisplayType {
    return "logo";
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::AuthSSL - Perl extension for building Lemonldap::NG
compatible portals with SSL authentication.

=head1 SYNOPSIS

With Lemonldap::NG::Portal::SharedConf, set authentication field to "SSL" in
configuration database.

With Lemonldap::NG::Portal::Simple:

  use Lemonldap::NG::Portal::Simple;
  my $portal = new Lemonldap::NG::Portal::Simple(
         domain         => 'example.com',
         globalStorage  => 'Apache::Session::MySQL',
         globalStorageOptions => {
           DataSource   => 'dbi:mysql:database',
           UserName     => 'db_user',
           Password     => 'db_password',
           TableName    => 'sessions',
         },
         ldapServer     => 'ldap.domaine.com',
         securedCookie  => 1,
         authentication => 'SSL',
         
         # SSLVar: field to search in client certificate
         #         default: SSL_CLIENT_S_DN_Email the mail address
         SSLVar         => 'SSL_CLIENT_S_DN_CN',
    );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header('text/html; charset=utf8'); # DON'T FORGET THIS (see CGI(3))
    print "...";

    # or redirect the user to the menu
    print $portal->redirect( -uri => 'https://portal/menu');
  }
  else {
    # If the user enters here, IT MEANS THAT YOUR SSL PARAMETERS ARE BAD
    print $portal->header('text/html; charset=utf8'); # DON'T FORGET THIS (see CGI(3))
    print "<html><body><h1>Unable to work</h1>";
    print "This server isn't well configured. Contact your administrator.";
    print "</body></html>";
  }

Modify your httpd.conf:

  <Location /My/File>
    SSLVerifyClient optional # or 'require' if login/password are disabled
    SSLOptions +StdEnvVars
  </Location>

=head1 DESCRIPTION

This library just overload few methods of Lemonldap::NG::Portal::Simple to use
Apache SSLv3 mechanism: we've just to verify that
C<$ENV{SSL_CLIENT_S_DN_Email}> exists. So remenber to export SSL variables
to CGI.

If SSL is used, authenticationLevel is set to 5. You can use this parameter in
L<Lemonldap::NG::Handler> rules to force users to use certificates in some
applications:

  virtualHost1 => {
    'default' => '$authenticationLevel > 5 and $uid = "jeff"',
  },

Note that you can use Apache SSL environment variables in "exported variables".

See L<Lemonldap::NG::Portal::Simple> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Portal::Simple>,
L<http://lemonldap-ng.org/>

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2007, 2010 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

