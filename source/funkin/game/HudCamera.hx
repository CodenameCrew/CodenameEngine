package funkin.game;

import flixel.math.FlxPoint;

/**
 * Camera meant for PlayState hud, allows for flipping the camera.
**/
class HudCamera extends FlxCamera {
	/**
	 * Whenever the camera should flip the y axis.
	 * Sprites stay visually intact, only their Y positions are flipped.
	 */
	public var downscroll:Bool = false;

	/**
	 * A blacklist array of which sprites NOT to flip.
	 * May be helpful for manual positioning in scripts, but must be initialized first.
	 * It may not work correctly on notes and strums, for now
	 */
	public var noFlip:Array<FlxObject> = null;

	public override function alterScreenPosition(spr:FlxObject, pos:FlxPoint) {
		if (noFlip != null && noFlip.length > 0 && noFlip.contains(spr)) return pos;
		if (downscroll) {
			pos.set(pos.x, height - pos.y - spr.height);
		}
		return pos;
	}
}