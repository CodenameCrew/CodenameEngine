package funkin.game;

class Splash extends FunkinSprite
{
	/**
	 * The current splash strum
	 * WARNING: It can be null
	 */
	public var strum:Null<Strum>;

	/**
	 * Shortcut to `strum.ID`
	 * WARNING: It can be null
	 */
	public var strumID:Null<Int>;

	public static function copyFrom(source:Splash):Splash
	{
		var spr = new Splash();
		@:privateAccess {
			spr.setPosition(source.x, source.y);
			spr.frames = source.frames;
			spr.animation.copyFrom(source.animation);
			spr.visible = source.visible;
			spr.alpha = source.alpha;
			spr.antialiasing = source.antialiasing;
			spr.scale.set(source.scale.x, source.scale.y);
			spr.scrollFactor.set(source.scrollFactor.x, source.scrollFactor.y);
			spr.skew.set(source.skew.x, source.skew.y);
			spr.zoomFactor = source.zoomFactor;
			spr.animOffsets = source.animOffsets.copy();
		}
		return spr;
	}
}
