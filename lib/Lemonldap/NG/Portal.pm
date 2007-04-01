package Lemonldap::NG::Portal;

print STDERR
"See Lemonldap::NG::Portal(3) to know which Lemonldap::NG::Portal::* module to use.";
our $VERSION = "0.71";

1;

__END__

=pod

=head1 NAME

Lemonldap::NG::Portal - The authentication portal part of Lemonldap::NG Web-SSO
system.

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::SharedConf (
        configStorage => {
            type          => 'DBI',
            dbiChain      => "dbi:mysql:database=lmSessions;host=1.2.3.4",
            dbiUser       => "lemon",
            dbiPassword   => "pass",
          },
        );


  if($portal->process()) {
      # Write here the menu with CGI methods. This page is displayed ONLY IF
      # the user was not redirected here by a Lemonldap::NG::Handler,
      # else, the process sub redirect the user to the initial requested URI.
      print $portal->header; # DON'T FORGET THIS (see L<CGI(3)>)
      print "...";
  
      # or redirect the user to the menu
      print $portal->redirect( -uri => 'https://portal/menu');
      
      # You can also add a "Logout" link:
      print "<a href=\"$ENV{SCRIPT_NAME}?logout=1\">";
  }
  else {
      # Write here the html form used to authenticate with CGI methods.
      # $portal->error returns the error message if authentification failed
      # Warning: by defaut, input names are "user" and "password"
      print $portal->header; # DON'T FORGET THIS (see L<CGI(3)>)
      print "<html> ...";
      print '<form method="POST">';
      # In your form, the following value is required for redirection
      print '<input type="hidden" name="url" value="'.$portal->param('url').'">';
      # Next, login and password
      print 'Login : <input name="user"><br>';
      print 'Password : <input name="password" type="password" autocomplete="off"><br>';
      print '<input type=submit value="OK">';
      print '</form>';
  }

=head1 DESCRIPTION

Lemonldap::NG is a modular Web-SSO based on Apache::Session modules. It
simplifies the build of a protected area with a few changes in the application.

It manages both authentication and authorization and provides headers for
accounting. So you can have a full AAA protection for your web space as
described below.

The portal part inherits from L<CGI> so yo can use it both with Apache 1 and 2
and use all L<CGI> features.

=head2 Authentication, Autorization, Accounting

=head3 B<Authentication>

If a user isn't authenticated and attemps to connect to an area protected by a
Lemonldap::NG compatible handler, he is redirected to a portal. The portal
authenticates user with a ldap bind by default, but you can also use another
authentication sheme like using x509 user certificates (see
L<Lemonldap::NG::Portal::AuthSSL> for more).

Lemonldap use session cookies generated by L<Apache::Session> so as secure as a
128-bit random cookie. You may use the C<securedCookie> options of
L<Lemonldap::NG::Portal> to avoid session hijacking.

You have to manage life of sessions by yourself since Lemonldap knows nothing
about the L<Apache::Session> module you've choosed, but it's very easy using a
simple cron script because L<Lemonldap::NG::Portal> stores the start time in the
C<_utime> field.
By default, a session stay 10 minutes in the Handler local storage, so in the
worth case, a user is authorized 10 minutes after he lost his rights.

=head3 B<Authorization>

Authorization is controled only by handlers because the portal knows nothing
about the way the user will choose. When configuring your Web-SSO, you have to:

=over

=item * choose the ldap attributes you want to use to manage accounting and
authorization (see C<exportedHeaders> parameter in L<Lemonldap::NG::Portal>
documentation),

=item * create Perl expression to define user groups (using ldap attributes):
optionnal, this mechanism is available with Lemonldap::NG::*::SharedConf
modules,

=item * create an array foreach virtual host associating URI regular
expressions and Perl expressions to use to grant access.

=back

=head4 Example

Exported variables (in Lemonldap::NG::Portal, will be stored in
configuration database):

  exportedVars => {
      cn            => "cn",
      departmentUID => "departmentUID",
      login         => "uid",
  },

User groups (stored in configuration database with L<Lemonldap::NG::Manager>):

  groups => {
      group1 => '{ $departmentUID eq "unit1" or $login = "xavier.guimard" }',
      ...
  },

Area protection (stored in configuration database with
L<Lemonldap::NG::Manager>):

  locationRules => {
      www1.domain.com => {
          '^/protected/.*$' => '$groups =~ /\bgroup1\b/',
          default           => 'accept',
      },
      www2.domain.com => {
          '^/site/.*$' => '$uid eq "xavier.guimard" or $groups =~ /\bgroup2\b/',
          '^/(js|css)' => 'accept',
          default      => 'deny',
      },
  },

=head4 Performance

You can use Perl expressions as complicated as you want and you can use all
the exported LDAP attributes (and create your own attributes: see examples in
L<Lemonldap::NG::Portal> distribution) both in groups evaluations and area
protections (you just have to call them with a "$").

You have to be careful when choosing your expressions:

=over

=item * C<groups> are evaluated each time a user is redirected to the portal,

=item * C<locationRules> are evaluated for each request.

=back

It is also recommanded to use the C<groups> mechanism to avoid having to
evaluate a long expression at each HTTP request:

  locationRules => {
      www1.domain.com => {
          '^/protected/.*$' => '$groups =~ /\bgroup1\b/',
      },
  },

You can also use ldap filters in C<groups> parameter, or Perl expression or
mixed expressions. Perl expressions has to be enclosed with C<{}>:

=over

=item * C<group1 =E<gt> '(|(uid=xavier.guimard)(ou=unit1))'>

=item * C<group1 =E<gt> '{$uid eq "xavier.guimard" or $ou eq "unit1"}'>

=item * C<group1 =E<gt> '(|(uid=xavier.guimard){$ou eq "unit1"})'>

=back

It is also recommanded to use Perl expressions to avoid requiering the LDAP
server more than 2 times per authentication.

=head3 B<Accounting>

=head4 I<Logging portal access>

L<Lemonldap::NG::Portal> doesn't log anything by default, but it's easy to overload
C<log> method for normal portal access or using C<error> method to know what
was wrong if C<process> method has failed.

=head4 I<Logging application access>

Because an handler knows nothing about the protected application, it can't do
more than logging URL. As Apache does this fine, L<Lemonldap::NG::Handler> gives it
the name to used in logs. The C<whatToTrace> parameters indicates which
variable Apache has to use (C<$uid> by default).

The real accounting has to be done by the application itself which knows the
result of SQL transaction for example.

Lemonldap can export http headers either using a proxy or protecting directly
the application. By default, the C<User-Auth> field is used but you can change
it using the C<exportedHeaders> parameters (stored in the configuration
database). This parameters contains an associative array:

=over

=item * B<keys> are the names of the choosen headers

=item * B<values> are perl expressions where you can use user datas stored in
the global store by calling them C<$E<lt>varnameE<gt>>.

=back

Example:

  exportedHeaders => {
      www1.domain.com => {
          'Auth-User' => '$uid',
          'Unit'      => '$ou',
      },
      www2.domain.com => {
          'Authorization' => '"Basic ".encode_base64($employeeNumber.":dummy")',
      },
  }

=head2 Storage systems

Lemonldap::NG use 3 levels of cache for authenticated users:

=over

=item * an Apache::Session::* module choosed with the C<globalStorage>
parameter (completed with C<globalglobalStorageOptions>) and used by
L<lemonldap::NG::Portal> to store authenticated user parameters,

=item * a L<Cache::Cache> module choosed with the C<localStorage> parameter
(completed with C<localStorageOptions> and used to share authenticated users
between Apache's threads or processus and of course between virtual hosts,

=item * Lemonldap::NG variables: if the same user use the same thread or
processus a second time, no request are needed to grant or refuse access. This
is very efficient with HTTP/1.1 Keep-Alive system.

=back

So the number of request to the central storage is limited to 1 per user each
10 minutes.

Lemonldap::NG is very fast, but you can increase performance using a
L<Cache::Cache> module that does not use disk access.

=head2 Logout system

Lemonldap::NG provides a single logout system: you can use it by adding a link
to the portal with "logout=1" parameter (See Synopsis) and/or by configuring
Handler to intercept some URL (See L<Lemonldap::NG::Handler>). The logout
system:

=over

=item * delete session in the global session storage,

=item * replace Lemonldap::NG cookie by '',

=item * delete handler caches only if logout action was started from a
protected application and only in the current Apache server. So in other
servers, session is still in cache for 10 minutes maximum if the user was
connected on it in the last 10 minutes.

=back

=head1 USING LEMONLDAP::NG::PORTAL FOR DEVELOPMENT

Lemonldap::NG::Portal provides different modules:

=over

=item * L<Lemonldap::NG::Portal::Simple>: base module to build a portal,

=item * L<Lemonldap::NG::Portal::AuthSsl>: module that modify authentication
scheme to use X509 authentication,

=item * L<Lemonldap::NG::Portal::SharedConf>: this module provide the ability
to read portal configuration from a central database. It inherits from
L<Lemonldap::NG::Portal::Simple>. It's the more used module.

=back

=head1 SEE ALSO

L<Lemonldap::NG::Portal::SharedConf>, L<Lemonldap::NG::Portal::Simple>
L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Manager>,
http://wiki.lemonldap.objectweb.org/xwiki/bin/view/NG/Presentation

=head1 AUTHOR

Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by Xavier Guimard E<lt>x.guimard@free.frE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

Lemonldap was originaly written by Eric German who decided to publish him in
2003 under the terms of the GNU General Public License version 2.
Lemonldap::NG is a complete rewrite of Lemonldap and is able to have different
policies in a same Apache virtual host.

=cut
