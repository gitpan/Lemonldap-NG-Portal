<TMPL_INCLUDE NAME="header.tpl">

	<div id="mailcontent">

	<div class="message <TMPL_VAR NAME="AUTH_ERROR_TYPE">"><ul><li><TMPL_VAR NAME="AUTH_ERROR"></li></ul></div>

	<div class="loginlogo"></div>

        <TMPL_IF NAME="DISPLAY_FORM">

        <form action="#" method="post" class="login">

        <h3><lang en="Forgot your password?" fr="Mot de passe oubli&eacute; ?"/></h3>

                <table>
                <tr><th><lang en="Mail" fr="Adresse mail"/></th>
                <td><input name="mail" type="text"/></td>
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

        <div class="link">
                <a href="<TMPL_VAR NAME="PORTAL_URL">">
                        <lang en="Go back to portal" fr="Retourner au portail" />
                </a>
        </div>

	</div>

<TMPL_INCLUDE NAME="footer.tpl">
