package mobile.objects;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.tweens.*;
import flixel.util.FlxColor;
import openfl.display.Shape;
import funkin.options.Options;
import mobile.flixel.FlxButton;
import openfl.display.BitmapData;
import flixel.util.FlxDestroyUtil;
import openfl.geom.Matrix;

/**
 * A zone with 4 hint's (A hitbox).
 * It's really easy to customize the layout.
 *
 * @author: Mihai Alexandru and Karim Akra
 */
class Hitbox extends FlxButtonGroup
{
	public var buttonLeft:FlxButton = new FlxButton(0, 0);
	public var buttonDown:FlxButton = new FlxButton(0, 0);
	public var buttonUp:FlxButton = new FlxButton(0, 0);
	public var buttonRight:FlxButton = new FlxButton(0, 0);
	public var buttonExtra:FlxButton = new FlxButton(0, 0);
	public var buttonExtra2:FlxButton = new FlxButton(0, 0);

	/**
	 * Create the zone.
	 */
	public function new()
	{
		super();

		add(buttonLeft = createHint(0, 0, Std.int(FlxG.width / 4), FlxG.height, 0xFFC24B99));
		add(buttonDown = createHint(FlxG.width / 4, 0, Std.int(FlxG.width / 4), FlxG.height, 0xFF00FFFF));
		add(buttonUp = createHint(FlxG.width / 2, 0, Std.int(FlxG.width / 4), FlxG.height, 0xFF12FA05));
		add(buttonRight = createHint((FlxG.width / 2) + (FlxG.width / 4), 0, Std.int(FlxG.width / 4), FlxG.height, 0xFFF9393F));
		scrollFactor.set();
		var guh = Options.controlsAlpha;
		if (guh >= 0.9)
			guh = guh - 0.07;
		alpha = Options.controlsAlpha;
	}

	/**
	 * Clean up memory.
	 */
	override function destroy()
	{
		super.destroy();

		buttonLeft = FlxDestroyUtil.destroy(buttonLeft);
		buttonDown = FlxDestroyUtil.destroy(buttonDown);
		buttonUp = FlxDestroyUtil.destroy(buttonUp);
		buttonRight = FlxDestroyUtil.destroy(buttonRight);
		buttonExtra = FlxDestroyUtil.destroy(buttonExtra);
		buttonExtra2 = FlxDestroyUtil.destroy(buttonExtra2);
	}

	private function createHint(X:Float, Y:Float, Width:Int, Height:Int, Color:Int = 0xFFFFFF):FlxButton
	{
		var hintTween:FlxTween = null;
		var hintLaneTween:FlxTween = null;
		var hint = new FlxButton(X, Y);
		hint.loadGraphic(createHintGraphic(Width, Height));
		hint.color = Color;
		hint.solid = false;
		hint.immovable = true;
		hint.multiTouch = true;
		hint.moves = false;
		hint.scrollFactor.set();
		hint.alpha = 0.00001;
		hint.antialiasing = Options.antialiasing;
		hint.label = new FlxSprite();
		hint.labelStatusDiff = (Options.hitboxType != "hidden") ? Options.controlsAlpha : 0.00001;
		hint.label.loadGraphic(createHintGraphic(Width, Math.floor(Height * 0.035), true));
		hint.label.color = Color;
		hint.label.offset.y -= (hint.height - hint.label.height);
		if (Options.hitboxType != 'hidden')
		{
			hint.onDown.callback = function()
			{
				if (hintTween != null)
					hintTween.cancel();

				if (hintLaneTween != null)
					hintLaneTween.cancel();

				hintTween = FlxTween.tween(hint, {alpha: Options.controlsAlpha}, Options.controlsAlpha / 100, {
					ease: FlxEase.circInOut,
					onComplete: (twn:FlxTween) -> hintTween = null
				});

				hintLaneTween = FlxTween.tween(hint.label, {alpha: 0.00001}, Options.controlsAlpha / 10, {
					ease: FlxEase.circInOut,
					onComplete: (twn:FlxTween) -> hintLaneTween = null
				});
			}

			hint.onOut.callback = hint.onUp.callback = function()
			{
				if (hintTween != null)
					hintTween.cancel();

				if (hintLaneTween != null)
					hintLaneTween.cancel();

				hintTween = FlxTween.tween(hint, {alpha: 0.00001}, Options.controlsAlpha / 10, {
					ease: FlxEase.circInOut,
					onComplete: (twn:FlxTween) -> hintTween = null
				});

				hintLaneTween = FlxTween.tween(hint.label, {alpha: Options.controlsAlpha}, Options.controlsAlpha / 100, {
					ease: FlxEase.circInOut,
					onComplete: (twn:FlxTween) -> hintLaneTween = null
				});
			}
		}
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}

	function createHintGraphic(Width:Int, Height:Int, ?isLane:Bool = false):BitmapData
	{
		var guh = Options.controlsAlpha;
		if (guh >= 0.9)
			guh = Options.controlsAlpha - 0.07;
		var shape:Shape = new Shape();
		shape.graphics.beginFill(0xFFFFFF);
		if (Options.hitboxType == "noGradient")
		{
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(Width, Height, 0, 0, 0);

			if (isLane)
				shape.graphics.beginFill(0xFFFFFF);
			else
				shape.graphics.beginGradientFill(RADIAL, [0xFFFFFF, 0xFFFFFF], [0, 1], [60, 255], matrix, PAD, RGB, 0);
			shape.graphics.drawRect(0, 0, Width, Height);
			shape.graphics.endFill();
		}
		else if (Options.hitboxType == 'gradient')
		{
			shape.graphics.lineStyle(3, 0xFFFFFF, 1);
			shape.graphics.drawRect(0, 0, Width, Height);
			shape.graphics.lineStyle(0, 0, 0);
			shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
			shape.graphics.endFill();
			if (isLane)
				shape.graphics.beginFill(0xFFFFFF);
			else
				shape.graphics.beginGradientFill(RADIAL, [0xFFFFFF, FlxColor.TRANSPARENT], [1, 0], [0, 255], null, null, null, 0.5);
			shape.graphics.drawRect(3, 3, Width - 6, Height - 6);
			shape.graphics.endFill();
		}
		else //if (Options.hitboxType == "noGradientOld")
		{
			shape.graphics.lineStyle(10, 0xFFFFFF, 1);
			shape.graphics.drawRect(0, 0, Width, Height);
			shape.graphics.endFill();
		}
		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape);
		return bitmap;
	}
}
