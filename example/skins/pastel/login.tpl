<TMPL_INCLUDE NAME="header.tpl">

	<div id="logincontent">

	<div class="message <TMPL_VAR NAME="AUTH_ERROR_TYPE">"><ul><li><TMPL_VAR NAME="AUTH_ERROR"></li></ul></div>

	<div class="loginlogo"></div>

	<TMPL_IF AUTH_LOOP>

	<!-- Authentication loop -->
		
	<!-- Choice tabs -->
	<div id="authMenu">
	<ul>
	<TMPL_LOOP NAME="AUTH_LOOP">
	<li title="<TMPL_VAR NAME="key">"><a href="#<TMPL_VAR NAME="key">"><TMPL_VAR NAME="name"></a></li>
	</TMPL_LOOP>
	</ul>
	</div>
	
	<!-- Forms -->
	<TMPL_LOOP NAME="AUTH_LOOP">

	<div id="<TMPL_VAR NAME="key">">

	<form action="#" method="post" class="login">

	<!-- Hidden fields -->
	<TMPL_VAR NAME="HIDDEN_INPUTS">
	<input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
	<input type="hidden" name="timezone" />
	<input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="key">" />

        <TMPL_IF NAME="standardform">

	<TMPL_INCLUDE NAME="standardform.tpl">

	</TMPL_IF>

        <TMPL_IF NAME="openidform">

	<TMPL_INCLUDE NAME="openidform.tpl">

	</TMPL_IF>

        <TMPL_IF NAME="logo">

		<h3><lang en="Authentication with" fr="Authentification avec"/> <TMPL_VAR NAME="module"></h3>		

		<table>
	        <TMPL_IF NAME="module">
		<tr class="authLogo"><td>
		<img src="/skins/common/<TMPL_VAR NAME="module">.png" />
		</td></tr>
		</TMPL_IF>

		<tr><td>
		<div class="buttons">
		<button type="reset" class="negative" tabindex="4">
			<img src="/skins/common/cancel.png" alt="" />
			<lang en="Cancel" fr="Annuler" />
		</button>
		<button type="submit" class="positive" tabindex="3">
			<img src="/skins/common/accept.png" alt="" />
			<lang en="Connect" fr="Se connecter" />
		</button>
		</div></td></tr>
                </table>

	</TMPL_IF>

        </form>

	</div>

	</TMPL_LOOP>

        </TMPL_IF>

	<TMPL_IF NAME="DISPLAY_FORM">

	<form action="#" method="post" class="login">
	<!-- Hidden fields -->
	<TMPL_VAR NAME="HIDDEN_INPUTS">
	<input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
	<input type="hidden" name="timezone" />
	<TMPL_INCLUDE NAME="standardform.tpl">
        </form>

        </TMPL_IF>

	<TMPL_IF NAME="DISPLAY_OPENID_FORM">

	<form action="#" method="post" class="login">
	<!-- Hidden fields -->
	<TMPL_VAR NAME="HIDDEN_INPUTS">
	<input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
	<input type="hidden" name="timezone" />
	<TMPL_INCLUDE NAME="openidform.tpl">
	</form>
		
        </TMPL_IF>

	<TMPL_IF NAME="DISPLAY_PASSWORD">

	<TMPL_INCLUDE NAME="password.tpl">

        </TMPL_IF>

	<TMPL_IF NAME="LOGIN_INFO">
	<div class="login_info">
	<TMPL_VAR NAME="LOGIN_INFO">
	</div>
	</TMPL_IF>

	<TMPL_IF NAME="PORTAL_URL">
	<div id="logout">
        <TMPL_IF NAME="MSG"><TMPL_VAR NAME="MSG"></TMPL_IF>
        <div class="buttons">
                <a href="<TMPL_VAR NAME="PORTAL_URL">" class="positive">
                        <img src="/skins/common/accept.png" alt="" />
                        <lang en="Go to portal" fr="Aller au portail" />
                </a>
	</div>
	</div>
	</TMPL_IF>

	<TMPL_IF NAME="LOGOUT_URL">
	<div id="logout">
		<div class="buttons">
		<a href="<TMPL_VAR NAME="LOGOUT_URL">" class="negative">
			<img src="/skins/common/cancel.png" alt="" />
			<lang en="Logout" fr="Se d&eacute;connecter"/>
		</a>
		</div>
	</div>
	</TMPL_IF>

	</div>

<TMPL_INCLUDE NAME="footer.tpl">
