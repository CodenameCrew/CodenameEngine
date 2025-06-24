package funkin.game;

import funkin.backend.chart.ChartData;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import funkin.backend.system.Conductor;
import funkin.backend.scripting.events.*;

using StringTools;

@:allow(funkin.game.PlayState)
class Note extends FlxSprite
{
	public var extra:Map<String, Dynamic> = [];

	public var strumTime:Float = 0;

	public var mustPress(get, never):Bool;
	public var strumLine(default, set):StrumLine;
	private function set_strumLine(strLine:StrumLine) {
		if (this.strumLine != null) {
			if (this.strumLine.notes != null)
				this.strumLine.notes.remove(this, true);
			strLine.notes.add(this);
			strLine.notes.sortNotes();
		}
		return strumLine = strLine;
	}

	private function get_mustPress():Bool {
		return false;
	}
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;

	/**
	 * Whenever that note should be avoided by Botplay.
	 */
	public var avoid:Bool = false;

	/**
	 * The note that comes before this one (sustain and not)
	 */
	public var prevNote:Note;
	/**
	 * The note that comes after this one (sustain and not)
	 */
	public var nextNote:Note;
	/**
	 * The next sustain after this one
	 */
	public var nextSustain:Note;

	/**
	 * Name of the splash.
	 */
	public var splash:String = "default";

	public var strumID(get, never):Int;
	private function get_strumID() {
		var id = noteData % strumLine.members.length;
		if (id < 0) id = 0;
		return id;
	}

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var flipSustain:Bool = true;

	public var noteTypeID:Int = 0;

	// TO APPLY THOSE ON A SINGLE NOTE
	public var scrollSpeed:Null<Float> = null;
	public var noteAngle:Null<Float> = null;

	public var copyStrumAngle:Bool = true;
	public var updateNotesPosX:Bool = true;
	public var updateNotesPosY:Bool = true;
	public var updateFlipY:Bool = true;

	public var noteType(get, null):String;

	@:dox(hide) public var __strumCameras:Array<FlxCamera> = null;
	@:dox(hide) public var __strum:Strum = null;
	@:dox(hide) public var __noteAngle:Float = 0;

	private function get_noteType() {
		if (PlayState.instance == null) return null;
		return PlayState.instance.getNoteType(noteTypeID);
	}

	public static var swagWidth:Float = 160 * 0.7;

	private static var __customNoteTypeExists:Map<String, Bool> = [];

	public var animSuffix:String = null;


	private static function customTypePathExists(path:String) {
		if (__customNoteTypeExists.exists(path))
			return __customNoteTypeExists[path];
		return __customNoteTypeExists[path] = Assets.exists(path);
	}

	static var DEFAULT_FIELDS:Array<String> = ["time", "id", "type", "sLen"];

	public function new(strumLine:StrumLine, noteData:ChartNote, sustain:Bool = false, sustainLength:Float = 0, sustainOffset:Float = 0, ?prev:Note)
	{
		super();

		moves = false;

		if(prev != null)
			this.prevNote = prev;
		else
			this.prevNote = strumLine.notes.members.last();

		if (this.prevNote != null) this.prevNote.nextNote = this;
		this.noteTypeID = noteData.type.getDefault(0);
		this.isSustainNote = sustain;
		this.sustainLength = sustainLength;
		this.strumLine = strumLine;
		for(field in Reflect.fields(noteData)) {
			if(!DEFAULT_FIELDS.contains(field)) {
				this.extra.set(field, Reflect.field(noteData, field));
			}
		}

		x += 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;

		this.strumTime = noteData.time.getDefault(0) + sustainOffset;
		this.noteData = noteData.id.getDefault(0);

		var customType = Paths.image('game/notes/${this.noteType}');
		var event = EventManager.get(NoteCreationEvent).recycle(this, strumID, this.noteType, noteTypeID, PlayState.instance.strumLines.members.indexOf(strumLine), mustPress,
			(this.noteType != null && customTypePathExists(customType)) ? 'game/notes/${this.noteType}' : 'game/notes/default', @:privateAccess strumLine.strumScale * 0.7, animSuffix);

		if (PlayState.instance != null)
			event = PlayState.instance.scripts.event("onNoteCreation", event);

		this.animSuffix = event.animSuffix;
		if (!event.cancelled) {
			switch (event.noteType)
			{
				// case "My Custom Note Type": // hardcoding note types
				default:
					frames = Paths.getFrames(event.noteSprite);

					switch(event.strumID % 4) {
						case 0:
							animation.addByPrefix('scroll', 'purple0');
							animation.addByPrefix('hold', 'purple hold piece');
							animation.addByPrefix('holdend', frames.getByName('pruple end hold') != null ? 'pruple end hold' : 'purple hold end');
						case 1:
							animation.addByPrefix('scroll', 'blue0');
							animation.addByPrefix('hold', 'blue hold piece');
							animation.addByPrefix('holdend', 'blue hold end');
						case 2:
							animation.addByPrefix('scroll', 'green0');
							animation.addByPrefix('hold', 'green hold piece');
							animation.addByPrefix('holdend', 'green hold end');
						case 3:
							animation.addByPrefix('scroll', 'red0');
							animation.addByPrefix('hold', 'red hold piece');
							animation.addByPrefix('holdend', 'red hold end');
					}

					scale.set(event.noteScale, event.noteScale);
					antialiasing = true;
			}
		}

		updateHitbox();

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			animation.play('holdend');

			updateHitbox();

			if (prevNote.isSustainNote)
			{
				prevNote.nextSustain = this;
				prevNote.animation.play('hold');
			}
		} else {
			animation.play("scroll");
		}

		if (PlayState.instance != null) {
			PlayState.instance.splashHandler.getSplashGroup(splash);
			PlayState.instance.scripts.event("onPostNoteCreation", event);
		}
	}

	public var lastScrollSpeed:Null<Float> = null;
	public var angleOffsets:Bool = true;
	public var gapFix:Single = 0;
	public var useAntialiasingFix(get, set):Bool;
	inline function set_useAntialiasingFix(v:Bool) {
		if(v != useAntialiasingFix) {
			gapFix = v ? 1 : 0;
		}
		return v;
	}
	inline function get_useAntialiasingFix() {
		return gapFix>0;
	}

	/**
	 * Whenever the position of the note should be relative to the strum position or not.
	 * For example, if this is true, a note at the position 0; 0 will be on the strum, instead of at the top left of the screen.
	 */
	public var strumRelativePos:Bool = true;

	override function drawComplex(camera:FlxCamera) {
		var downscrollCam = (camera is HudCamera ? cast(camera, HudCamera).downscroll : false);
		if (updateFlipY) flipY = (isSustainNote && flipSustain) && (downscrollCam != (__strum != null && __strum.getScrollSpeed(this) < 0));
		if (downscrollCam) {
			frameOffset.y += __notePosFrameOffset.y * 2;
			super.drawComplex(camera);
			frameOffset.y -= __notePosFrameOffset.y * 2;
		} else
			super.drawComplex(camera);
	}

	static var __notePosFrameOffset:FlxPoint = new FlxPoint();
	static var __posPoint:FlxPoint = new FlxPoint();

	override function draw() {
		@:privateAccess var oldDefaultCameras = FlxCamera._defaultCameras;
		@:privateAccess if (__strumCameras != null) FlxCamera._defaultCameras = __strumCameras;

		var negativeScroll = isSustainNote && nextSustain != null && lastScrollSpeed < 0;
		if (negativeScroll)	offset.y *= -1;

		if (__strum != null && strumRelativePos) {
			var pos = __posPoint.set(x, y);

			setPosition(__strum.x, __strum.y);

			__notePosFrameOffset.set(pos.x / scale.x, pos.y / scale.y);

			frameOffset.x -= __notePosFrameOffset.x;
			frameOffset.y -= __notePosFrameOffset.y;

			this.frameOffsetAngle = __noteAngle;

			super.draw();

			this.frameOffsetAngle = 0;

			frameOffset.x += __notePosFrameOffset.x;
			frameOffset.y += __notePosFrameOffset.y;

			setPosition(pos.x, pos.y);
			//pos.put();
		} else {
			__notePosFrameOffset.set(0, 0);
			super.draw();
		}

		if (negativeScroll)	offset.y *= -1;
		@:privateAccess FlxCamera._defaultCameras = oldDefaultCameras;
	}

	// The * 0.5 is so that it's easier to hit them too late, instead of too early
	public var earlyPressWindow:Float = 0.5;
	public var latePressWindow:Float = 1;

	public function updateSustain(strum:Strum) {
		var scrollSpeed = strum.getScrollSpeed(this);

		var len = 0.45 * CoolUtil.quantize(scrollSpeed, 100);

		if (nextSustain != null && lastScrollSpeed != scrollSpeed) {
			// is long sustain
			lastScrollSpeed = scrollSpeed;

			scale.y = (sustainLength * len) / frameHeight;
			updateHitbox();
			scale.y += gapFix / frameHeight;
		}

		if (!wasGoodHit) return;
		var t = FlxMath.bound((Conductor.songPosition - strumTime) / (height) * len, 0, 1);
		var swagRect = this.clipRect == null ? new FlxRect() : this.clipRect;
		swagRect.x = 0;
		swagRect.y = t * frameHeight;
		swagRect.width = frameWidth;
		swagRect.height = frameHeight;

		setClipRect(swagRect);
	}

	public inline function setClipRect(rect:FlxRect) {
		this.clipRect = rect;
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}

	public override function destroy() {
		super.destroy();
	}
}
