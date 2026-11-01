package funkin.game.modchart.mods;

class Tipsy extends BaseModifier {
	var tipsyX:ModifierFloat = 0;
	var tipsyXSpeed:ModifierFloat = 0;
	var tipsyXSpacing:ModifierFloat = 0;
	var tipsyXOffset:ModifierFloat = 0;

	var tipsy:ModifierFloat = 0;
	var tipsySpeed:ModifierFloat = 0;
	var tipsySpacing:ModifierFloat = 0;
	var tipsyOffset:ModifierFloat = 0;

	var tipsyZ:ModifierFloat = 0;
	var tipsyZSpeed:ModifierFloat = 0;
	var tipsyZSpacing:ModifierFloat = 0;
	var tipsyZOffset:ModifierFloat = 0;

	public function new(parent:ModchartManager) {
		super(parent, 0);
	}

	// https://github.com/riconuts/FNF-Troll-Engine/blob/main/source/funkin/modchart/modifiers/DrunkModifier.hx#L30
	inline function getTipsyVal(val:Float, speed:Float, spacing:Float, offset:Float, lane:Int, time:Float, arrowSize:Float) {
		final rads = time * ((speed * 1.2) + 1.2) + offset * 1.2 + lane * ((spacing * 1.8) + 1.8);
		return val * Math.cos(rads) * arrowSize * 0.4;
	}
	
	// if this looks similar, hi, srt here, developer of camellia 2.75's modchart backend, i'm here as well.
	override function edit(queue:QueuedDraw) {
		final time = queue.time * 0.001;

		final valX = tipsyX;
		if (valX != 0.0)
			queue.position.x += getTipsyVal(valX, tipsyXSpeed, tipsyXSpacing, tipsyXOffset, queue.lane, time, queue.arrowSize);

		final val = tipsy;
		if (val != 0.0)
			queue.position.y += getTipsyVal(val, tipsySpeed, tipsySpacing, tipsyOffset, queue.lane, time, queue.arrowSize);

		final valZ = tipsyZ;
		if (valZ != 0.0)
			queue.position.z += getTipsyVal(valZ, tipsyZSpeed, tipsyZSpacing, tipsyZOffset, queue.lane, time, queue.arrowSize);
	}
}