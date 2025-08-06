package funkin.editors.ui;

import flixel.util.typeLimit.OneOfTwo;

class UIRadioButton extends UISprite {
	public var checked:Bool = false;
	public var onChecked:Bool->Void = null;

	public var field:UIText;
	public var check:FlxSprite;

	public var parent:OneOfTwo<UIWindow, UISubstateWindow> = null;
	public var forID:String = null;

	public function new(x:Float, y:Float, text:String, checked:Bool = false, forID:String = null, w:Int = 0) {
		super(x, y);
		this.forID = forID;
		loadGraphic(Paths.image('editors/ui/radiobutton'), true, 20, 20);
		for(frame=>name in ["normal", "hover", "pressed", "selected"])
			animation.add(name, [frame], 0, false);

		this.checked = checked;
		this.targetScale = checked ? 1 : 0;

		field = new UIText(x, y, w, text);
		check = new FlxSprite().loadGraphicFromSprite(this);
		check.animation.play("selected");
		check.scale.set(targetScale, targetScale);

		members.push(check);
		members.push(field);

		cursor = CLICK;

		autoAlpha = false;
	}

	public var targetScale:Float = 1;

	public override function update(elapsed:Float) {
		// ANIMATION HANDLING
		animation.play(hovered ? (pressed ? "pressed" : "hover") : "normal");

		// CHECKMARK HANDLING
		if(autoAlpha)
			check.alpha = checked ? 1 : 0;
		check.scale.x = CoolUtil.fpsLerp(check.scale.x, targetScale, 0.25);
		check.scale.y = CoolUtil.fpsLerp(check.scale.y, targetScale, 0.25);

		// POSITION HANDLING
		updatePositions();

		super.update(elapsed);
	}

	public inline function updatePositions() {
		check.follow(this);
		field.follow(this, 25, 0);
	}

	public override function draw() {
		updatePositions();
		super.draw();
	}

	public override function onHovered() {
		super.onHovered();
		if (FlxG.mouse.justReleased) {
			// clicked
			checked = !checked;
			check.scale.set(1.25, 1.25);
			targetScale = checked ? 1 : 0;

			if (Options.editorSFX)
				CoolUtil.playMenuSFX(checked ? CHECKED : UNCHECKED, 0.5);

			if(parent != null) {
				var members = (parent is UIWindow) ? (cast(parent, UIWindow)).members : (cast(parent, UISubstateWindow)).members;
				var radios:Array<UIRadioButton> = cast members.filter((o) -> o is UIRadioButton && o != this);
				//trace(radios);
				for(radio in radios) {
					if(radio.forID != null && radio.forID == forID) {
						radio.checked = false;
						radio.targetScale = 0;
					}
				}
			}

			if (onChecked != null)
				onChecked(checked);
		}
	}

	public override function updateButton() {
		__rect.set(x, y, field.width + 30, field.height > height ? field.height : height);
		UIState.state.updateRectButtonHandler(this, __rect, onHovered);
	}

	public override function toString() {
		return "RadioButton(" + field.text + ", " + checked + ", " + forID + ")";
	}
}