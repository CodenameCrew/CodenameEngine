package funkin.game.modchart.drawing;

import funkin.backend.system.Conductor;

/*
TODO:
- Create storage of FoxInstancedModels and allow notes to have a `mesh` variable for 3d notes
*/
@:access(funkin.game.modchart.ModchartManager)
@:access(funkin.game.Strum)
@:access(flixel.FlxCamera)
@:access(flixel.FlxBasic)
class ModchartDrawing {
	public var parent:ModchartManager;

	// there may be extra queues in the array, this is to reduce allocations.
	// Update! this may just become like a singleton, ModchartModel's taking a lot of care of the rendering work.
	public var queues:Array<QueuedDraw> = [];
	public var queueCount:Int = 0;
	public var models:Array<ModchartModel> = [];

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
		pushToModel(queue);
	}
	function drawNote(note:Note, index:Int) {
		final strum = note.__strum;

		var ogNoteX = note.x;
		var ogNoteY = note.y;
		var wasRelative = note.strumRelativePos;
		parent.curField = index;
		parent.curLane = note.strumID;

		if (wasRelative) {
			note.strumRelativePos = false;
			strum.updateNotePos(note);
		}

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
		queue.position.z += note.isSustainNote ? 1 : 2;
		pushToModel(queue);

		note.setPosition(ogNoteX, ogNoteY);
		note.strumRelativePos = wasRelative;
	}

	function pushToModel(queue:QueuedDraw) {
		var emptyModel = null;
		var tex = ModchartModel.getTex(queue);
		for (model in models) {
			if (model.elemCount <= 0) {
				emptyModel ??= model;
				continue;
			}

			if (model.curTex == tex) {
				model.buildFromQueue(queue);
				return;
			}
		}

		if (emptyModel == null) {
			emptyModel = new ModchartModel(parent);
			models.push(emptyModel);
			parent.add(emptyModel);
		}
		emptyModel.buildFromQueue(queue);
	}

	function preDraw() {
		// store the strumlines' visibility and if this is visible, hide it internally
		__fieldsVisible = strumLines.visible;
		strumLines.visible = !parent.visible && __fieldsVisible;

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
	}
}