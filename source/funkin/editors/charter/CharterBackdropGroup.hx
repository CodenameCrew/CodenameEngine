package funkin.editors.charter;

import flixel.addons.display.FlxBackdrop;
import flixel.graphics.FlxGraphic;
import funkin.backend.system.Conductor;
import openfl.geom.Rectangle;
import funkin.backend.shaders.CustomShader;

class FlxFastTypedGroup<T:FlxBasic> extends FlxTypedGroup<T> {
	public function new(?maxSize:Int = 0) {
		super(maxSize);
	}

	override public function add(Object:T):T
	{
		if (Object == null)
		{
			FlxG.log.warn("Cannot add a `null` object to a FlxGroup.");
			return null;
		}

		// removed the check for multiple
		// removed the check for null reuse

		// If the group is full, return the Object
		if (maxSize > 0 && length >= maxSize)
			return Object;

		// If we made it this far, we need to add the object to the group.
		members.push(Object);
		length++;

		if (_memberAdded != null)
			_memberAdded.dispatch(Object);

		return Object;
	}
}

class CharterBackdropGroup extends FlxTypedGroup<CharterBackdrop> {
	public var strumLineGroup:CharterStrumLineGroup;
	public var notesGroup:CharterNoteGroup;

	public var conductorSprY:Float = 0;
	public var bottomLimitY:Float = 0;

	// Just here so you can update display sprites all dat and above
	public var strumlinesAmount:Int = 0;

	public function new(strumLineGroup:CharterStrumLineGroup) {
		super();
		this.strumLineGroup = strumLineGroup;
	}

	public function createGrids(amount:Int = 0) {
		for (i in 0...amount) {
			var grid = new CharterBackdrop();
			grid.active = grid.visible = false;
			add(grid);
		}
	}

	public override function update(elapsed:Float) {
		for (grid in members)
			grid.active = grid.visible = false;

		super.update(elapsed);

		for (i => strumLine in strumLineGroup.members) {
			if (strumLine == null) continue;

			if (members[i] == null)
				members[i] = recycle(CharterBackdrop, () -> {return new CharterBackdrop();});

			var grid = members[i];
			grid.cameras = this.cameras;
			grid.strumLine = strumLine;

			grid.conductorFollowerSpr.y = conductorSprY;
			grid.bottomSeparator.y = (grid.bottomLimit.y = bottomLimitY)-2;

			grid.waveformSprite.shader = strumLine.waveformShader;

			grid.notesGroup.clear();
			notesGroup.forEach((n) -> {
				if(n.exists && n.visible) {
					var onStr:Bool = (n.snappedToGrid ? n.strumLineID : CoolUtil.boundInt(Std.int((n.x+n.width)/(40*strumLine.keyCount)), 0, strumLineGroup.members.length-1)) == i;
					if(onStr) grid.notesGroup.add(n);
				}
			});

			grid.active = grid.visible = true;
			grid.updateSprites();
		}
	}

	public var draggingObj:CharterBackdrop = null;
	override function draw() @:privateAccess {
		var i:Int = 0;
		var basic:FlxBasic = null;

		for (grid in members) {
			if (strumLineGroup.draggingObj == null) break;
			if (grid.strumLine == null) continue;

			if (strumLineGroup.draggingObj.strumLine == grid.strumLine.strumLine) {
				draggingObj = grid;
				break;
			}
		}

		var oldDefaultCameras = FlxCamera._defaultCameras;
		if (cameras != null)
			FlxCamera._defaultCameras = cameras;

		while (i < length) {
			basic = members[i++];
			if (basic != null && basic != draggingObj && basic.exists && basic.visible)
				basic.draw();
		}
		if (draggingObj != null) draggingObj.draw();

		FlxCamera._defaultCameras = oldDefaultCameras;
	}
}

// Batches note draws (neos idea) >:D -lunar
class NotesDrawGroup extends FlxFastTypedGroup<CharterNote> {
	public override function draw() @:privateAccess {
		var oldDefaultCameras = FlxCamera._defaultCameras;
		if (cameras != null)
			FlxCamera._defaultCameras = cameras;

		var i:Int = 0;
		var note:CharterNote = null;

		while (i < length) {
			note = members[i++];
			if (note != null && note.exists && note.visible) {
				if (note.snappedToGrid) note.x = (note.strumLine != null ? note.strumLine.x : 0) + (note.id % (note.strumLine != null ? note.strumLine.keyCount : 4)) * 40;
				note.drawMembers();
			}
		}

		i = 0; note = null;
		while (i < length) {
			note = members[i++];
			if (note != null && note.exists && note.visible)
				note.drawSuper();
		}

		i = 0; note = null;
		while (i < length) {
			note = members[i++];
			if (note != null && note.exists && note.visible)
				note.drawNoteTypeText();
		}

		FlxCamera._defaultCameras = oldDefaultCameras;
	}
}

class CharterBackdrop extends FlxTypedGroup<FlxBasic> {
	public var gridBackDrop:FlxBackdrop;
	public var topLimit:FlxSprite;
	public var topSeparator:FlxSprite;
	public var bottomLimit:FlxSprite;
	public var bottomSeparator:FlxSprite;

	public var waveformSprite:FlxSprite;

	public var conductorFollowerSpr:FlxSprite;
	public var beatSeparator:CharterGridSeperator;

	public var notesGroup:NotesDrawGroup = new NotesDrawGroup();
	public var strumLine:CharterStrumline;

	public var gridShader:CustomShader = new CustomShader("engine/charterGrid");
	var __lastKeyCount:Int = 4;

	public function new() {
		super();

		gridBackDrop = new FlxBackdrop(null, Y, 0, 0);
		gridBackDrop.makeSolid(1, 1, -1);
		gridBackDrop.shader = gridShader;
		add(gridBackDrop);
		gridShader.hset("segments", 4);

		waveformSprite = new FlxSprite().makeSolid(1, 1, 0xFF000000);
		waveformSprite.scale.set(160, 1);
		waveformSprite.updateHitbox();
		add(waveformSprite);

		beatSeparator = new CharterGridSeperator();
		beatSeparator.makeSolid(1, 1, -1);
		beatSeparator.alpha = 0.5;
		beatSeparator.scrollFactor.set(1, 1);
		beatSeparator.scale.set((4 * 40), 2);
		beatSeparator.updateHitbox();

		add(beatSeparator);
		add(notesGroup);

		bottomSeparator = new FlxSprite(0,-2);
		bottomSeparator.makeSolid(1, 1, -1);
		bottomSeparator.alpha = 0.5;
		bottomSeparator.scrollFactor.set(1, 1);
		bottomSeparator.scale.set(4 * 40, 4);
		bottomSeparator.updateHitbox();
		add(bottomSeparator);

		topSeparator = new FlxSprite(0, -2);
		topSeparator.makeSolid(1, 1, -1);
		topSeparator.alpha = 0.5;
		topSeparator.scrollFactor.set(1, 1);
		topSeparator.scale.set(4 * 40, 4);
		topSeparator.updateHitbox();
		add(topSeparator);

		// Limits
		topLimit = new FlxSprite();
		topLimit.makeSolid(1, 1, -1);
		topLimit.color = 0xFF888888;
		topLimit.blend = MULTIPLY;
		add(topLimit);

		bottomLimit = new FlxSprite();
		bottomLimit.makeSolid(1, 1, -1);
		bottomLimit.color = 0xFF888888;
		bottomLimit.blend = MULTIPLY;
		add(bottomLimit);

		// Follower
		conductorFollowerSpr = new FlxSprite(0, 0).makeSolid(1, 1, -1);
		conductorFollowerSpr.scale.set(4 * 40, 4);
		conductorFollowerSpr.updateHitbox();
		add(conductorFollowerSpr);
	}

	public function updateSprites() {
		var x:Float = 0; // fuck you
		var alpha:Float = 0.9;
		var keyCount:Int = 4;

		if (strumLine != null) {
			x = strumLine.x;
			alpha = strumLine.strumLine.visible ? 0.9 : 0.4;
			keyCount = strumLine.keyCount;
		} else alpha = 0.9;

		for (spr in [gridBackDrop, beatSeparator, topLimit, bottomLimit, 
				topSeparator, bottomSeparator, conductorFollowerSpr, waveformSprite]) {
			spr.x = x; if (spr != waveformSprite) spr.alpha = alpha;
			spr.cameras = this.cameras;
		}

		gridBackDrop.setGraphicSize(40*keyCount, 160);
		gridBackDrop.updateHitbox();
		if (__lastKeyCount != keyCount) gridShader.hset("segments", keyCount);
		__lastKeyCount = keyCount;

		topLimit.scale.set(keyCount * 40, Math.ceil(FlxG.height / cameras[0].zoom));
		topLimit.updateHitbox();
		topLimit.y = -topLimit.height;

		bottomLimit.scale.set(keyCount * 40, Math.ceil(FlxG.height / cameras[0].zoom));
		bottomLimit.updateHitbox();

		for (spr in [conductorFollowerSpr, beatSeparator, topSeparator, bottomSeparator]) {
			spr.scale.x = keyCount * 40;
			spr.updateHitbox();
		}

		waveformSprite.visible = waveformSprite.shader != null;
		if (waveformSprite.shader == null) return;

		waveformSprite.scale.set(keyCount * 40, FlxG.height * (1/cameras[0].zoom));
		waveformSprite.updateHitbox();

		waveformSprite.y = (cameras[0].scroll.y+FlxG.height/2)-(waveformSprite.height/2);

		if (waveformSprite.y < 0) {waveformSprite.scale.y += waveformSprite.y; waveformSprite.y = 0;}
		if (waveformSprite.y + waveformSprite.height > bottomLimit.y) {
			waveformSprite.scale.y -= (waveformSprite.y + waveformSprite.height)-(bottomLimit.y);
			waveformSprite.y = (bottomLimit.y) - waveformSprite.scale.y;
		}
		waveformSprite.updateHitbox();

		waveformSprite.shader.data.pixelOffset.value = [Math.max(conductorFollowerSpr.y - ((FlxG.height * (1/cameras[0].zoom)) * 0.5), 0)];
		waveformSprite.shader.data.textureRes.value = [waveformSprite.width, waveformSprite.height];
		waveformSprite.shader.data.playerPosition.value = [conductorFollowerSpr.y];
	}
}

class CharterGridSeperatorBase extends FlxSprite {

	private static var minStep:Float = 0;
	private static var maxStep:Float = 0;

	private static var minBeat:Float = 0;
	private static var maxBeat:Float = 0;

	private static var minMeasure:Float = 0;
	private static var maxMeasure:Float = 0;

	private static var lastMinBeat:Float = -1;
	private static var lastMaxBeat:Float = -1;

	private static var lastMinMeasure:Float = -1;
	private static var lastMaxMeasure:Float = -1;

	public static var lastConductorSprY:Float = Math.NEGATIVE_INFINITY;

	private static var beatStepTimes:Array<Float> = [];
	private static var measureStepTimes:Array<Float> = [];
	private static var timeSignatureChangeGaps:Array<Float> = [];

	private function recalculateBeats() {
		var conductorSprY = Charter.instance.gridBackdrops.conductorSprY;
		if (conductorSprY == lastConductorSprY) return;

		var zoomOffset = ((FlxG.height * (1/cameras[0].zoom)) * 0.5);

		minStep = (conductorSprY - zoomOffset)/40;
		maxStep = (conductorSprY + zoomOffset)/40;

		var minTime:Float = Conductor.getStepsInTime(minStep);
		var maxTime:Float = Conductor.getStepsInTime(maxStep);

		var minBpmChange = Conductor.bpmChangeMap[Conductor.getTimeInChangeIndex(minTime)];
		var maxBpmChange = Conductor.bpmChangeMap[Conductor.getTimeInChangeIndex(maxTime)];

		minBeat = Conductor.getTimeInBeats(minTime);
		maxBeat = Conductor.getTimeInBeats(maxTime);

		minMeasure = minBpmChange.measureTime + (minBeat - minBpmChange.beatTime) / minBpmChange.beatsPerMeasure;
		maxMeasure = maxBpmChange.measureTime + (maxBeat - maxBpmChange.beatTime) / maxBpmChange.beatsPerMeasure;

		//cap out the beats/measures at the end of the song
		var endTime = Conductor.getStepsInTime(Charter.instance.__endStep);
		var endBeat = Conductor.getTimeInBeats(endTime);
		var endBpmChange = Conductor.bpmChangeMap[Conductor.getTimeInChangeIndex(endTime)];
		var endMeasure = endBpmChange.measureTime + (endBeat - endBpmChange.beatTime) / endBpmChange.beatsPerMeasure;

		if (maxBeat > endBeat) maxBeat = endBeat;
		if (maxMeasure > endMeasure) maxMeasure = endMeasure;
		if (minMeasure < 0) minMeasure = 0;
		if (minBeat < 0) minBeat = 0;

		//only calculate if needed
		if ((minBeat != lastMinBeat) || (maxBeat != lastMaxBeat) || (minMeasure != lastMinMeasure) || (maxMeasure != lastMaxMeasure) || lastConductorSprY == Math.NEGATIVE_INFINITY) {
			calculateTimeSignatureGaps();
			calculateStepTimes();
			lastMinBeat = minBeat;
			lastMaxBeat = maxBeat;
			lastMinMeasure = minMeasure;
			lastMaxMeasure = maxMeasure;
		}

		lastConductorSprY = conductorSprY;
	}

	private inline function calculateTimeSignatureGaps() {
		//for time signatures that start mid step
		timeSignatureChangeGaps.splice(0, timeSignatureChangeGaps.length);
		for (i => change in Conductor.bpmChangeMap) {
			if (change.stepTime >= minStep && change.stepTime <= maxStep) {
				//get step while ignoring the current change
				var index:Int = CoolUtil.boundInt(i-1, 0, Conductor.bpmChangeMap.length - 1);
				var step:Float = Conductor.getTimeWithBPMInSteps(change.songTime, index, Conductor.getTimeWithIndexInBPM(change.songTime, index));

				if (Math.ceil(step) - step > 0 && (step - Math.floor(step)) > FlxMath.EPSILON) { //mid step change
					timeSignatureChangeGaps.push(step);
				}
			}
		}
	}

	private inline function calculateStepTimes() {
		beatStepTimes.splice(0, beatStepTimes.length);
		for (i in Math.floor(minBeat)...Math.ceil(maxBeat)) {
			beatStepTimes.push(Conductor.getTimeInSteps(Conductor.getBeatsInTime(i)));
		}
		measureStepTimes.splice(0, measureStepTimes.length);
		for (i in Math.floor(minMeasure)...Math.ceil(maxMeasure)) {
			measureStepTimes.push(Conductor.getTimeInSteps(Conductor.getMeasuresInTime(i)));
		}
	}

	override public function draw() {

		//should only need to recalculate once per frame and will be shared across each instance
		recalculateBeats();

		drawTimeSignatureChangeGaps();

		if (Options.charterShowBeats) drawBeats();
		if (Options.charterShowSections) drawMeasures();
	}

	private function drawBeats(offset:Float = 0.0) {
		for (i in beatStepTimes) {
			y = (i*40)+offset;
			super.draw();
		}
	}
	private function drawMeasures(offset:Float = 0.0) {
		for (i in measureStepTimes) {
			y = (i*40)+offset;
			super.draw();
		}
	}
	private function drawTimeSignatureChangeGaps() {
		if (timeSignatureChangeGaps.length == 0) return;
		var prevColor = color;
		var prevBlend = blend;

		color = 0xFF888888;
		blend = MULTIPLY;

		for (step in timeSignatureChangeGaps) {
			y = step*40;
			var diff = Math.ceil(step) - step;
			scale.y = diff*40;
			updateHitbox();

			super.draw();
		}

		color = prevColor;
		blend = prevBlend;
	}
}

class CharterGridSeperator extends CharterGridSeperatorBase {
	override private function drawBeats(offset:Float = 0.0) {
		scale.y = 2;
		updateHitbox();
		super.drawBeats(-2);
	}
	override private function drawMeasures(offset:Float = 0.0) {
		scale.y = 4;
		updateHitbox();
		super.drawMeasures(-3);
	}
}

class EventBackdrop extends FlxBackdrop {
	public var eventBeatSeparator:CharterEventGridSeperator;

	public var topSeparator:FlxSprite;
	public var bottomSeparator:FlxSprite;

	public var global:Bool = false;

	public function new(global:Bool) {
		super(Paths.image('editors/charter/events-grid'), Y, 0, 0);
		this.global = flipX = flipY = global;
		alpha = 0.9;

		// Separators
		eventBeatSeparator = new CharterEventGridSeperator();
		eventBeatSeparator.makeSolid(1, 1, -1);
		eventBeatSeparator.alpha = 0.5;
		eventBeatSeparator.scrollFactor.set(1, 1);
		eventBeatSeparator.global = global;

		bottomSeparator = new FlxSprite(0,-2);
		bottomSeparator.makeSolid(1, 1, -1);
		bottomSeparator.alpha = 0.5;
		bottomSeparator.scrollFactor.set(1, 1);
		bottomSeparator.scale.set(20, 4);
		bottomSeparator.updateHitbox();

		topSeparator = new FlxSprite(0, -2);
		topSeparator.makeSolid(1, 1, -1);
		topSeparator.alpha = 0.5;
		topSeparator.scrollFactor.set(1, 1);
		topSeparator.scale.set(20, 4);
		topSeparator.updateHitbox();

	}

	public override function draw() {
		super.draw();

		eventBeatSeparator.cameras = cameras;
		eventBeatSeparator.xPos = global ? x : x+width;
		eventBeatSeparator.draw();

		topSeparator.x = global ? x : (x+width) - 20;
		topSeparator.cameras = this.cameras;
		if (!Options.charterShowSections) topSeparator.draw();

		bottomSeparator.x = global ? x : (x+width) - 20;
		bottomSeparator.cameras = this.cameras;
		bottomSeparator.draw();
	}
}

class CharterEventGridSeperator extends CharterGridSeperatorBase {
	public var xPos:Float = 0.0;
	public var global:Bool = false;
	override private function drawBeats(offset:Float = 0.0) {
		scale.set(10, 2);
		updateHitbox();
		x = global ? xPos : xPos-10;
		super.drawBeats(-2);
	}
	override private function drawMeasures(offset:Float = 0.0) {
		scale.set(20, 4);
		updateHitbox();
		x = global ? xPos : xPos-20;
		super.drawMeasures(-3);
	}
	override private function drawTimeSignatureChangeGaps() {}
}