package Lemonldap::NG::Portal::Error;

use strict;
use Lemonldap::NG::Portal::SharedConf qw(:all);

our $VERSION = '0.01';
use base ('Lemonldap::NG::Portal::SharedConf');

*EXPORT_OK   = *Lemonldap::NG::Portal::SharedConf::EXPORT_OK;
*EXPORT_TAGS = *Lemonldap::NG::Portal::SharedConf::EXPORT_TAGS;
*EXPORT      = *Lemonldap::NG::Portal::SharedConf::EXPORT;

# getPortal
# Return portal URL from configuration
sub getPortal {
    my $self = shift;

    # Return portal
    return $self->{portal};
}

1;

__END__

=head1 NAME

Lemonldap::NG::Portal::Error - Simple error page

=head1 SYNOPSIS

  #!/usr/bin/perl

  use Lemonldap::NG::Portal::Error;

  my $portal = Lemonldap::NG::Portal::Error->new(
    {
        configStorage => {
            type    => 'File',
            dirName => '/opt/lemonldap-ng/conf/',
        },
    });

  my $portal_url = $portal->getPortal;
  my $logout_url = "$portal_url?logout=1";

  print $portal->header('text/html; charset=utf8');
  print $portal->star_html('Error');
  print "...":
  print "<a href=$portal_url>Go to portal</a>";
  print "<a href=$logout_url>Logout</a>";
  print $portal->end_html;

=head1 DESCRIPTION

Create a simple portal to display an error page.

=head1 METHODS

=head2 getPortal

Return the portal URL that was configured.

=head1 SEE ALSO

L<Lemonldap::NG::SharedConf>, L<Lemonldap::NG::Handler>,
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

Copyright (C) 2007 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

