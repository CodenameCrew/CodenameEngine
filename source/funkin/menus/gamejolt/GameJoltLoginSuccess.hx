package funkin.menus.gamejolt;

import funkin.editors.ui.UIButton;
import funkin.editors.ui.UISubstateWindow;

class GameJoltLoginSuccess extends UISubstateWindow
{
	var confirmButton:UIButton;

	public override function create()
	{
		winTitle = "Login Success!";

		messageSpr.text = 'You have successfully logged in as ${GJUtil.userName}!';

		super.create();

		add(confirmButton = new UIButton(windowSpr.x + (windowSpr.bWidth / 2) - 62, windowSpr.y + windowSpr.bHeight - 48, "Sweet!", function() {
			close();
		}, 125));
		confirmButton.color = 0xFF00FF00;
	}
}