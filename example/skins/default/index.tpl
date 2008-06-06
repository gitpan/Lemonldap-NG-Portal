<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<title><TMPL_VAR NAME="AUTH_TITLE"></title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <meta http-equiv="Content-Language" content="en" />
        <meta http-equiv="Content-Script-Type" content="text/javascript" />
        <link rel="stylesheet" type="text/css" href="<TMPL_VAR NAME="CSS_FILE">" />
</head>
<body>
	<div id="page">
	<div id="top"><h1><TMPL_VAR NAME="AUTH_TITLE"></h1></div>
	<div id="content">

	<div id="messages"><ul><li><TMPL_VAR NAME="AUTH_ERROR"></li></ul></div>

	<TMPL_IF NAME="AUTH_SITES">
	<!-- Display sites -->
        <h2>Protected sites</h2>
        <ul>
        <TMPL_LOOP NAME="AUTH_SITES">
        <li><a href="http://<TMPL_VAR NAME='SITE_NAME'>"><TMPL_VAR NAME="SITE_NAME"></a></li>
        </TMPL_LOOP>
        </ul>

	<TMPL_ELSE>
	<!-- Display login form -->
	<form method="post">
	<input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
	<fieldset><legend>Authentication</legend>
		<label class="required">Login</label>
		<input name="user" type="text" size="30" /><br />
		<label class="required">Password</label>
		<input name="password" type="password" autocomplete="off" size="30" /><br />
                <input type="submit" name="submit" value="Submit" />
	</fieldset>
	</form>
	</TMPL_IF>

        <TMPL_IF NAME="LOGOUT_URL">
        <p><a href="<TMPL_VAR NAME='LOGOUT_URL'>">Logout</a></p>
        </TMPL_IF>

	</div>

	<div id="footer"><p>Provided by LemonLDAP::NG</p></div>

	</div>

</body>

</html>

