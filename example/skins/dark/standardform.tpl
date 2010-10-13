                <h3><lang en="Please enter your credentials" fr="Merci de vous authentifier"/></h3>

                <table>
                <tr><th><lang en="Login" fr="Identifiant"/></th>
                <td><input name="user" type="text" value="<TMPL_VAR NAME="LOGIN">" tabindex="1" /></td>
                </tr>
                <tr><th><lang en="Password" fr="Mot de passe"/></th>
                <td><input name="password" type="password" tabindex="2" /></td>
                </tr>
                <tr><td colspan="2">
                <div class="buttons">
                <button type="reset" class="negative" tabindex="4">
                        <img src="/skins/common/cancel.png" alt="" />
                        <lang en="Cancel" fr="Annuler" />
                </button>
                <button type="submit" class="positive" tabindex="3">
                        <img src="/skins/common/accept.png" alt="" />
                        <lang en="Connect" fr="Se connecter" />
                </button>
                </div></td></tr>
                <TMPL_IF NAME="DISPLAY_RESETPASSWORD">
                <tr><td colspan="2">
                <div class="buttons">
                <button class="positive" tabindex="5" onclick="$(location).attr('href','<TMPL_VAR NAME="MAIL_URL">');return false">
                        <img src="/skins/common/email.png" alt="" />
                        <lang en="Reset my password" fr="R&eacute;initialiser mon mot de passe"/>
                </button>
                </div></td></tr>
                </TMPL_IF>
                </table>
