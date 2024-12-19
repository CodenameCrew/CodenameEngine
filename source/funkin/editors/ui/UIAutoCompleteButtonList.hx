package funkin.editors.ui;

typedef UIAutoCompleteButtonList = UITypedAutoCompleteButtonList<UIAutoCompleteButton>;

class UITypedAutoCompleteButtonList<T:UIAutoCompleteButton> extends UIButtonList<T> {
	public var suggestItems(default, set):Array<String> = [];

	private function set_suggestItems(value:Array<String>) {
		buttons.forEachAlive((button) -> button.textBox.suggestItems = value);
		return suggestItems = value;
	}

	public function new(x:Float, y:Float, width:Int, height:Int, windowName:String, ?suggestItems:Array<String>, ?buttonSize:FlxPoint, ?buttonOffset:FlxPoint, buttonSpacing:Float = 0) {
		super(x, y, width, height, windowName, buttonSize == null ? FlxPoint.get(width, width * 0.15) : buttonSize, buttonOffset, buttonSpacing);
		if (suggestItems != null && suggestItems.length > 0) this.suggestItems = suggestItems;
		addButton.callback = () -> add(cast new UIAutoCompleteButton(0, 0, cast this, this.suggestItems));
	}
}

class UIAutoCompleteButton extends UIButton {
	public var textBox:UIAutoCompleteTextBox;
	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public function new (x:Float, y:Float, parent:UIAutoCompleteButtonList, ?suggestItems:Array<String>, text:String = "", ?w:Int, ?h:Int, multiline:Bool = false) {
		super(x, y, "", null, w == null ? Std.int(parent.buttonSize.x) : w, h == null ? Std.int(parent.buttonSize.y) : h);

		members.push(textBox = new UIAutoCompleteTextBox(16, bHeight/2 - (32/2), text, Std.int(bWidth - 32 - 36), 32, multiline));
		if (suggestItems != null && suggestItems.length > 0) textBox.suggestItems = suggestItems;
		textBox.antialiasing = false;

		members.push(deleteButton = new UIButton(textBox.x + textBox.bWidth + 10, textBox.y, "", () -> { parent.remove(this); destroy(); }, 32));
		deleteButton.color = 0xFFFF0000;
		deleteButton.autoAlpha = false;

		members.push(deleteIcon = new FlxSprite(deleteButton.x + (15/2), deleteButton.y + 8).loadGraphic(Paths.image('editors/delete-button')));
		deleteIcon.antialiasing = false;
	}

	override function update(elapsed) {
		deleteButton.y = y + bHeight / 2 - deleteButton.bHeight / 2;
		textBox.y = y + bHeight/2 - 16;
		deleteIcon.x = deleteButton.x + (15/2); deleteIcon.y = deleteButton.y + 8;

		textBox.selectable = deleteButton.selectable = selectable;
		deleteButton.shouldPress = shouldPress;

		super.update(elapsed);
	}
}