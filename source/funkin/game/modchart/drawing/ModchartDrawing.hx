package funkin.game.modchart.drawing;

import funkin.backend.system.Conductor;

@:access(funkin.game.modchart.ModchartManager)
@:access(funkin.game.Strum)
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
		var angle = strum.getNotesAngle();
		if (angle != Strum.__lastNoteAngle) {
			Strum.__lastNoteAngle = angle;
			final result = FlxMath.fastSinCos((angle + 90) * flixel.math.FlxAngle.TO_RAD);
			Strum.__lastAngleSin = result.sin;
			Strum.__lastAngleCos = result.cos;
		}

		prepareExtra(strum, strum.extra);
		parent.curField = index;
		parent.curLane = strum.ID;

		if (queueCount >= queues.length)
			queues[queueCount] = new QueuedDraw();
		var queue = queues[queueCount];//++];
		queue.reset(0, parent.curLane, index, strumLines.members[index], strum);
		queue.speed = strum.getScrollSpeed();
		queue.strum = strum;

		for (mod in parent.allMods) {
			if (mod.active[index])
				mod.edit(queue);
		}
		queue.project();
		if (!queue.shouldRender)
			return;

		// for now
		strum.setPosition(queue.position.x - strum.width * 0.5, queue.position.y - strum.height * 0.5);
		strum.scale.set(queue.scale.x, queue.scale.y);
	}
	function drawNote(note:Note, index:Int) {
		final strum = note.__strum;

		prepareExtra(note, note.extra);
		note.extra.set("__modRelative", note.strumRelativePos);
		parent.curField = index;
		parent.curLane = note.strumID;

		note.strumRelativePos = false;
		strum.updateNotePos(note);
		if  (strum.updateNotesPosX && note.updateNotesPosX)
			note.x -= strum.x - strum.extra.get("__modchartX");
		if  (strum.updateNotesPosY && note.updateNotesPosY)
			note.y -= strum.y - strum.extra.get("__modchartY");

		if (queueCount >= queues.length)
			queues[queueCount] = new QueuedDraw();
		var queue = queues[queueCount];//++];
		var speed = strum.getScrollSpeed(note);
		queue.reset((note.strumTime - Conductor.songPosition) * 0.45 * speed, parent.curLane, index, strumLines.members[index], note);
		queue.speed = speed;
		queue.note = note;

		for (mod in parent.allMods) {
			if (mod.active[index])
				mod.edit(queue);
		}
		queue.project();
		if (!queue.shouldRender)
			return;

		// for now
		note.setPosition(queue.position.x - note.width * 0.5, queue.position.y - note.height * 0.5);
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