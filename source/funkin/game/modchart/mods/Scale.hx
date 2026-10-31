package funkin.game.modchart.mods;

class Scale extends BaseModifier {
	var scale:LaneModValue = new LaneModValue("scale", "", 1);
	var scalex:LaneModValue = new LaneModValue("scalex", "", 1);
	var scaley:LaneModValue = new LaneModValue("scaley", "", 1);
	//var scalez:LaneModValue = new LaneModValue("scalez", "");
	
	var squish:LaneModValue = new LaneModValue("squish", "", 0);
	var stretch:LaneModValue = new LaneModValue("stretch", "", 0);

	var tiny:LaneModValue = new LaneModValue("tiny", "", 0);
	var tinyx:LaneModValue = new LaneModValue("tinyx", "", 0);
	var tinyy:LaneModValue = new LaneModValue("tinyy", "", 0);

	public function new(parent:ModchartManager) {
		super(parent, 0);
	}

	override function edit(queue:QueuedDraw) {
		var mainScale = scale.base() * scale.get(queue.lane);
		mainScale *= Math.pow(0.5, tiny.base() + tiny.get(queue.lane));

		final squish = squish.base() + squish.get(queue.lane);
		final stretch = stretch.base() + stretch.get(queue.lane);

		var scaleX = mainScale * scalex.base() * scaley.get(queue.lane);
		scaleX *= Math.pow(0.5, tinyx.base() + tinyx.get(queue.lane));
		scaleX *= FlxMath.lerp(1, 0.5, stretch);
		scaleX *= FlxMath.lerp(1, 2, squish);

		var scaleY = mainScale * scaley.base() * scaley.get(queue.lane);
		scaleY *= Math.pow(0.5, tinyy.base() + tinyy.get(queue.lane));
		scaleY *= FlxMath.lerp(1, 2, stretch);
		scaleY *= FlxMath.lerp(1, 0.5, squish);

		queue.scale.x *= scaleX;
		queue.scale.y *= scaleY;
	}
}