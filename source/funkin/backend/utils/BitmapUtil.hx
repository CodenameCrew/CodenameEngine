package funkin.backend.utils;

import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

final class BitmapUtil {
	/**
	 * Returns the most present color in a Bitmap.
	 * @param bmap Bitmap
	 * @return FlxColor Color that is the most present.
	 */
	public static function getMostPresentColor(bmap:BitmapData):FlxColor {
		// map containing all the colors and the number of times they've been assigned.
		var colorMap:Map<FlxColor, Float> = [];
		var color:FlxColor = 0;
		var fixedColor:FlxColor = 0;

		for(y in 0...bmap.height) {
			for(x in 0...bmap.width) {
				color = bmap.getPixel32(x, y);
				fixedColor = 0xFF000000 | (color & 0xFFFFFF);
				if (!colorMap.exists(fixedColor))
					colorMap[fixedColor] = 0;
				colorMap[fixedColor] += color.alphaFloat;
			}
		}

		var mostPresentColor:FlxColor = 0;
		var mostPresentColorCount:Float = -1;
		for(c=>n in colorMap) {
			if (n > mostPresentColorCount) {
				mostPresentColorCount = n;
				mostPresentColor = c;
			}
		}
		return mostPresentColor;
	}
	/**
	 * Returns the most present saturated color in a Bitmap.
	 * @param bmap Bitmap
	 * @return FlxColor Color that is the most present.
	 */
	public static function getMostPresentSaturatedColor(bmap:BitmapData):FlxColor {
		// map containing all the colors and the number of times they've been assigned.
		var colorMap:Map<FlxColor, Float> = [];
		var color:FlxColor = 0;
		var fixedColor:FlxColor = 0;

		for(y in 0...bmap.height) {
			for(x in 0...bmap.width) {
				color = bmap.getPixel32(x, y);
				fixedColor = 0xFF000000 | (color & 0xFFFFFF);
				if (!colorMap.exists(fixedColor))
					colorMap[fixedColor] = 0;
				colorMap[fixedColor] += color.alphaFloat * 0.33 + (0.67 * (color.saturation * (2 * (color.lightness > 0.5 ? 0.5 - (color.lightness) : color.lightness))));
			}
		}

		var mostPresentColor:FlxColor = 0;
		var mostPresentColorCount:Float = -1;
		for(c=>n in colorMap) {
			if (n > mostPresentColorCount) {
				mostPresentColorCount = n;
				mostPresentColor = c;
			}
		}
		return mostPresentColor;
	}

	/**
	 * Returns a new bitmap without any empty transperent space on the edges
	 * @param bitmap The bitmap to be cropped
	 */
	public static function crop(bitmap:BitmapData) {
		var bitmapBounds:Rectangle = BitmapUtil.bounds(bitmap);

		var croppedBitmap:BitmapData = new BitmapData(Std.int(bitmapBounds.width), Std.int(bitmapBounds.height), true, 0x00000000);
		croppedBitmap.copyPixels(bitmap, bitmapBounds, new Point(0,0));
		return croppedBitmap;
	}

	/**
	 * Get bounds of non empty pixels in the bitmap
	 * @param bitmap
	 * @return
	 */
	public static function bounds(bitmap:BitmapData, ?limit:Rectangle = null):Rectangle {
		var hasLimit:Bool = limit != null;
		// Searching bounds
		var startX:Int = hasLimit ? Std.int(limit.x) : 0;
		var startY:Int = hasLimit ? Std.int(limit.y) : 0;
		var endX:Int = hasLimit ? Std.int(limit.width) : bitmap.width;
		var endY:Int = hasLimit ? Std.int(limit.height) : bitmap.height;

		// Detected bounds
		var minX:Int = endX;
		var minY:Int = endY;
		var maxX:Int = startX;
		var maxY:Int = startY;

		for (y in startY...endY) {
			for (x in startX...endX) {
				if (bitmap.getPixel32(x, y) != 0x00000000) {
					if (x < minX) minX = x;
					if (y < minY) minY = y;
					if (x > maxX) maxX = x;
					if (y > maxY) maxY = y;
				}
			}
		}

		return new Rectangle(minX, minY, maxX-minX+1, maxY-minY+1);
	}
}