<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
 <title><lang en="Authentication portal" fr="Portail d'authentification"/></title>
 <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
 <meta http-equiv="Content-Script-Type" content="text/javascript" />
 <meta http-equiv="cache-control" content="no-cache" />
 <TMPL_IF NAME="browserIdEnabled">
  <meta http-equiv="X-UA-Compatible" content="IE=Edge">
 </TMPL_IF>
 <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="SKIN_PATH">/<TMPL_VAR NAME="SKIN">/css/styles.css" />
 <link href="<TMPL_VAR NAME="SKIN_PATH">/common/favicon.ico" rel="icon" type="image/x-icon" />
 <link href="<TMPL_VAR NAME="SKIN_PATH">/common/favicon.ico" rel="shortcut icon" />
 <TMPL_IF NAME="PROVIDERURI">
  <link rel="openid.server" href="<TMPL_VAR NAME="PROVIDERURI">" />
  <link rel="openid2.provider" href="<TMPL_VAR NAME="PROVIDERURI">" />
 </TMPL_IF>
 <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/jquery-1.10.2.js"></script>
 <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/jquery-ui-1.10.3.custom.js"></script>
 <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/jquery.base64.js"></script>
 <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/jquery.cookie.js"></script>
 <TMPL_IF NAME="browserIdEnabled">
  <script src="https://login.persona.org/include.js"></script>
 </TMPL_IF>
 <TMPL_IF NAME="browserIdLoadLoginScript">
  <script type="text/javascript">//<![CDATA[
     var browserIdSiteName="<TMPL_VAR NAME="browserIdSiteName">";
     var browserIdSiteLogo="<TMPL_VAR NAME="browserIdSiteLogo">";
     var browserIdBackgroundColor="<TMPL_VAR NAME="browserIdBackgroundColor">";
     var browserIdAutoLogin="<TMPL_VAR NAME="browserIdAutoLogin">";
  //]]></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/browserid.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/browseridlogin.js"></script>
 </TMPL_IF>
 <TMPL_IF NAME="browserIdLoadLogoutScript">
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/browserid.js"></script>
  <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/browseridlogout.js"></script>
 </TMPL_IF>
 <script type="text/javascript">//<![CDATA[
    var displaytab="<TMPL_VAR NAME="DISPLAY_TAB">";
    var choicetab="<TMPL_VAR NAME="CHOICE_VALUE">";
    var autocomplete="<TMPL_VAR NAME="AUTOCOMPLETE">";
    var login="<TMPL_VAR NAME="LOGIN">";
    var newwindow="<TMPL_VAR NAME="NEWWINDOW">";
    var antiframe="<TMPL_VAR NAME="ANTIFRAME">";
    var appslistorder="<TMPL_VAR NAME="APPSLIST_ORDER">";
 //]]></script>
 <script type="text/javascript" src="<TMPL_VAR NAME="SKIN_PATH">/common/portal.js"></script>
 <TMPL_INCLUDE NAME="customhead.tpl">
</head>
<body>
  <div id="page">

    <div id="header"><TMPL_INCLUDE NAME="customheader.tpl"></div>

