package funkin.menus.ui.effects;

import flixel.util.FlxColor;
import funkin.menus.ui.effects.RegionEffect;

class ColorWaveEffect extends RegionEffect {
	public var period:Float = 30;
	public var color1:FlxColor;
	public var color2:FlxColor;

	public function new(color1:FlxColor, color2:FlxColor, ?period:Float = 30) {
		super();
		speed = 5;
		this.color1 = color1;
		this.color2 = color2;
		this.period = period;
	}

	override function modify(index:Int, lineIndex:Int, renderData:AlphabetRenderData) {
		renderData.color = FlxColor.interpolate(color1, color2, (-effectTime + lineIndex).positiveModulo(period) / period);
	}
}