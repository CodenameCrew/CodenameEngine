package funkin.backend;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.math.FlxAngle;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.graphics.frames.FlxFrame;
import funkin.backend.system.Flags;

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
        if (Size == null)
            Size = Flags.DEFAULT_FONT_SIZE;

        super(X, Y, FieldWidth, Text, Size);

        setFormat(Paths.font(Flags.DEFAULT_FONT), Size, FlxColor.WHITE);

        if (Border)
        {
            borderStyle = OUTLINE;
            borderSize = 1;
            borderColor = 0xFF000000;
        }
    }

	var _rect2:FlxRect;

	override function initVars() {
		super.initVars();
		skew = new FlxPoint();
		transformMatrix = new FlxMatrix();
		_rect2 = FlxRect.get();
	}

    private inline function __shouldDoZoomFactor():Bool
    {
        return zoomFactorEnabled && zoomFactor != 1;
    }

    private inline function __prepareZoomFactor(rect:FlxRect, camera:FlxCamera):FlxRect {
		if (Flags.USE_LEGACY_ZOOM_FACTOR)
			return rect.set(
				camera.width * 0.5 + camera.scroll.x * scrollFactor.x,
				camera.height * 0.5 + camera.scroll.y * scrollFactor.y,
				(camera.scaleX > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleX, 1, zoomFactor)),
				(camera.scaleY > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleY, 1, zoomFactor))
			);
		else
			return rect.set(
				camera.width * 0.5,
				camera.height * 0.5,
				(camera.scaleX > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleX, 1, zoomFactor)),
				(camera.scaleY > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleY, 1, zoomFactor))
			);
	}

    private inline function __shouldDoAngleFactor():Bool
    {
        return angleFactorEnabled && angleFactor != 1;
    }

    private inline function __prepareAngleFactor(camera:FlxCamera):Float
    {
        return FlxMath.lerp(-camera.angle, 0, angleFactor);
    }

	// EVERYTHING AFTER THIS COMMENT IS STOLen from flixel animate ok sorry
	public override function drawComplex(camera:FlxCamera):Void
	{
		if (!__shouldDoZoomFactor() && !__shouldDoAngleFactor() && (skew.x == 0) && (skew.y == 0)) {
			return super.drawComplex(camera);
		}

		final frame = this._frame;
		final matrix = this._matrix; // TODO: Just use local?

		frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		prepareDrawMatrix(matrix, camera);

		if (layer != null)
			layer.drawPixels(this, camera, frame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
		else
			camera.drawPixels(frame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
	}

    function prepareDrawMatrix(matrix:FlxMatrix, camera:FlxCamera):Void {
		matrix.translate(-origin.x, -origin.y);
		if (frameOffsetAngle != null && frameOffsetAngle != angle)
		{
			var angleOff = (frameOffsetAngle - angle) * FlxAngle.TO_RAD;
			var cos = Math.cos(angleOff);
			var sin = Math.sin(angleOff);
			// cos doesnt need to be negated
			_matrix.rotateWithTrig(cos, -sin);
			_matrix.translate(-frameOffset.x, -frameOffset.y);
			_matrix.rotateWithTrig(cos, sin);
		}
		else
			_matrix.translate(-frameOffset.x, -frameOffset.y);

		matrix.scale(scale.x, scale.y);

		if (matrixExposed) matrix.concat(transformMatrix);
		else {
			if (angle != 0)
			{
				updateTrig();
				matrix.rotateWithTrig(_cosAngle, _sinAngle);
			}
			if (skew.x != 0 || skew.y != 0)
			{
				updateSkew();
				matrix.concat(_skewMatrix);
			}
		}

		getScreenPosition(_point, camera).subtractPoint(offset).add(origin.x, origin.y);
		matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
			preparePixelPerfectMatrix(matrix);
	
		if (__shouldDoZoomFactor() || __shouldDoAngleFactor()) {
			__prepareZoomFactor(_rect2, camera);

			if (__shouldDoZoomFactor()) {
				matrix.setTo(
					matrix.a * _rect2.width, matrix.b * _rect2.height,
					matrix.c * _rect2.width, matrix.d * _rect2.height,
					(matrix.tx - _rect2.x) * _rect2.width + _rect2.x,
					(matrix.ty - _rect2.y) * _rect2.height + _rect2.y
				);
			}
			if (__shouldDoAngleFactor()) {
				matrix.translate(-_rect2.x, -_rect2.y);
				matrix.rotate(FlxAngle.asRadians(__prepareAngleFactor(camera)));
				matrix.translate(_rect2.x, _rect2.y);
			}
		}
	}

	function preparePixelPerfectMatrix(matrix:FlxMatrix):Void
	{
		matrix.tx = Math.floor(matrix.tx);
		matrix.ty = Math.floor(matrix.ty);
	}

	// semi stolen from FlxSkewedSprite
	static var _skewMatrix:FlxMatrix = new FlxMatrix();

	private inline function updateSkew():Void
	{
		_skewMatrix.setTo(1, Math.tan(skew.y * FlxAngle.TO_RAD), Math.tan(skew.x * FlxAngle.TO_RAD), 1, 0, 0);
	}

	public override function destroy()
	{
		super.destroy();
		_rect2 = FlxDestroyUtil.put(_rect2);
		skew = FlxDestroyUtil.put(skew);
		transformMatrix = null;
	}
}
