package funkin.menus.gamejolt;

import funkin.editors.ui.*;

class GameJoltInfoWindow extends UISubstateWindow {
	public var infoTitle:String;
	public var description:String;
	public var closeText:String;
	public var callback:Null<Void->Void>;

	public var closeButton:UIButton;

	public var daX:Float;

	override public function new(infoTitle:String = 'General', description:String = "No description provided.", ?callback:Void->Void, ?closeText:String)
	{
		super();
		this.infoTitle = infoTitle;
		this.description = description;
		this.closeText = closeText != null ? closeText : TU.translate('editor.ok');
		this.callback = callback;
	}

	public override function create() {
		//TODO: get translations for text
		winTitle = 'Info - $infoTitle';

		winWidth = 756;

		super.create();

		daX = windowSpr.x + 20;

		add(messageSpr = new UIText(daX, windowSpr.y + 46, windowSpr.bWidth - ((daX - windowSpr.x) * 2), description));
		messageSpr.alignment = CENTER;

		windowSpr.resize(winWidth, Std.int(messageSpr.y + messageSpr.height + 68));
		
		//add(new UISprite(daX, text.y + text.height + 10).loadGraphic(Paths.image()))
		add(closeButton = new UIButton(windowSpr.x + (windowSpr.bWidth / 2) - 62, windowSpr.y + windowSpr.bHeight - 48, TU.translate("editor.close"), close, 125));
	}

	public override function close()
	{
		if (callback != null) callback();
		super.close();
	}
}