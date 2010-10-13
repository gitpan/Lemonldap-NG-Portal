	<div id="password">
	<form action="#" method="post" class="password">
	<h3><lang en="Change your password" fr="Changez votre mot de passe" /></h3>
	<table>
        <TMPL_IF NAME="LOGIN">
        <tr><th><lang en="Login" fr="Identifiant"/></th>
        <td><input name="user" type="text" value="<TMPL_VAR NAME=LOGIN>" tabindex="1" /></td></tr>
        </TMPL_IF>
	<TMPL_IF NAME="REQUIRE_OLDPASSWORD">
	<tr><th><lang en="Current password" fr="Mot de passe actuel" /></th>
	<td><input name="oldpassword" type="password" tabindex="2" /></td></tr>
	</TMPL_IF>
	<tr><th><lang en="New password" fr="Nouveau mot de passe" /></th>
	<td><input name="newpassword" type="password" tabindex="3" /></td></tr>
	<tr><th><lang en="Confirm password" fr="Confirmez le mot de passe" /></th>
	<td><input name="confirmpassword" type="password" tabindex="4" /></td></tr>
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
