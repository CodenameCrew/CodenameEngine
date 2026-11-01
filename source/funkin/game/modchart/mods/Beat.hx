package funkin.game.modchart.mods;

class Beat extends BaseModifier {
	var beat:ModifierFloat = 0;
	var beatOffset:ModifierFloat = 0;
	var beatPeriod:ModifierFloat = 0;
	var beatMult:ModifierFloat = 0;

	var beatY:ModifierFloat = 0;
	var beatYOffset:ModifierFloat = 0;
	var beatYPeriod:ModifierFloat = 0;
	var beatYMult:ModifierFloat = 0;

	var beatZ:ModifierFloat = 0;
	var beatZOffset:ModifierFloat = 0;
	var beatZPeriod:ModifierFloat = 0;
	var beatZMult:ModifierFloat = 0;

	// x, y, z, beat
	public var beatTimes:Array<Array<Float>> = [];

	public function new(parent:ModchartManager) {
		super(parent, 0);
	}

	// from https://github.com/riconuts/FNF-Troll-Engine/blob/main/source/funkin/modchart/modifiers/BeatModifier.hx#L19
	// however the math is simplified.
	final accelTime:Float = 0.2;
	final totalTime:Float = 0.5;
	function getBeatTime(inBeat:Float, offset:Float, mult:Float) {
		var beat:Float = (inBeat + accelTime + offset) * (mult + 1.0);
		if (beat < 0) return 0.0;

		final endMult:Float = beat % 2 >= 1 ? -1 : 1;
		beat %= 1.0;

		if (beat >= totalTime) return 0.0;

		var amt:Float = 0.0;
		if (beat <= accelTime) {
			amt = beat / accelTime;
			amt *= amt;
		} else {
			amt = (beat - accelTime) / (totalTime - accelTime);
			amt = 1 - amt * amt;
		}

		return 40.0 * amt * endMult;
	}

	override function edit(queue:QueuedDraw) {
		while (beatTimes.length < queue.fieldIndex + 1)
			beatTimes.push([0, 0, 0, -1000]);

		var times = beatTimes[queue.fieldIndex];
		if (times[3] != queue.beat) {
			times[0] = getBeatTime(queue.beat, beatOffset, beatMult);
			times[1] = getBeatTime(queue.beat, beatYOffset, beatYMult);
			times[2] = getBeatTime(queue.beat, beatZOffset, beatZMult);
			times[3] = queue.beat;
		}

		final xVal = beat * times[0];
		if (xVal != 0.0) {
			final xPeriod = ((beatPeriod * 30) + 30);
			queue.position.x += xVal * Math.cos(queue.distance / xPeriod);
		}

		final yVal = beatY * times[1];
		if (yVal != 0.0) {
			final xPeriod = ((beatPeriod * 30) + 30);
			queue.position.x += xVal * Math.cos(queue.distance / xPeriod);
		}

		final zVal = beatZ * times[2];
		if (zVal != 0.0) {
			final xPeriod = ((beatPeriod * 30) + 30);
			queue.position.x += xVal * Math.cos(queue.distance / xPeriod);
		}
	}
}