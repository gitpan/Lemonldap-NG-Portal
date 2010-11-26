<TMPL_INCLUDE NAME="header.tpl">

	<div id="menucontent">

	<div class="message <TMPL_VAR NAME="AUTH_ERROR_TYPE">"><ul><li><TMPL_VAR NAME="AUTH_ERROR"></li></ul></div>

	<div id="menu">

                <div class="user"><lang en="Connected as" fr="Connect&eacute; en tant que" /> <TMPL_VAR NAME="AUTH_USER"></div>

	<TMPL_IF DISPLAY_MODULES>
	<!-- Tabs list -->
		<ul>
		<TMPL_LOOP NAME="DISPLAY_MODULES">

                <TMPL_IF NAME="Appslist">
		<li><a href="#appslist"><span><img src="/skins/common/application_cascade.png" width="16" height="16" alt="appslist" /> <lang en="Your applications" fr="Vos applications" /></span></a></li>
		</TMPL_IF>
                <TMPL_IF NAME="ChangePassword">
		<li><a href="#password"><span><img src="/skins/common/vcard_edit.png" width="16" height="16" alt="password" /> <lang en="Password" fr="Mot de passe" /></span></a></li>
		</TMPL_IF>
                <TMPL_IF NAME="Logout">
		<li><a href="#logout"><span><img src="/skins/common/door_out.png" width="16" height="16" alt="logout" /> <lang en="Logout" fr="D&eacute;connexion" /></span></a></li>
		</TMPL_IF>

		</TMPL_LOOP>
		</ul>
	</TMPL_IF>

                <div class="menulogo"></div>
	<!-- Tabs content -->
	<TMPL_LOOP NAME="DISPLAY_MODULES">

	<TMPL_IF NAME="Appslist">
		<div id="appslist">

		<TMPL_LOOP NAME="APPSLIST_LOOP">
		<!-- Template loops -->

		<TMPL_IF NAME="category">
		<!-- Category -->

		<div class="category cat-level-<TMPL_VAR NAME="catlevel"> <TMPL_VAR NAME="catid">">
		<h3 class="catname"><TMPL_VAR NAME="catname"></h3>

		<TMPL_IF applications>
		<!-- Applications -->

		<TMPL_LOOP NAME=applications>

		<!-- Application -->

		<div class="application <TMPL_VAR NAME="appid">">

		<!-- Logo (optional) -->
		<TMPL_IF NAME="applogo">
		<img 	src="/skins/common/apps/<TMPL_VAR NAME="applogo">"
			class="applogo <TMPL_VAR NAME="appid">"
			alt="<TMPL_VAR NAME="appname">" />
		</TMPL_IF>

		<!-- Name and link (mandatory) -->
		<h4 class="appname <TMPL_VAR NAME="appid">">
		<a href="<TMPL_VAR NAME="appuri">" alt="<TMPL_VAR NAME="appname">">
		<TMPL_VAR NAME="appname">
		</a>
		</h4>

		<!-- Logo (optional) -->
		<TMPL_IF NAME="appdesc">
		<p class="appdesc <TMPL_VAR NAME="appid">">
		<TMPL_VAR NAME="appdesc">
		</p>
		</TMPL_IF>

		<div class="clearfix"></div>
                </div>

		<!-- End of applications loop -->
		</TMPL_LOOP>
		</TMPL_IF>

		<TMPL_IF categories>
		<!-- Sub categories -->

		<TMPL_LOOP NAME=categories>
		<div class="category cat-level-<TMPL_VAR NAME="catlevel">">
		<h3 class="catname"><TMPL_VAR NAME="catname"></h3>

		<TMPL_IF applications>
		<!-- Applications in sub category -->

		<TMPL_LOOP NAME=applications>

		<!-- Application in sub category-->

		<div class="application <TMPL_VAR NAME="appid">">

		<!-- Logo (optional) -->
		<TMPL_IF NAME="applogo">
		<img 	src="/skins/common/apps/<TMPL_VAR NAME="applogo">"
			class="applogo <TMPL_VAR NAME="appid">"
			alt="<TMPL_VAR NAME="appname">" />
		</TMPL_IF>

		<!-- Name and link (mandatory) -->
		<h4 class="appname <TMPL_VAR NAME="appid">">
		<a href="<TMPL_VAR NAME="appuri">" alt="<TMPL_VAR NAME="appname">">
		<TMPL_VAR NAME="appname">
		</a>
		</h4>

		<!-- Logo (optional) -->
		<TMPL_IF NAME="appdesc">
		<p class="appdesc <TMPL_VAR NAME="appid">">
		<TMPL_VAR NAME="appdesc">
		</p>
		</TMPL_IF>

		<div class="clearfix"></div>
		</div>

		<!-- End of applications loop -->
		</TMPL_LOOP>
		</TMPL_IF>

		<div class="clearfix"></div>
		</div>

		<!-- End of sub categories loop -->
		</TMPL_LOOP>
		</TMPL_IF>

		<div class="clearfix"></div>
		</div>

		<!-- End of categories loop -->
		</TMPL_IF>
		</TMPL_LOOP>

	</div>
		</TMPL_IF>

	<TMPL_IF NAME="ChangePassword">
		<TMPL_INCLUDE NAME="password.tpl">
	</TMPL_IF>
		
	<TMPL_IF NAME="Logout">
		<div id="logout">
		<h3><lang en="Are you sure ?" fr="&Ecirc;tes vous s&ucirc;r ?" /></h3>
		<div class="buttons">
			<a href="<TMPL_VAR NAME="LOGOUT_URL">" class="positive">
			<span><img src="/skins/common/accept.png" alt="ok"/> <lang en="I'm sure" fr="Je suis s&ucirc;r" /></span>
			</a>
		</div>
		</div>
		</TMPL_IF>

	</TMPL_LOOP>

	</div>

	</div>
<!-- Keep session alive -->
<script type="text/javascript">
	scriptname='<TMPL_VAR NAME="SCRIPT_NAME">';
	setTimeout('ping();',60000);
</script>
<TMPL_INCLUDE NAME="footer.tpl">
