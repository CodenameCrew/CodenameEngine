package funkin.backend.utils;

import flixel.graphics.frames.FlxFrame;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.util.typeLimit.OneOfTwo;
import funkin.backend.system.FakeCamera;
import funkin.backend.system.FakeCamera.FakeCallCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
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
		//if(_width == -1) _width = sprite.width;
		//if(_height == -1) _height = sprite.height;
		if(camera == null) camera = sprite.camera;
		if(points is FlxBasePoint) points = [points];
		var isFunkinSprite = sprite is FunkinSprite;
		var funkinSprite:FunkinSprite = null;
		if(isFunkinSprite) funkinSprite = cast sprite;
		var isAnimateAtlas = isFunkinSprite && funkinSprite.animateAtlas != null;

		var nc:FakeCamera = isAnimateAtlas ? FakeCallCamera.instance : FakeCamera.instance;
		nc.zoom = camera.zoom;
		nc.scroll.set(camera.scroll.x, camera.scroll.y);
		nc.pixelPerfectRender = camera.pixelPerfectRender;

		var points:Array<FlxPoint> = cast points;

		if(isAnimateAtlas) {
			var cnc = FakeCallCamera.instance;
			var sprite = funkinSprite;
			var oldOnDraw = cnc.onDraw;

			// TODO: fix rotation
			// TODO: fix skew

			var boundsTopLeft = new FlxPoint(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
			var boundsTopRight = new FlxPoint(Math.NEGATIVE_INFINITY, Math.POSITIVE_INFINITY);
			var boundsBottomLeft = new FlxPoint(Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY);
			var boundsBottomRight = new FlxPoint(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);

			cnc.onDraw = function(?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false, ?shader:FlxShader) {
				// cnc is already perfect rn
				// so we need to manually process the limb
				var points = [
					// corners
					FlxPoint.get(0, 0),
					FlxPoint.get(1, 0),
					FlxPoint.get(0, 1),
					FlxPoint.get(1, 1)
				];

				rawTransformPoints(points, matrix, frame.sourceSize.x, frame.sourceSize.y);

				// sort the points, incase like they were transformed with a scale -1 matrix

				var topLeft:FlxPoint = points[0];
				var topRight:FlxPoint = points[1];
				var bottomLeft:FlxPoint = points[2];
				var bottomRight:FlxPoint = points[3];

				if (points[0].y > points[1].y) {
					topLeft = points[1];
					topRight = points[0];
				}
				if (points[2].y > points[3].y) {
					bottomLeft = points[3];
					bottomRight = points[2];
				}

				if (topLeft.x > topRight.x) {
					var temp = topLeft;
					topLeft = topRight;
					topRight = temp;
				}

				if (bottomLeft.x > bottomRight.x) {
					var temp = bottomLeft;
					bottomLeft = bottomRight;
					bottomRight = temp;
				}

				// points should now contain the corners of the limb

				// trace("Corners of limb: " + points);

				// set the max bounds of each corner of the limb
				if(topLeft.x < boundsTopLeft.x) boundsTopLeft.x = topLeft.x;
				if(topLeft.y < boundsTopLeft.y) boundsTopLeft.y = topLeft.y;
				if(topRight.x > boundsTopRight.x) boundsTopRight.x = topRight.x;
				if(topRight.y < boundsTopRight.y) boundsTopRight.y = topRight.y;
				if(bottomLeft.x < boundsBottomLeft.x) boundsBottomLeft.x = bottomLeft.x;
				if(bottomLeft.y > boundsBottomLeft.y) boundsBottomLeft.y = bottomLeft.y;
				if(bottomRight.x > boundsBottomRight.x) boundsBottomRight.x = bottomRight.x;
				if(bottomRight.y > boundsBottomRight.y) boundsBottomRight.y = bottomRight.y;

				// recycle the points
				for(point in points) point.put();
			}
			var cameras = sprite._cameras;
			var oldVisible = cnc.visible;
			cnc.visible = true;
			sprite._cameras = [cnc];
			sprite.draw();
			sprite._cameras = cameras;
			cnc.visible = oldVisible;
			cnc.onDraw = oldOnDraw;

			// fake transform

			//trace("");
			//trace("topLeft: " + boundsTopLeft);
			//trace("topRight: " + boundsTopRight);
			//trace("bottomLeft: " + boundsBottomLeft);
			//trace("bottomRight: " + boundsBottomRight);
			//trace("Before transform");
			//trace(points);

			for(point in points) {
				//var x = matrix.__transformX(point.x * _width, point.y * _height);
				//var y = matrix.__transformY(point.x * _width, point.y * _height);
				// apply using boundsTopLeft, boundsTopRight, boundsBottomLeft, boundsBottomRight
				// matrix doesnt work for this
				var x = FlxMath.lerp(
					FlxMath.lerp(boundsTopLeft.x, boundsTopRight.x, point.x),
					FlxMath.lerp(boundsBottomLeft.x, boundsBottomRight.x, point.x),
					point.y
				);
				var y = FlxMath.lerp(
					FlxMath.lerp(boundsTopLeft.y, boundsTopRight.y, point.x),
					FlxMath.lerp(boundsBottomLeft.y, boundsBottomRight.y, point.x),
					point.y
				);

				//trace("(" + point.x + ", " + point.y + ") -> (" + x + ", " + y + ")");

				// reset to ingame coords
				x += camera.scroll.x;
				y += camera.scroll.y;

				if(isFunkinSprite) {
					var ratio = 1 - FlxMath.lerp(1 / camera.zoom, 1, funkinSprite.zoomFactor);
					x += camera.width / 2 * ratio;
					y += camera.height / 2 * ratio;
				}
				point.set(x, y);
			}

			//trace("After transform");
			//trace(points);
		} else {
			if(sprite is IPrePostDraw) {
				var postDraw = cast(sprite, IPrePostDraw);
				postDraw.preDraw();
				sprite.drawComplex(nc);
				postDraw.postDraw();
			} else {
				sprite.drawComplex(nc);
			}
			transformPoints(sprite, points, sprite._matrix, camera, _width, _height);
		}

		return points;
	}

	/**
	 * Warning: modifies the points in the array
	**/
	public static function transformPoints(sprite:FlxSprite, points:Array<FlxPoint>, matrix:FlxMatrix, ?camera:FlxCamera, _width:Float = 1, _height:Float = 1, doCameraTransform:Bool = true):Array<FlxPoint> {
		var isFunkinSprite = sprite is FunkinSprite;
		var funkinSprite:FunkinSprite = null;
		if(isFunkinSprite) funkinSprite = cast sprite;

		for(point in points) {
			var x = matrix.__transformX(point.x * _width, point.y * _height);
			var y = matrix.__transformY(point.x * _width, point.y * _height);

			if(doCameraTransform) {
				// reset to ingame coords
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
			var x = matrix.__transformX(point.x * _width, point.y * _height);
			var y = matrix.__transformY(point.x * _width, point.y * _height);

			point.set(x, y);
		}
		return points;
	}
}