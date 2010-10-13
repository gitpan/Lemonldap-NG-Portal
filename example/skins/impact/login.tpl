<TMPL_INCLUDE NAME="header.tpl">

  <div id="content">

    <TMPL_IF AUTH_LOOP>

    <!-- Authentication loop -->
    <div id="content-left">

      <TMPL_INCLUDE NAME="authmessage.tpl">

      <TMPL_IF NAME="LOGIN_INFO">
      <div>
        <TMPL_VAR NAME="LOGIN_INFO">
      </div>
      </TMPL_IF>

    </div>

    <div id="content-right">

      <h1><lang en="Open your SSO session" fr="Ouvrir une session SSO" /></h1>
      <hr class="solid" />
      <p><span class="text-error"><TMPL_VAR NAME="AUTH_ERROR"></span></p>

      <form action="#" method="post" class="login">

      <!-- Hidden fields -->
        <TMPL_VAR NAME="HIDDEN_INPUTS">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
        <input type="hidden" name="timezone" />
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="" />

      <!-- tabs -->
      <div id="authMenu">
      <ul>
        <TMPL_LOOP NAME="AUTH_LOOP">
        <li title="<TMPL_VAR NAME="key">"><a href="#<TMPL_VAR NAME="key">"><TMPL_VAR NAME="name"></a></li>
        </TMPL_LOOP>
      </ul>
      </div>

      <!-- Forms -->
      <TMPL_LOOP NAME="AUTH_LOOP">

      <div id="<TMPL_VAR NAME="key">">

      <TMPL_IF NAME="standardform">

      <TMPL_INCLUDE NAME="standardform.tpl">

      </TMPL_IF>

      <TMPL_IF NAME="openidform">

      <TMPL_INCLUDE NAME="openidform.tpl">

      </TMPL_IF>

      <TMPL_IF NAME="logo">

        <TMPL_IF NAME="module">
        <div class="authLogo">
        <img src="/skins/common/<TMPL_VAR NAME="module">.png" />
        </div>
        </TMPL_IF>

        <hr class="solid" />
        <div class="panel-buttons">
          <button type="reset" class="negative" tabindex="4">
            <lang en="Cancel" fr="Annuler" />
          </button>
          <button type="submit" class="positive" tabindex="3">
            <lang en="Connect" fr="Se connecter" />
          </button>
        </div>

      </TMPL_IF>

      </div>

      </TMPL_LOOP>

      </form>

    </div>

      </TMPL_IF>

    <TMPL_IF NAME="DISPLAY_FORM">

    <div id="content-left">

      <TMPL_INCLUDE NAME="authmessage.tpl">

      <TMPL_IF NAME="LOGIN_INFO">
      <div>
        <TMPL_VAR NAME="LOGIN_INFO">
      </div>
      </TMPL_IF>

    </div>

    <div id="content-right">
      <h1><lang en="Open your SSO session" fr="Ouvrir une session SSO" /></h1>
      <hr class="solid" />
      <p><span class="text-error"><TMPL_VAR NAME="AUTH_ERROR"></span></p>
      <form action="#" method="post" class="login">
        <TMPL_VAR NAME="HIDDEN_INPUTS">
        <input type="hidden" name="url" value="" />
        <input type="hidden" name="timezone" />
        <TMPL_INCLUDE NAME="standardform.tpl">
      </form>
    </div>

    </TMPL_IF>

    <TMPL_IF NAME="DISPLAY_OPENID_FORM">

    <div id="content-left">

      <TMPL_INCLUDE NAME="authmessage.tpl">

      <TMPL_IF NAME="LOGIN_INFO">
      <div>
        <TMPL_VAR NAME="LOGIN_INFO">
      </div>
      </TMPL_IF>

    </div>

    <div id="content-right">
      <h1><lang en="Open your SSO session" fr="Ouvrir une session SSO" /></h1>
      <hr class="solid" />
      <p><span class="text-error"><TMPL_VAR NAME="AUTH_ERROR"></span></p>
      <form action="#" method="post" class="login">
        <TMPL_VAR NAME="HIDDEN_INPUTS">
        <input type="hidden" name="url" value="" />
        <input type="hidden" name="timezone" />
        <TMPL_INCLUDE NAME="openidform.tpl">
      </form>
    </div>

    </TMPL_IF>

    <TMPL_IF NAME="DISPLAY_PASSWORD">

      <div id="content-all">
      <div class="title">
        <img src="/skins/<TMPL_VAR NAME="SKIN">/images/logo-info.png" />
        <lang en="Password change" fr="Changement de mot de passe" />
      </div>
      <hr class="solid" />
      <p class="text-error"><TMPL_VAR NAME="AUTH_ERROR"></p>
      <TMPL_INCLUDE NAME="password.tpl">
      </div>

    </TMPL_IF>

    <TMPL_IF NAME="PORTAL_URL">
    <div id="content-all">
      <div class="title">
        <img src="/skins/<TMPL_VAR NAME="SKIN">/images/logo-info.png" />
        <lang en="SSO session inactive" fr="Session SSO inactive" />
      </div>
      <hr class="solid" />
      <p class="text-error"><TMPL_VAR NAME="AUTH_ERROR"></p>
      <TMPL_IF NAME="MSG">
      <div id="content-all-info">
        <TMPL_VAR NAME="MSG">
      </div>
      </TMPL_IF>
      <p>
        <img src="/skins/<TMPL_VAR NAME="SKIN">/images/arrow.png" /><a href="<TMPL_VAR NAME="PORTAL_URL">" class="positive"><lang en="Go to portal" fr="Aller au portail" /></a>
      </p>
    </div>
    </TMPL_IF>

    <TMPL_IF NAME="LOGOUT_URL">
    <div id="content-all">
      <div class="title">
        <img src="/skins/<TMPL_VAR NAME="SKIN">/images/logo-info.png" />
        <lang en="Close your SSO session" fr="Fermer votre Session SSO" />
      </div>
      <hr class="solid" />
      <p class="text-error"><TMPL_VAR NAME="AUTH_ERROR"></p>
      <p>
        <img src="/skins/<TMPL_VAR NAME="SKIN">/images/arrow.png" /><a href="<TMPL_VAR NAME="LOGOUT_URL">" class="negative"><lang en="Logout" fr="Se d&eacute;connecter"/></a>
      </p>
    </div>
    </TMPL_IF>

  </div>

<TMPL_INCLUDE NAME="footer.tpl">

