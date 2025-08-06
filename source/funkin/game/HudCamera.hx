package funkin.game;

import flixel.math.FlxPoint;

/**
 * Camera meant for PlayState hud, allows for flipping the camera.
**/
class HudCamera extends FlxCamera {
	/**
	 * Whenever the camera should flip the y axis.
	 * Keeps the sprites not flipped, but the positions are flipped.
	 */
	public var downscroll:Bool = false;
	//public override function update(elapsed:Float) {
	//	super.update(elapsed);
	//	// flipY = downscroll;
	//}


	// public override function drawPixels(?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false,
	// 	?shader:FlxShader):Void
	// {
	// 	if (downscroll) {
	// 		matrix.scale(1, -1);
	// 		matrix.translate(0, height);
	// 	}
	// 	super.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
	// }


	public override function alterScreenPosition(spr:FlxObject, pos:FlxPoint) {
		if (downscroll) {
			pos.set(pos.x, height - pos.y - spr.height);
		}
		return pos;
	}
}