<TMPL_INCLUDE NAME="header.tpl">

	<div class="message <TMPL_VAR NAME="AUTH_ERROR_TYPE">"><ul><li><TMPL_VAR NAME="AUTH_ERROR"></li></ul></div>

	<div class="loginlogo"></div>

	<TMPL_IF NAME="DISPLAY_FORM">
	<form action="#" method="post" class="login">

		<h3><lang en="Please enter your credentials" fr="Merci de vous authentifier"/></h3>
		
	        <p><input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" /></p>
	        <p><input type="hidden" name="timezone" /></p>

		<table>
		<tr><th><lang en="Login" fr="Identifiant"/></th>
		<td><input name="user" type="text" value="<TMPL_VAR NAME="LOGIN">"/></td>
		</tr>
		<tr><th><lang en="Password" fr="Mot de passe"/></th>
		<td><input name="password" type="password" /></td>
		</tr>
		<tr><td colspan="2">
		<div class="buttons">
		<button type="reset" class="negative">
			<img src="skins/common/cancel.png" alt="" />
			<lang en="Cancel" fr="Annuler" />
		</button>
		<button type="submit" class="positive">
			<img src="skins/common/accept.png" alt="" />
			<lang en="Connect" fr="Se connecter" />
		</button>
		</div></td></tr>
		</table>

	</form>
	</TMPL_IF>

        <TMPL_IF NAME="DISPLAY_RESETPASSWORD">

        <form action="#" method="post" class="login">

        <h3><lang en="Forgot your password?" fr="Mot de passe oubli&eacute; ?"/></h3>

                <table>
                <tr><th><lang en="Mail" fr="Adresse mail"/></th>
                <td><input name="mail" type="text"/></td>
                </tr>
                <tr><td colspan="2">
                <div class="buttons">
                <button type="submit" class="positive">
                        <img src="skins/common/accept.png" alt="" />
                        <lang en="Send me a new password" fr="Envoyez-moi un nouveau mot de passe" />
                </button>
                </div></td></tr>
                </table>

        </form>
        </TMPL_IF>

	<TMPL_INCLUDE NAME="password.tpl">

	<TMPL_IF NAME="LOGOUT_URL">
		<div class="buttons">
		<a href="<TMPL_VAR NAME="LOGOUT_URL">" class="negative">
			<img src="skins/common/cancel.png" alt="" />
			<lang en="Logout" fr="Se d&eacute;connecter"/>
		</a>
		</div>
	</TMPL_IF>

<TMPL_INCLUDE NAME="footer.tpl">
