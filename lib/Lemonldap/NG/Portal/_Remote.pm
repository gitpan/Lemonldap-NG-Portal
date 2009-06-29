## @file
# Remote authentication and userDB base.

## @class
# Remote authentication and userDB base class.
package Lemonldap::NG::Portal::_Remote;

use strict;
use Lemonldap::NG::Portal::Simple;
use MIME::Base64;

our $VERSION = '0.1';

## @apmethod int init()
# Checks if remote portal parameters are set.
# @return Lemonldap::NG::Portal constant
sub init {
    my $self    = shift;
    my @missing = ();
    foreach (qw(remotePortal remoteGlobalStorage)) {
        push @missing, $_ unless ( defined( $self->{$_} ) );
    }
    $self->abort( "Missing parameters",
        "Required parameters: " . join( ', ', @missing ) )
      if (@missing);
    eval "require " . $self->{remoteGlobalStorage};
    $self->abort( "Configuration error",
        "Module " . $self->{remoteGlobalStorage} . " not found in \@INC" )
      if ($@);
    $self->{remoteCookieName} ||= $self->{cookieName};
    PE_OK;
}

## @apmethod int checkRemoteId()
# check if a CDA mechanism has been instanciated and if session is available.
# Redirect the user to the remote portal else by calling goToPortal().
# @return Lemonldap::NG::Portal constant
sub checkRemoteId {
    my $self = shift;
    my %h;

    if ( my $rId = $self->param( $self->{remoteCookieName} ) ) {
        $self->{mustRedirect} = 1;

        # Trying to recover session from global session storage
        # Note that since user has just been redirect to the remote portal, $@
        # can not be "Object does not exist in the data store"
        eval {
            tie %h, $self->{remoteGlobalStorage}, $rId,
              $self->{remoteGlobalStorageOptions};
        };
        if ( $@ or not tied(%h) ) {
            $self->lmLog( "Remote session error: $@", 'error' );
            return PE_ERROR;
        }
        %{ $self->{rSessionInfo} } = %h;
        untie %h;
        delete( $self->{rSessionInfo}->{'_password'} )
          unless ( $self->{storePassword} );
        return PE_OK;
    }
    return $self->_sub('goToPortal');
}

## @method protected void goToPortal()
# Redirect the user to the remote portal.
sub goToPortal {
    my $self = shift;
    print $self->redirect(
        $self->{remotePortal} . "?url="
          . encode_base64(
            $self->{portal}
              . ( $ENV{QUERY_STRING} ? "?$ENV{QUERY_STRING}" : '' ),
            ''
          )
    );
    exit;
}

1;

