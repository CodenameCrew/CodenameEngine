package funkin.editors.character;

import flixel.util.typeLimit.OneOfTwo;
import funkin.backend.utils.XMLUtil.AnimData;
import flixel.animation.FlxAnimation;
import flixel.graphics.FlxGraphic;
import openfl.geom.Rectangle;
import flixel.graphics.frames.FlxFrame;
import funkin.game.Character;
import flixel.animation.FlxPrerotatedAnimation;

using funkin.backend.utils.BitmapUtil;

class CharacterAnimsWindow extends UIButtonList<CharacterAnimButton> {
	public var character:CharacterGhost;

	public var displayWindowSprite:FlxSprite;
	public var displayWindowGraphic:FlxGraphic;
	public var displayAnimsFramesList:Map<String, {scale:Float, animBounds:Rectangle, frame:OneOfTwo<Int, String>}> = [];

	public var animButtons:Map<String, CharacterAnimButton> = [];
	public var animsList:Array<String> = [];

	public function new(x:Float, y:Float, character:CharacterGhost) {
		super(x, y, Std.int(500-16), 419, null, FlxPoint.get(Std.int(500-16-32), 208));
		this.character = character;

		cameraSpacing = 0;
		frames = Paths.getFrames('editors/ui/inputbox');

		buttonCameras.pixelPerfectRender = true;

		if (Assets.exists(Paths.image('characters/${character.sprite}')) && character.animateAtlas == null)
			displayWindowGraphic = FlxG.bitmap.add(Assets.getBitmapData(Paths.image('characters/${character.sprite}'), true, false));

		displayWindowSprite = new FlxSprite();
		displayWindowSprite.loadGraphicFromSprite(character);
		displayWindowSprite.antialiasing = character.antialiasing;
		displayWindowSprite.flipX = character.flipX;

		alpha = 0.7;

		for (anim in character.getAnimOrder())
			addAnimation(character.animDatas.get(anim), -1, false);
		addButton.callback = generateAnimation;

		setAnimAutoComplete(CoolUtil.getAnimsListFromSprite(character));

		nextscrollY = 0;
		// dragCallback = (button:CharacterAnimButton, oldID:Int, newID:Int) -> {}
	}

	public var ghosts:Array<String> = [];
	var __movingAnimOldOrder:Int = -1;
	public override function update(elapsed:Float) {
		var __oldMoving:CharacterAnimButton = curMoving;
		super.update(elapsed);

		if (curMoving != null && __oldMoving == null) 
			__movingAnimOldOrder = curMoving.ID;

		if (curMoving == null && __oldMoving != null)
			if (__movingAnimOldOrder != __oldMoving.ID) 
				CharacterEditor.undos.addToUndo(CAnimEditOrder(__movingAnimOldOrder, __oldMoving.ID));
		

		animsList = [for (button in buttons) button.anim];
		character.ghosts = ghosts;
	}

	public function buildAnimDisplay(name:String, anim:AnimData) @:privateAccess {
		if (character.animateAtlas == null) {
			var anim:FlxAnimation = character.animation._animations[anim.name];
			if (anim == null || anim.frames.length <= 0) return;

			var frameIndex:Int = anim.frames.getDefault([0])[0];
			var frame:FlxFrame = displayWindowSprite.frames.frames[frameIndex];

			var frameRect:Rectangle = new Rectangle(frame.offset.x, frame.offset.y, frame.sourceSize.x, frame.sourceSize.y);
			var animBounds:Rectangle = displayWindowGraphic != null ? displayWindowGraphic.bitmap.bounds(frameRect) : frameRect;

			displayAnimsFramesList.set(name, {frame: anim.frames.getDefault([0])[0], scale: 104/Math.max(animBounds.width, animBounds.height), animBounds: animBounds});
		} else {
			character.storeAtlasState();

			/*
			character.animateAtlas.anim.play(anim.name, true, false, 0);
			character.animateAtlas.anim.stop();

			var animBounds:Rectangle = MatrixUtil.getBounds(character).copyToFlash();
			displayAnimsFramesList.set(name, {frame: anim.anim, scale: 104/animBounds.height, animBounds: animBounds});
			*/

			character.restoreAtlasState();
		}
	}

	public function removeAnimDisplay(name:String)
		displayAnimsFramesList.remove(name);

	public function deleteAnimation(button:CharacterAnimButton, addToUndo:Bool = true) {
		UIState.playEditorSound(Flags.DEFAULT_EDITOR_DELETE_SOUND);
		if (buttons.members.length <= 1) return;
		if (character.getAnimName() == button.anim)
			@:privateAccess CharacterEditor.instance._animation_down(null);

		character.removeAnimation(button.anim);
		if (character.animOffsets.exists(button.anim)) character.animOffsets.remove(button.anim);
		if (character.animDatas.exists(button.anim)) character.animDatas.remove(button.anim);

		if (addToUndo) CharacterEditor.undos.addToUndo(CAnimDelete(button.ID, button.data));
		remove(button); button.destroy();
	}

	public function generateAnimation() {
		var newAnim = TU.translate("characterEditor.characterAnim.defaultAnimName");
		var animName:String = newAnim;
		var animNames:Array<String> = character.getNameList();

		var newAnimCount:Int = 0;
		while (animNames.indexOf(animName) != -1) {
            newAnimCount++;
            animName = '$newAnim - $newAnimCount';
        }

		if (__autoCompleteAnims.length <= 0)
			setAnimAutoComplete(CoolUtil.getAnimsListFromSprite(character));

		var animData:AnimData = {
			name: animName,
			anim: __autoCompleteAnims[0],
			fps: 24, loop: false,
			x: 0, y: 0,
			indices: [],
			animType: NONE,
		};
		addAnimation(animData);
	}

	public function addAnimation(animData:AnimData, animID:Int = -1, addToUndo:Bool = true) @:privateAccess {
		XMLUtil.addAnimToSprite(character, animData);

		var newButton:CharacterAnimButton = new CharacterAnimButton(0, 0, animData, this);
		newButton.alpha = 0.25; animButtons.set(animData.name, newButton);
		newButton.animTextBox.suggestItems = __autoCompleteAnims;

		if (animID == -1) add(newButton);
		else insert(newButton, animID);

		if (newButton.valid)
			buildAnimDisplay(animData.name, animData);

		if (addToUndo)
			CharacterEditor.undos.addToUndo(CAnimCreate(newButton.ID, newButton.data));

		var nextButtonY:Float = 0;
		for (buttonID in 0...newButton.ID)
			nextButtonY += buttons.members[buttonID].bHeight + buttonOffset.y;
		nextscrollY = nextButtonY;
	}

	@:noCompletion var __autoCompleteAnims:Array<String> = [];
	public inline function setAnimAutoComplete(anims:Array<String>) {
		__autoCompleteAnims = anims.copy();
		for (button in buttons)
			button.animTextBox.suggestItems = __autoCompleteAnims;
	}

	public function findValid():Null<String> {
		for (button in buttons) if (button.valid) return button.anim;
		return null;
	}
}