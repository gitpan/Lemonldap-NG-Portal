<TMPL_INCLUDE NAME="header.tpl">

	<div class="message <TMPL_VAR NAME="AUTH_ERROR_TYPE">"><ul><li><TMPL_VAR NAME="AUTH_ERROR"></li></ul></div>

	<div id="menu">

                <div class="user"><lang en="Connected as" fr="Connect&eacute; en tant que" /> <TMPL_VAR NAME="AUTH_USER"></div>

		<ul>
		<TMPL_IF NAME="DISPLAY_APPSLIST">
		<li><a href="#appslist"><span><img src="skins/common/application_cascade.png" width="16" height="16" alt="appslist" /> <lang en="Your applications" fr="Vos applications" /></span></a></li>
		</TMPL_IF>
		<TMPL_IF NAME="DISPLAY_PASSWORD">
		<li><a href="#password"><span><img src="skins/common/vcard_edit.png" width="16" height="16" alt="password" /> <lang en="Password" fr="Mot de passe" /></span></a></li>
		</TMPL_IF>
		<TMPL_IF NAME="DISPLAY_LOGOUT">
		<li><a href="#logout"><span><img src="skins/common/door_out.png" width="16" height="16" alt="logout" /> <lang en="Logout" fr="D&eacute;connexion" /></span></a></li>
		</TMPL_IF>
		</ul>

                <div class="menulogo"></div>

		<TMPL_IF NAME="DISPLAY_APPSLIST">
		<div id="appslist">
		<TMPL_VAR NAME="APPSLIST_MENU">
		<TMPL_VAR NAME="APPSLIST_DESC">
                </div>
		</TMPL_IF>

		<TMPL_INCLUDE NAME="password.tpl">
		
		<TMPL_IF NAME="DISPLAY_LOGOUT">
		<div id="logout">
		<h3><lang en="Are you sure ?" fr="&Ecirc;tes vous s&ucirc;r ?" /></h3>
		<div class="buttons">
			<a href="<TMPL_VAR NAME="LOGOUT_URL">" class="positive">
			<span><img src="skins/common/accept.png" alt="ok"/> <lang en="I'm sure" fr="Je suis s&ucirc;r" /></span>
			</a>
		</div>
		</div>
		</TMPL_IF>
	</div>

<TMPL_INCLUDE NAME="footer.tpl">
