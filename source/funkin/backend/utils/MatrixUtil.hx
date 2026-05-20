package funkin.backend.utils;

import flixel.graphics.frames.FlxFrame;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.util.typeLimit.OneOfTwo;
import funkin.backend.system.FakeCamera;
import funkin.backend.system.FakeCamera.FakeCallCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMatrix;
import flixel.math.FlxMath;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import openfl.geom.Rectangle;

interface IPrePostDraw {
	public function preDraw():Void;
	public function postDraw():Void;
}

@:access(flixel.FlxCamera)
@:access(flixel.FlxSprite)
@:access(flixel.math.FlxMatrix)
@:access(openfl.geom.Matrix)
final class MatrixUtil {
	public static function getMatrixPosition(sprite:FlxSprite, points:OneOfTwo<FlxPoint, Array<FlxPoint>>, ?camera:FlxCamera, _width:Float = 1, _height:Float = 1):Array<FlxPoint>
	{
		if(camera == null) camera = sprite.camera;
		
		if(!Std.isOfType(points, Array)) points = [cast points];

		var nc:FakeCamera = FakeCamera.instance;
		nc.width = camera.width;
		nc.height = camera.height;
		nc.zoom = camera.zoom;
		nc.scroll.set(camera.scroll.x, camera.scroll.y);
		nc.pixelPerfectRender = camera.pixelPerfectRender;

		var pointsArray:Array<FlxPoint> = cast points;

		if(sprite is IPrePostDraw) {
			var postDraw = cast(sprite, IPrePostDraw);
			postDraw.preDraw();
			sprite.drawComplex(nc);
			postDraw.postDraw();
		} else {
			sprite.drawComplex(nc);
		}
		transformPoints(sprite, pointsArray, sprite._matrix, camera, _width, _height);

		return pointsArray;
	}

	/**
	 * Warning: modifies the points in the array
	**/
	public static function transformPoints(sprite:FlxSprite, points:Array<FlxPoint>, matrix:FlxMatrix, ?camera:FlxCamera, _width:Float = 1, _height:Float = 1, doCameraTransform:Bool = true):Array<FlxPoint> {
		var isFunkinSprite = sprite is FunkinSprite;
		var funkinSprite:FunkinSprite = null;
		if(isFunkinSprite) funkinSprite = cast sprite;

		for(point in points) {
			var px = point.x * _width;
			var py = point.y * _height;

			var x = matrix.a * px + matrix.c * py + matrix.tx;
			var y = matrix.b * px + matrix.d * py + matrix.ty;

			if(doCameraTransform) {
				// Reset to ingame coords
				x += camera.scroll.x;
				y += camera.scroll.y;

				if(isFunkinSprite) {
					var ratio = 1 - FlxMath.lerp(1 / camera.zoom, 1, funkinSprite.zoomFactor);
					x += camera.width / 2 * ratio;
					y += camera.height / 2 * ratio;
				}
			}
			point.set(x, y);
		}
		return points;
	}

	private static function rawTransformPoints(points:Array<FlxPoint>, matrix:FlxMatrix, _width:Float = 1, _height:Float = 1):Array<FlxPoint> {
		for(point in points) {
			var px = point.x * _width;
			var py = point.y * _height;

			var x = matrix.a * px + matrix.c * py + matrix.tx;
			var y = matrix.b * px + matrix.d * py + matrix.ty;

			point.set(x, y);
		}
		return points;
	}
}
