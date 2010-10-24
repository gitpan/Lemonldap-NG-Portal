/**
 * LemonLDAP::NG Portal jQuery scripts
 */

/* Used variables
 * - displaytab
 * - choicetab
 * - autocomplete
 * - login
 * - newwindow
 * - antiframe
 */

/* Set autocomplete real value */
if(autocomplete.match('1')){autocomplete='on';}
if(autocomplete.match('0')){autocomplete='off';}

/* Set antiframe value (default is true) */
if(antiframe.match('0')){antiframe=false;}else{antiframe=true};

/* jQuery */
$(document).ready(function(){

	/* AntiFrame script */
	if(antiframe && top!=self){
		top.location.href = location.href;
	}

	/* Display message */
	$("div.message").fadeIn('slow');

	/* Set timezone */
	$("input[name=timezone]").val( -(new Date().getTimezoneOffset()/60) );

	/* Menu tabs */
	$("#menu").tabs({ fx: { opacity: 'toggle' } });
	$("#menu").tabs("select",displaytab);

	/* Authentication choice tabs */
	$("#authMenu").tabs({
		fx: {opacity: 'toggle'},
		cookie: {name: 'lemonldapauthchoice'},
		show:function(event,ui) {
		$('#authKey').val($('#authMenu li.ui-tabs-selected').attr('title'));
		return true;
		},
	});
	$("#authMenu").tabs("select",choicetab);

	/* Focus on first visible input */
	$("input[type!=hidden]:first").focus();
	if(login){ $("input[type=password]:first").focus(); }

	/* Password autocompletion */
	$("input[type='password']").attr("autocomplete",autocomplete);

	/* Open links in new windows */
	if(newwindow){ $('#appslist a[href^="http://"]').attr("target", "_blank"); }

	/* Complete removeOther link */
	if ($("p.removeOther").length) {
		var action = $("form.login").attr("action");
		var method = $("form.login").attr("method");

		var back_url = "";
		if (action.indexOf("?") != -1) {
			back_url = action.substring(0,action.indexOf("?")) + "?";
		} else {
			back_url = action + "?";
		}

		$("form.login input[type=hidden]").each(function(index){
			back_url = back_url + "&" + $(this).attr("name") + "=" + $(this).val();
		});

		var link = $("p.removeOther a").attr("href");

		link = link + "&method=" + method + "&url=" + $.base64Encode(back_url);

		$("p.removeOther a").attr("href",link);

	}
});

/* function boolean isHiddenFormValueSet(string option)
 * Check if an hidden option is set
 * @param option Option name
 * @return true if option is set, false else
 */
function isHiddenFormValueSet(option){
	if($('#lmhidden_'+option).length){
		return true;
	}else{
		return false;
	}
}

