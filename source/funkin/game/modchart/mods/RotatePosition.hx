package funkin.game.modchart.mods;

import openfl.geom.Vector3D;

class RotatePosition extends BaseModifier {
	var localRotateX:LaneModValue = new LaneModValue("localrotatex", "");
	var localRotateY:LaneModValue = new LaneModValue("localrotatey", "");
	var localRotateZ:LaneModValue = new LaneModValue("localrotatez", "");

	var centerRotateX:LaneModValue = new LaneModValue("centerrotatex", "");
	var centerRotateY:LaneModValue = new LaneModValue("centerrotatey", "");
	var centerRotateZ:LaneModValue = new LaneModValue("centerrotatez", "");

	public function new(parent:ModchartManager) {
		super(parent, 0);
	}

	final screenCenter:Vector3D = new Vector3D();
	override function edit(queue:QueuedDraw) {
		final localX = localRotateX.addBoth(queue.lane);
		final localY = localRotateY.addBoth(queue.lane);
		final localZ = localRotateZ.addBoth(queue.lane);

		if (MathUtil.notEqual(localX, 0) || MathUtil.notEqual(localY, 0) || MathUtil.notEqual(localZ, 0)) {
			queue.position.decrementBy(queue.fieldCenter);
			ModchartManager.rotateVec(queue.position, localX, localY, localZ);
			queue.position.incrementBy(queue.fieldCenter);
		}


		final centerX = centerRotateX.addBoth(queue.lane);
		final centerY = centerRotateY.addBoth(queue.lane);
		final centerZ = centerRotateZ.addBoth(queue.lane);

		if (MathUtil.notEqual(centerX, 0) || MathUtil.notEqual(centerY, 0) || MathUtil.notEqual(centerZ, 0)) {
			// some mods may subject this size to change sooooo
			screenCenter.setTo(FlxG.width * 0.5, FlxG.height * 0.5, 0);
			queue.position.decrementBy(screenCenter);
			queue.fieldCenter.decrementBy(screenCenter);

			ModchartManager.rotateVec(queue.position, centerX, centerY, centerZ);
			ModchartManager.rotateVec(queue.fieldCenter, centerX, centerY, centerZ);

			queue.position.incrementBy(screenCenter);
			queue.fieldCenter.incrementBy(screenCenter);
		}
	}
}