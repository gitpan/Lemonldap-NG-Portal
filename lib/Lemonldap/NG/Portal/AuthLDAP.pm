package Lemonldap::NG::Portal::AuthLDAP;

use Lemonldap::NG::Portal::Simple;

our $VERSION = '0.1';

sub authInit {
}

sub extractFormInfo {
    my $self = shift;
    return PE_FIRSTACCESS
      unless ( $self->param('user') );
    return PE_FORMEMPTY
      unless ( length( $self->{'user'} = $self->param('user') ) > 0
        && length( $self->{'password'} = $self->param('password') ) > 0 );
    PE_OK;
}

sub setAuthSessionInfo {
    PE_OK;
}

sub authenticate {
    my $self = shift;
    $self->unbind();
    my $err;
    return $err unless ( ( $err = $self->connectLDAP ) == PE_OK );
    # Check if we use Ppolicy control
    if ( $self->{ldapPpolicyControl} ) {

        # require Perl module
        eval 'require Net::LDAP::Control::PasswordPolicy';
        if ($@) {
            print STDERR "Module Net::LDAP::Control::PasswordPolicy not found in @INC\n";
            return PE_LDAPERROR;
        }
        no strict 'subs';

        # Create Control object
        my $pp = Net::LDAP::Control::PasswordPolicy->new;

        # Bind with user credentials
        my $mesg = $self->{ldap}->bind(
            $self->{dn},
            password => $self->{password},
            control  => [$pp]
        );

        # Get bind response
        return PE_OK if ( $mesg->code == 0 );

        # Get server control response
        my ($resp) = $mesg->control("1.3.6.1.4.1.42.2.27.8.5.1");

        if ( defined $resp ) {
            my $pp_error = $resp->error;
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
            else {
                return PE_BADCREDENTIALS;
            }
        }
        else {
            return PE_LDAPERROR;
        }
    }
    else {
        return PE_BADCREDENTIALS
          unless (
            $self->_bind( $self->{ldap}, $self->{dn}, $self->{password} ) );
    }
    $self->{sessionInfo}->{authenticationLevel} = 2;
    PE_OK;
}

1;
