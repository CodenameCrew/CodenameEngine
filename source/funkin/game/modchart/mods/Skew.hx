package funkin.game.modchart.mods;

import openfl.geom.Vector3D;

class Skew extends BaseModifier {
	var skewX:ModifierFloat = 0;
	var skewY:ModifierFloat = 0;

	var noteSkewX:LaneModValue = new LaneModValue("noteskewx", "");
	var noteSkewY:LaneModValue = new LaneModValue("noteskewy", "");

	public function new(parent:ModchartManager) {
		super(parent, 0);
	}

	override function willEditVertex():Bool {return true;}
	override function editVertex(vertex:Vector3D, queue:QueuedDraw) {
		final oldX = vertex.x;
		final oldY = vertex.y;

		vertex.x += (oldY - queue.fieldCenter.y) * skewX;
		vertex.y += FlxG.height * ((oldX - queue.fieldCenter.x) / (queue.arrowSize * queue.field.members.length)) * skewY;

		if (queue.isSustain())
			return;

		vertex.x += (oldY - queue.position.y) * noteSkewX.addBoth(queue.lane);
		vertex.y += (oldX - queue.position.x) * noteSkewY.addBoth(queue.lane);
	}
}