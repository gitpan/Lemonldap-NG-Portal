<TMPL_INCLUDE NAME="header.tpl">

	<div class="message <TMPL_VAR NAME="AUTH_ERROR_TYPE">"><ul><li>
      <lang en="You have some new messages" fr="Vous avez de nouveaux messages"/>
    </li></ul></div>

	<div class="loginlogo"></div>

	<form action="#" method="post" class="login">
		<TMPL_VAR NAME="HIDDEN_INPUTS">
		<input type="hidden" name="url" value="<TMPL_VAR NAME="AUTH_URL">" />
		<h3><lang en="New message(s)" fr="Nouveaux messages"/>&nbsp;:</h3>
		<table>
		<tr><td>
		<TMPL_VAR NAME="NOTIFICATION">
		<div class="buttons">
			<button type="submit" class="positive">
				<img src="/skins/common/accept.png" alt="" />
				<lang en="Accept" fr="Accepter" />
			</button>
		</div>
		</td></tr>
		</table>
	</form>

<TMPL_INCLUDE NAME="footer.tpl">
