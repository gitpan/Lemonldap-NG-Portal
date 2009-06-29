##@file
# LDAP password backend file

##@class
# LDAP password backend class
package Lemonldap::NG::Portal::PasswordDBLDAP;

use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_LDAP 'ldap';    #link protected ldap
use Lemonldap::NG::Portal::UserDBLDAP;      #inherits

our $VERSION = '0.2';

*_formateFilter = *Lemonldap::NG::Portal::UserDBLDAP::formateFilter;
*_search        = *Lemonldap::NG::Portal::UserDBLDAP::search;

## @apmethod int apasswordDBInit()
# Load Net::LDAP::Control::PasswordPolicy if needed
# @return Lemonldap::NG::Portal constant
sub passwordDBInit {
    my $self = shift;
    if ( $self->{ldapPpolicyControl} and not $self->ldap->loadPP()) {
        return PE_LDAPERROR;
    }
    PE_OK;
}

## @apmethod int modifyPassword()
# Modify the password by LDAP mechanism.
# @return Lemonldap::NG::Portal constant
sub modifyPassword {
    my $self = shift;

    # Exit method if no password change requested
    return PE_OK unless ( $self->{newpassword} );

    unless ( $self->ldap ) {
        return PE_LDAPCONNECTFAILED;
    }

    # Set the dn unless done before
    unless ( $self->{dn} ) {
        my $tmp = $self->_subProcess(qw(_formateFilter _search));
        return $tmp if ($tmp);
    }

    $self->lmLog("Modify password request for ".$self->{dn},'debug');

    # Call the modify password method
    return $self->ldap->userModifyPassword( $self->{dn}, $self->{newpassword}, $self->{confirmpassword}, $self->{oldpassword} );
    PE_OK;
}

## @apmethod int resetPasswordByMail()
# Reset the password and send a mail.
# @return Lemonldap::NG::Portal constant
sub resetPasswordByMail {
    my $self = shift;

    # Exit method if no mail
    return PE_OK unless ( $self->{mail} );

    unless ( $self->ldap ) {
        return PE_LDAPCONNECTFAILED;
    }

    # Set the dn unless done before
    unless ( $self->{dn} ) {
        my $tmp = $self->_subProcess(qw(_formateFilter _search));
        return $tmp if ($tmp);
    }

    $self->lmLog("Reset password request for ".$self->{dn},'debug');

    # Check the required modules before changing password
    eval {require String::Random};
    if ($@) {
        $self->lmLog("Module String::Random not found in @INC",'error' );
        return PE_ERROR;
    }
    eval {require MIME::Lite};
    if ($@) {
        $self->lmLog("Module MIME::Lite not found in @INC",'error' );
        return PE_ERROR;
    }

    # Generate a complex password
    my $random = new String::Random;
    my $password = $random->randregex( $self->{randomPasswordRegexp}  );

    $self->lmLog("Generated password: ".$password,'debug');

    # Call the modify password method
    my $pe_error = $self->ldap->userModifyPassword( $self->{dn}, $password, $password );

    return $pe_error unless ($pe_error == PE_PASSWORD_OK);

    # If Password Policy, set the PwdReset flag
    if ( $self->{ldapPpolicyControl} ) {
        my $result = $self->ldap->modify( $self->{dn}, replace => { 'pwdReset' => 'TRUE' } );

        unless ( $result->code == 0) {
            $self->lmLog("LDAP modify pwdReset error: ".$result->code,'error');
            return PE_LDAPERROR;
        }

        $self->lmLog("pwdReset set to TRUE",'debug');
    }

    # Send new password by mail
    $self->{mailBody} =~ s/\$password/$password/g;
    $self->{mailBody} =~ s/\$(\w+)/$self->{sessionInfo}->{$1}/g;
    $self->lmLog("SMTP From ".$self->{mailFrom},'debug');
    $self->lmLog("SMTP To ".$self->{mail},'debug');
    $self->lmLog("SMTP Subject ".$self->{mailSubject},'debug');
    $self->lmLog("SMTP Body ".$self->{mailBody},'debug');
    eval {
        my $message = MIME::Lite->new(
            From => $self->{mailFrom},
            To => $self->{mail},
            Subject => $self->{mailSubject},
            Type => "TEXT",
            Data => $self->{mailBody},
        );
        $self->{SMTPServer} ? $message->send("smtp",$self->{SMTPServer}) : $message->send();
    };
    if ($@) {
        $self->lmLog("Send message failed: $@",'error');
        return PE_ERROR;
    }  


    PE_PASSWORD_OK;
}
1;
