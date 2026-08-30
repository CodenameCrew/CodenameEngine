package funkin.editors.charter;

class CharterDeleteAnim extends CharterNote {
	public var garbageIcon:FlxSprite;
	public var garbageCircle:FlxSprite;

	public var deleteNotes:Array<{note:CharterNote, time:Float}> = [];
	public var deleteTime:Float = .4;

	public function new() {
		super();

		sustainSpr.color = 0xFF630000; color = 0xFF605A5A;
		snappedToGrid = selectable = autoAlpha = false;
		@:privateAccess __animSpeed = 1.25;

		garbageIcon = new FlxSprite().loadGraphic(Paths.image("editors/deleter"));
		garbageIcon.color = 0xFF880000;
		garbageIcon.cameras = [Charter.instance.uiCamera];

		garbageCircle = new FlxSprite().loadGraphic(Paths.image("editors/deleter circle"));
		garbageCircle.color = 0xFF880000; garbageCircle.alpha = .6;
		garbageCircle.cameras = [Charter.instance.uiCamera];
	}

	var __garbageAlpha:Float = 0;
	var __deletionTimer:Float = .1;
	@:noCompletion var __mousePos:FlxPoint = FlxPoint.get();
	public override function update(elapsed:Float) {
		for (deleteData in deleteNotes) {
			deleteData.time -= elapsed;
			if (deleteData.time < 0) deleteNotes.remove(deleteData);
		}

		if (FlxG.mouse.justPressedRight) __deletionTimer = .1;
		__deletionTimer -= elapsed;

		__garbageAlpha = FlxMath.lerp(__garbageAlpha, FlxG.mouse.pressedRight && __deletionTimer <= 0 ? 1 : 0, 1/10);

		FlxG.mouse.getWorldPosition(Charter.instance.uiCamera, __mousePos);
		if (FlxG.mouse.pressedRight && __deletionTimer <= 0) {
			garbageIcon.setPosition(
				__mousePos.x + garbageIcon.width/2 + (.65*FlxG.random.float(-1, 1)) + 2,
				__mousePos.y - garbageIcon.height + (.65*FlxG.random.float(-1, 1)) - 8
			);

			garbageCircle.setPosition(
				__mousePos.x - garbageCircle.width/2,
				(__mousePos.y - garbageCircle.height/2) + 2
			);
		}

		garbageIcon.alpha = __garbageAlpha;
		garbageCircle.alpha = __garbageAlpha*.6;
	}

	static var __stupidScriptParamArray:Array<CharterNote> = [];

	static function callScriptOnNotes(event:String, note1:CharterNote, note2:CharterNote) {
		if (Charter.instance != null) {
			__stupidScriptParamArray[0] = note1;
			__stupidScriptParamArray[1] = note2;
			Charter.instance.stateScripts.call(event, __stupidScriptParamArray);
		}
	}

	public override function draw() @:privateAccess {
		// kill me
		final __lastFrame:flixel.graphics.frames.FlxFrame = this.frame;
		final __lastSX:Float = this.scale.x;
		final __lastSY:Float = this.scale.y;
		final __lastW:Float = this.width;
		final __lastH:Float = this.height;
		final __lastOX:Float = this.offset.x;
		final __lastOY:Float = this.offset.y;
		final __lastRX:Float = this.origin.x;
		final __lastRY:Float = this.origin.y;
		final __lastFX:Float = this.frameOffset.x;
		final __lastFY:Float = this.frameOffset.y;
		final __lastColor:flixel.util.FlxColor = this.color;

		for (deleteData in deleteNotes) {
			y = deleteData.note.y + (deleteData.time>deleteTime*.5 ? (deleteData.time/deleteTime)*FlxG.random.float(-1.1, 1.1) : 0); // lunar when no shake :((
			x = deleteData.note.x + (deleteData.time>deleteTime*.5 ? (deleteData.time/deleteTime)*FlxG.random.float(-1.1, 1.1) : 0); // lunar when no shake :((
			angle = 0;
			setSize(deleteData.note.width, deleteData.note.height);
			scale.set(deleteData.note.scale.x, deleteData.note.scale.y);
			offset.set(deleteData.note.offset.x, deleteData.note.offset.y);
			origin.set(deleteData.note.origin.x, deleteData.note.origin.y);
			frameOffset.set(deleteData.note.frameOffset.x, deleteData.note.frameOffset.y);

			if (!deleteData.note.noDefaultAnims) {
				frame = __lastFrame;
				angle = deleteData.note.angle;
				animation.curAnim.curFrame = 3;
				color = __lastColor;
			} else {
				frame = deleteData.note.frame;
			}
			alpha = 1;

			sustainSpr.scale.set(10, (40 * deleteData.note.susLength) + (height/2));
			sustainSpr.updateHitbox(); sustainSpr.follow(this, 15, 20);
			sustainSpr.exists = deleteData.note.susLength != 0; sustainSpr.alpha = .8;

			type = deleteData.note.type;
			typeAlpha = .4;
			//typeText.text = Std.string(deleteData.note.type);
			//typeText.exists = deleteData.note.type != 0; typeAlpha = .4;
			//typeText.follow(this, 20 - (typeText.frameWidth/2), 20 - (typeText.frameHeight/2));

			var mult = FlxEase.quadInOut(deleteData.time/deleteTime);

			for (member in [this, sustainSpr])
				member.alpha *= mult;
			typeAlpha *= mult;

			callScriptOnNotes('onCharterNoteDeleteUpdate', deleteData.note, this);

			super.draw();
		}

		this.frame = __lastFrame;
		this.scale.set(__lastSX, __lastSY);
		this.setSize(__lastW, __lastH);
		this.offset.set(__lastOX, __lastOY);
		this.origin.set(__lastRX, __lastRY);
		this.frameOffset.set(__lastFX, __lastFY);
		this.color = __lastColor;

		if (garbageIcon.alpha > 0) garbageIcon.draw();
		if (garbageCircle.alpha > 0) garbageCircle.draw();
	}

	public override function destroy() {
		super.destroy();
		__mousePos.put();
	}
}