package funkin.backend.system;

import lime.graphics.Image;
import lime.graphics.cairo.CairoImageSurface;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.utils.BitmapDataUtil;

@:deprecated("Use openfl.utils.BitmapDataUtil.toHardware instead.")
class OptimizedBitmapData extends BitmapData {
	@SuppressWarnings("checkstyle:Dynamic")
	@:noCompletion private override function __fromImage(image:#if lime Image #else Dynamic #end):Void
	{
		#if lime
		if (image != null && image.buffer != null)
		{
			this.image = image;

			width = image.width;
			height = image.height;
			rect = new Rectangle(0, 0, image.width, image.height);

			__textureWidth = width;
			__textureHeight = height;

			#if sys
			image.format = BGRA32;
			image.premultiplied = true;
			#end

			__isValid = true;
			readable = true;

			BitmapDataUtil.toHardware(this);
		}
		#end
	}
}