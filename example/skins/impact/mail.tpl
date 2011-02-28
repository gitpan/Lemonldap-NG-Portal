<TMPL_INCLUDE NAME="header.tpl">

  <div id="content">
    <div id="content-all">
      <div class="title">
        <img src="/skins/<TMPL_VAR NAME="SKIN">/images/logo-ok.png" />
        <lang en="Forgot your password?" fr="Mot de passe oubli&eacute; ?"/>
      </div>
      <hr class="solid" />
      <TMPL_IF NAME="DISPLAY_FORM">
      <p class="text-error"><TMPL_VAR NAME="AUTH_ERROR"></p>
      <form action="#" method="post" class="login">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      <div id="content-all-info">
        <table>
          <tr>
            <th><lang en="Mail" fr="Adresse mail"/></th>
            <td><input name="mail" type="text"/></td>
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
      <div class="panel-buttons">
        <button type="button" class="positive" tabindex="1" onclick="location.href='<TMPL_VAR NAME="PORTAL_URL">';return false;">
          <lang en="Go to portal" fr="Aller au portail" />
        </button>
      </div>
    </div>
  </div>

<TMPL_INCLUDE NAME="footer.tpl">
