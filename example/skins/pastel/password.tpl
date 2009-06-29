	<TMPL_IF NAME="DISPLAY_PASSWORD">
	<div id="password">
	<form action="#" method="post" class="password">
	<h3><lang en="Change your password" fr="Changez votre mot de passe" /></h3>
	<table>
        <TMPL_IF NAME="LOGIN">
        <tr><th><lang en="Login" fr="Identifiant"/></th>
        <td><input name="user" type="text" value="<TMPL_VAR NAME=LOGIN>"/></td></tr>
        </TMPL_IF>
	<TMPL_IF NAME="REQUIRE_OLDPASSWORD">
	<tr><th><lang en="Current password" fr="Mot de passe actuel" /></th>
	<td><input name="oldpassword" type="password" /></td></tr>
	</TMPL_IF>
	<tr><th><lang en="New password" fr="Nouveau mot de passe" /></th>
	<td><input name="newpassword" type="password" /></td></tr>
	<tr><th><lang en="Confirm password" fr="Confirmez le mot de passe" /></th>
	<td><input name="confirmpassword" type="password" /></td></tr>
	<tr><td colspan="2">
        <div class="buttons">
        <button type="reset" class="negative">
                <img src="skins/common/cancel.png" alt="" />
                <lang en="Cancel" fr="Annuler" />
        </button>
        <button type="submit" class="positive">
                <img src="skins/common/accept.png" alt="" />
                <lang en="Submit" fr="Soumettre" />
        </button>
	</div>
	</td></tr></table>
	</form>
	</div>
	</TMPL_IF>
