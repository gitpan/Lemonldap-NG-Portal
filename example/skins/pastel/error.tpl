<TMPL_INCLUDE NAME="header.tpl">

	<div class="message negative">
	<ul><li>
	<lang en="You have no access authorization for this application" fr="Vous n'avez pas les droits d'acc&egrave;s &agrave; cette application" />
	</li></ul></div>

	<div class="loginlogo"></div>

	<div class="buttons">
		<a href="<TMPL_VAR NAME="PORTAL_URL">" class="positive">
			<img src="skins/pastel/accept.png" alt="" />
			<lang en="Go to portal" fr="Aller au portail" />
		</a>
		<a href="<TMPL_VAR NAME="LOGOUT_URL">" class="negative">
			<img src="skins/pastel/cancel.png" alt="" />
			<lang en="Logout" fr="Se d&eacute;connecter" />
		</a>
	</div>

<TMPL_INCLUDE NAME="footer.tpl">
