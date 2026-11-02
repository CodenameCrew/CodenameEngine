package funkin.game.modchart.mods;

import funkin.backend.system.Conductor;

class CenteredPath extends BaseModifier {
	var centeredPath:LaneModValue = new LaneModValue("centeredpath", "", 0, ["movepath", "centered2"]);
	var transformPath:LaneModValue = new LaneModValue("transformpath", "");
	var centeredPathType:ModifierFloat = 0;
	
	public function new(parent:ModchartManager) {
		super(parent, 0);
	}

	override function edit(queue:QueuedDraw) {
		var adjustedCrotchet = Conductor.crochet * 0.45 * queue.speed;
		var pathSize = FlxMath.lerp(queue.arrowSize, adjustedCrotchet, centeredPathType);

		queue.distance += transformPath.addBoth(queue.lane) + centeredPath.addBoth(queue.lane) * pathSize;
	}
}