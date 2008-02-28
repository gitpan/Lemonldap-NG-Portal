<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<title>LemonLDAP::NG Portal</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <meta http-equiv="Content-Language" content="en" />
        <meta http-equiv="Content-Script-Type" content="text/javascript" />
        <link rel="stylesheet" type="text/css" href="tpl/themes/federid/sso.css" title="FederID" />
</head>
<body>
	<div id="page">
	<div id="top">&nbsp;</div>
	<div id="info-box"><h1>FederID WebSSO</h1><p>LemonLDAP::NG Portal</p></div>
	<div id="content">

        <TMPL_IF NAME="AUTH_ERROR">
	<div id="messages"><ul class="message"><li><TMPL_VAR NAME="AUTH_ERROR"></li></ul></div>
        </TMPL_IF>

        <TMPL_IF NAME="AUTH_SITES">
        <h2>Sites :</h2>
        <ul>
        <TMPL_LOOP NAME="AUTH_SITES">
        <li><a href="http://<TMPL_VAR NAME='SITE_NAME'>"><TMPL_VAR NAME="SITE_NAME"></a></li>
        </TMPL_LOOP>
        </ul>
        </TMPL_IF>

        <TMPL_IF NAME="LOGOUT_URL">
        <p><a href="<TMPL_VAR NAME='LOGOUT_URL'>">Logout</a></p>
        </TMPL_IF>

	</div>

	<div id="footer"><p>Provided by LemonLDAP::NG</p></div>

	</div>
</body>

</html>

