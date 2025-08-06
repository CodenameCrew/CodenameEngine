package funkin.editors.charter;

import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import funkin.backend.chart.ChartData.ChartBookmark;

class CharterBookmarkCreation extends UISubstateWindow {
	public var saveButton:UIButton;
	public var closeButton:UIButton;
	public var textBox:UITextBox;
	public var colorPicker:UICompactColorwheel;

	var callback:Bool->String->FlxColor->Float->Void;

	var bookmarkStep:Float = 0;

	override public function new(step:Float, close:Bool->String->FlxColor->Float->Void)
	{
		super();

		winWidth = 320;
		winHeight = 250;
		winTitle = TU.translate("charter.bookmarks.createBookmarkTitle");

		callback = close;

		bookmarkStep = step;
	}

	public override function create() {
		FlxG.sound.music.pause();
		Charter.instance.vocals.pause();

		function addLabelOn(ui:UISprite, text:String):UIText {
			var text:UIText = new UIText(ui.x, ui.y - 24, 0, text);
			ui.members.push(text);
			return text;
		}

		super.create();

		textBox = new UITextBox(windowSpr.x + 20, windowSpr.y + 70, TU.translate("charter.bookmarks.newBookmarkName"), 276);
		textBox.antialiasing = true;
		add(textBox);
		addLabelOn(textBox, TU.translate("charter.bookmarks.createBookmarkName"));
		
		colorPicker = new UICompactColorwheel(textBox.x, textBox.y + textBox.bHeight + 34, flixel.util.FlxColor.RED);
		add(colorPicker);
		addLabelOn(colorPicker, TU.translate("charter.bookmarks.createBookmarkColor"));

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, TU.translate("editor.saveClose"), function() {
			callback(true, textBox.label.text, colorPicker.curColor, bookmarkStep);
			close();
		}, 125);
		add(saveButton);

		closeButton = new UIButton(saveButton.x - 20, saveButton.y, TU.translate("editor.close"), function() {
			callback(false, "", FlxColor.TRANSPARENT, -1);
			close();
		}, 125);
		add(closeButton);
		closeButton.color = 0xFFFF0000;
		closeButton.x -= closeButton.bWidth;
	}
}