
$(document).ready(function(){
	var select='<select id="appsselector">';
	$('#appslist').find('li.appname').each(function(index){
		var link=$(this).find('a').get(0);
		var title=$(link).html();
		var url=$(link).attr('href');
		select+='<option value="'+url+'">'+title+'</option>';
	});
	select+='</select>';
	select+='<input type="button" onclick="goToApplication();return false;" value="OK" />';
	$('#appslist').append(select);
	$('#logout').hide();
});

function goToApplication(){
	var select=$('#appsselector option:selected').get(0);
	var url=$(select).attr('value');
	location.href=url;
}

function showLogoutBox(url){
	$('#layout').fadeTo('fast',0.1);
	jConfirm(confirmlogoutmsg, confirmlogouttitle, function(r) {
		$('#layout').fadeTo('fast',1);
		if(r){location.href=url;};
	});
	return false;
}

