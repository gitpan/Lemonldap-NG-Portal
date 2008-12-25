package Lemonldap::NG::Portal::CDA;

use strict;
use Lemonldap::NG::Portal::SharedConf qw(:all);

our $VERSION = '0.04';
use base ('Lemonldap::NG::Portal::SharedConf');

*EXPORT_OK   = *Lemonldap::NG::Portal::SharedConf::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::SharedConf::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::SharedConf::EXPORT;

##################
# OVERLOADED SUB #
##################

# 2. Existing sessions are validated so users coming from an other domain
#    are not re-prompted
sub existingSession {
    my ( $self, $id, $datas ) = @_;
    PE_DONE;
}

# 16. If the user was redirected to the portal, we will now redirect him
#     to the requested URL. If it does not come from our domain, we add
#     ID in URL
sub autoRedirect {
    my $self       = shift;
    my $tmp        = $self->{domain};
    my $cookieName = $self->{cookieName};

    if (    $self->{urldc}
        and $self->{urldc} !~ m#^https?://[^/]*$tmp/#oi
        and $self->{id}
        and $self->{urldc} !~ m#[\?&]?$cookieName=\w+&?#oi )
    {
        $self->{urldc} .= ( $self->{urldc} =~ /\?{1}/oi ) ? '&' : '?';
        $self->{urldc} .= $cookieName . "=" . $self->{id};
    }
    return $self->SUPER::autoRedirect(@_);
}

1;
__END__

=head1 NAME

Lemonldap::NG::Portal::CDA - Perl extension for building Lemonldap::NG
compatible portals with Cross Domain Authentication.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::SharedConf( {
         configStorage => {
             type        => 'DBI',
             dbiChain    => "dbi:mysql:...",
             dbiUser     => "lemonldap",
             dbiPassword => "password",
             dbiTable    => "lmConfig",
         },
    } );

  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header('text/html; charset=utf8'); # DON'T FORGET THIS (see L<CGI(3)>)
    print "...";

    # or redirect the user to the menu
    print $portal->redirect( -uri => 'https://portal/menu');
  }
  else {
    # Write here the html form used to authenticate with CGI methods.
    # $portal->error returns the error message if athentification failed
    # Warning: by defaut, input names are "user" and "password"
    print $portal->header('text/html; charset=utf8'); # DON'T FORGET THIS (see L<CGI(3)>)
    print "...";
    print '<form method="POST">';
    # In your form, the following value is required for redirection
    print '<input type="hidden" name="url" value="'.$portal->param('url').'">';
    # Next, login and password
    print 'Login : <input name="user"><br>';
    print 'Password : <input name="password" type="password" autocomplete="off">';
    print '<input type="submit" value="go" />';
    print '</form>';
  }

Modify your httpd.conf:

  <Location /My/File>
    SSLVerifyClient require
    SSLOptions +ExportCertData +CompatEnvVars +StdEnvVars
  </Location>

=head1 DESCRIPTION

This library just overload few methods of L<Lemonldap::NG::Portal::SharedConf>
to add Cross Domain Authentication. Handlers that are not used in the same
domain than the portal must inherit from L<Lemonldap::NG::Handler::CDA>.

See L<Lemonldap::NG::Portal::SharedConf> for usage and other methods.

=head1 SEE ALSO

L<Lemonldap::NG::SharedConf>, L<Lemonldap::NG::Handler>,
L<Lemonldap::NG::Handler::CDA>,
http://wiki.lemonldap.objectweb.org/xwiki/bin/view/NG/Presentation

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://forge.objectweb.org/tracker/?group_id=274>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

