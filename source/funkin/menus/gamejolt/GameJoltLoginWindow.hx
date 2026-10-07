package funkin.menus.gamejolt;

import funkin.editors.ui.*;
import funkin.menus.gamejolt.*;

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

		winWidth = 360;
		winHeight = 250;

		super.create();

		daX = windowSpr.x + 20;

		add(usernameBox = new UITextBox(daX, windowSpr.y + 60, ""));
		usernameBox.members.push(new UIText(daX, usernameBox.y - 24, 0, "Username"));

		add(userTokenBox = new UITextBox(daX, usernameBox.y + usernameBox.height + 60, ""));
		userTokenBox.members.push(userTokenLabel = new UIText(daX, userTokenBox.y - 24, 0, "User Token"));
		userTokenBox.members.push(userTokenInfo = new UIButton(daX + userTokenLabel.width, userTokenLabel.y - 4, "?", () -> {
			openSubState(new GameJoltInfoWindow('GameJolt User Token', "!! THIS IS NOT YOUR GAMEJOLT ACCOUNT PASSWORD !!\n\nTo access your game token, click on your profile icon, then click on \"Game Token\"."));
		}, 24, 24));
		userTokenInfo.color = 0xFF3737FF;
		userTokenBox.label.textField.displayAsPassword = true;

		add(loginButton = new UIButton(windowSpr.x + (windowSpr.bWidth / 2) + 20, windowSpr.y + windowSpr.bHeight - 48, "Login", function() {
			GJUtil.attemptLogin(usernameBox.label.text, userTokenBox.label.text, (bl) -> {
				openSubState(new GameJoltInfoWindow(bl ? "Login Success!" : "Login Error", bl ? 'You have successfully logged in as ${GJUtil.userName}!' : 'Could not log into GameJolt.', () -> {
					if (bl) {
						close();
						FlxG.resetState();
					}
				}, bl ? 'Sweet!' : TU.translate('editor.ok')));
			}, true);
		}, 125));

		add(closeButton = new UIButton(loginButton.x - loginButton.bWidth - 20, loginButton.y, TU.translate("editor.cancel"), function() {
			close();
		}, 125));
		closeButton.color = 0xFFFF0000;
	}
}