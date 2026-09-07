package funkin.menus.gamejolt;

import funkin.editors.ui.*;

class GameJoltConfirmationWindow extends UISubstateWindow
{
	public var actionType:String;
	public var description:String;
	public var callback:Null<Void->Void>;
	public var closeOnConfirm:Bool;
	public var yesText:String;
	public var noText:String;

	public var yesButton:UIButton;
	public var noButton:UIButton;

	override public function new(actionType:String = 'Logout', description:String = 'No description provided.', ?callback:Void->Void, closeOnConfirm:Bool = true, ?yesText:String, ?noText:String)
	{
		super();
		this.actionType = actionType;
		this.description = description;
		this.callback = callback;
		this.closeOnConfirm = closeOnConfirm;
		this.yesText = yesText != null ? yesText : TU.translate('editor.yes');
		this.noText = noText != null ? noText : TU.translate('editor.cancel');
	}

	override public function create()
	{
		winWidth = 360;

		winTitle = 'Confirm $actionType';

		super.create();

		add(messageSpr = new UIText(windowSpr.x + 20, windowSpr.y + 46, windowSpr.bWidth - 40, description));
		messageSpr.alignment = CENTER;

		windowSpr.resize(winWidth, Std.int(messageSpr.y + messageSpr.height + 68));

		add(yesButton = new UIButton(windowSpr.x + (windowSpr.bWidth / 2) - 130, windowSpr.y + windowSpr.bHeight - 48, yesText, confirmAndClose, 125));
		add(noButton = new UIButton(windowSpr.x + (windowSpr.bWidth / 2) + 5, windowSpr.y + windowSpr.bHeight - 48, noText, close, 125));
		noButton.color = 0xFFFF0000;
	}

	function confirmAndClose()
	{
		if (callback != null)
			callback();
		if (closeOnConfirm)
			close();
	}
}