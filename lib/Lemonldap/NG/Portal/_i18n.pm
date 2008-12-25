package Lemonldap::NG::Portal::_i18n;

# Developpers warning : this file must stay UTF-8 encoded

use AutoLoader qw(AUTOLOAD);
our $VERSION = '0.3';

sub error {
    my ( $error, $lang ) = @_;
    $lang = lc($lang);
    $lang =~ s/-/_/g;
    $error = 0 if ( $error < 0 );
    foreach ( split( /[,;]/, $lang ) ) {
        next if /=/;
        if ( __PACKAGE__->can("error_$_") ) {
            return &{"error_$_"}->[$error];
        }
        s/^(..).*$/$1/;
        if ( __PACKAGE__->can("error_$_") ) {
            return &{"error_$_"}->[$error];
        }
    }
    return &error_en->[$error];
}

1;
__END__

# Order of the constants:
# * PE_OK                                 0
# * PE_SESSIONEXPIRED                     1
# * PE_FORMEMPTY                          2
# * PE_WRONGMANAGERACCOUNT                3
# * PE_USERNOTFOUND                       4
# * PE_BADCREDENTIALS                     5
# * PE_LDAPCONNECTFAILED                  6
# * PE_LDAPERROR                          7
# * PE_APACHESESSIONERROR                 8
# * PE_FIRSTACCESS                        9
# * PE_BADCERTIFICATE                    10
# * PE_LA_FAILED                         11
# * PE_LA_ARTFAILED                      12
# * PE_LA_DEFEDFAILED                    13
# * PE_LA_QUERYEMPTY                     14
# * PE_LA_SOAPFAILED                     15
# * PE_LA_SLOFAILED                      16
# * PE_LA_SSOFAILED                      17
# * PE_LA_SSOINITFAILED                  18
# * PE_LA_SESSIONERROR                   19
# * PE_LA_SEPFAILED                      20
# * PE_PP_ACCOUNT_LOCKED                 21
# * PE_PP_PASSWORD_EXPIRED               22
# * PE_CERTIFICATEREQUIRED               23
# * PE_ERROR                             24
# * PE_PP_CHANGE_AFTER_RESET             25
# * PE_PP_PASSWORD_MOD_NOT_ALLOWED       26
# * PE_PP_MUST_SUPPLY_OLD_PASSWORD       27
# * PE_PP_INSUFFICIENT_PASSWORD_QUALITY  28
# * PE_PP_PASSWORD_TOO_SHORT             29
# * PE_PP_PASSWORD_TOO_YOUNG             30
# * PE_PP_PASSWORD_IN_HISTORY            31
# * PE_PP_GRACE                          32
# * PE_PP_EXP_WARNING                    33
# * PE_PASSWORD_MISMATCH                 34
# * PE_PASSWORD_OK                       35
# * PE_NOTIFICATION                      36
# * PE_BADURL                            37

# Not used in errors:
# * PE_DONE                -1
# * PE_REDIRECT            -2

sub error_fr {
    use utf8;
    [
        "Utilisateur authentifié",
        "Votre session a expiré, vous devez vous réauthentifier",
        "Identifiant ou mot de passe non renseigné",
        "Compte ou mot de passe LDAP de l'application incorrect",
        "Utilisateur inexistant",
        "Mot de passe ou identifiant incorrect",
        "Connexion impossible au serveur LDAP",
        "Erreur anormale du serveur LDAP",
        "Erreur du module Apache::Session choisi",
        "Authentification exigée",
        "Certificat invalide",
        "Échec de l'initialisation de Lasso:Login ou Lasso:Logout",
        "Échec de la résolution de l'artefact Liberty Alliance",
        "Échec de la défédération Liberty Alliance",
        "La requête renvoyée par le fournisseur d'identité Liberty Alliance est vide",
        "Un des appels SOAP Liberty Alliance a échoué",
        "Un des appels de déconnexion Liberty Alliance a échoué",
        "Aucun artefact SAML trouvé, ou échec de l'auto-acceptation SSO",
        "Initialisation, construction ou requête SSO en échec",
        "Impossible d'enregistrer l'identifiant de connexion Liberty Alliance",
        "Un processus terminal Liberty Alliance a échoué",
        "Votre compte est bloqué",
        "Votre mot de passe a expiré",
        "Certificat exigé",
        "Erreur",
        "Le mot de passe a été réinitialisé et doit être changé",
        "Modification du mot de passe non autorisée",
        "Ancien mot de passe à fournir pour le changer",
        "Qualité de mot de passe insuffisante",
        "Mot de passe trop court",
        "Mot de passe trop récent",
        "Mot de passe utilisé trop récemment",
        " authentifications restantes, changez votre mot de passe !",
        " secondes avant expiration de votre mot de passe, pensez &agrave; le changer !",
        "Les mots de passe ne correspondent pas",
        "Le mot de passe a &eacute;t&eacute; chang&eacute;",
        "Vous avez un nouveau message",
        'Mauvaise URL',
    ];
}

sub error_en {
    [
        "User authenticated",
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
        "Certificate required",
        'Error',
        'Password has been reset and now must be changed',
        'Password may not be modified',
        'Old password must also be supplied when setting a new password',
        'Insufficient password quality',
        'Password too short',
        'Password too young',
        'Password used too recently',
        ' authentications remaining, change your password!',
        ' seconds before password expiration, change it!',
        'Passwords mismatch',
        'Password successfully changed',
        'You have a new message',
        'Bad URL',
    ];
}

sub error_ro {
    use utf8;
    [
        "Utilizator autentificat",
        "Sesiunea dvs. a expirat, trebuie să vă reautentificaţi",
        "Identificator sau parolă inexistentă",
        "Cont sau parolă LDAP a aplicaţiei incorect",
        "Utilizator inexistent",
        "Parolă sau identificator incorect",
        "Conexiune imposibilă la serverul LDAP",
        "Eroare anormală a serverului LDAP",
        "Eroare a modulului Apache::Session aleasă",
        "Autentificare cerută",
        "Certificat invalid",
        "Eşec al iniţializării Lasso:Login sau Lasso:Logout",
        "Eşec al rezoluţiei artefact-ului Liberty Alliance",
        "Eşec al defederaţiei Liberty Alliance",
        "Cererea retrimisă de către furnizorul de identitate Liberty Alliance este goală",
        "Unul dintre apelurile SOAP Liberty Alliance a eşuat",
        "Unul dintre apelurile de deconectare Liberty Alliance a eşuat",
        "Nici un artefact SAML găsit, sau eşec al auto-acceptării SSO",
        "Iniţiere, construcţie sau cerere SSO în eşec",
        "Imposibil de a înregistra identificatorul de conectare Liberty Alliance",
        "Un proces terminal Liberty Alliance a eşuat",
        "Contul dvs. este blocat",
        "Parola dvs. a expirat",
        "Certificat cerut",
        'Eroare',
        'Password has been reset and now must be changed',
        'Password may not be modified',
        'Old password must also be supplied when setting a new password',
        'Insufficient password quality',
        'Password too short',
        'Password too young',
        'Password used too recently',
        ' authentications remaining, change your password!',
        ' seconds before password expiration, change it!',
        'Passwords mismatch',
        'Password successfully changed',
        'You have a new message',
        'Bad URL',
    ];
}
