package funkin.game.modchart.mods;

class Reverse extends BaseModifier {
	var reverse:LaneModValue = new LaneModValue("reverse", "");

	var cross:ModifierFloat = 0;
	var split:ModifierFloat = 0;
	var alternate:ModifierFloat = 0;

	var centered:ModifierFloat = 0;

	function getReverse(lane:Int, count:Int) {
		var reverse = reverse.addBoth(lane);

		if (lane >= Math.floor(count * 0.5))
			reverse += split;
		if (lane % 2 == 1)
			reverse += alternate;
		if (lane >= Math.floor(count * 0.25) && lane <= Math.floor(count * 0.75))
			reverse += cross;

		return reverse;
	}

	override function edit(queue:QueuedDraw) {
		queue.yMult *= 1 - getReverse(queue.lane, queue.field.members.length) * 2;
		var noDistY = queue.position.y - queue.distance * queue.directionSin * queue.yMult;
		queue.position.y += FlxMath.lerp(noDistY, FlxG.height * 0.5, centered) - noDistY;
	}
}