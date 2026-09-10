package funkin.editors.charter;

class CharterNoteHoverer extends CharterNote {
	public var showHoverer:Bool = false;

	public function new() {
		super();

		snappedToGrid = selectable = autoAlpha = false; visible = sustainSpr.visible = false;
		@:privateAccess __animSpeed = 1.25; typeVisible = false; alpha = 0.4;
	}

	@:noCompletion var __mousePos:FlxPoint = FlxPoint.get();
	public override function update(elapsed:Float) @:privateAccess {
		FlxG.mouse.getWorldPosition(FlxG.camera, __mousePos);

		switch (Charter.instance.gridActionType) {
			case NONE:
				var inBoundsY:Bool = (__mousePos.y > 0 && __mousePos.y < (Charter.instance.__endStep)*40);
				if ((__mousePos.x > 0 && __mousePos.x < Charter.instance.strumLines.totalKeyCount * 40 && inBoundsY) && showHoverer) {
					step = CoolUtil.bound(FlxG.keys.pressed.SHIFT ? ((__mousePos.y-20) / 40) : Charter.instance.quantStep(__mousePos.y/40), 0, Charter.instance.__endStep-1);
					id = Math.floor(__mousePos.x / 40); y = step * 40; x = id * 40; visible = true; sustainSpr.visible = typeVisible = false;
					if (!noDefaultAnims)
						angle = switch(animation.curAnim.curFrame = ((id - Charter.instance.strumLines.getStrumlineFromID(id).startingID) % 4)) {
							case 0: -90;
							case 1: 180;
							case 2: 0;
							case 3: 90;
							default: 0; // how is that even possible
						};
				} else
					visible = false;
			case NOTE_DRAG:
				visible = sustainSpr.visible = typeVisible = true; __doAnim = false;
			default:
				visible = sustainSpr.visible = typeVisible = false; __doAnim = false;
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

		switch (Charter.instance.gridActionType) {
			case NONE:
				super.draw();
			case NOTE_DRAG:
				if (Charter.instance.gridActionType == NOTE_DRAG) {
					var verticalChange:Float = (__mousePos.y - Charter.instance.dragStartPos.y) / 40;
					var horizontalChange:Int = CoolUtil.floorInt((__mousePos.x - (Std.int(Charter.instance.dragStartPos.x / 40) * 40)) / 40);

					for (s in Charter.selection) {
						if (s != null && s.draggable && s is CharterNote) {
							var draggingNote:CharterNote = cast s;
							y = (draggingNote.step + verticalChange);
							if (!FlxG.keys.pressed.SHIFT)
								y -= ((draggingNote.step + verticalChange)
									- Charter.instance.quantStepRounded(draggingNote.step+verticalChange, verticalChange > 0 ? 0.35 : 0.65));
							y *= 40;
							var newID:Int = CoolUtil.boundInt(draggingNote.fullID + horizontalChange, 0, Charter.instance.strumLines.totalKeyCount-1);
							x = (id=newID) * 40; y = CoolUtil.bound(y, 0, (Charter.instance.__endStep*40) - height);

							angle = 0;
							setSize(draggingNote.width, draggingNote.height);
							scale.set(draggingNote.scale.x, draggingNote.scale.y);
							offset.set(draggingNote.offset.x, draggingNote.offset.y);
							origin.set(draggingNote.origin.x, draggingNote.origin.y);
							frameOffset.set(draggingNote.frameOffset.x, draggingNote.frameOffset.y);
							color = draggingNote.color;
							if (!draggingNote.noDefaultAnims) {
								frame = __lastFrame;
								angle = switch(animation.curAnim.curFrame = (draggingNote.id % 4)) {
									case 0: -90;
									case 1: 180;
									case 2: 0;
									case 3: 90;
									default: 0; // how is that even possible
								};
							} else {
								frame = draggingNote.frame;
							}

							sustainSpr.scale.set(10, (40 * draggingNote.susLength) + (height/2));
							sustainSpr.color = draggingNote.noDefaultAnims ? draggingNote.sustainSpr.color : CharterNote.colors[animation.curAnim.curFrame];
							sustainSpr.updateHitbox(); sustainSpr.alpha = alpha; sustainSpr.follow(this, 15, 20);
							sustainSpr.exists = draggingNote.susLength != 0;

							type = draggingNote.type;
							//typeText.text = Std.string(draggingNote.type);
							//typeText.exists = draggingNote.type != 0;
							typeText.follow(this, 20 - (typeText.frameWidth/2), 20 - (typeText.frameHeight/2));

							super.draw();
						}
					}
				}
			default: // do nothing
		}
		this.frame = __lastFrame;
		this.scale.set(__lastSX, __lastSY);
		this.setSize(__lastW, __lastH);
		this.offset.set(__lastOX, __lastOY);
		this.origin.set(__lastRX, __lastRY);
		this.frameOffset.set(__lastFX, __lastFY);
		this.color = __lastColor;
	}

	public override function destroy() {
		super.destroy();
		__mousePos.put();
	}
}