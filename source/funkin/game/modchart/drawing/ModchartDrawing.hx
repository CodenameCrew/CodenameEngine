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

	public var distance:Float = 0.0;
	//public var beatDistance:Float = 0.0;
	public var originalDistance(default, null):Float = 0.0;
	public var lane:Int = 0;

	public var time:Float = 0;
	public var beat:Float = 0;

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
		position.setTo(object.x, object.y, 0);
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

		this.distance = this.originalDistance = distance;
		//this.beatDistance = beatDistance;
		this.lane = lane;
		this.object = object;
		frame = object._frame;

		time = Conductor.songPosition;
		beat = Conductor.curBeatFloat;
	}

	public inline function isSustain()
		return note != null && note.isSustainNote;
	public inline function isForNote()
		return note != null;
	public inline function isForStrum()
		return strum != null;


	// for now
	static final projectDiv:Float = 1 / 1280;
	public function project() {
		position.w = (1280 - position.z) * projectDiv;
		shouldRender = position.w > 0;
		if (!shouldRender)
			return;

		var scaleMult = 1 / position.w;
		position.x = (position.x - FlxG.width * 0.5) * scaleMult + FlxG.width * 0.5;
		position.y = (position.y - FlxG.height * 0.5) * scaleMult + FlxG.height * 0.5;
		scale.x *= scaleMult;
		scale.y *= scaleMult;
	}
}

@:access(funkin.game.modchart.ModchartManager)
@:access(flixel.FlxCamera)
@:access(flixel.FlxBasic)
class ModchartDrawing {
	public var parent:ModchartManager;

	// there may be extra queues in the array, this is to reduce allocations.
	public var queues:Array<QueuedDraw> = [];
	public var queueCount:Int = 0;

	public var strumLines:FlxTypedGroup<StrumLine>;
	var __fieldsVisible:Bool = true;

	public function new(parent:ModchartManager, strumLines:FlxTypedGroup<StrumLine>) {
		this.parent = parent;
		this.strumLines = strumLines;

		FlxG.signals.preDraw.add(preDraw);
		FlxG.signals.postDraw.add(postDraw);
	}

	public function removeSignals() {
		FlxG.signals.preDraw.remove(preDraw);
		FlxG.signals.postDraw.remove(postDraw);
	}


	function drawStrum(strum:Strum, index:Int) {
		prepareExtra(strum, strum.extra);
		parent.curField = index;
		parent.curLane = strum.ID;

		if (queueCount >= queues.length)
			queues[queueCount] = new QueuedDraw();
		var queue = queues[queueCount];//++];
		queue.reset(0, parent.curLane, index, strumLines.members[index], strum);
		queue.strum = strum;

		for (mod in parent.allMods) {
			if (mod.active[index])
				mod.edit(queue);
		}
		queue.project();
		if (!queue.shouldRender)
			return;

		// for now
		strum.setPosition(queue.position.x, queue.position.y);
		strum.scale.set(queue.scale.x, queue.scale.y);
	}
	function drawNote(note:Note, index:Int) {
		prepareExtra(note, note.extra);
		note.extra.set("__modRelative", note.strumRelativePos);
		parent.curField = index;
		parent.curLane = note.strumID;

		note.strumRelativePos = false;
		note.__strum.updateNotePos(note);
		if  (note.__strum.updateNotesPosX && note.updateNotesPosX)
			note.x -= note.__strum.x - note.__strum.extra.get("__modchartX");
		if  (note.__strum.updateNotesPosY && note.updateNotesPosY)
			note.y -= note.__strum.y - note.__strum.extra.get("__modchartY");

		if (queueCount >= queues.length)
			queues[queueCount] = new QueuedDraw();
		var queue = queues[queueCount];//++];
		queue.reset(note.y - note.__strum.extra.get("__modchartY"), parent.curLane, index, strumLines.members[index], note);
		queue.note = note;

		for (mod in parent.allMods) {
			if (mod.active[index])
				mod.edit(queue);
		}
		queue.project();
		if (!queue.shouldRender)
			return;

		// for now
		note.setPosition(queue.position.x, queue.position.y);
		note.scale.set(queue.scale.x, queue.scale.y);
	}

	function preDraw() {
		// store the strumlines' visibility and if this is visible, hide it internally
		__fieldsVisible = strumLines.visible;
		//strumLines.visible = !parent.visible && __fieldsVisible;

		var oldDefaultCams = FlxCamera._defaultCameras;
		if (parent._cameras != null)
			FlxCamera._defaultCameras = parent._cameras;

		for (i in 0...strumLines.members.length) {
			var field = strumLines.members[i];

			var oldDefaultCams = FlxCamera._defaultCameras;
			if (field._cameras != null)
				FlxCamera._defaultCameras = field._cameras;

			field.resetStrumPositions();
			for (strum in field.members)
				drawStrum(strum, i);
			field.notes.forEachAlive(drawNote.bind(_, i));

			FlxCamera._defaultCameras = oldDefaultCams;
		}

		FlxCamera._defaultCameras = oldDefaultCams;
	}
	function postDraw() {
		strumLines.visible = __fieldsVisible;

		for (field in strumLines.members) {
			for (strum in field.members)
				restoreFromExtra(strum, strum.extra);
			field.notes.forEachAlive(restoreNote);
		}
	}

	// leaving this down here since this isnt gonna stay once foxlite gets into this
	function restoreNote(note:Note) {
		restoreFromExtra(note, note.extra);
		note.strumRelativePos = note.extra.get("__modRelative");
	}
	function restoreFromExtra(obj:FlxSprite, map:Map<String, Dynamic>) {
		obj.setPosition(map.get("__modchartX"), map.get("__modchartY"));
		obj.scale.set(map.get("__modScaleX"), map.get("__modScaleY"));
		obj.angle = map.get("__modchartRot");
	}
	function prepareExtra(obj:FlxSprite, map:Map<String, Dynamic>) {
		map.set("__modchartX", obj.x);
		map.set("__modchartY", obj.y);
		map.set("__modScaleX", obj.scale.x);
		map.set("__modScaleY", obj.scale.y);
		map.set("__modchartRot", obj.angle);
	}
}