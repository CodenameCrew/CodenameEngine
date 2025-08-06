package funkin.editors.extra;

class PropertyButton extends UIButton {
	public var propertyText:UITextBox;
	public var valueText:UITextBox;
	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public function new(property, value, parent, width:Int = 280, height:Int = 35, nameWidth:Int = 100, valueWidth:Int = 135, inputHeight:Int = 25) {
		super(0, 0, '', function () {}, width, height);
		members.push(propertyText = new UITextBox(5, 5, property, nameWidth, inputHeight));
		members.push(valueText = new UITextBox(propertyText.x + propertyText.bWidth + 10, 5, value, valueWidth, inputHeight));

		var deleteSize = height - 5 * 2;
		deleteButton = new UIButton(valueText.x + 135, bHeight/2 - (deleteSize/2), null, function () {
			parent.remove(this);
		}, deleteSize, deleteSize);
		deleteButton.color = 0xFFFF0000;
		deleteButton.autoAlpha = false;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(deleteButton.x, deleteButton.y).loadGraphic(Paths.image('editors/delete-button'));
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);

		updatePos();
	}

	public override function update(elapsed) {
		super.update(elapsed);
		updatePos();
	}

	public function updatePos() {
		propertyText.follow(this, 5, bHeight/2 - (propertyText.bHeight/2));
		valueText.follow(this, propertyText.x + propertyText.bWidth, bHeight/2 - (valueText.bHeight/2));
		//deleteButton.follow(this, valueText.x + 135, bHeight/2 - (25/2));
		deleteButton.follow(this, bWidth - deleteButton.bWidth - 5, bHeight/2 - deleteButton.bHeight/2);
		deleteIcon.follow(deleteButton, deleteButton.bWidth / 2 - deleteIcon.width / 2, deleteButton.bHeight / 2 - deleteIcon.height / 2);
	}
}