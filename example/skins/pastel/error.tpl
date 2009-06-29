<TMPL_INCLUDE NAME="header.tpl">

	<div class="loginlogo"></div>

        <div id="error">
        <h3><lang en="You have no access authorization for this application" fr="Vous n'avez pas les droits d'acc&egrave;s &agrave; cette application" /></h3>

	<div class="buttons">
		<a href="<TMPL_VAR NAME="PORTAL_URL">" class="positive">
			<img src="skins/common/accept.png" alt="" />
			<lang en="Go to portal" fr="Aller au portail" />
		</a>
        <TMPL_IF NAME="LOGOUT_URL">
		<a href="<TMPL_VAR NAME="LOGOUT_URL">" class="negative">
			<img src="skins/common/cancel.png" alt="" />
			<lang en="Logout" fr="Se d&eacute;connecter" />
		</a>
        </TMPL_IF>
	</div>

        </div>

<TMPL_INCLUDE NAME="footer.tpl">
