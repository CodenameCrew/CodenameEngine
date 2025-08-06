package funkin.backend.utils;

import openfl.display.Sprite;

final class ShaderResizeFix {
	public static var doResizeFix:Bool = true;

	public static function init() {
		FlxG.signals.gameResized.add((w:Int, h:Int) -> {fixSpritesShadersSizes();});
	}

	public inline static function fixSpritesShadersSizes() {
		if (!doResizeFix) return;

		fixSpriteShaderSize(Main.instance);
		if (FlxG.game != null) fixSpriteShaderSize(FlxG.game);

		if (FlxG.cameras == null) return;
		for (cam in FlxG.cameras.list) {
			@:privateAccess
			if (cam != null && (cam._filters != null && cam._filters.length > 0))
				fixSpriteShaderSize(cam.flashSprite);
		}
	}

	public inline static function fixSpriteShaderSize(sprite:Sprite) // Shout out to Ne_Eo for bringing this to my attention
	{
		if (sprite == null) return;

		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
			sprite.__cacheBitmapData2 = null;
			sprite.__cacheBitmapData3 = null;
			sprite.__cacheBitmapColorTransform = null;
		}
	}
}