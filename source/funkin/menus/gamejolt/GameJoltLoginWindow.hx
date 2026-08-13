package funkin.menus.gamejolt;

import funkin.editors.ui.UISubstateWindow;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UITextBox;
import funkin.editors.ui.UIText;
import funkin.menus.gamejolt.GameJoltTokenInfoWindow;

class GameJoltLoginWindow extends UISubstateWindow {
	public var usernameBox:UITextBox;
	public var userTokenLabel:UIText;
	public var userTokenInfo:UIButton;
	public var userTokenBox:UITextBox;

	public var closeButton:UIButton;
	public var loginButton:UIButton;

	public var daX:Float;

	public override function create() {
		//TODO: get translations for text
		winTitle = "Login with GameJolt...";

		winWidth = 350;
		winHeight = 350;

		super.create();

		daX = windowSpr.x + 20;

		add(usernameBox = new UITextBox(daX, windowSpr.y + 60, ""));
		usernameBox.members.push(new UIText(daX, usernameBox.y - 24, 0, "Username"));

		add(userTokenBox = new UITextBox(daX, usernameBox.y + usernameBox.height + 60, ""));
		userTokenBox.members.push(userTokenLabel = new UIText(daX, userTokenBox.y - 24, 0, "User Token"));
		userTokenBox.members.push(userTokenInfo = new UIButton(daX + userTokenLabel.width, userTokenLabel.y, "?", () -> { FlxG.state.openSubState(new GameJoltTokenInfoWindow()); }, 24, 24));
		userTokenInfo.color = 0xFF3737FF;
		userTokenBox.label.textField.displayAsPassword = true;

		add(loginButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, "Login", function() {
			if (GJUtil.attemptLogin(usernameBox.label.text, userTokenBox.label.text, true)) {
				FlxG.state.openSubState(new GameJoltLoginSuccess());
				close();
			} else {

			}
		}, 125));

		add(closeButton = new UIButton(loginButton.x - 20 - loginButton.bWidth, loginButton.y, TU.translate("editor.cancel"), close, 125));
		closeButton.color = 0xFFFF0000;
	}
}