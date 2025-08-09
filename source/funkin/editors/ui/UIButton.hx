package funkin.editors.ui;

class UIButton extends UISliceSprite {
	public var callback:Void->Void = null;
	public var field:UIText;
	public var shouldPress = true;
	public var hasBeenPressed = false;

	public var autoFrames:Bool = true;
	public var autoFollow:Bool = true;

	public override function new(x:Float, y:Float, text:String, callback:Void->Void, w:Int = 120, h:Int = 32) {
		super(x, y, w, h, 'editors/ui/button');
		this.callback = callback;
		if(text != null) {
			members.push(field = new UIText(x, y, w, text));
			field.alignment = CENTER;
			field.fieldWidth = w;
		}

		cursor = CLICK;
	}

	public override function resize(w:Int, h:Int) {
		super.resize(w, h);
		if (field != null && autoFollow) field.fieldWidth = w;
	}

	public override function onHovered() {
		super.onHovered();
		if (FlxG.mouse.justPressed) {
			hasBeenPressed = true;
			FlxG.sound.play(Paths.sound(Flags.DEFAULT_EDITOR_BUTTONCLICK_SOUND));
		}
		if (FlxG.mouse.justReleased && callback != null && shouldPress && hasBeenPressed) {
			callback();
			hasBeenPressed = false;
		}
	}

	public override function update(elapsed:Float) {
		if (autoFollow && field != null) field.follow(this, 0, (bHeight - field.height) / 2);
		if (!hovered && hasBeenPressed && FlxG.mouse.justReleased) hasBeenPressed = false;
		if (autoAlpha) {
			alpha = selectable ? 1 : 0.4;
			if(field != null) field.alpha = alpha;
		}
		super.update(elapsed);
	}

	public override function draw() {
		setFrameOffset();
		super.draw();
	}

	public function setFrameOffset() {
		framesOffset = hovered ? (pressed ? 18 : 9) : 0;
	}
}