package funkin.menus.ui.effects;

import funkin.menus.ui.effects.RegionEffect;

class ShakeEffect extends RegionEffect {
	public var intensityX:Float = 2;
	public var intensityY:Float = 2;

	public function new(?x:Float = 2, ?y:Float = 2) {
		super();
		intensityX = x;
		intensityY = y;
	}

	override function willModify(index:Int, lineIndex:Int, renderData:AlphabetRenderData) {
		return (intensityX != 0 || intensityY != 0) && super.willModify(index, lineIndex, renderData);
	}

	override function modify(index:Int, lineIndex:Int, renderData:AlphabetRenderData):Void {
		renderData.offsetX += FlxG.random.float(-intensityX, intensityX);
		renderData.offsetY += FlxG.random.float(-intensityY, intensityY);
	}
}