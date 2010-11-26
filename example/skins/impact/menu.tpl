<TMPL_INCLUDE NAME="header.tpl">

  <div id="content">
    <div id="content-all">

      <div class="title">
        <img src="/skins/<TMPL_VAR NAME="SKIN">/images/logo-ok.png" />
        <TMPL_VAR NAME="AUTH_ERROR">
      </div>
      <hr class="solid" />
      <p>
        <span class="text-error"><lang en="Connected as" fr="Connect&eacute; en tant que " />: <u><TMPL_VAR NAME="AUTH_USER"></u></span>
      </p>

      <div id="menu">

      <TMPL_IF DISPLAY_MODULES>
        <ul>
        <TMPL_LOOP NAME="DISPLAY_MODULES">
          <TMPL_IF NAME="Appslist">
          <li><a href="#appslist"><span><img src="/skins/common/application_cascade.png" width="16" height="16" alt="appslist" /> <lang en="Your applications" fr="Vos applications" /></span></a></li>
          </TMPL_IF>
          <TMPL_IF NAME="ChangePassword">
          <li><a href="#password"><span><img src="/skins/common/vcard_edit.png" width="16" height="16" alt="password" /> <lang en="Password" fr="Mot de passe" /></span></a></li>
          </TMPL_IF>
          <TMPL_IF NAME="Logout">
          <li><a href="#logout"><span><img src="/skins/common/door_out.png" width="16" height="16" alt="logout" /> <lang en="Logout" fr="Se d&eacute;connecter" /></span></a></li>
          </TMPL_IF>
        </TMPL_LOOP>
        </ul>
      </TMPL_IF>

      </div>

      <div id="content-all-info2">

      <TMPL_IF DISPLAY_MODULES>

        <TMPL_LOOP NAME="DISPLAY_MODULES">

        <TMPL_IF NAME="Appslist">
        <div id="appslist">
          <p class="text-label">
            <lang en="Choose an application your are allowed to access to" fr="Choisissez une application &agrave; laquelle vous &ecirc;tes autoris&eacute;es &agrave; acc&eacute;der" /> :
          </p>
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
                <img    src="/skins/common/apps/<TMPL_VAR NAME="applogo">"
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
                <img    src="/skins/common/apps/<TMPL_VAR NAME="applogo">"
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
          <p class="text-label">
            <lang en="Are you sure?" fr="&Ecirc;tes vous s&ucirc;r ?" />
          </p>
          <button type="submit" class="positive" onclick="location.href='<TMPL_VAR NAME="LOGOUT_URL">';return false;">
            <lang en="I'm sure" fr="Je suis s&ucirc;r" />
          </button>
        </div>
        </TMPL_IF>

	</TMPL_LOOP>

      </TMPL_IF>

      </div>
    </div>
  </div>

<!-- Keep session alive -->
<script type="text/javascript">
	scriptname='<TMPL_VAR NAME="SCRIPT_NAME">';
	setTimeout('ping();',60000);
</script>
<TMPL_INCLUDE NAME="footer.tpl">

