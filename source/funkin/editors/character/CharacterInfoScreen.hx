package funkin.editors.character;

import flixel.math.FlxPoint;
import haxe.xml.Access;
import funkin.game.Character;
import funkin.editors.extra.PropertyButton;

class CharacterInfoScreen extends UISubstateWindow {
	public var character:Character;

	public var spriteTextBox:UITextBox;
	public var iconTextBox:UITextBox;
	public var iconSprite:FlxSprite;
	public var gameOverCharTextBox:UITextBox;
	public var antialiasingCheckbox:UICheckbox;
	public var flipXCheckbox:UICheckbox;
	public var iconColorWheel:UIColorwheel;
	public var positionXStepper:UINumericStepper;
	public var positionYStepper:UINumericStepper;
	public var cameraXStepper:UINumericStepper;
	public var cameraYStepper:UINumericStepper;
	public var scaleStepper:UINumericStepper;
	public var singTimeStepper:UINumericStepper;
	public var customPropertiesButtonList:UIButtonList<PropertyButton>;
	public var isPlayerCheckbox:UICheckbox;
	public var isGFCheckbox:UICheckbox;

	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public var onSave:(xml:Xml) -> Void = null;

	public function new(character:Character, ?onSave:(xml:Xml) -> Void) {
		this.character = character;
		this.onSave = onSave;
		super();
	}

	public override function create() {
		winTitle = "Editing Character";
		winWidth = 1014;
		winHeight = 600;

		super.create();

		function addLabelOn(ui:UISprite, text:String)
			add(new UIText(ui.x, ui.y - 24, 0, text));

		var title:UIText;
		add(title = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, "Sprite Data", 28));

		spriteTextBox = new UITextBox(title.x, title.y + title.height + 38, character.sprite, 200);
		add(spriteTextBox);
		addLabelOn(spriteTextBox, "Sprite");

		iconTextBox = new UITextBox(spriteTextBox.x + 200 + 26, spriteTextBox.y, character.getIcon(), 150);
		iconTextBox.onChange = (newIcon:String) -> {updateIcon(newIcon);}
		add(iconTextBox);
		addLabelOn(iconTextBox, "Icon");

		updateIcon(character.getIcon());

		gameOverCharTextBox = new UITextBox(iconTextBox.x + 150 + (75 + 12), iconTextBox.y, character.gameOverCharacter, 200);
		add(gameOverCharTextBox);
		addLabelOn(gameOverCharTextBox, "Game Over Character");

		antialiasingCheckbox = new UICheckbox(spriteTextBox.x, spriteTextBox.y + 10 + 32 + 28, "Antialiasing", character.antialiasing);
		add(antialiasingCheckbox);
		addLabelOn(antialiasingCheckbox, "Antialiased");

		flipXCheckbox = new UICheckbox(antialiasingCheckbox.x + 172, spriteTextBox.y + 10 + 32 + 28, "FlipX", character.flipX);
		add(flipXCheckbox);
		addLabelOn(flipXCheckbox, "Flipped");

		iconColorWheel = new UIColorwheel(gameOverCharTextBox.x + 200 + 20, gameOverCharTextBox.y, character.iconColor);
		add(iconColorWheel);
		addLabelOn(iconColorWheel, "Icon Color");

		if (character.iconColor != null)
			iconColorWheel.colorChanged = true;

		add(title = new UIText(spriteTextBox.x, spriteTextBox.y + 10 + 46 + 84, 0, "Character Data", 28));

		positionXStepper = new UINumericStepper(title.x, title.y + title.height + 36, character.globalOffset.x, 0.001, 2, null, null, 84);
		add(positionXStepper);
		addLabelOn(positionXStepper, "Position (X,Y)");

		add(new UIText(positionXStepper.x + 84 - 32 + 0, positionXStepper.y + 9, 0, ",", 22));

		positionYStepper = new UINumericStepper(positionXStepper.x + 84 - 32 + 26, positionXStepper.y, character.globalOffset.y, 0.001, 2, null, null, 84);
		add(positionYStepper);

		cameraXStepper = new UINumericStepper(positionYStepper.x + 36 + 84 - 32, positionYStepper.y, character.cameraOffset.x, 0.001, 2, null, null, 84);
		add(cameraXStepper);
		addLabelOn(cameraXStepper, "Camera Position (X,Y)");

		add(new UIText(cameraXStepper.x + 84 - 32 + 0, cameraXStepper.y + 9, 0, ",", 22));

		cameraYStepper = new UINumericStepper(cameraXStepper.x + 84 - 32 + 26, cameraXStepper.y, character.cameraOffset.y, 0.001, 2, null, null, 84);
		add(cameraYStepper);

		scaleStepper = new UINumericStepper(cameraYStepper.x + 84 - 32 + 90, cameraYStepper.y, character.scale.x, 0.001, 2, null, null, 74);
		add(scaleStepper);
		addLabelOn(scaleStepper, "Scale");

		singTimeStepper = new UINumericStepper(scaleStepper.x + 74 - 32 + 36, scaleStepper.y, character.holdTime, 0.001, 2, null, null, 74);
		add(singTimeStepper);
		addLabelOn(singTimeStepper, "Sing Duration (Steps)");

		customPropertiesButtonList = new UIButtonList<PropertyButton>(singTimeStepper.x + singTimeStepper.width + 200, singTimeStepper.y, 290, 200, '', FlxPoint.get(280, 35), null, 5);
		customPropertiesButtonList.frames = Paths.getFrames('editors/ui/inputbox');
		customPropertiesButtonList.cameraSpacing = 0;
		customPropertiesButtonList.addButton.callback = function() {
			customPropertiesButtonList.add(new PropertyButton("newProperty", "valueHere", customPropertiesButtonList));
		}
		for (prop=>val in character.extra)
			customPropertiesButtonList.add(new PropertyButton(prop, val, customPropertiesButtonList));
		add(customPropertiesButtonList);
		addLabelOn(customPropertiesButtonList, "Custom Values (Advanced)");

		isPlayerCheckbox = new UICheckbox(positionXStepper.x, positionXStepper.y + 10 + 32 + 28, "isPlayer", character.playerOffsets);
		add(isPlayerCheckbox);
		addLabelOn(isPlayerCheckbox, "Is Player");

		isGFCheckbox = new UICheckbox(isPlayerCheckbox.x + 128, positionXStepper.y + 10 + 32 + 28, "isGF", false);
		add(isGFCheckbox);
		addLabelOn(isGFCheckbox, "Is GF");

		for (checkbox in [isPlayerCheckbox, isGFCheckbox, antialiasingCheckbox, flipXCheckbox])
			{checkbox.y += 4; checkbox.x += 6;}

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight- 20, "Save & Close", function() {
			saveCharacterInfo();
			close();
		}, 125);
		saveButton.x -= saveButton.bWidth;
		saveButton.y -= saveButton.bHeight;

		closeButton = new UIButton(saveButton.x - 20, saveButton.y, "Close", function() {
			if (onSave != null) onSave(null);
			close();
		}, 125);
		closeButton.x -= closeButton.bWidth;
		closeButton.color = 0xFFFF0000;
		add(closeButton);
		add(saveButton);
	}

	function updateIcon(icon:String) {
		if (iconSprite == null) add(iconSprite = new FlxSprite());

		if (iconSprite.animation.exists(icon)) return;
		@:privateAccess iconSprite.animation.clearAnimations();

		var path:String = Paths.image('icons/$icon');
		if (!Assets.exists(path)) path = Paths.image('icons/face');

		iconSprite.loadGraphic(path, true, 150, 150);
		iconSprite.animation.add(icon, [0], 0, false);
		iconSprite.antialiasing = true;
		iconSprite.animation.play(icon);

		iconSprite.scale.set(0.5, 0.5);
		iconSprite.updateHitbox();
		iconSprite.setPosition(iconTextBox.x + 150 + 8, (iconTextBox.y + 16) - (iconSprite.height/2));
	}

	function saveCharacterInfo() {
		for (stepper in [positionXStepper, positionYStepper, cameraXStepper, cameraYStepper, singTimeStepper, scaleStepper])
			@:privateAccess stepper.__onChange(stepper.label.text);

		var xml = Xml.createElement("character");
		xml.set("isPlayer", isPlayerCheckbox.checked ? "true" : "false");
		xml.set("x", Std.string(positionXStepper.value));
		xml.set("y", Std.string(positionYStepper.value));
		xml.set("gameOverChar", gameOverCharTextBox.label.text);
		xml.set("camx", Std.string(cameraXStepper.value));
		xml.set("camy", Std.string(cameraYStepper.value));
		xml.set("holdTime", Std.string(singTimeStepper.value));
		xml.set("flipX", Std.string(flipXCheckbox.checked));
		xml.set("icon", iconTextBox.label.text);
		xml.set("scale", Std.string(scaleStepper.value));
		xml.set("antialiasing", antialiasingCheckbox.checked ? "true" : "false");
		xml.set("sprite", spriteTextBox.label.text);
		if (iconColorWheel.colorChanged)
			xml.set("color", iconColorWheel.curColor.toWebString());
		for (val in customPropertiesButtonList.buttons.members)
			xml.set(val.propertyText.label.text, val.valueText.label.text);

		for (anim in character.animDatas)
		{
			var animXml:Xml = Xml.createElement('anim');
			animXml.set("name", anim.name);
			animXml.set("anim", anim.anim);
			animXml.set("loop", Std.string(anim.loop));
			animXml.set("fps", Std.string(anim.fps));
			var offset:FlxPoint = character.getAnimOffset(anim.name);
			animXml.set("x", Std.string(offset.x));
			animXml.set("y", Std.string(offset.y));
			offset.put();

			if (anim.indices.length > 0)
				animXml.set("indices", CoolUtil.formatNumberRange(anim.indices));
			xml.addChild(animXml);
		}

		if (onSave != null) onSave(xml);
	}
}