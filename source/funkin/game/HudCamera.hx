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
	public override function alterScreenPosition(spr:FlxObject, pos:FlxPoint) {
		if (downscroll) {
			pos.set(pos.x, height - pos.y - spr.height);
		}
		return pos;
	}
}
