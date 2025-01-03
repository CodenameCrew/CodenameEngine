package funkin.backend;

import flixel.graphics.frames.FlxFramesCollection;
import openfl.geom.ColorTransform;
import flixel.math.FlxMatrix;
import flixel.math.FlxAngle;
import flixel.math.FlxRect;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import openfl.display.BlendMode;

class FlxAnimate extends flxanimate.FlxAnimate {
	static var rMatrix = new FlxMatrix();

	override function drawLimb(limb:FlxFrame, _rMatrix:FlxMatrix, ?colorTransform:ColorTransform, ?blendMode:BlendMode)
	{
		if (alpha == 0 || colorTransform != null && (colorTransform.alphaMultiplier == 0 || colorTransform.alphaOffset == -255) || limb == null || limb.type == EMPTY)
			return;

		if (blendMode == null)
			blendMode = BlendMode.NORMAL;

		for (camera in cameras)
		{
			rMatrix.identity();
			limb.prepareMatrix(rMatrix, FlxFrameAngle.ANGLE_0, _checkFlipX() != camera.flipX, _checkFlipY() != camera.flipY);
			rMatrix.concat(_rMatrix);
			if (!camera.visible || !camera.exists || !limbOnScreen(limb, _rMatrix, camera))
				return;

			getScreenPosition(_point, camera).subtractPoint(offset);
			rMatrix.translate(-origin.x, -origin.y);
			if (limb != _pivot) {
				if (frameOffsetAngle != null && frameOffsetAngle != angle)
				{
					var angleOff = (frameOffsetAngle - angle) * FlxAngle.TO_RAD;
					var cos = Math.cos(angleOff);
					var sin = Math.sin(angleOff);
					// cos doesnt need to be negated
					rMatrix.rotateWithTrig(cos, -sin);
					rMatrix.translate(-frameOffset.x, -frameOffset.y);
					rMatrix.rotateWithTrig(cos, sin);
				}
				else
				{
					rMatrix.translate(-frameOffset.x, -frameOffset.y);
				}
				rMatrix.scale(scale.x, scale.y);

				if (!matrixExposed && bakedRotationAngle <= 0)
				{
					updateTrig();

					if (angle != 0)
						rMatrix.rotateWithTrig(_cosAngle, _sinAngle);
				}
			}
			else
				rMatrix.a = rMatrix.d = 0.7 / camera.zoom;

			if (matrixExposed)
			{
				rMatrix.concat(transformMatrix);
			}
			else
			{
				rMatrix.concat(@:privateAccess flxanimate.FlxAnimate._skewMatrix);
			}

			_point.addPoint(origin);
			if (isPixelPerfectRender(camera))
			{
				_point.floor();
			}

			rMatrix.translate(_point.x, _point.y);
			camera.drawPixels(limb, null, rMatrix, colorTransform, blendMode, antialiasing, shaderEnabled ? shader : null);
			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}

		// doesnt work, needs to be remade
		// #if FLX_DEBUG
		// if (FlxG.debugger.drawDebug)
		// 	drawDebug();
		// #end
	}

	override function limbOnScreen(limb:FlxFrame, m:FlxMatrix, ?Camera:FlxCamera)
	{
		// TODO: ACTUAL OPTIMISATION
		return true;
	}
}
