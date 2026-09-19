package funkin.editors.stage.elements;

import flixel.util.FlxColor;
import haxe.xml.Access;

using flixel.util.FlxColorTransformUtil;

class StageElementButton extends UIButton {
	public var xml:Access;

	public var editButton:UIButton;
	public var editIcon:FlxSprite;

	public var visibilityButton:UIButton;
	public var visibilityIcon:FlxSprite;

	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public var isHidden:Bool = false;
	public var hasAdvancedEdit:Bool = false;

	public var selected:Bool = false;

	public var tagColor:UISliceSprite;

	public function new(x:Float,y:Float, xml:Access) {
		this.xml = xml;
		super(x,y, getInfoText(), function () {
			onSelect();
		}, StageEditor.SPRITE_WINDOW_WIDTH, StageEditor.SPRITE_WINDOW_BUTTON_HEIGHT);
		autoAlpha = false;

		tagColor = new UISliceSprite(x, y, 10, StageEditor.SPRITE_WINDOW_BUTTON_HEIGHT, 'editors/ui/button');
		tagColor.alpha = 1; // Make entire sprite transparent
		tagColor.selectable = false;
		tagColor.active = false;
		//members.push(tagColor);

		topAlpha = middleAlpha = bottomAlpha = 0.7;

		field.alignment = LEFT;

		visibilityButton = new UIButton(x+282+17, y, null, function () {
			onVisiblityToggle();
		}, 32);
		visibilityButton.autoAlpha = false;
		members.push(visibilityButton);

		visibilityIcon = new FlxSprite(visibilityButton.x + 8, visibilityButton.y + 8).loadGraphic(Paths.image('editors/stage/visible-icon'), true, 16, 16);
		visibilityIcon.animation.add("visible", [0]);
		visibilityIcon.animation.add("invisible", [1]);
		visibilityIcon.animation.play("visible");
		visibilityIcon.antialiasing = false;
		visibilityIcon.updateHitbox();
		members.push(visibilityIcon);

		editButton = new UIButton(visibilityButton.x+32+17, y, null, function () {
			onEdit();
		}, 32);
		editButton.frames = Paths.getFrames("editors/ui/grayscale-button");
		editButton.color = FlxColor.YELLOW;
		editButton.autoAlpha = false;
		members.push(editButton);

		editIcon = new FlxSprite(editButton.x + 8, editButton.y + 10).loadGraphic(Paths.image('editors/stage/edit-button'), true, 16, 16);
		editIcon.animation.add("edit", [0]);
		editIcon.animation.add("advanced", [1]);
		editIcon.antialiasing = false;
		members.push(editIcon);

		deleteButton = new UIButton(editButton.x+32+17, y, null, function () {
			onDelete();
		}, 32);
		deleteButton.color = FlxColor.RED;
		deleteButton.autoAlpha = false;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(deleteButton.x + 8, deleteButton.y + 8).loadGraphic(Paths.image('editors/stage/trash-icon'));
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);

		setEditNormal();
	}

	public function setEditNormal() {
		editIcon.animation.play("edit");
		editButton.color = FlxColor.YELLOW;
	}

	public function setEditAdvanced() {
		editIcon.animation.play("advanced");
		editButton.color = 0xFFFF5B0F;
	}


	var _lastSelected:Bool = false;

	public override function update(elapsed:Float) {
		editButton.selectable = visibilityButton.selectable = deleteButton.selectable = selectable;
		editButton.shouldPress = visibilityButton.shouldPress = deleteButton.shouldPress = shouldPress;

		hovered = !deleteButton.hovered;
		updatePos();
		super.update(elapsed);
		field.x += 12;

		if(hasAdvancedEdit) {
			if(FlxG.keys.pressed.SHIFT) {
				setEditAdvanced();
			} else {
				setEditNormal();
			}
		}

		tagColor.color = color;
	}

	//private var _lastHovered:Bool = false;

	public override function draw() {
		//if(_lastHovered != (_lastHovered = hovered && !pressed)) {
		if(_lastSelected != (_lastSelected = selected)) {
			updateColorTransform();
		}
		super.draw();
	}

	/*public override function setFrameOffset() {
		var _frameOffset = 0;
		if(selected) _frameOffset = 9;
		if(hovered && pressed) _frameOffset = 18;
		framesOffset = _frameOffset;
	}*/

	public override function updateColorTransform() {
		super.updateColorTransform();

		if(selected) {
			useColorTransform = true;
			colorTransform.setOffsets(70, 70, 70, 0);
		} else {
			colorTransform.setOffsets(0, 0, 0, 0);
		}
	}

	public function updateInfo() {
		field.text = getInfoText();

		visibilityIcon.animation.play(isHidden ? "invisible" : "visible");
		visibilityIcon.alpha = !isHidden ? 1 : 0.5;
	}

	public function updatePos() {
		// buttons
		var spacing = 8;
		var buttonY = y + (bHeight - 32) / 2;
		deleteButton.x = bWidth - deleteButton.bWidth - spacing;
		deleteButton.y = buttonY;
		editButton.x = deleteButton.x - editButton.bWidth - spacing;
		editButton.y = buttonY;
		visibilityButton.x = editButton.x - visibilityButton.bWidth - spacing;
		visibilityButton.y = buttonY;
		//deleteButton.x = (editButton.x = (visibilityButton.x = (x+282+17))+32+17)+32+17;
		//deleteButton.y = editButton.y = visibilityButton.y = y;
		// icons
		visibilityIcon.x = visibilityButton.x + 8; visibilityIcon.y = visibilityButton.y + 8;
		editIcon.x = editButton.x + 8; editIcon.y = editButton.y + 8;
		deleteIcon.x = deleteButton.x + 8; deleteIcon.y = deleteButton.y + 8;

		tagColor.x = x;// + bWidth - tagColor.bWidth;
		tagColor.y = y;
	}

	public function getSprite():FunkinSprite {
		return null;
	}

	public function canRender() {
		return true;
	}

	public function getName():String {
		return "UNKNOWN";
	}

	public function onSelect() {
		// TODO: implement
	}

	public function onVisiblityToggle() {
		// TODO: implement
	}

	public function onEdit() {
		// TODO: implement
	}

	public function onDelete() {
		// TODO: implement
	}

	public function getPos():FlxPoint {
		return FlxPoint.get(-1, -1);
	}

	public function getInfoText():String {
		var pos = getPos();
		var text = '${getName()} (${CoolUtil.quantize(pos.x, 100)}, ${CoolUtil.quantize(pos.y, 100)})';
		var sprite = getSprite();
		if(sprite != null) {
			var scaleText = TU.getRaw("stageElement.scale");
			var scrollText = TU.getRaw("stageElement.scroll");
			text += '\n${scaleText.format([CoolUtil.quantize(sprite.scale.x, 100), CoolUtil.quantize(sprite.scale.y, 100)])}';
			text += '\n${scrollText.format([CoolUtil.quantize(sprite.scrollFactor.x, 100), CoolUtil.quantize(sprite.scrollFactor.y, 100)])}';
		}
		pos.put();
		return text;
	}
}