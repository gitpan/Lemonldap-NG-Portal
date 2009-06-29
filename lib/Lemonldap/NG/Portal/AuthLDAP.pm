##@file
# LDAP authentication backend file

##@class
# LDAP authentication backend class
package Lemonldap::NG::Portal::AuthLDAP;

use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_LDAP 'ldap';    #link protected ldap
use Lemonldap::NG::Portal::_WebForm;
use Lemonldap::NG::Portal::UserDBLDAP;      #inherits

our $VERSION = '0.3';
use base qw(Lemonldap::NG::Portal::_WebForm);

*_formateFilter = *Lemonldap::NG::Portal::UserDBLDAP::formateFilter;
*_search        = *Lemonldap::NG::Portal::UserDBLDAP::search;

## @apmethod int authInit()
# Load Net::LDAP::Control::PasswordPolicy if needed
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;
    if ( $self->{ldapPpolicyControl} and not $self->ldap->loadPP()) {
        return PE_LDAPERROR;
    }
    PE_OK;
}

## @apmethod int authenticate()
# Authenticate user by LDAP mechanism.
# @return Lemonldap::NG::Portal constant
sub authenticate {
    my $self = shift;
    unless ( $self->ldap ) {
        return PE_LDAPCONNECTFAILED;
    }

    # Set the dn unless done before
    unless ( $self->{dn} ) {
        my $tmp = $self->_subProcess(qw(_formateFilter _search));
        return $tmp if ($tmp);
    }
    return $self->ldap->userBind( $self->{dn}, password => $self->{password} );
    PE_OK;
}

1;
