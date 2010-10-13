<TMPL_INCLUDE NAME="header.tpl">

  <div id="content">
    <div id="content-all">
      <div class="title">
        <img src="/skins/<TMPL_VAR NAME="SKIN">/images/logo-ok.png" />
        <lang en="You have some new messages" fr="Vous avez de nouveaux messages"/>
      </div>
      <hr class="solid" />
      <p class="text-error"><lang en="New message(s)" fr="Nouveaux messages"/></p>
      <form action="#" method="post" class="login">
      <TMPL_VAR NAME="HIDDEN_INPUTS">
      <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
      <div id="content-all-info">
        <TMPL_VAR NAME="NOTIFICATION">
      </div>
      <div class="buttons">
        <button type="submit" class="positive">
          <lang en="Accept" fr="Accepter" />
        </button>
      </div>
      </form>
    </div>
  </div>

<TMPL_INCLUDE NAME="footer.tpl">
