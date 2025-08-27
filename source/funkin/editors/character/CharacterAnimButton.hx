package funkin.editors.character;

import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import flxanimate.animate.FlxAnim.FlxSymbolAnimation;
import flxanimate.animate.FlxSymbol;
import flxanimate.animate.FlxElement;
import flxanimate.animate.SymbolParameters;
import flxanimate.animate.FlxKeyFrame;
import flxanimate.animate.FlxTimeline;
import flixel.graphics.frames.FlxFrame;
import flixel.animation.FlxAnimation;
import openfl.geom.Rectangle;
import funkin.backend.utils.XMLUtil.AnimData;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

using StringTools;

class CharacterAnimButton extends UIButton {
	public var anim:String = null;
	public var valid:Bool = true;
	public var data:AnimData = null;
	public var parent:CharacterAnimsWindow;

	public var animationDisplayBG:UISliceSprite;
	public var nameTextBox:UITextBox;
	public var animTextBox:UIAutoCompleteTextBox;
	public var positionXStepper:UINumericStepper;
	public var positionYStepper:UINumericStepper;
	public var fpsStepper:UINumericStepper;
	public var loopedCheckbox:UICheckbox;
	public var indicesTextBox:UITextBox;
	public var XYComma:UIText;

	public var editButton:UIButton;
	public var editIcon:FlxSprite;

	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;
	public var ghostButton:UIButton;
	public var ghostIcon:FlxSprite;

	public var animIcon:FlxSprite;

	public var labels:Map<UISprite, UIText> = [];

	public var foldableButtons:Array<FlxSprite> = [];
	public var closed:Bool = true;

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("characterEditor.characterAnim." + id, args);

	public function new(x:Float, y:Float, animData:AnimData, parent:CharacterAnimsWindow) {
		this.anim = animData.name;
		this.data = animData;
		this.parent = parent;
		super(x,y, '${animData.name} (${animData.x}, ${animData.y})', function () {
			CharacterEditor.instance.playAnimation(this.anim);
		}, Std.int(500-16-32), 208);

		function addLabelOn(ui:UISprite, text:String, ?size:Int):UIText {
			var uiText:UIText = new UIText(ui.x, ui.y-18, 0, text, size);
			members.push(uiText); labels.set(ui, uiText);
			return uiText;
		}

		autoAlpha = autoFrames = autoFollow = false;

		frames = Paths.getFrames('editors/ui/inputbox');
		field.fieldWidth = 0; framesOffset = 9;
		field.size = 14;

		animationDisplayBG = new UISliceSprite(x+12, y+12+18+12, 128, 128, 'editors/ui/inputbox-small');
		members.push(animationDisplayBG);
		foldableButtons.push(animationDisplayBG);

		nameTextBox = new UITextBox(animationDisplayBG.x+126+16, animationDisplayBG.y, animData.name, 104, 22, false, true);
		nameTextBox.onChange = (newName:String) -> {this.changeName(newName);};
		members.push(nameTextBox);
		foldableButtons.push(nameTextBox);
		addLabelOn(nameTextBox, translate("name"), 12);

		animTextBox = new UIAutoCompleteTextBox(nameTextBox.x + 100, nameTextBox.y, animData.anim, 156, 22, false, true);
		animTextBox.onChange = (newAnim:String) -> {this.changeAnim(newAnim);};
		members.push(animTextBox);
		foldableButtons.push(animTextBox);
		addLabelOn(animTextBox, translate("anim"), 12);

		positionXStepper = new UINumericStepper(animTextBox.x, animTextBox.y+32+18, animData.x, 0.001, 2, null, null, 64, 22, true);
		positionXStepper.onChange = (text:String) -> {
			@:privateAccess positionXStepper.__onChange(text);
			this.changeOffset(positionXStepper.value, null);
		};
		members.push(positionXStepper);
		foldableButtons.push(positionXStepper);
		addLabelOn(positionXStepper, translate("position"), 12);

		members.push(XYComma = new UIText(positionXStepper.x+104-32+0, positionXStepper.y + 9, 0, ",", 18));
		foldableButtons.push(XYComma);

		positionYStepper = new UINumericStepper(positionXStepper.x+104-32+26, positionXStepper.y, animData.y, 0.001, 2, null, null, 64, 22, true);
		positionYStepper.onChange = (text:String) -> {
			@:privateAccess positionYStepper.__onChange(text);
			this.changeOffset(null, positionYStepper.value);
		};
		members.push(positionYStepper);
		foldableButtons.push(positionYStepper);

		fpsStepper = new UINumericStepper(animTextBox.x + 200 + 26, animTextBox.y, animData.fps, 0.1, 2, 1, 100, 52, 22, true);
		fpsStepper.onChange = (text:String) -> {
			@:privateAccess fpsStepper.__onChange(text);
			this.changeFPS(fpsStepper.value);
		};
		members.push(fpsStepper);
		foldableButtons.push(fpsStepper);
		addLabelOn(fpsStepper, translate("fps"), 12);

		loopedCheckbox = new UICheckbox(fpsStepper.x + 82 - 32 + 26, fpsStepper.y, "Looping?", animData.loop, 0, true);
		loopedCheckbox.onChecked = (newLooping:Bool) -> {this.changeLooping(newLooping);};
		members.push(loopedCheckbox);
		foldableButtons.push(loopedCheckbox);

		loopedCheckbox.x += 8; loopedCheckbox.y += 6;

		indicesTextBox = new UITextBox(nameTextBox.x, nameTextBox.y, CoolUtil.formatNumberRange(animData.indices.getDefault([]), ", "), 278, 22, false, true);
		indicesTextBox.onChange = (text:String) -> {
			this.changeIndicies(CoolUtil.parseNumberRange(text));
		}
		members.push(indicesTextBox);
		foldableButtons.push(indicesTextBox);
		addLabelOn(indicesTextBox, translate("indices"), 12);

		animIcon = new FlxSprite(x-(10+16), y+8).loadGraphic(Paths.image("editors/character/anim-icons"), true, 16, 12);
		animIcon.animation.add("play", [0]);
		animIcon.animation.add("error", [1]);
		// animIcon.color = 0xFFD60E0E;
		animIcon.animation.play("play");
		animIcon.antialiasing = false;
		animIcon.updateHitbox();
		members.push(animIcon);

		deleteButton = new UIButton(0, 0, null, () -> {parent.deleteAnimation(this);}, 28*2,24);
		deleteButton.frames = Paths.getFrames("editors/ui/grayscale-button");
		deleteButton.color = 0xFFAC3D3D;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(x-(10+16), y+8).loadGraphic(Paths.image("editors/deleter"));
		deleteIcon.color = 0xFFD60E0E;
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);

		editButton = new UIButton(0, 0, null, () -> {
			if (!this.closed) UIUtil.confirmUISelections(this);
			this.closed = !this.closed;
		}, 28,24);
		editButton.frames = Paths.getFrames("editors/ui/grayscale-button");
		editButton.color = 0xFFAFAA12;
		members.push(editButton);

		editIcon = new FlxSprite().loadGraphic(Paths.image('editors/character/edit-button'));
		//editIcon.color = 0xFFE8E801;
		editIcon.antialiasing = false;
		members.push(editIcon);

		ghostButton = new UIButton(0, 0, null, toggleGhost, 28, 24);
		ghostButton.frames = Paths.getFrames("editors/ui/grayscale-button");
		ghostButton.color = 0xFFADADAD;
		ghostButton.alpha = 0.5;
		members.push(ghostButton);

		ghostIcon = new FlxSprite(x-(10+16), y+8).loadGraphic(Paths.image('editors/character/ghost'), true, 16, 12);
		ghostIcon.animation.add("alive", [0]);
		ghostIcon.animation.add("dead", [1]);
		ghostIcon.animation.play("dead");
		ghostIcon.color = 0xFFADADAD;
		ghostIcon.antialiasing = false;
		ghostIcon.updateHitbox();
		members.push(ghostIcon);

		checkValid();
	}

	public inline function updateButtonsPos() {
		animIcon.follow(this, 22, (52/2) - (animIcon.height/2) + (animIcon.animation.name == "error" ? 2 : 0));
		field.follow(this, 22+16+10, (52/2) - (field.height/2) + 1);

		deleteButton.follow(this, 380, 14);
		deleteIcon.follow(deleteButton, (deleteButton.bWidth/2)-6.5, (deleteButton.bHeight/2)-6);

		editButton.follow(this, 340, 14);
		editIcon.follow(editButton, (editButton.bWidth/2)-6,  (editButton.bHeight/2)-6);

		ghostButton.follow(this, 300, 14);
		ghostIcon.follow(ghostButton, (ghostButton.bWidth/2)-8, (ghostButton.bHeight/2)-6);

		animationDisplayBG.follow(this, 16, 61);
		nameTextBox.follow(this, 158, 72);
		animTextBox.follow(this, 282, 72);

		positionXStepper.follow(this, 158, 118);
		positionYStepper.follow(this, 218, 118);
		XYComma.follow(positionXStepper, 64-24, 6);

		fpsStepper.follow(this, 282, 118);
		loopedCheckbox.follow(this, 336, 122);

		indicesTextBox.follow(this, 158, 164);

		for (ui => text in labels) {
			text.follow(ui, -(2+(ui is UICheckbox?12:0)), -(18+(ui is UICheckbox?6:0)));
			text.visible = text.active = ui.visible;
		}
	}

	public override function update(elapsed:Float) {
		bHeight = closed ? 52 : 208;

		for (button in foldableButtons)
			button.visible = button.active = !closed;

		super.update(elapsed);
	}

	public function changeName(newName:String, addToUndo:Bool = true) @:privateAccess {
		if (newName == anim) return;

		if  (parent.character.getNameList().indexOf(newName) != -1) {
			nameTextBox.label.text = anim;
			return;
		}

		var oldName:String = anim;
		if (parent.character.animateAtlas != null) {
			var animSymbol:FlxSymbolAnimation = __getAnimationSymbol();

			parent.character.animateAtlas.anim.animsMap.remove(anim);
			parent.character.animateAtlas.anim.animsMap.set(newName, animSymbol);
		} else {
			var flxAnimation:FlxAnimation = __getFlxAnimation();
			flxAnimation.name = newName;

			parent.character.animation._animations.remove(anim);
			parent.character.animation._animations.set(newName, flxAnimation);
		}

		var animData:AnimData = parent.character.animDatas[anim];
		animData.name = newName;

		parent.character.animDatas.remove(anim);
		parent.character.animDatas.set(newName, animData);

		var animOffset:FlxPoint = parent.character.animOffsets[anim];
		parent.character.animOffsets.remove(anim);
		parent.character.animOffsets.set(newName, animOffset);

		var displayFrame:{scale:Float, animBounds:Rectangle, frame:Int} = parent.displayAnimsFramesList[anim];
		parent.displayAnimsFramesList.remove(anim);
		parent.displayAnimsFramesList.set(newName, displayFrame);

		var animButton = parent.animButtons.get(this.anim);
		parent.animButtons.remove(this.anim);
		parent.animButtons.set(newName, animButton);

		this.anim = newName;
		nameTextBox.label.text = newName;
		updateText();

		if (addToUndo) CharacterEditor.undos.addToUndo(CAnimEditName(ID, oldName, newName));
	}

	public function changeAnim(newAnim:String, addToUndo:Bool = true) @:privateAccess {
		var animData:AnimData = parent.character.animDatas[anim];
		if (newAnim == animData.anim) return;

		var oldAnim:String = animData.anim;
		animData.anim = newAnim;

		if (parent.character.animateAtlas != null) 
			__refreshAnimation();
		else {
			var flxAnimation:FlxAnimation = __getFlxAnimation();
			flxAnimation.prefix = newAnim;

			refreshFlxAnimationFrames(flxAnimation, animData);

			if (valid) {
				parent.buildAnimDisplay(anim, data);
				animationDisplayBG.alpha = 1;
			} else {
				parent.removeAnimDisplay(anim);
				animationDisplayBG.alpha = 0.4;
			}
		}

		if (parent.character.getAnimName() == anim)
			CharacterEditor.instance.playAnimation(anim);

		animTextBox.label.text = newAnim;

		if (addToUndo) CharacterEditor.undos.addToUndo(CAnimEditAnim(ID, oldAnim, newAnim));
	}

	public function changeOffset(newOffsetX:Null<Float>, newOffsetY:Null<Float>, addToUndo:Bool = true) {
		var animData:AnimData = parent.character.animDatas[anim];

		if (newOffsetX != null && newOffsetY != null && newOffsetX == animData.x && newOffsetY == animData.y)
			return;
		
		var oldPosition:FlxPoint = FlxPoint.get(animData.x, animData.y);

		if (newOffsetX != null) animData.x = newOffsetX;
		if (newOffsetY != null) animData.y = newOffsetY;

		parent.character.animOffsets[anim].set(animData.x, animData.y);

		if (parent.character.getAnimName() == anim && Options.playAnimOnOffset)
			CharacterEditor.instance.playAnimation(anim);

		positionXStepper.label.text = Std.string(animData.x);
		positionYStepper.label.text = Std.string(animData.y);

		updateText();

		if (addToUndo) CharacterEditor.undos.addToUndo(CAnimEditOffset(ID, oldPosition, FlxPoint.get(animData.x, animData.y)));
	}

	public function changeFPS(newFPS:Float, addToUndo:Bool = true) @:privateAccess {
		var animData:AnimData = parent.character.animDatas[anim];
		var oldFPS:Float = animData.fps;
		animData.fps = newFPS;

		if (parent.character.animateAtlas != null) {
			var animSymbol:FlxSymbolAnimation = __getAnimationSymbol();
			animSymbol.frameRate = newFPS;
		} else {
			var flxAnimation:FlxAnimation = __getFlxAnimation();
			flxAnimation.frameRate = newFPS;
		}

		if (parent.character.getAnimName() == anim)
			CharacterEditor.instance.playAnimation(anim);

		fpsStepper.label.text = Std.string(newFPS);

		if (addToUndo) CharacterEditor.undos.addToUndo(CAnimEditFPS(ID, oldFPS, newFPS));
	}

	public function changeLooping(newLooping:Bool, addToUndo:Bool = true) @:privateAccess {
		var animData:AnimData = parent.character.animDatas[anim];

		animData.loop = newLooping;

		if (parent.character.animateAtlas != null) {
			var animSymbol:FlxSymbolAnimation = __getAnimationSymbol();
			animSymbol.instance.symbol.loop = animData.loop ? Loop : PlayOnce;
		} else {
			var flxAnimation:FlxAnimation = __getFlxAnimation();
			flxAnimation.looped = animData.loop;
		}

		if (parent.character.getAnimName() == anim)
			CharacterEditor.instance.playAnimation(anim);

		loopedCheckbox.checked = newLooping;

		if (addToUndo) CharacterEditor.undos.addToUndo(CAnimEditLooping(ID, newLooping));
	}

	public function changeIndicies(indicies:Array<Int>, addToUndo:Bool = true) @:privateAccess {
		var animData:AnimData = parent.character.animDatas[anim];
		var oldIndices:Array<Int> = animData.indices.copy();

		var maxFrameIndex = parent.character.frames.frames.length - 1;
		for (index in indicies) {
			if (index < 0 || index > maxFrameIndex) {
				Logs.trace('[changeIndicies] Invalid frame index $index (max allowed: $maxFrameIndex). Change aborted.', ERROR, RED);
				return;
			}
		}

		animData.indices = indicies;

		try {
			__refreshAnimation();

			if (parent.character.getAnimName() == anim)
				CharacterEditor.instance.playAnimation(anim);
		} catch (e:Dynamic) {
			Logs.trace('[changeIndicies] Error occurred: $e. Reverting to old indices.', WARNING, YELLOW);

			animData.indices = oldIndices;
			__refreshAnimation();
			if (parent.character.getAnimName() == anim)
				CharacterEditor.instance.playAnimation(anim);

			return;
		}

		indicesTextBox.label.text = animData.indices.join(", ");

		if (addToUndo)
			CharacterEditor.undos.addToUndo(CAnimEditIndices(ID, oldIndices, indicies));
	}


	public inline function refreshFlxAnimationFrames(flxAnimation:FlxAnimation, animData:AnimData) @:privateAccess {
		try {
			if (animData.indices.length > 0) {
				var frameIndices:Array<Int> = new Array<Int>();
				parent.character.animation.byIndicesHelper(frameIndices, flxAnimation.prefix, animData.indices, "");

				flxAnimation.frames = frameIndices;
			} else {
				final animFrames:Array<FlxFrame> = new Array<FlxFrame>();
				parent.character.animation.findByPrefix(animFrames, flxAnimation.prefix);

				final frameIndices:Array<Int> = [];
				parent.character.animation.byPrefixHelper(frameIndices, animFrames, flxAnimation.prefix);

				flxAnimation.frames = frameIndices;
			}

			if (flxAnimation.frames.length <= 0) invalidate();
			else validate();
		} catch (e) {
			trace('ERROR REFRESHING FLXANIMATION FRAMES: $e');
			invalidate();
		}
	}

	public inline function refreshSymbolKeyFrames(symbol:FlxSymbolAnimation, animData:AnimData) @:privateAccess {
		var wasRefreshed:Bool = false;

		try {
			parent.character.animateAtlas.anim.animsMap.remove(animData.name);
			if (animData.indices.length > 0)
				parent.character.animateAtlas.anim.addBySymbolIndices(animData.name, animData.anim, animData.indices, animData.fps, animData.loop);
			else 
				parent.character.animateAtlas.anim.addBySymbol(animData.name, animData.anim, animData.fps, animData.loop);
			wasRefreshed = parent.character.animateAtlas.anim.animsMap.exists(animData.name);
			if (!wasRefreshed) __getAnimationSymbol();
		} catch (e) {
			trace('ERROR REFRESHING SYMBOL FRAMES: $e');
		}

		validate(wasRefreshed);
	}

	public function toggleGhost() {
		if (valid && parent.ghosts.indexOf(anim) == -1) {
			FlxG.sound.play(Paths.sound(Flags.DEFAULT_CHARACTER_GHOSTENABLE_SOUND)); 
			parent.ghosts.push(anim);
			ghostIcon.animation.play("alive", true);
			ghostIcon.color = 0xFFFFFFFF;
		} else {
			FlxG.sound.play(Paths.sound(Flags.DEFAULT_CHARACTER_GHOSTDISABLE_SOUND));
			parent.ghosts.remove(anim);
			ghostIcon.animation.play("dead", true);
			ghostIcon.color = 0xFFADADAD;
		}
	}

	public override function draw() {
		updateButtonsPos();
		super.draw();

		if (!closed && parent.displayAnimsFramesList.exists(anim)) {
			var displayData:{frame:Int, scale:Float, animBounds:Rectangle} = parent.displayAnimsFramesList.get(anim);
			parent.displayWindowSprite.frame = parent.displayWindowSprite.frames.frames[displayData.frame];

			parent.displayWindowSprite.scale.x = parent.displayWindowSprite.scale.y = displayData.scale;
			parent.displayWindowSprite.updateHitbox();

			parent.displayWindowSprite.follow(
				this, 16+(128/2)-((parent.displayWindowSprite.frame.sourceSize.x*displayData.scale)/2),
				8+32+8+2+11+(128/2)-((parent.displayWindowSprite.frame.sourceSize.y*displayData.scale)/2)
			);
			parent.displayWindowSprite.draw();
		}
	}

	public function updateText() {
		field.applyMarkup(
			'${anim} ' + (valid ? '(${parent.character.animOffsets[anim].x}, ${parent.character.animOffsets[anim].y})' : "|(Invalid Animation!!!)|"),
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFF29797), "|")]);
	}

	public function validate(isValid:Bool = true) {
		var wasValid:Bool = valid;
		this.valid = isValid;

		animIcon.animation.play(valid ? "play" :"error");
		color = valid ? 0xFFFFFFFF : 0xFFD60E0E;

		ghostIcon.visible = ghostButton.visible = isValid;
		XYComma.alpha = isValid ? 1 : 0.4;
		for (uiElement in [nameTextBox, positionXStepper, positionYStepper, fpsStepper, loopedCheckbox, indicesTextBox]) {
			uiElement.selectable = isValid;
			if (labels[uiElement] != null)
				labels[uiElement].alpha = isValid ? 1 : 0.4;
		}
		if (!valid) toggleGhost();
		updateText();

		if (!wasValid && isValid && CharacterEditor.instance.characterFakeAnim == anim)
			CharacterEditor.instance.playAnimation(this.anim);
	}

	public inline function invalidate()
		validate(false);

	public inline function __getFlxAnimation():Null<FlxAnimation> @:privateAccess {
		if (!parent.character.animation._animations.exists(anim)) {
			final flxanim = new FlxAnimation(parent.character.animation, anim, [], data.fps, data.loop);
			flxanim.prefix = data.anim; // sobbing

			parent.character.animation._animations.set(anim, flxanim);
			parent.character.animDatas.set(anim, data);
		}
		return parent.character.animation._animations[anim];
	}

	public inline function __getAnimationSymbol():Null<FlxSymbolAnimation> @:privateAccess {
		if (!parent.character.animateAtlas.anim.animsMap.exists(anim))
			XMLUtil.addAnimToSprite(parent.character, data);
		return parent.character.animateAtlas.anim.animsMap[anim];
	}


	@:noCompletion function __refreshAnimation() @:privateAccess {
		if (parent.character.animateAtlas != null) refreshSymbolKeyFrames(__getAnimationSymbol(), data);
		else refreshFlxAnimationFrames(__getFlxAnimation(), data);

		if (valid) {
			parent.buildAnimDisplay(anim, data);
			animationDisplayBG.alpha = 1;
		} else {
			parent.removeAnimDisplay(anim);
			animationDisplayBG.alpha = 0.4;
		}
	}

	public inline function checkValid()
		__refreshAnimation();
}