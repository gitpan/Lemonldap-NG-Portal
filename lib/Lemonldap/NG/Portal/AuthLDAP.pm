package Lemonldap::NG::Portal::AuthLDAP;

use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_LDAP;
use Lemonldap::NG::Portal::_WebForm;
use Lemonldap::NG::Portal::UserDBLDAP;

our $VERSION = '0.2';
use base qw(Lemonldap::NG::Portal::_WebForm);

sub ldap {
    my $self = shift;
    unless ( ref( $self->{ldap} ) ) {
        my $mesg = $self->{ldap}->bind
          if ( $self->{ldap} = Lemonldap::NG::Portal::_LDAP->new($self) );
        if ( !$mesg || $mesg->code != 0 ) {
            return 0;
        }
    }
    return $self->{ldap};
}

*_formateFilter = *Lemonldap::NG::Portal::UserDBLDAP::formateFilter;
*_search = *Lemonldap::NG::Portal::UserDBLDAP::search;

sub authenticate {
    my $self = shift;
    unless ( $self->ldap ) {
        return PE_LDAPCONNECTFAILED;
    }

    # Set the dn unless done before
    unless($self->{dn}) {
        my $tmp = $self->_subProcess(qw(_formateFilter _search));
        return $tmp if($tmp);
    }

    # Check if we use Ppolicy control
    if ( $self->{ldapPpolicyControl} ) {

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

        # Bind with user credentials
        my $mesg = $self->ldap->bind(
            $self->{dn},
            password => $self->{password},
            control  => [$pp]
        );

        # Get server control response
        my ($resp) = $mesg->control("1.3.6.1.4.1.42.2.27.8.5.1");

        # Get expiration warning and graces
        $self->{ppolicy}->{time_before_expiration} =
          $resp->time_before_expiration;
        $self->{ppolicy}->{grace_authentications_remaining} =
          $resp->grace_authentications_remaining;

        # Get bind response
        return PE_OK if ( $mesg->code == 0 );

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
            else {
                return PE_BADCREDENTIALS;
            }
        }
        else {
            return PE_LDAPERROR;
        }
    }
    else {
        my $mesg =
          $self->ldap->bind( $self->{dn}, password => $self->{password} );
        return PE_BADCREDENTIALS if ( $mesg->code != 0 );
    }
    $self->{sessionInfo}->{authenticationLevel} = 2;
    PE_OK;
}

1;
