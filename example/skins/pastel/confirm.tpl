<TMPL_INCLUDE NAME="header.tpl">

	<div id="logincontent">

	<div class="message warning"><ul><li><lang en="Confirmation" fr="Confirmation"/></li></ul></div>

	<div class="loginlogo"></div>

	<form id="form" action="#" method="<TMPL_VAR NAME="FORM_METHOD">" class="login">
		<TMPL_VAR NAME="HIDDEN_INPUTS">
		<input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
	        <input type="hidden" id="authKey" name="<TMPL_VAR NAME="CHOICE_PARAM">" value="<TMPL_VAR NAME="CHOICE_VALUE">" />
		<input type="hidden" id="confirm" name="confirm" value="<TMPL_VAR NAME="CONFIRMKEY">" />
		<TMPL_VAR NAME="MSG">
		<p id="timer"><lang en="Automaticaly accept in 5 seconds" fr="Acceptation automatique dans 5 secondes"/></p>
		<table><tbody><tr><td>
		<div class="buttons">
			<button type="submit" class="positive">
				<img src="/skins/common/accept.png" alt="" />
				<lang en="Accept" fr="Accepter" />
			</button>
			<button type="submit" class="negative" onclick="$('#confirm').attr('value','-<TMPL_VAR NAME="CONFIRMKEY">');">
				<img src="/skins/common/cancel.png" alt="" />
				<lang en="Refuse" fr="Refuser" />
			</button>
		</div>
		</td></tr></tbody></table>
	</form>
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

	</div>

<TMPL_INCLUDE NAME="footer.tpl">
