##@file
# AD authentication backend file

##@class
# AD authentication backend class
package Lemonldap::NG::Portal::AuthAD;

use strict;

our $VERSION = '1.4.0';
use Lemonldap::NG::Portal::Simple;
use base qw(Lemonldap::NG::Portal::AuthLDAP);

*_formateFilter = *Lemonldap::NG::Portal::UserDBAD::formateFilter;
*getDisplayType = *Lemonldap::NG::Portal::AuthLDAP::getDisplayType;

## @apmethod int authInit()
# Add specific attributes for search
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;

    $self->{ldapExportedVars}->{_AD_pwdLastSet}         = 'pwdLastSet';
    $self->{ldapExportedVars}->{_AD_userAccountControl} = 'userAccountControl';

    return $self->SUPER::authInit();
}

## @apmethod int authenticate()
# Authenticate user by LDAP mechanism.
# Check AD specific attribute to get password state.
# @return Lemonldap::NG::Portal constant
sub authenticate {
    my $self = shift;

    my $res = $self->SUPER::authenticate;

    unless ( $res == PE_OK ) {

        # Check specific AD attributes
        my $pls = $self->{entry}->get_value('pwdLastSet');

        # Password must be changed if pwdLastSet 0
        if ( $pls == 0 ) {
            $self->lmLog( "[AD] User must change its password", 'debug' );
            return PE_PP_CHANGE_AFTER_RESET;
        }

    }

    # Remember password if password reset needed
    $self->{oldpassword} = $self->{password}
      if ( $res == PE_PP_CHANGE_AFTER_RESET );

    return $res;
}

1;
