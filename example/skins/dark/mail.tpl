<TMPL_INCLUDE NAME="header.tpl">

	<div id="mailcontent">

	<div class="message <TMPL_VAR NAME="AUTH_ERROR_TYPE">"><ul><li><TMPL_VAR NAME="AUTH_ERROR"></li></ul></div>

	<div class="loginlogo"></div>

        <TMPL_IF NAME="DISPLAY_FORM">

        <form action="#" method="post" class="login">

        <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />

        <h3><lang en="Forgot your password?" fr="Mot de passe oubli&eacute; ?"/></h3>

                <table>
                <tr><th><lang en="Mail" fr="Adresse mail"/></th>
                <td><input name="mail" type="text" value="<TMPL_VAR NAME="MAIL">"/></td>
                </tr>
                <tr><td colspan="2">
                <div class="buttons">
                <button type="submit" class="positive">
                        <img src="/skins/common/accept.png" alt="" />
                        <lang en="Send me a new password" fr="Envoyez-moi un nouveau mot de passe" />
                </button>
                </div></td></tr>
                </table>

        </form>
        </TMPL_IF>

        <TMPL_IF NAME="DISPLAY_RESEND_FORM">

        <form action="#" method="post" class="login">

        <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
        <input type="hidden" value="<TMPL_VAR NAME="MAIL">" name="mail">

        <h3><lang en="Resend confirmation mail?" fr="Renvoyer le mail de confirmation ?"/></h3>

                <table>
                <tr><th><input id="resendconfirmation" type="checkbox" name="resendconfirmation"></th>
                <td><lang en="Yes, resend the mail" fr="Oui, renvoyer le mail"/></td>
                </tr>
                <tr><td colspan="2">
                <div class="buttons">
                <button type="submit" class="positive">
                        <img src="/skins/common/accept.png" alt="" />
                        <lang en="Submit" fr="Valider" />
                </button>
                </div></td></tr>
                </table>

        </form>
        </TMPL_IF>

	<TMPL_IF NAME="DISPLAY_PASSWORD_FORM">
        <div id="password">
        <form action="#" method="post" class="password">
        <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
        <input type="hidden" id="mail_token" name="mail_token" value="<TMPL_VAR NAME="MAIL_TOKEN">" />
        <h3><lang en="Change your password" fr="Changez votre mot de passe" /></h3>
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
                <img src="/skins/common/cancel.png" alt="" />
                <lang en="Cancel" fr="Annuler" />
        </button>
        <button type="submit" class="positive" tabindex="5">
                <img src="/skins/common/accept.png" alt="" />
                <lang en="Submit" fr="Soumettre" />
        </button>
        </div>
        </td></tr></table>
        </form>
        </div>
	</TMPL_IF>

        <div class="link">
                <a href="<TMPL_VAR NAME="PORTAL_URL">">
                        <lang en="Go back to portal" fr="Retourner au portail" />
                </a>
        </div>

	</div>

<TMPL_INCLUDE NAME="footer.tpl">
