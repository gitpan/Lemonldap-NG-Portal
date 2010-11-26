<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
        <title><lang en="Authentication portal" fr="Portail d'authentification"/></title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <meta http-equiv="Content-Script-Type" content="text/javascript" />
	<meta http-equiv="cache-control" content="no-cache" />
        <link rel="stylesheet" type="text/css" href="/skins/<TMPL_VAR NAME="SKIN">/css/styles.css" />
        <link href="/skins/common/favicon.ico" rel="icon" type="image/x-icon" />
        <link href="/skins/common/favicon.ico" rel="shortcut icon" />
        <TMPL_IF NAME="PROVIDERURI">
        <link rel="openid.server" href="<TMPL_VAR NAME="PROVIDERURI">" />
        <link rel="openid2.provider" href="<TMPL_VAR NAME="PROVIDERURI">" />
        </TMPL_IF>
        <script type="text/javascript" src="/skins/common/jquery-1.4.2.min.js"></script>
        <script type="text/javascript" src="/skins/common/jquery-ui-1.8.5.custom.min.js"></script>
        <script type="text/javascript" src="/skins/common/jquery.base64.js"></script>
        <script type="text/javascript" src="/skins/common/jquery.cookie.js"></script>
        <script type="text/javascript">//<![CDATA[
            var displaytab='<TMPL_VAR NAME="DISPLAY_TAB">';
            var choicetab='<TMPL_VAR NAME="CHOICE_VALUE">';
            var autocomplete='<TMPL_VAR NAME="AUTOCOMPLETE">';
            var login='<TMPL_VAR NAME="LOGIN">';
            var newwindow='<TMPL_VAR NAME="NEWWINDOW">';
            var antiframe='<TMPL_VAR NAME="ANTIFRAME">';
        //]]></script>
        <script type="text/javascript" src="/skins/common/portal.js"></script>
</head>
<body>

<div id="layout">

