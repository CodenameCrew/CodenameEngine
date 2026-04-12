package funkin.editors.stage.elements;

import funkin.backend.utils.XMLUtil.AnimData;
import haxe.xml.Access;
import funkin.editors.extra.PropertyButton;

class StageSpriteAnimButton extends PropertyButton
{
	public var fpsStepper:UINumericStepper;
	public var editButton:UIButton;
	public var editIcon:FlxSprite;
	@:unreflective private var __initialized:Bool = false;

	public var spriteXML:Access;
	public var animData(default, null):AnimData;

	public function new(anim:AnimData, parent, width:Int = 280, height:Int = 35, nameWidth:Int = 100, valueWidth:Int = 135, inputHeight:Int = 25)
	{
		super("", "", parent, width, height, nameWidth, valueWidth, inputHeight);
		animData = anim;
		propertyText.onChange = (text) -> animData.name = text;
		valueText.onChange = 		(text) -> animData.anim = text;

		var editSize = height - 5 * 2;
		editButton = new UIButton(deleteButton.x - deleteButton.bWidth - 5, 5, null, openAnimEdit, editSize, editSize);
		editButton.frames = Paths.getFrames("editors/ui/grayscale-button");
		editButton.color = 0xFFFF5B0F;
		editButton.autoAlpha = false;
		members.insert(members.indexOf(deleteButton), editButton);

		editIcon = new FlxSprite(editButton.x + 8, editButton.y + 10).loadGraphic(Paths.image('editors/stage/edit-button'), true, 16, 16);
		editIcon.animation.add("advanced", [1]);
		editIcon.animation.play("advanced");
		editIcon.antialiasing = false;
		members.insert(members.indexOf(editButton) + 1, editIcon);

		fpsStepper = new UINumericStepper(valueText.x + valueText.bWidth + 15, 5, 0, 1, 2, 0, null, Math.round(width / 4), 25);
		fpsStepper.onChange = (text) -> 
		{
			@:privateAccess fpsStepper.__onChange(text);
			animData.fps = fpsStepper.value;
		};
		members.insert(members.indexOf(deleteButton), fpsStepper);

		__initialized = true;
		updateDisplay();
	}

	public function openAnimEdit()
	{
		final parent = (FlxG.state.subState is UISoftcodedWindow) ? FlxG.state.subState : FlxG.state;
		parent.openSubState(new SpriteAnimEditScreen(spriteXML, this, null));
	}

	public override function updatePos()
	{
		super.updatePos();
		if (!__initialized) return;

		fpsStepper.follow(this, valueText.x + valueText.bWidth, bHeight/2 - (fpsStepper.bHeight/2));
		editButton.follow(this, deleteButton.x - deleteButton.bWidth - 5, bHeight/2 - (editButton.bHeight/2));
		editIcon.follow(editButton, editButton.bWidth / 2 - editIcon.width / 2, editButton.bHeight / 2 - editIcon.height / 2);
	}

	public inline function updateDisplay()
	{
		propertyText.label.text = animData.name;
		valueText.label.text = animData.anim;
		fpsStepper.value = animData.fps;
	}
}

class SpriteAnimEditScreen extends UISoftcodedWindow
{
	public var saveCallback:Void->Void;
	public var parentButton:StageSpriteAnimButton;
	public var xml:Access;

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("stageSpriteAnimEditScreen." + id, args);

	public function new(xml:Access, parentButton:StageSpriteAnimButton, saveCallback:Void->Void) {
		this.saveCallback = saveCallback;
		this.parentButton = parentButton;
		this.xml = xml;
		super("layouts/stage/animEditScreen", [
			"stage" => StageEditor.instance.stage,
			"xml" => xml,
			"exID" => StageEditor.exID,
			"translate" => translate,
			"button" => parentButton
		]);
	}

	override function saveData() {
		super.saveData();
		if(saveCallback != null) saveCallback();
	}
}