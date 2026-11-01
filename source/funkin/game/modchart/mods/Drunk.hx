package funkin.game.modchart.mods;

class Drunk extends BaseModifier {
	var drunk:ModifierFloat = 0;
	var drunkSpeed:ModifierFloat = 0;
	var drunkSpacing:ModifierFloat = 0;
	var drunkPeriod:ModifierFloat = 0;
	var drunkOffset:ModifierFloat = 0;

	var drunkY:ModifierFloat = 0;
	var drunkYSpeed:ModifierFloat = 0;
	var drunkYSpacing:ModifierFloat = 0;
	var drunkYPeriod:ModifierFloat = 0;
	var drunkYOffset:ModifierFloat = 0;

	var drunkZ:ModifierFloat = 0;
	var drunkZSpeed:ModifierFloat = 0;
	var drunkZSpacing:ModifierFloat = 0;
	var drunkZPeriod:ModifierFloat = 0;
	var drunkZOffset:ModifierFloat = 0;

	public function new(parent:ModchartManager) {
		super(parent, 0);
	}

	// https://github.com/riconuts/FNF-Troll-Engine/blob/main/source/funkin/modchart/modifiers/DrunkModifier.hx#L15
	inline function getDrunkVal(val:Float, speed:Float, spacing:Float, period:Float, offset:Float, distance:Float, lane:Int, time:Float, arrowSize:Float) {
		final rads = time * (1.0 + speed) + offset + lane * ((spacing * 0.2) + 0.2) + distance * ((period * 10.0) + 10.0) / FlxG.height;
		return val * Math.sin(rads) * arrowSize * 0.5;
	}

	// if this looks similar, hi, srt here, developer of camellia 2.75's modchart backend, i'm here as well.
	override function edit(queue:QueuedDraw) {
		final time = queue.time * 0.001;

		final val = drunk;
		if (val != 0.0)
			queue.position.x += getDrunkVal(val, drunkSpeed, drunkSpacing, drunkPeriod, drunkOffset, queue.distance, queue.lane, time, queue.arrowSize);

		final valY = drunkY;
		if (valY != 0.0)
			queue.position.y += getDrunkVal(valY, drunkYSpeed, drunkYSpacing, drunkYPeriod, drunkYOffset, queue.distance, queue.lane, time, queue.arrowSize);

		final valZ = drunkZ;
		if (valZ != 0.0)
			queue.position.z += getDrunkVal(valZ, drunkZSpeed, drunkZSpacing, drunkZPeriod, drunkZOffset, queue.distance, queue.lane, time, queue.arrowSize);
	}
}