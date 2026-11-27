package funkin.game.modchart.mods;

class Stealth extends BaseModifier {
	var stealth:LaneModValue = new LaneModValue("stealth", "");
	var dark:LaneModValue = new LaneModValue("dark", "");

	var hidden:ModifierFloat = 0;
	@:optional var hiddenOffset:ModifierFloat = 0;
	var sudden:ModifierFloat = 0;
	@:optional var suddenOffset:ModifierFloat = 0;

	var stealthGlowRed:LaneModValue = new LaneModValue("stealthglowred", "", 1, ["stealthgr"]);
	var stealthGlowGreen:LaneModValue = new LaneModValue("stealthglowgreen", "", 1, ["stealthgg"]);
	var stealthGlowBlue:LaneModValue = new LaneModValue("stealthglowblue", "", 1, ["stealthgb"]);

	@:optional var stealthType:ModifierInt = 0;

	function getRemap(distance:Float, multOffset:Float, pixOffset:Float, from:Float, to:Float) {
		final swapRanges = from > to;
		return CoolUtil.bound(
			FlxMath.remapToRange(
				distance,
				FlxG.height * (0.45 + multOffset) + pixOffset,
				FlxG.height * (0.55 + multOffset) + pixOffset,
				from,
				to
			),
			swapRanges ? to : from,
			swapRanges ? from : to
		);
	}

	override function edit(queue:QueuedDraw) {
		queue.stealthColor.x *= stealthGlowRed.multBoth(queue.lane);
		queue.stealthColor.y *= stealthGlowGreen.multBoth(queue.lane);
		queue.stealthColor.z *= stealthGlowBlue.multBoth(queue.lane);

		if (queue.isForStrum()) {
			queue.stealth += dark.addBoth(queue.lane);
			return;
		}

		final regionMult = Math.max((hidden + sudden) - 1.0, 0.0);

		final usedDistance = switch (stealthType) {
			case 0: (queue.position.y - FlxG.height * 0.5) + FlxG.height * 0.5;// * (queue.scrollMult > 0 ? 1 : -1) + FlxG.height * 0.5;
			case 2: queue.originalDistance;
			default: queue.distance;
		}
		queue.stealth += getRemap(usedDistance, -0.25 * regionMult, 160 * hiddenOffset, hidden, 0);
		queue.stealth += getRemap(usedDistance, 0.15 * regionMult, 160 * suddenOffset, 0, sudden);
		queue.stealth += stealth.addBoth(queue.lane);
	}
}