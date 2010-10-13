<TMPL_INCLUDE NAME="header.tpl">

  <div id="content">
    <div id="content-all">
      <div class="title">
        <img src="/skins/<TMPL_VAR NAME="SKIN">/images/logo-info.png" />
        <lang en="Confirmation" fr="Confirmation" />
      </div>
      <hr class="solid" />
      <p id="timer" class="text-error"><lang en="Automaticaly accept in 5 seconds" fr="Acceptation automatique dans 5 secondes"/></p>
      <form id="form" action="#" method="<TMPL_VAR NAME="FORM_METHOD">" class="login">
        <TMPL_VAR NAME="HIDDEN_INPUTS">
        <input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
        <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
        <input type="hidden" id="confirm" name="confirm" value="<TMPL_VAR NAME="CONFIRMKEY">" />
        <div id="content-all-info">
          <TMPL_VAR NAME="MSG">
        </div>
        <div class="panel-buttons">
          <button type="submit" class="negative" tabindex="4" onclick="$('#confirm').attr('value','-<TMPL_VAR NAME="CONFIRMKEY">');">
            <lang en="Refuse" fr="Refuser" />
          </button>
          <button type="submit" class="positive" tabindex="3">
            <lang en="Accept" fr="Accepter" />
          </button>
        </div>
      </form>
    </div>
  </div>

  <script>
  var i=5;
  var _go=1;
  function stop() {
    _go=0;
    $('#timer').html("...");
  }
  function go() {
    if(_go)$("#form").submit();
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
    window.setTimeout('go()',5000);
    window.setTimeout('timer()',1000);
    } else {
      stop();
    }
  });
  </script>

<TMPL_INCLUDE NAME="footer.tpl">

