package funkin.game.modchart.mods;

class Bumpy extends BaseModifier {
	var bumpyX:ModifierFloat = 0;
	var bumpyXOffset:ModifierFloat = 0;
	var bumpyXPeriod:ModifierFloat = 0;

	var bumpyY:ModifierFloat = 0;
	var bumpyYOffset:ModifierFloat = 0;
	var bumpyYPeriod:ModifierFloat = 0;

	var bumpy:ModifierFloat = 0;
	var bumpyOffset:ModifierFloat = 0;
	var bumpyPeriod:ModifierFloat = 0;

	public function new(parent:ModchartManager) {
		super(parent, 0);
	}

	// https://github.com/riconuts/FNF-Troll-Engine/blob/main/source/funkin/modchart/modifiers/DrunkModifier.hx#L45
	inline function getBumpyVal(val:Float, offset:Float, period:Float, distance:Float) {
		var rads = (distance + (100.0 * offset)) / ((period * 24.0) + 24.0);
		return val * Math.sin(rads) * 40.0;
	}
	
	// if this looks similar, hi, srt here, developer of camellia 2.75's modchart backend, i'm here as well.
	override function edit(queue:QueuedDraw) {
		final valX = bumpyX;
		if (valX != 0.0)
			queue.position.x += getBumpyVal(valX, bumpyXOffset, bumpyXPeriod, queue.distance);

		final valY = bumpyY;
		if (valY != 0.0)
			queue.position.y += getBumpyVal(valY, bumpyYOffset, bumpyYPeriod, queue.distance);

		final val = bumpy;
		if (val != 0.0)
			queue.position.z += getBumpyVal(val, bumpyOffset, bumpyPeriod, queue.distance);
	}
}