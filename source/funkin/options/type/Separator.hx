package funkin.options.type;

import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.FlxBasic;

class Separator extends FlxSprite {
	var separatorHeight:Float;
	public function new(height:Float = 67) {
		super();
		separatorHeight = height;
	}

	override function initVars() {
		flixelType = OBJECT;

		offset = FlxPoint.get();
		origin = FlxPoint.get();
		scale = FlxPoint.get(1, 1);
		scrollFactor = FlxPoint.get(1, 1);

		initMotionVars();
	}

	override function update(elapsed:Float) {}
	override function draw() {}

	override function get_height():Float return separatorHeight;
	override function get_width():Float return 600;
}