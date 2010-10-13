/**
 * Lemonldap::NG Portal jQuery scripts
 */

/* Used variables
 * - displaytab
 * - autocomplete
 * - login
 * - newwindow
 */

/* Set autocomplete real value */
if(autocomplete.match('1')){autocomplete='on';}
if(autocomplete.match('0')){autocomplete='off';}

/* jQuery */
$(document).ready(function(){
	$("div.message").fadeIn('slow');
	$("input[name=timezone]").val( -(new Date().getTimezoneOffset()/60) );
	$("#menu").tabs({ fx: { opacity: 'toggle' } });
	$("#menu").tabs("select",displaytab);

	/* Authentication choice */
	$("#authMenu").tabs({
		fx: {opacity: 'toggle'},
		cookie: {name: 'lemonldapauthchoice'},
		show:function(event,ui) {
		$('#authKey').val($('#authMenu li.ui-tabs-selected').attr('title'));
		return true;
		},
	});
	$("#authMenu").tabs("select",choicetab);

	$("input[type!=hidden]:first").focus();
	$("input[type='password']").attr("autocomplete",autocomplete);

	/*
	$("#appslist li[class!=catname]").hover(
		function(){
			var appid = $(this).attr("title");
			$("div.appsdesc").hide();
			$("div#" + appid).show();
		},
		function() {
			var appid = $(this).attr("title");
			// Show parent application if this was a sub application
			if ( $("#appslist li[title="+appid+"]").parent().parent().hasClass("appname") ) {
				var parentappid = $("#appslist li[title="+appid+"]").parent().parent().attr("title");
				$("div.appsdesc").hide();
				$("div#" + parentappid).show();
			}
		}
	);
	*/

	if(login){ $("input[type=password]:first").focus(); }
	if(newwindow){ $('#appslist a[href^="http://"]').attr("target", "_blank"); }

	// Complete removeOther link
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

function isHiddenFormValueSet(option){
	if($('#lmhidden_'+option).length){
		return true;
	}else{
		return false;
	}
}
