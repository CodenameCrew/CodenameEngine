package funkin.editors.charter;

import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.backend.system.Conductor;
import funkin.editors.charter.Charter.ICharterSelectable;

class CharterNote extends UISprite implements ICharterSelectable {
	var angleTween:FlxTween;
	var __doAnim:Bool = false;
	var __animSpeed:Float = 1;
	var __susInstaLerp:Bool = false;

	private static var colors:Array<FlxColor> = [
		0xFFC24B99,
		0xFF00FFFF,
		0xFF12FA05,
		0xFFF9393F
	];

	public var sustainSpr:UISprite;
	public var tempSusLength:Float = 0;
	public var sustainDraggable:Bool = false;

	public var typeText:UIText;

	public var selected:Bool = false;
	public var draggable:Bool = true;

	static var noteTypeTexts:Array<UIText> = [];

	public function new() {
		super();

		antialiasing = true; ID = -1;
		loadGraphic(Paths.image('editors/charter/note'), true, 157, 154);
		animation.add("note", [for(i in 0...frames.frames.length) i], 0, true);
		animation.play("note");
		this.setUnstretchedGraphicSize(40, 40, false);

		sustainSpr = new UISprite(10, 20);
		sustainSpr.makeSolid(1, 1, -1, false, "note-sustain");
		sustainSpr.scale.set(10, 0);
		members.push(sustainSpr);

		this.type = 0;

		cursor = sustainSpr.cursor = CLICK;
		moves = false;
	}

	public override function updateButtonHandler() {
		__rect.set(x, y, 40, 40);
		UIState.state.updateRectButtonHandler(this, __rect, onHovered);
	}

	public var step:Float;
	public var id:Int;
	public var susLength:Float;
	public var type(default, set):Null<Int> = null;
	public var typeVisible:Bool = true;
	public var typeAlpha:Float = 1;

	function set_type(v:Null<Int>) {
		if(v != this.type) {
			if(noteTypeTexts[v] == null || noteTypeTexts[v].graphic.isDestroyed) {
				noteTypeTexts[v] = new UIText(x, y, 0, Std.string(v));
				noteTypeTexts[v].exists = v != 0;
				//noteTypeTexts[v].layer = (Charter.instance != null) ? Charter.instance.textLayer : null;
			}

			typeText = noteTypeTexts[v];
		}
		return this.type = v;
	}

	public var strumLine:CharterStrumline;
	public var strumLineID(get, default):Int = -1;
	public function get_strumLineID():Int
		return strumLineID = (strumLine == null ? strumLineID : Charter.instance.strumLines.members.indexOf(strumLine));

	public var snappedToGrid:Bool = true;

	public var fullID(get, never):Int; // instead of %4 get fullID (for mousepos stuff)
	public function get_fullID():Int
		return strumLine.startingID + id;

	public function updatePos(step:Float, id:Int, susLength:Float = 0, ?type:Int = 0, ?strumLine:CharterStrumline = null) {
		this.step = step;
		this.id = id;
		this.susLength = Math.max(susLength, 0);
		this.type = type;
		if (strumLine != null) this.strumLine = strumLine;

		sustainSpr.exists = susLength != 0;

		y = step * 40;

		if (angleTween != null) angleTween.cancel();

		var destAngle:Float = switch(animation.curAnim.curFrame = (id % 4)) {
			case 0: 270;
			case 1: 180;
			case 2: 0;
			case 3: 90;
			default: 0; // how is that even possible
		};

		sustainSpr.color = colors[animation.curAnim.curFrame];

		if (!__doAnim) {
			angle = destAngle;
			return;
		}

		if (angle == destAngle) return;

		if(angleTween != null)
			angleTween.cancel();

		destAngle = CoolUtil.getClosestAngle(angle, destAngle);
		
		angleTween = FlxTween.angle(this, angle, destAngle, (2/3)/__animSpeed, {ease: function(t) {
			return ((Math.sin(t * Math.PI) * 0.35) * 3 * t * Math.sqrt(1 - t)) + t;
		}});
	}

	public override function kill() {
		if (angleTween != null) {
			angleTween.cancel();
			angleTween = null;
			angle = switch(animation.curAnim.curFrame = (id % 4)) {
				case 0: 270;
				case 1: 180;
				case 2: 0;
				case 3: 90;
				default: 0; // how is that even possible
			};
			__doAnim = false;
		}
		super.kill();
	}

	var __passed:Bool = false;
	public override function update(elapsed:Float) {
		super.update(elapsed);

		if(susLength != 0) {
			var sprLength:Float = (40 * (susLength+tempSusLength)) + ((susLength+tempSusLength) != 0 ? (height/2) : 0);
			sustainSpr.scale.set(10, __susInstaLerp ? sprLength : CoolUtil.fpsLerp(sustainSpr.scale.y, sprLength, 1/2));
			sustainSpr.updateHitbox();
			sustainSpr.follow(this, 15, 20);
		}

		sustainDraggable = false;
		if (!hovered && susLength != 0) {
			sustainSpr.updateSpriteRect();
			sustainDraggable = UIState.state.isOverlapping(sustainSpr, @:privateAccess sustainSpr.__rect);
		}

		if (__passed != (__passed = step < Conductor.curStepFloat + (Options.songOffsetAffectEditors ? (Conductor.songOffset / Conductor.stepCrochet) : 0))) {
			if (__passed && FlxG.sound.music.playing) {
				Charter.instance.playHitsound(strumLineID);
			}
		}

		if (strumLine != null) {
			var isVisible = strumLine.strumLine.visible;
			sustainSpr.alpha = alpha = !isVisible ? (__passed ? 0.2 : 0.4) : (__passed ? 0.6 : 1);
			typeAlpha = !isVisible ? (__passed ? 0.4 : 0.6) : (__passed ? 0.8 : 1);
		}

		colorTransform.redMultiplier = colorTransform.greenMultiplier = colorTransform.blueMultiplier = selected ? 0.75 : 1;
		colorTransform.redOffset = colorTransform.greenOffset = selected ? 96 : 0;
		colorTransform.blueOffset = selected ? 168 : 0;

		__doAnim = true;
	}

	public function handleSelection(selectionBox:UISliceSprite):Bool {
		var minX = Std.int(selectionBox.x / 40);
		var minY = (selectionBox.y / 40) - 1;
		var maxX = Std.int(Math.ceil((selectionBox.x + selectionBox.bWidth) / 40));
		var maxY = ((selectionBox.y + selectionBox.bHeight) / 40);

		return this.fullID >= minX && this.fullID < maxX && this.step >= minY && this.step < maxY;
	}

	public function handleDrag(change:FlxPoint) {
		var newStep = CoolUtil.bound(step + change.x, 0, Charter.instance.__endStep-1);
		var newID:Int = Std.int(FlxMath.bound(fullID + Std.int(change.y), 0, Charter.instance.strumLines.totalKeyCount-1));
		var newStrumLine = Charter.instance.strumLines.getStrumlineFromID(newID);

		updatePos(newStep, (newID - newStrumLine.startingID) % newStrumLine.keyCount, susLength, type, newStrumLine);
	}

	public override function draw() {
		if (snappedToGrid)
			x = (strumLine != null ? strumLine.x : 0) + (id % (strumLine != null ? strumLine.keyCount : 4)) * 40;

		drawMembers();
		drawSuper();
		drawNoteTypeText();
	}

	public inline function drawNoteTypeText() {
		if(typeText.exists && typeText.visible && typeVisible) {
			typeText.alpha = typeAlpha;
			typeText.follow(this, 20 - (typeText.frameWidth/2), 20 - (typeText.frameHeight/2));
			typeText.draw();
		}
	}
}