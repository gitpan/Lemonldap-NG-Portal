        <p>
          <span class="text-label"><lang en="Login" fr="Identifiant de compte"/></span><br/>
          <input name="user" type="text" value="<TMPL_VAR NAME="LOGIN">" tabindex="1" /><br/>
          <span class="text-help">(<lang en="for example: jdoe" fr="par exemple: toto"/>)</span>
        </p>
        <p>
          <span class="text-label"><lang en="Password" fr="Mot de passe"/></span><br/>
          <input name="password" type="password" tabindex="2" /><br/>
        </p>
        <hr class="solid" />
        <div class="panel-buttons">
          <button type="reset" class="negative" tabindex="4">
            <lang en="Cancel" fr="Annuler" />
          </button>
          <button type="submit" class="positive" tabindex="3">
            <lang en="Connect" fr="Se connecter" />
          </button>
        </div>

      <TMPL_IF NAME="DISPLAY_RESETPASSWORD">
      <p>
        <img src="/skins/<TMPL_VAR NAME="SKIN">/images/arrow.png" /><a href="<TMPL_VAR NAME="MAIL_URL">"><lang en="Reset my password" fr="R&eacute;initialiser mon mot de passe"/></a>
      </p>
      </TMPL_IF>

