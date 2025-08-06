package funkin.menus.ui.effects;

import funkin.menus.ui.effects.RegionEffect;

class WaveEffect extends RegionEffect {
	public var intensityX:Float = 0;
	public var intensityY:Float = 5;
	public var period:Float = 10;

	public function new(?x:Float = 0, ?y:Float = 5, ?p:Float = 10) {
		super();
		speed = 3;
		intensityX = x;
		intensityY = y;
		period = p;
	}

	override function willModify(index:Int, lineIndex:Int, renderData:AlphabetRenderData) {
		return period != 0 && (intensityX != 0 || intensityY != 0) && super.willModify(index, lineIndex, renderData);
	}

	override function modify(index:Int, lineIndex:Int, renderData:AlphabetRenderData):Void {
		renderData.offsetX += intensityX * Math.cos((effectTime + lineIndex) * Math.PI * 2 / period);
		renderData.offsetY += intensityY * Math.sin((effectTime + lineIndex) * Math.PI * 2 / period);
	}
}