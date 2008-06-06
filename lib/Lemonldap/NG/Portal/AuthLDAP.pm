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
        die('Module Net::LDAP::Control::PasswordPolicy not found in @INC')
          if ($@);
        eval
'use Net::LDAP::Constant qw( LDAP_CONTROL_PASSWORDPOLICY LDAP_PP_ACCOUNT_LOCKED LDAP_PP_PASSWORD_EXPIRED );';
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
        my ($resp) = $mesg->control(LDAP_CONTROL_PASSWORDPOLICY);

        if ( defined $resp ) {
            my $pp_error = $resp->error;
            if ($pp_error) {
                return PE_PP_ACCOUNT_LOCKED
                  if ( $pp_error == LDAP_PP_ACCOUNT_LOCKED );
                return PE_PP_PASSWORD_EXPIRED
                  if ( $pp_error == LDAP_PP_PASSWORD_EXPIRED );
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
