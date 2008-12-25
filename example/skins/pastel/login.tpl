<TMPL_INCLUDE NAME="header.tpl">

	<div class="message <TMPL_VAR NAME="AUTH_ERROR_TYPE">"><ul><li><TMPL_VAR NAME="AUTH_ERROR"></li></ul></div>

	<div class="loginlogo"></div>

	<TMPL_IF NAME="DISPLAY_FORM">
	<form action="#" method="post" class="login">

		<h3><lang en="Please enter your credentials" fr="Merci de vous authentifier"/></h3>
		
	        <p><input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" /></p>

		<table>
		<tr><th><lang en="Login" fr="Identifiant"/></th>
		<td><input name="user" type="text" /></td>
		</tr>
		<tr><th><lang en="Password" fr="Mot de passe"/></th>
		<td><input name="password" type="password" /></td>
		</tr>
		<tr><td colspan="2">
		<div class="buttons">
		<button type="reset" class="negative">
			<img src="skins/pastel/cancel.png" alt="" />
			<lang en="Cancel" fr="Annuler" />
		</button>
		<button type="submit" class="positive">
			<img src="skins/pastel/accept.png" alt="" />
			<lang en="Connect" fr="Se connecter" />
		</button>
		</div></td></tr>
		</table>

	</form>
	</TMPL_IF>

	<TMPL_IF NAME="LOGOUT_URL">
		<div class="buttons">
		<a href="<TMPL_VAR NAME="LOGOUT_URL">" class="negative">
			<img src="skins/pastel/cancel.png" alt="" />
			<lang en="Logout" fr="Se d&eacute;connecter"/>
		</a>
		</div>
	</TMPL_IF>

<TMPL_INCLUDE NAME="footer.tpl">
