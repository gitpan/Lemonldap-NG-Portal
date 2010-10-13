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
          <br/><br/>
          <p class="text-label">
            <lang en="Choose an application your are allowed to access to" fr="Choisissez une application &agrave; laquelle vous &ecirc;tes autoris&eacute;es &agrave; acc&eacute;der" /> :
          </p>
          <TMPL_VAR NAME="APPSLIST_MENU">
          <TMPL_VAR NAME="APPSLIST_DESC">
        </div>
        </TMPL_IF>

	<TMPL_IF NAME="ChangePassword">
        <TMPL_INCLUDE NAME="password.tpl">
        </TMPL_IF>

        <TMPL_IF NAME="Logout">
        <div id="logout">
          <br/><br/><br/>
          <p class="text-label">
            <lang en="Are you sure ?" fr="&Ecirc;tes vous s&ucirc;r ?" /> :
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

<TMPL_INCLUDE NAME="footer.tpl">

