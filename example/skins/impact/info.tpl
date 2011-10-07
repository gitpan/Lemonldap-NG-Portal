<TMPL_INCLUDE NAME="header.tpl">

  <div id="content">
    <div id="content-all">
      <div class="title">
        <img src="/skins/<TMPL_VAR NAME="SKIN">/images/logo-info.png" />
        <lang en="Information" fr="Information" />
      </div>
      <hr class="solid" />
      <p id="timer" class="text-error"><lang en="You'll be redirected in 10 seconds" fr="Vous allez &ecirc;tre redirig&eacute;(e) automatiquement dans 10 secondes"/></p>
      <form id="form" action="<TMPL_VAR NAME="URL">" method="<TMPL_VAR NAME="FORM_METHOD">" class="login">
      <TMPL_VAR NAME="HIDDEN_INPUTS">
      <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
      <div id="content-all-info">
        <TMPL_VAR NAME="MSG">
      </div>
        <div class="panel-buttons">
          <button type="reset" class="negative" tabindex="4" onclick="stop();">
            <lang en="Wait" fr="Attendre" />
          </button>
          <button type="submit" class="positive" tabindex="3">
            <lang en="Continue" fr="Continuer" />
          </button>
        </div>
      </form>
    </div>
  </div>

  <script>
  var i=10;
  var _go=1;
  function stop() {
    _go=0;
    $('#timer').html("...");
  }
  function go() {
    if(_go) {
        $("#form").submit();
      }
    }
  function timer() {
    var h=$('#timer').html();
    if(i>0){i--;}
    h=h.replace(/\d+/,i);
    $('#timer').html(h);
    window.setTimeout('timer()',1000);
  }
  $(document).ready(function(){
    // Check if timer should be activated (true by default)
    var activeTimer = true;
    if (!<TMPL_VAR NAME="ACTIVE_TIMER">) {activeTimer = false;}

    if (activeTimer) {
    window.setTimeout('go()',10000);
    window.setTimeout('timer()',1000);
    } else {
      stop();
    }
  });
  </script>

<TMPL_INCLUDE NAME="footer.tpl">

