<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<title>LemonLDAP::NG Portal - Authentication</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <meta http-equiv="Content-Language" content="en" />
        <meta http-equiv="Content-Script-Type" content="text/javascript" />
        <link rel="stylesheet" type="text/css" href="tpl/themes/federid/sso.css" title="FederID"/>
</head>
<body>
	<div id="page">
	<div id="top"><h1>&nbsp;</h1></div>
	<div id="info-box"><h1>FederID WebSSO</h1><p>LemonLDAP::NG Portal - Authentication</p></div>
	<div id="content">

	<form method="post">

	<div class="error"><p><TMPL_VAR NAME="AUTH_ERROR"></p></div>

	<input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />

	<fieldset><legend>Authentication on this service (no Identity federation)</legend>
	<label class="required">Login</label>
		<TMPL_IF NAME="AUTH_USER">
		<input type="hidden" name="user" value="<TMPL_VAR NAME="AUTH_USER">" />
		<TMPL_VAR NAME="AUTH_USER"><br />
		<TMPL_ELSE>
		<input name="user" size="30" /><br />
		</TMPL_IF>

		<label class="required">Password</label>
		<input name="password" type="password" autocomplete="off" size="30" /></td>
	</fieldset>

	<fieldset><legend>Liberty Alliance authentication</legend>
		<select name="idpChoice">
			<option value="null">Selection d'un IDP</option>
			<TMPL_LOOP NAME="AUTH_IDPS">
			<option value="<TMPL_VAR NAME="IDPNAME">"><TMPL_VAR NAME="IDPNAME"></option>
			</TMPL_LOOP>
		</select>
	</fieldset>

	<fieldset><legend>Submit your choice</legend>
        	<input type="submit" name="submit" value="Submit" />
                <input type="reset" name="reset" value="Reset" />
        </fieldset>
</form>

</body>

</html>

