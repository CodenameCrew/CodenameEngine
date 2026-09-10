package funkin.backend;

import animate.FlxAnimate;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxAngle;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.graphics.frames.FlxFrame;

import funkin.backend.system.Flags;

@:access(animate.FlxAnimate)
class FunkinText extends FlxText
{
	public var zoomFactor:Float = 1;
	public var zoomFactorEnabled:Bool = true;

	public var angleFactor:Float = 1;
	public var angleFactorEnabled:Bool = true;

	/**
	 * Change the skew of your sprite's graphic.
	 */
	public var skew(default, null):FlxPoint;

	/**
	 * The matrix to use for rendering if `matrixExposed` is true.
	 */
	public var transformMatrix(default, null):FlxMatrix;

	/**
	 * Whether to draw the matrix exposed with `transformMatrix`.
	 */
	public var matrixExposed:Bool = false;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, ?Size:Int, Border:Bool = true)
	{
		if (Size == null) Size = Flags.DEFAULT_FONT_SIZE;

		super(X, Y, FieldWidth, Text, Size);

		setFormat(Paths.font(Flags.DEFAULT_FONT), Size, FlxColor.WHITE);

		if (Border)
		{
			borderStyle = OUTLINE;
			borderSize = 1;
			borderColor = 0xFF000000;
		}
	}

	override function initVars()
	{
		super.initVars();
		skew = new FlxPoint();
		transformMatrix = new FlxMatrix();
	}

	override function destroy()
	{
		super.destroy();
		skew = FlxDestroyUtil.put(skew);
		transformMatrix = null;
	}

	override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);

		if (frameOffsetAngle != null && frameOffsetAngle != angle)
		{
			var angleOff = (frameOffsetAngle - angle) * FlxAngle.TO_RAD;
			var cos = Math.cos(angleOff), sin = Math.sin(angleOff);
			// cos doesnt need to be negated
			_matrix.rotateWithTrig(cos, -sin);
			_matrix.translate(-frameOffset.x, -frameOffset.y);
			_matrix.rotateWithTrig(cos, sin);
		}
		else
			_matrix.translate(-frameOffset.x, -frameOffset.y);

		_matrix.scale(scale.x, scale.y);

		if (matrixExposed) _matrix.concat(transformMatrix);
		else {
			if (angle != 0)
			{
				updateTrig();
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
			}
			if (skew.x != 0 || skew.y != 0)
			{
				FlxAnimate._skewMatrix.setTo(1, Math.tan(skew.y * FlxAngle.TO_RAD), Math.tan(skew.x * FlxAngle.TO_RAD), 1, 0, 0);
				_matrix.concat(FlxAnimate._skewMatrix);
			}
		}

		getScreenPosition(_point, camera).subtractPoint(offset).addPoint(origin);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}

		// Copied from FunkinSprite
		final ox = camera.width * 0.5, oy = camera.height * 0.5;
		final sx = (camera.scaleX > 0.0 ? Math.max : Math.min)(0.0, (1.0 - zoomFactor) / camera.scaleX + zoomFactor);
		final sy = (camera.scaleY > 0.0 ? Math.max : Math.min)(0.0, (1.0 - zoomFactor) / camera.scaleY + zoomFactor);

		if (zoomFactorEnabled && zoomFactor != 1) {
			_matrix.setTo(
				_matrix.a * sx, _matrix.b * sy,
				_matrix.c * sx, _matrix.d * sy,
				(_matrix.tx - ox) * sx + ox,
				(_matrix.ty - oy) * sy + oy
			);
		}

		if (angleFactorEnabled && angleFactor != 1) {
			_matrix.translate(-ox, -oy);
			_matrix.rotate(-camera.angle * FlxAngle.TO_RAD * (1.0 - angleFactor));
			_matrix.translate(ox, oy);
		}
		
		if (layer != null)
			layer.drawPixels(this, camera, _frame, framePixels, _matrix, colorTransform, blend, antialiasing, shaderEnabled ? shader : null);
		else
			camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shaderEnabled ? shader : null);
	}

	override function getScreenBounds(?rect:FlxRect, ?camera:FlxCamera):FlxRect
	{
		if (camera == null) camera = FlxG.camera;
		rect = super.getScreenBounds(rect, camera);

		if (zoomFactorEnabled && zoomFactor != 1) {
			final ox = camera.width * 0.5, oy = camera.height * 0.5;
			final sx = (camera.scaleX > 0.0 ? Math.max : Math.min)(0.0, (1.0 - zoomFactor) / camera.scaleX + zoomFactor);
			final sy = (camera.scaleY > 0.0 ? Math.max : Math.min)(0.0, (1.0 - zoomFactor) / camera.scaleY + zoomFactor);

			rect.set(
				(rect.x - ox) * sx + ox,
				(rect.y - oy) * sy + oy,
				rect.width * sx,
				rect.height * sy
			);
		}

		return rect;
	}
}
