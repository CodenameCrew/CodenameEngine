package funkin.menus.gamejolt;

import funkin.editors.ui.UISprite;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIText;
import funkin.editors.ui.UISubstateWindow;

class GameJoltTokenInfoWindow extends UISubstateWindow {
	public var text:UIText;
	public var closeButton:UIButton;

	public var daX:Float;

	public override function create() {
		//TODO: get translations for text
		winTitle = "GameJolt Token Info";

		winWidth = 756;
		winHeight = 220;

		super.create();

		daX = windowSpr.x + 20;

		add(text = new UIText(daX, windowSpr.y + 46, windowSpr.width - ((daX - windowSpr.x) * 2), "!! THIS IS NOT YOUR GAMEJOLT ACCOUNT PASSWORD !!\n\nTo access your game token, click on your profile icon, then click on \"Game Token\"."));
		
		//add(new UISprite(daX, text.y + text.height + 10).loadGraphic(Paths.image()))
		add(closeButton = new UIButton(windowSpr.x + (windowSpr.bWidth / 2) - 62, windowSpr.y + windowSpr.bHeight - 48, TU.translate("editor.saveClose"), function() {
			close();
		}, 125));
	}
}