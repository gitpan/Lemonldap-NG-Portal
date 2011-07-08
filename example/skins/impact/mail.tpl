<TMPL_INCLUDE NAME="header.tpl">

  <div id="content">
    <div id="content-all">
      <div class="title">
        <img src="/skins/<TMPL_VAR NAME="SKIN">/images/logo-ok.png" />
        <lang en="Forgot your password?" fr="Mot de passe oubli&eacute; ?"/>
      </div>
      <hr class="solid" />
      <p class="text-error"><TMPL_VAR NAME="AUTH_ERROR"></p>

      <TMPL_IF NAME="DISPLAY_FORM">
      <form action="#" method="post" class="login">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      <div id="content-all-info">
        <table>
          <tr>
            <th><lang en="Mail" fr="Adresse mail"/></th>
            <td><input name="mail" type="text" value="<TMPL_VAR NAME="MAIL">" /></td>
          </tr>
          <tr>
            <td colspan="2">
              <div class="buttons">
                <button type="submit" class="positive">
                  <lang en="Send me a new password" fr="Envoyez-moi un nouveau mot de passe" />
                </button>
              </div>
            </td>
          </tr>
        </table>
      </div>
      </form>
      </TMPL_IF>

      <TMPL_IF NAME="DISPLAY_RESEND_FORM">
      <form action="#" method="post" class="login">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      <input type="hidden" value="<TMPL_VAR NAME="MAIL">" name="mail">
      <div id="content-all-info">
        <table>
          <tr>
            <th><input id="resendconfirmation" type="checkbox" name="resendconfirmation"></th>
            <td><lang en="Yes, resend the mail" fr="Oui, renvoyer le mail"/></td>
          </tr>
          <tr>
            <td colspan="2">
              <div class="buttons">
                <button type="submit" class="positive">
                  <lang en="Submit" fr="Valider" />
                </button>
              </div>
            </td>
          </tr>
        </table>
      </div>
      </form>
      </TMPL_IF>

      <TMPL_IF NAME="DISPLAY_PASSWORD_FORM">
      <form action="#" method="post" class="password">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      <input type="hidden" id="mail_token" name="mail_token" value="<TMPL_VAR NAME="MAIL_TOKEN">" />
      <div id="content-all-info">
        <table>
        <tr><th><lang en="New password" fr="Nouveau mot de passe" /></th>
        <td><input name="newpassword" type="password" tabindex="3" /></td></tr>
        <tr><th><lang en="Confirm password" fr="Confirmez le mot de passe" /></th>
        <td><input name="confirmpassword" type="password" tabindex="4" /></td></tr>
        <tr><td colspan="2">
        <input id="reset" type="checkbox" name="reset" />
        <lang en="Generate the password automatically" fr="Générer le mot de passe automatiquement" />
        </td></tr>
        <tr><td colspan="2">
        <div class="buttons">
        <button type="reset" class="negative" tabindex="6">
                <lang en="Cancel" fr="Annuler" />
        </button>
        <button type="submit" class="positive" tabindex="5">
                <lang en="Submit" fr="Soumettre" />
        </button>
        </div>
        </td></tr></table>
      </div>
      </form>
      </TMPL_IF>

      <div class="panel-buttons">
        <button type="button" class="positive" tabindex="1" onclick="location.href='<TMPL_VAR NAME="PORTAL_URL">';return false;">
          <lang en="Go to portal" fr="Aller au portail" />
        </button>
      </div>
    </div>
  </div>

<TMPL_INCLUDE NAME="footer.tpl">
