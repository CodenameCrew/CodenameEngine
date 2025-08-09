package funkin.menus.ui.effects;

import flixel.util.FlxColor;

class AlphabetRenderData { 
	public var parent:Alphabet;
	public var letter:String;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var color(get, set):FlxColor;
	public var red:Float = 0;
	public var green:Float = 0;
	public var blue:Float = 0;
	public var alpha:Float = 1;

	public function new(parent:Alphabet) {
		this.parent = parent;
	}

	public function reset(parent:Alphabet, red:Float, green:Float, blue:Float, alpha:Float, letter:String) {
		this.parent = parent;
		this.letter = letter;
		this.offsetX = 0;
		this.offsetY = 0;
		this.red = red;
		this.green = green;
		this.blue = blue;
		this.alpha = alpha;
	}

	function get_color():FlxColor {
		return FlxColor.fromRGBFloat(red, green, blue);
	}
	function set_color(value:FlxColor):FlxColor {
		red = value.redFloat;
		green = value.greenFloat;
		blue = value.blueFloat;
		return value;
	}
}

class RegionEffect {
	public var effectTime:Float = 0;
	public var speed:Float = 1;
	public var enabled:Bool = true;
	public var regionMin:Array<Int> = [];
	public var regionMax:Array<Int> = [];

	public function new() {}

	public function resetRegions() {
		regionMin.splice(0, regionMin.length);
		regionMax.splice(0, regionMax.length);
	}

	public function addRegion(min:Int, max:Int) {
		regionMin.push(min);
		regionMax.push(max);
	}

	public function willModify(index:Int, lineIndex:Int, renderData:AlphabetRenderData):Bool {
		if (!enabled) return false;

		if (regionMin.length == 0) regionMin.push(0);
		if (regionMax.length == 0) regionMax.push(-1);

		for (i in 0...Std.int(Math.min(regionMin.length, regionMax.length))) {
			var min = (regionMin[i] < 0) ? renderData.parent.text.length - regionMin[i] : regionMin[i];
			var max = (regionMax[i] < 0) ? renderData.parent.text.length - regionMax[i] : regionMax[i];
			if (index >= min && index <= max)
				return true;
		}
		return false;
	}

	public function modify(index:Int, lineIndex:Int, renderData:AlphabetRenderData):Void {}
}