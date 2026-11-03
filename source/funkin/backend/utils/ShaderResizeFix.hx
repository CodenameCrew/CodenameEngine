package funkin.backend.utils;

import openfl.display.Sprite;

// DEPRECATED, Done automatically in cne-openfl openfl.display.DisplayObjectRenderer
final class ShaderResizeFix {
	public static var doResizeFix:Bool = false;

	public static function init() {}

	public inline static function fixSpritesShadersSizes() {}

	public inline static function fixSpriteShaderSize(sprite:Sprite)
	@:privateAccess {
		if (sprite == null) return;

		sprite.__cacheBitmap = null;
		sprite.__cacheBitmapData = null;
		sprite.__cacheBitmapData2 = null;
		sprite.__cacheBitmapData3 = null;
		sprite.__cacheBitmapColorTransform = null;
	}
}