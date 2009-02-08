<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
        <title><lang en="Authentication portal" fr="Portail d'authentification"/></title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <meta http-equiv="Content-Script-Type" content="text/javascript" />
	<meta http-equiv="cache-control" content="no-cache" />
        <link rel="stylesheet" type="text/css" href="skins/pastel/styles.css" />
        <link href="skins/pastel/favicon.ico" rel="icon" type="image/x-icon" />
        <link href="skins/pastel/favicon.ico" rel="shortcut icon" />
        <script type="text/javascript" src="skins/pastel/jquery.js"></script>
        <script type="text/javascript" src="skins/pastel/jquery-tabs.js"></script>
        <script type="text/javascript">
        $(document).ready(function(){
          $("input[name=user]").focus();
          $("div.message").slideToggle('slow');
          $("input[type='password']").attr("autocomplete","off");
  	  $("#menu > ul").tabs();
  	  $("#menu > ul").tabs("select","#<TMPL_VAR NAME="DISPLAY_TAB">");
	  $("#appslist li").hover(
                function(){
                        var appid = $(this).attr("title");
                        $("div.appsdesc").hide();
                        $("div#" + appid).show();},
                function(){}
          );
        });
        </script>
</head>
<body>
        <div id="page">

        <div id="header"></div>

