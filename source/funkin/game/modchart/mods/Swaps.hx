package funkin.game.modchart.mods;

class Swaps extends BaseModifier {
	var opponentSwap:ModifierFloat = 0;
	var invert:ModifierFloat = 0;
	var flip:ModifierFloat = 0;

	public function new(parent:ModchartManager) {
		super(parent, 0);
	}

	override function edit(queue:QueuedDraw) {
		var newLane:Float = queue.lane + (1 - (queue.lane % 2) * 2) * invert;
		newLane = FlxMath.lerp(newLane, queue.field.members.length - 1 - newLane, flip);

		queue.position.x += queue.arrowSize * (newLane - queue.lane);

		var opSwap:Float = (queue.fieldCenter.x - FlxG.width * 0.5) * (1 - 2 * opponentSwap) + FlxG.width * 0.5;
		opSwap -= queue.fieldCenter.x;
		queue.position.x += opSwap;
		queue.fieldCenter.x += opSwap;
	}
}