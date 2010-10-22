## @file
# Common functions for authentication choice

## @class
# Common functions for authentication choice

package Lemonldap::NG::Portal::_Choice;

use Lemonldap::NG::Portal::Simple;

our $VERSION = '0.991';

## @cmethod Lemonldap::NG::Portal::_Choice new(Lemonldap::NG::Portal::Simple portal)
# Constructor
# @param $portal Lemonldap::NG::Portal::Simple object
# @return new Lemonldap::NG::Portal::_Choice object
sub new {
    my ( $class, $portal ) = splice @_;

    # Create object with portal parameter
    my $self = bless { p => $portal }, $class;

    # Recover authChoice from session
    $portal->{_authChoice} ||= $portal->{sessionInfo}->{_authChoice};

    # Test authChoice
    unless ( $portal->{_authChoice}
        and exists $portal->{authChoiceModules}->{ $portal->{_authChoice} } )
    {
        $portal->lmLog( "No authentication choice done, or wrong choice",
            'debug' );
        $portal->{_authChoice} = "";
    }

    # Special workaround for SAML
    # because we cannot easily set SSO return URL
    # and SLO URL with authChoice parameter

    # Test authForce to see if URL is an SAML URL
    unless ( $portal->{_authChoice} ) {
        my $samlModule = 'Lemonldap::NG::Portal::AuthSAML';
        my $samlForce  = 0;
        eval {
            $portal->loadModule($samlModule);
            $authForce = $samlModule . '::authForce';
            $samlForce = $portal->$authForce;
        };

        if ($@) {
            $portal->lmLog( "SAML choice force not tested: $@", 'debug' );
        }

        # Force SAML choice if needed
        if ($samlForce) {
            $portal->lmLog( "SAML is a forced choice", 'debug' );
            $portal->{_authChoice} = 'forcedSAML';
            $portal->{authChoiceModules}->{'forcedSAML'} = 'SAML|SAML|Null';
        }

    }

    return $self unless $portal->{_authChoice};

    # Find modules associated to authChoice
    my ( $auth, $userDB, $passwordDB ) =
      split( /\|/, $portal->{authChoiceModules}->{ $portal->{_authChoice} } );

    if ( $auth and $userDB and $passwordDB ) {

        my $modulePrefix     = 'Lemonldap::NG::Portal::';
        my $authModule       = $modulePrefix . 'Auth' . $auth;
        my $userDBModule     = $modulePrefix . 'UserDB' . $userDB;
        my $passwordDBModule = $modulePrefix . 'PasswordDB' . $passwordDB;

        foreach my $module ( $authModule, $userDBModule, $passwordDBModule ) {
            $portal->abort( 'Bad configuration', "Unable to load $module" )
              unless $portal->loadModule($module);
        }

        $self->{modules} = [
            { m => $authModule,       n => $auth },
            { m => $userDBModule,     n => $userDB },
            { m => $passwordDBModule, n => $passwordDB }
        ];

        $portal->lmLog( "Authentication module $auth selected", 'debug' );
        $portal->lmLog( "User module $userDB selected",         'debug' );
        $portal->lmLog( "Password module $passwordDB selected", 'debug' );

    }

    else {
        $portal->abort( "Authentication choice "
              . $self->{_authChoice}
              . " value is invalid" );
    }

    return $self;
}

## @method int try(string sub,int type)
# Main method: try to call $sub method in the choosen module.
# If no choice, return default behavior
# @param sub name of the method to launch
# @param type 0 for authentication, 1 for userDB, 2 for passworDB
# @return Lemonldap::NG::Portal error code returned by method $sub
sub try {
    my ( $self, $sub, $type ) = splice @_;

    # Default behavior in no choice
    unless ( defined $self->{modules} ) {
        return PE_FORMEMPTY if ( $sub eq 'extractFormInfo' );
        return PE_OK;
    }

    # Launch wanted subroutine
    my $s    = $self->{modules}->[$type]->{m} . "::$sub";
    my $name = $self->{modules}->[$type]->{n};

    $self->{p}
      ->lmLog( "Try to launch $sub on module $name (type $type)", 'debug' );

    return $self->{p}->$s();
}

package Lemonldap::NG::Portal::Simple;

## @method private Lemonldap::NG::Portal::_Choice _choice()
# Return Lemonldap::NG::Portal::_Choice object and builds it if it was not build
# before. This method is used if authentication is set to "Choice".
# @return Lemonldap::NG::Portal::_Choice object
sub _choice {
    my $self = shift;
    return $self->{_choice} if ( $self->{_choice} );
    return $self->{_choice} = Lemonldap::NG::Portal::_Choice->new($self);
}

## @method private Lemonldap::NG::Portal::_Choice _buildAuthLoop()
# Build authentication loop displayed in template
# @return authLoop rarray reference
sub _buildAuthLoop {
    my $self = shift;
    my @authLoop;

    # Test authentication choices
    unless ( ref $self->{authChoiceModules} eq 'HASH' ) {
        $self->lmLog( "No authentication choices defined", 'warn' );
        return [];
    }

    foreach ( sort keys %{ $self->{authChoiceModules} } ) {

        my $name = $_;

        # Ignore 'forcedSAML'
        next if $name eq 'forcedSAML';

        # Name can have a digit as first character
        # for sorting purpose
        # Remove it in displayed name
        $name =~ s/^(\d*)?(\s*)?//;

        # Find modules associated to authChoice
        my ( $auth, $userDB, $passwordDB ) =
          split( /\|/, $self->{authChoiceModules}->{$_} );

        # What do display
        # -> login/password form (LDAP, DBI, ...)
        # -> OpenID form
        # -> logo with link (ex: CAS, SSL, etc.)
        my $displayType = {
            'standardform' => [qw(LDAP DBI Proxy)],
            'openidform'   => [qw(OpenID)],
            'logo'         => [qw(CAS Twitter SAML SSL Apache Remote)],
        };

        if ( $auth and $userDB and $passwordDB ) {

            # Options to store in the loop
            my $optionsLoop = { name => $name, key => $_, module => $auth };

            # Get displayType for this module

            foreach my $type ( keys %$displayType ) {
                foreach my $backend ( @{ $displayType->{$type} } ) {
                    if ( $auth eq $backend ) {
                        $self->lmLog( "Display type $type for module $auth",
                            'debug' );

                        $optionsLoop->{$type} = 1;
                        last;
                    }
                }
            }

            # Register item in loop
            push @authLoop, $optionsLoop;

            $self->lmLog( "Authentication choice $name will be displayed",
                'debug' );
        }

        else {
            $self->abort("Authentication choice $_ value is invalid");
        }

    }

    return \@authLoop;

}

1;

