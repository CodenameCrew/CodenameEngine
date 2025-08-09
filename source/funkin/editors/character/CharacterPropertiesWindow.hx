
package funkin.editors.character;

import funkin.backend.FlxAnimate;
import haxe.io.Path;
import funkin.editors.character.CharacterInfoScreen.CharacterExtraInfo;
import funkin.game.Character;

class CharacterPropertiesWindow extends UISliceSprite {
	public var character:Character;
	public var animsWindow:CharacterAnimsWindow;

	public var positionXStepper:UINumericStepper;
	public var positionYStepper:UINumericStepper;
	public var positionXYComma:UIText;
	public var scaleStepper:UINumericStepper;
	public var editCharacterButton:UIButton;
	public var editSpriteButton:UIButton;
	public var flipXCheckbox:UICheckbox;

	public var cameraXStepper:UINumericStepper;
	public var cameraYStepper:UINumericStepper;
	public var cameraXYComma:UIText;
	public var antialiasingCheckbox:UICheckbox;
	public var testAsDropDown:UIDropDown;
	public var designedAsDropDown:UIDropDown;

	public var labels:Map<UISprite, UIText> = [];

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("characterEditor.characterProperties." + id, args);

	public function new(x:Float, y:Float, character:Character) @:privateAccess {
		super(x, y, 424+16, 204+20, "editors/ui/inputbox");

		function addLabelOn(ui:UISprite, text:String) {
			var uiText:UIText = new UIText(ui.x, ui.y-24, 0, text);
			members.push(uiText); labels.set(ui, uiText);
		}

		positionXStepper = new UINumericStepper(x+16, y+36, character.globalOffset.x, 0.001, 2, null, null, 104);
		positionXStepper.onChange = (text:String) -> {
			@:privateAccess positionXStepper.__onChange(text);
			this.changePosition(positionXStepper.value, null);
		};
		members.push(positionXStepper);
		addLabelOn(positionXStepper, translate("position"));

		members.push(positionXYComma = new UIText(positionXStepper.x+104-32+0, positionXStepper.y + 9, 0, ",", 22));

		positionYStepper = new UINumericStepper(positionXStepper.x+104-32+26, positionXStepper.y, character.globalOffset.y, 0.001, 2, null, null, 104);
		positionYStepper.onChange = (text:String) -> {
			@:privateAccess positionYStepper.__onChange(text);
			this.changePosition(null, positionYStepper.value);
		};
		members.push(positionYStepper);

		scaleStepper = new UINumericStepper(positionYStepper.x+104-32+26, positionYStepper.y, character.scale.x, 0.001, 2, 0, null, 90);
		scaleStepper.onChange = (text:String) -> {
			@:privateAccess scaleStepper.__onChange(text);
			this.changeScale(scaleStepper.value);
		};
		members.push(scaleStepper);
		addLabelOn(scaleStepper, translate("scale"));

		editCharacterButton = new UIButton(scaleStepper.x + 90 -32 + 26, scaleStepper.y-20, translate("editInfo"), editCharacterInfoUI, 120, 24);
		editCharacterButton.field.size -= 2;
		members.push(editCharacterButton);

		editSpriteButton = new UIButton(editCharacterButton.x, editCharacterButton.y+24+6, translate("editSprite"), editCharacterSpriteUI, 120, 24);
		editSpriteButton.field.size -= 2;
		members.push(editSpriteButton);

		flipXCheckbox = new UICheckbox(scaleStepper.x+22, scaleStepper.y+32+14, translate("charFlipped"), character.isPlayer ? !character.__baseFlipped : character.__baseFlipped);
		flipXCheckbox.onChecked = (checked:Bool) -> {this.changeFlipX(checked);};
		members.push(flipXCheckbox);

		cameraXStepper = new UINumericStepper(positionXStepper.x, positionXStepper.y+32+32+4, character.cameraOffset.x, 0.001, 2, null, null, 104);
		cameraXStepper.onChange = (text:String) -> {
			@:privateAccess cameraXStepper.__onChange(text);
			this.changeCamPosition(cameraXStepper.value, null);
		};
		members.push(cameraXStepper);
		addLabelOn(cameraXStepper, translate("camPosition"));

		members.push(cameraXYComma = new UIText(cameraXStepper.x + 104-32+0, cameraXStepper.y+9, 0, ",", 22));

		cameraYStepper = new UINumericStepper(cameraXStepper.x+104-32+26, cameraXStepper.y, character.cameraOffset.y, 0.001, 2, null, null, 104);
		cameraYStepper.onChange = (text:String) -> {
			@:privateAccess cameraYStepper.__onChange(text);
			this.changeCamPosition(null, cameraYStepper.value);
		};
		members.push(cameraYStepper);

		antialiasingCheckbox = new UICheckbox(scaleStepper.x+22, flipXCheckbox.y+32, translate("antialiased"), character.antialiasing);
		antialiasingCheckbox.onChecked = (checked:Bool) -> {this.changeAntialiasing(checked);};
		members.push(antialiasingCheckbox);

		testAsDropDown = new UIDropDown(cameraXStepper.x, cameraXStepper.y+32+32+4, 193, 32, ["BOYFRIEND", "DAD"], character.playerOffsets ? 0 : 1);
		testAsDropDown.onChange = (index:Int) -> {
			CharacterEditor.instance.changeStagePosition(testAsDropDown.options[index]);
		};
		members.push(testAsDropDown);
		addLabelOn(testAsDropDown, translate("testCharAs"));
		testAsDropDown.bWidth = 193; //REFUSES TO FUCKING SET TO 170 PIECE OF SHIT!!

		designedAsDropDown = new UIDropDown(testAsDropDown.x+193+22, testAsDropDown.y, 193, 32, ["BOYFRIEND", "DAD"], character.playerOffsets ? 0 : 1);
		designedAsDropDown.onChange = (index:Int) -> {
			CharacterEditor.instance.changeCharacterDesginedAs(designedAsDropDown.options[index] == "BOYFRIEND");
		};
		members.push(designedAsDropDown);
		addLabelOn(designedAsDropDown, translate("charDesign"));
		designedAsDropDown.bWidth = 193;

		alpha = 0.7;

		this.character = character;
	}

	public function changePosition(newPosX:Null<Float>, newPosY:Null<Float>, addToUndo:Bool = true) {
		if (newPosX != null && newPosY != null && newPosX == character.globalOffset.x && newPosY == character.globalOffset.y)
			return;
		else if (addToUndo) {
			if (newPosX != null && newPosX == character.globalOffset.x) return;
			if (newPosY != null && newPosY == character.globalOffset.y) return;
		}
		var oldPosition:FlxPoint = character.globalOffset.clone();

		if (newPosX != null) character.globalOffset.x = newPosX;
		if (newPosY != null) character.globalOffset.y = newPosY;

		CharacterEditor.instance.playAnimation(character.getAnimName());

		positionXStepper.label.text = Std.string(character.globalOffset.x);
		positionYStepper.label.text = Std.string(character.globalOffset.y);

		if (addToUndo) CharacterEditor.undos.addToUndo(CCharEditPosition(oldPosition, character.globalOffset.clone()));
		else oldPosition.put();
	}

	public function changeScale(newScale:Float, addToUndo:Bool = true) {
		if (character.scale.x == newScale) return;
		var oldScale:Float = character.scale.x;

		character.scale.set(newScale, newScale);
		character.updateHitbox();

		CharacterEditor.instance.playAnimation(character.getAnimName());

		scaleStepper.label.text = Std.string(newScale);
		if (addToUndo) CharacterEditor.undos.addToUndo(CCharEditScale(oldScale, newScale));
	}

	public function editCharacterInfoUI() {
		CharacterEditor.instance.openSubState(new CharacterInfoScreen(character, (info:CharacterExtraInfo) -> {editCharacterInfo(info);}));
	}

	public function editCharacterInfo(info:CharacterExtraInfo, addToUndo:Bool = true) {
		var oldInfo:CharacterExtraInfo = {
			icon: character.icon,
			iconColor: character.iconColor,
			holdTime: character.holdTime,
			customProperties: character.extra.copy()
		};

		character.icon = info.icon;
		character.iconColor = info.iconColor;
		character.holdTime = info.holdTime;
		character.extra = info.customProperties.copy();

		if (addToUndo) CharacterEditor.undos.addToUndo(CCharEditInfo(oldInfo, info));
	}

	public function editCharacterSpriteUI() {
		CharacterEditor.instance.openSubState(new CharacterSpriteScreen('characters/${character.sprite}', (sprite:String, isAtlas:Bool) -> {
			changeSprite(sprite);
		}));
	}

	public function changeSprite(sprite:String) @:privateAccess {
		var path:String = Paths.image('characters/$sprite');
		var noExt:String = Path.withoutExtension(path);

		character.sprite = sprite;

		animsWindow.displayWindowSprite.animation.reset();
		animsWindow.displayAnimsFramesList.clear();
		if (animsWindow.displayWindowGraphic != null) 
			animsWindow.displayWindowGraphic.destroy();

		if (Assets.exists('$noExt/Animation.json')) {
			if (character.animateAtlas == null) {
				character.animation.reset();
				character.animateAtlas = new FlxAnimate(character.x, character.y);
			} else
				character.animateAtlas.anim.stop();

			character.atlasPath = noExt;
			character.animateAtlas.loadAtlas(noExt);
		} else {
			if (character.animateAtlas != null) {
				character.animateAtlas.destroy();
				character.animateAtlas = null;
				character.atlasPlayingAnim = character.atlasPath = null;
			}
			character.frames = Paths.getFrames(path, true);

			animsWindow.displayWindowSprite.loadGraphicFromSprite(character);
			if (Assets.exists(Paths.image('characters/${character.sprite}')))
				animsWindow.displayWindowGraphic = FlxG.bitmap.add(Assets.getBitmapData(Paths.image('characters/${character.sprite}'), true, false));
		}

		character.animDatas.clear();
		for (anim in animsWindow.buttons) anim.checkValid(); // Re-add all animations

		CharacterEditor.instance.playAnimation(animsWindow.findValid().getDefault(animsWindow.buttons.members[0].anim));
		animsWindow.setAnimAutoComplete(CoolUtil.getAnimsListFromSprite(character));
	}

	public function changeFlipX(newFlipX:Bool, addToUndo:Bool = true) @:privateAccess {
		character.flipX = character.isPlayer ? !newFlipX : newFlipX;
		character.__baseFlipped = character.flipX;
		
		CharacterEditor.instance.playAnimation(character.getAnimName());

		flipXCheckbox.checked = newFlipX;
		if (addToUndo) CharacterEditor.undos.addToUndo(CCharEditFlipped(newFlipX));
	}

	public function changeCamPosition(newPosX:Null<Float>, newPosY:Null<Float>, addToUndo:Bool = true) {
		if (newPosX != null && newPosY != null && newPosX == character.cameraOffset.x && newPosY == character.cameraOffset.y)
			return;
		else if (addToUndo) {
			if (newPosX != null && newPosX == character.cameraOffset.x) return;
			if (newPosY != null && newPosY == character.cameraOffset.y) return;
		}
		var oldCamPosition:FlxPoint = character.cameraOffset.clone();

		if (newPosX != null) character.cameraOffset.x = newPosX;
		if (newPosY != null) character.cameraOffset.y = newPosY;

		cameraXStepper.label.text = Std.string(character.cameraOffset.x);
		cameraYStepper.label.text = Std.string(character.cameraOffset.y);

		if (addToUndo) CharacterEditor.undos.addToUndo(CCharEditCamPosition(oldCamPosition, character.cameraOffset.clone()));
		else oldCamPosition.put();
	}

	public function changeAntialiasing(newAntialiasing:Bool, addToUndo:Bool = true) {
		if (character.antialiasing == newAntialiasing) return;
		character.antialiasing = newAntialiasing;
		animsWindow.displayWindowSprite.antialiasing = newAntialiasing;

		antialiasingCheckbox.checked = newAntialiasing;
		if (addToUndo) CharacterEditor.undos.addToUndo(CCharEditAntialiasing(newAntialiasing));
	}

	public function updateButtonsPos() {
		positionXStepper.follow(this, 16, 36);
		positionYStepper.follow(this, 16+104-32+26, 36);
		positionXYComma.follow(this, 16+104-32+0, 36 + 9);
		scaleStepper.follow(this, (16+104-32+26)+104-32+26, 36);
		editCharacterButton.follow(this, ((16+104-32+26)+104-32+26)+90-32+26, 36-20);
		editSpriteButton.follow(this, ((16+104-32+26)+104-32+26)+90-32+26, (36-20)+24+6);
		flipXCheckbox.follow(this, (16+104-32+26)+104-32+26+22, 36+32+14);
	
		cameraXStepper.follow(this, 16, 36+32+32+4);
		cameraYStepper.follow(this, (16)+104-32+26, 36+32+32+4);
		cameraXYComma.follow(this, 16 + 104-32+0, (36+32+32+4)+9);
		antialiasingCheckbox.follow(this, ((16+104-32+26)+104-32+26)+22, 36+32+14+32);
		testAsDropDown.follow(this, 16, (36+32+32+4)+32+32+4);
		designedAsDropDown.follow(this, (16)+193+22, (36+32+32+4)+32+32+4);

		for (ui => text in labels)
			text.follow(ui, 0, -24);
	}

	public override function draw() {
		updateButtonsPos();
		super.draw();
	}
}