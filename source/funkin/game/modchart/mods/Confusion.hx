package funkin.game.modchart.mods;

class Confusion extends BaseModifier {
	var confusionX:LaneModValue = new LaneModValue("confusionx", "");
	var confusionY:LaneModValue = new LaneModValue("confusiony", "");
	var confusion:LaneModValue = new LaneModValue("confusion", "");

	var confusionOffsetX:LaneModValue = new LaneModValue("confusionoffsetx", "");
	var confusionOffsetY:LaneModValue = new LaneModValue("confusionoffsety", "");
	var confusionOffset:LaneModValue = new LaneModValue("confusionoffset", "");

	// maybe later there'll be a Note.beat. then i'll add dizzy.

	public function new(parent:ModchartManager) {
		super(parent, 0);
	}

	override function edit(queue:QueuedDraw) {
		if (queue.isSustain())
			return;
		queue.rotation.x += queue.beat * confusionX.addBoth(queue.lane) + confusionOffsetX.addBoth(queue.lane);
		queue.rotation.y += queue.beat * confusionY.addBoth(queue.lane) + confusionOffsetY.addBoth(queue.lane);
		queue.rotation.z += queue.beat * confusion.addBoth(queue.lane) + confusionOffset.addBoth(queue.lane);
	}
}