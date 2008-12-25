#!/usr/bin/perl

=pod

=head1 NON AUTHENTICATING PORTAL TO USE WITH OTHER WEB-SSO

If Lemonldap::NG has to operate with another Web-SSO without any interworking
system, Lemonldap::NG can be used as slave.

Install :

=over

=item * Install and adapt this file in an area protected by the master SSO

=item * Use L<Lemonldap::NG::Handler::CDA> to protect Lemonldap::NG area if
this area is not in the same DNS domain than the portal

=back

Authentication scheme :

=over

=item * a user that wants to access to a protected url, Lemonldap::NG::Handler
redirect it to the portal

=item * the portal creates the Lemonldap::NG session with the parameters given
by the master SSO

=item * the user is redirected to the wanted application. If it is not in the
same domain, the handler detects the session id with the Lemonldap::NG 
cross-domain-authentication mechanism and generates the cookie

=back

=cut

use Lemonldap::NG::Portal::CDA;

my $portal = Lemonldap::NG::Portal::CDA->new(
    {
        # SUBROUTINES OVERLOAD
        # 2 cases :
        # 1 - If LDAP search is not needed (the master SSO gives all
        #     that we need)
        extractFormInfo => sub { PE_OK },
        connectLDAP     => sub { PE_OK },
        bind            => sub { PE_OK },
        search          => sub { PE_OK },
        setSessionInfo  => sub {
            my $self = shift;

            # TODO: You have to set $self->{sessionInfo}
            #       hash table with user attributes
            #       Example:
            #          $self->{sessionInfo}->{uid} = $ENV{REMOTE_USER};
            PE_OK,;
        },
        unbind => sub { PE_OK },

        # 2 - Else, LDAP will do its job, but we have to set UID or
        #     what is needed by C<formateFilter> subroutine.
        extractFormInfo => sub {
            my $self = shift;

            # EXAMPLE with $ENV{REMOTE_USER}
            $self->{user} = $ENV{REMOTE_USER};
            PE_OK;
        },

        # In the 2 cases, authentication phase has to be avoided
        authenticate => sub { PE_OK },

        # If no Lemonldap::NG protected application is in the same domaine than
        # the portal, it is recommended to not set a lemonldap::NG cookie in the
        # other domain :
        #     Lemonldap::NG::Handler protect its cookie from remote application
        #     (to avoid developers to spoof an identity), but the master SSO
        #     will probably keep it.
        buildCookie => sub {
            my $self = shift;
            $self->{cookie} = $self->cookie(
                -name => $self->{cookieName},

                # null value instead of de $self->{id}
                -value  => '',
                -domain => $self->{domain},
                -path   => "/",
                -secure => $self->{securedCookie},
                @_,
            );
            PE_OK;
        },
    }
);

# Else, we process as usual, but without prompting users with a form

if ( $portal->process() ) {
    print $portal->header('text/html; charset=utf8');
    print $portal->start_html;
    print "<h1>Your well authenticated !</h1>";
    print $portal->end_html;
}
else {
    print $portal->header('text/html; charset=utf8');
    print $portal->start_html;
    print qq#<h2>Authentication failed</h2>
    Portal is not able to recognize you
    <br>
    Contact your administrator (Error: # . $portal->error . ')';
    print $portal->end_html;
}
1;
