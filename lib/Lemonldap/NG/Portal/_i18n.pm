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
# Order of the constants:
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
# * PE_LA_FAILED           11
# * PE_LA_ARTFAILED        12
# * PE_LA_DEFEDFAILED      13
# * PE_LA_QUERYEMPTY       14
# * PE_LA_SOAPFAILED       15
# * PE_LA_SLOFAILED        16
# * PE_LA_SSOFAILED        17
# * PE_LA_SSOINITFAILED    18
# * PE_LA_SESSIONERROR     19
# * PE_LA_SEPFAILED        20


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
        "Echec de l'initialisation de Lasso:Login ou Lasso:Logout failed",
        "Echec de la résolution de l'artefact Liberty-Alliance",
        "Echec de la défédération Liberty-Alliance",
        "La requête renvoyée par le fournisseur d'identité Liberty-Alliance est vide",
        "Un des appels SOAP Liberty-Alliance a échoué",
        "Un des appels de déconnexion Liberty-Alliance a échoué",
        "Aucun artefact SAML trouvé, ou échec de l'auto-acceptation SSO",
        "Initialisation, construction ou requête SSO en échec",
        "Impossible d'enregistrer l'identifiant de connexion Liberty-Alliance",
        "Un processus terminal Liberty-Alliance a échoué",
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
        'Initialization of Lasso:Login or Lasso:Logout failed',
        'Liberty-Alliance artefact resolution failed',
        'Liberty-Alliance defederation failed',
        'Liberty-Alliance query returned by IDP in assertion is empty',
        'One of Liberty-Alliance soap calls failed',
        'One of Liberty-Alliance single logout failed',
        'No SAML artefact found, or auto-accepting SSO failed',
        'Initializing, building or requesting SSO failed',
        'Unable to store Liberty-Alliance session id',
        'A Liberty-Alliance Soap End Point process failed',
    ];
}

