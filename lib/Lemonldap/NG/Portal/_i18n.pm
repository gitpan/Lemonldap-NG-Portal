package Lemonldap::NG::Portal::_i18n;

use AutoLoader qw(AUTOLOAD);
use UNIVERSAL qw(can);
our $VERSION = '0.1';

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
# * PE_PP_ACCOUNT_LOCKED   21
# * PE_PP_PASSWORD_EXPIRED 22

# Not used in errors:
# * PE_DONE                -1

=pod
=cut
sub error_fr {
    [
        "Utilisateur authentifi�",
        "Votre session a expir�, vous devez vous r�authentifier",
        "Identifiant ou mot de passe non renseign�",
        "Compte ou mot de passe LDAP de l'application incorrect",
        "Utilisateur inexistant",
        "Mot de passe ou identifiant incorrect",
        "Connexion impossible au serveur LDAP",
        "Erreur anormale du serveur LDAP",
        "Erreur du module Apache::Session choisi",
        "Authentification exig�e",
        "Certificat invalide",
        "�chec de l'initialisation de Lasso:Login ou Lasso:Logout",
        "�chec de la r�solution de l'artefact Liberty Alliance",
        "�chec de la d�f�d�ration Liberty Alliance",
        "La requ�te renvoy�e par le fournisseur d'identit� Liberty Alliance est vide",
        "Un des appels SOAP Liberty Alliance a �chou�",
        "Un des appels de d�connexion Liberty Alliance a �chou�",
        "Aucun artefact SAML trouv�, ou �chec de l'auto-acceptation SSO",
        "Initialisation, construction ou requ�te SSO en �chec",
        "Impossible d'enregistrer l'identifiant de connexion Liberty Alliance",
        "Un processus terminal Liberty Alliance a �chou�",
        "Votre compte est bloqu�",
        "Votre mot de passe a expir�",
    ];
}

sub error_en {
    [
        "Everything is OK",
        "Your connection has expired; You must to be authentified once again",
        "User and password fields must be filled",
        "Wrong directory manager account or password",
        "User not found in directory",
        "Wrong credentials",
        "Unable to connect to LDAP server",
        "Abnormal error from LDAP server",
        "Apache::Session module failed",
        "Authentication required",
        "Invalid certificate",
        "Initialization of Lasso:Login or Lasso:Logout failed",
        "Liberty-Alliance artefact resolution failed",
        "Liberty-Alliance defederation failed",
        "Liberty-Alliance query returned by IDP in assertion is empty",
        "One of Liberty-Alliance soap calls failed",
        "One of Liberty-Alliance single logout failed",
        "No SAML artefact found, or auto-accepting SSO failed",
        "Initializing, building or requesting SSO failed",
        "Unable to store Liberty-Alliance session id",
        "A Liberty-Alliance Soap End Point process failed",
        "Your account is locked",
        "Your password has expired",
    ];
}

