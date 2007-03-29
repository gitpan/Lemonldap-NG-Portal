package Lemonldap::NG::Portal::_i18n;

use AutoLoader qw(AUTOLOAD);
use UNIVERSAL qw(can);
our $VERSION = '0.01';

sub error {
    my($error,$lang) = @_;
    $lang = lc($lang);
    $lang =~ s/-/_/g;
    foreach ( split( /[,;]/, $lang ) ) {
        next if /=/;
        if ( __PACKAGE__->can("error_$_") ) {
            return &{"error_$_"}->[$error];
        }
    }
    return &error_en->[$error];
}

*error_fr_fr = *error_fr;
*error_en_us = *error_en;

1;
__END__
# Order of the constants
# * PE_OK                   0
# * PE_SESSIONEXPIRED       1
# * PE_FORMEMPTY            2
# * PE_WRONGMANAGERACCOUNT  3
# * PE_USERNOTFOUND         4
# * PE_BADCREDENTIALS       5
# * PE_LDAPCONNECTFAILED    6
# * PE_LDAPERROR            7
# * PE_APACHESESSIONERROR   8
# * PE_FIRSTACCESS          9
# * PE_BADCERTIFICATE      10

# Not used in errors:
# * PE_DONE                -1

=pod
=cut
sub error_fr {
    [
        'Utilisateur authentifié',
        'Votre session a expiré, vous devez vous réauthentifier',
        'login ou mot de passe non renseigné',
        "Compte ou mot de passe LDAP de l'application incorrect",
        'Utilisateur inexistant',
        'mot de passe ou login incorrect',
        'Connexion impossible au serveur LDAP',
        'Erreur anormale du serveur LDAP',
        'Erreur du module Apache::Session choisi',
        'Authentification exigée',
        'Certificat invalide',
    ];
}

sub error_en {
    [
        'Everything is OK',
        'Your connection has expired; You must to be authentified once again',
        'User and password fields must be filled',
        'Wrong directory manager account or password',
        'User not found in directory',
        'Wrong credentials',
        'Unable to connect to LDAP server',
        'Abnormal error from LDAP server',
        'Apache::Session module failed',
        'Authentication required',
        'Invalid certificate',
    ];
}