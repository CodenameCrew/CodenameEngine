package funkin.game.modchart.mods;

class Move extends BaseModifier {
	var movex:LaneModValue = new LaneModValue("movex", "");
	var movey:LaneModValue = new LaneModValue("movey", "");
	var movez:LaneModValue = new LaneModValue("movez", "");

	var transformx:LaneModValue = new LaneModValue("transform", "x");
	var transformy:LaneModValue = new LaneModValue("transform", "y");
	var transformz:LaneModValue = new LaneModValue("transform", "z");

	public function new(parent:ModchartManager) {
		super(parent, 0);
	}

	override function edit(queue:QueuedDraw) {
		queue.position.x += queue.arrowSize * (movex.get(queue.lane) + movex.base());
		queue.position.y += queue.arrowSize * (movey.get(queue.lane) + movey.base());
		queue.position.z += queue.arrowSize * (movez.get(queue.lane) + movez.base());

		queue.position.x += transformx.get(queue.lane) + transformx.base();
		queue.position.y += transformy.get(queue.lane) + transformy.base();
		queue.position.z += transformz.get(queue.lane) + transformz.base();
	}
}