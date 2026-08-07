package funkin.backend.system;

import lime.graphics.Image;
import openfl.display.BitmapData;

@:deprecated("Use openfl.display.BitmapData.toHardware instead.")
class OptimizedBitmapData extends BitmapData {
	@SuppressWarnings("checkstyle:Dynamic")
	@:noCompletion private override function __fromImage(image:#if lime Image #else Dynamic #end):Void
	{
		super.__fromImage(image);
		toHardware();
	}
}