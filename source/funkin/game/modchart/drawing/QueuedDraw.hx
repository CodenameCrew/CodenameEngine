package funkin.game.modchart.drawing;

import flixel.graphics.frames.FlxFrame;
import funkin.backend.system.Conductor;
import openfl.geom.ColorTransform;
import openfl.geom.Vector3D;

@:access(flixel.FlxSprite)
class QueuedDraw {
	public var position:Vector3D = new Vector3D();
	public var scale:Vector3D = new Vector3D(1, 1, 1);
	public var rotation:Vector3D = new Vector3D();
	public var color:ColorTransform = new ColorTransform();

	public var stealthColor:Vector3D = new Vector3D(1, 1, 1);
	public var stealth:Float = 0.0;

	public var distance(default, set):Float = 0.0;
	//public var beatDistance:Float = 0.0;
	public var originalDistance(default, null):Float = 0.0;
	public var lane:Int = 0;

	public var time:Float = 0;
	public var beat:Float = 0;

	public var directionSin:Float = 1;
	public var directionCos:Float = 0;
	public var speed:Float = 1;

	public var fieldCenter:Vector3D = new Vector3D();
	public var fieldIndex:Int = 0;
	public var arrowSize:Float = 0;
	public var field:StrumLine;

	public var frame:FlxFrame;
	public var object:FlxSprite;
	public var strum:Strum;
	public var note:Note;

	public var shouldRender:Bool = true;
	public var antialiasing:Bool = true;

	public function new() {}

	public function reset(distance:Float, /*beatDistance:Float, */ lane:Int, fieldIndex:Int, field:StrumLine, object:FlxSprite) {
		position.setTo(object.x + object.width * 0.5, object.y + object.height * 0.5, 0);
		scale.setTo(object.scale.x, object.scale.y, 1);
		rotation.setTo(0, 0, object.angle);
		color.copyColorTransform(object.colorTransform);
		antialiasing = object.antialiasing;

		stealthColor.setTo(1, 1, 1);
		stealth = 0;

		this.fieldIndex = fieldIndex;
		this.field = field;
		arrowSize = Note.swagWidth * field.strumScale * (field.data?.strumSpacing ?? 1);
		@:privateAccess fieldCenter.setTo(field.startingPos.x + arrowSize * (field.members.length * 0.5), FlxG.height * 0.5, 0);

		@:bypassAccessor this.distance = distance;
		this.originalDistance = distance;
		//this.beatDistance = beatDistance;
		this.lane = lane;
		this.object = object;
		note = null; // these apply on `drawNote` and `drawStrum`
		strum = null;
		frame = object._frame;

		time = Conductor.songPosition;
		beat = Conductor.curBeatFloat;

		directionSin = Strum.__lastAngleSin;
		directionCos = Strum.__lastAngleCos;
		speed = 1;
	}

	public inline function isSustain()
		return note != null && note.isSustainNote;
	public inline function isTap()
		return note != null && !note.isSustainNote;
	public inline function isForNote()
		return note != null;
	public inline function isForStrum()
		return strum != null;

	function set_distance(to:Float) {
		final diff = to - distance;
		position.x += diff * directionCos;
		position.y += diff * directionSin;

		return distance = to;
	}
}