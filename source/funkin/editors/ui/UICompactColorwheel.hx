package funkin.editors.ui;

import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import funkin.editors.ui.UIColorwheel.UIColorWheelSelector;

using flixel.util.FlxSpriteUtil;

class UICompactColorwheel extends UISliceSprite {
	var colorSlider:FlxSprite;
	var colorSliderSelector:UIColorWheelSelector;

	var whiteColorButton:UIButton;

	public var curColor:Null<FlxColor>;
	public var curColorString:String = "#FFFFFF";

	public var hue:Float;

	public function new (x:Float, y:Float, ?color:Int) {
		super(x, y, Std.int((12.5 * 3) + 116), Std.int((12.5 * 2) + (16)), 'editors/ui/inputbox');

		curColor = cast color;
		hue = curColor.hue;

		colorSlider = new FlxSprite(x + 12.5, y + 12.5).makeGraphic(100, 16, FlxColor.TRANSPARENT);
		colorSlider.drawRoundRect(0, 0, 100, 16, 10, 10, FlxColor.WHITE);

		colorSlider.pixels.lock();
		for (pixelx in 0...Std.int(colorSlider.width)) {
			var color:Int = FlxColor.fromHSB(pixelx / (colorSlider.width-1) * 360, 1, 1);
			for (pixely in 0...Std.int(colorSlider.height))
				if (colorSlider.pixels.getPixel32(pixelx, pixely) != FlxColor.TRANSPARENT) colorSlider.pixels.setPixel32(pixelx, pixely, color);
		}
		colorSlider.pixels.unlock();

		whiteColorButton = new UIButton(colorSlider.x + colorSlider.width + 12.5, colorSlider.y, null, () -> {
			setColor(FlxColor.WHITE);
		}, 16, 16);
		whiteColorButton.colorTransform.color = FlxColor.WHITE;

		colorSliderSelector = new UIColorWheelSelector(colorSlider.x, colorSlider.y);

		colorSlider.antialiasing = true;

		for (item in [colorSlider, colorSliderSelector, whiteColorButton])
			members.push(item);

		updateColor(false);
	}

	inline function updateColorSliderPickerSelector()
		colorSliderSelector.selector.setPosition(colorSlider.x + (hue / 360 * (colorSlider.width-1)) - 8, colorSlider.y);

	inline function updateColorSliderMouse(mousePos:FlxPoint)
		hue = (mousePos.x / colorSlider.width) * 360;

	function setColor(newColor:FlxColor) {
		this.color = curColor = colorSliderSelector.curColor = newColor;
	}

	public function updateColor(checkChanged:Bool = true) {
		if(checkChanged) colorChanged = true;
		setColor(FlxColor.fromHSB(hue, 1, 1));

		updateColorSliderPickerSelector();
		curColorString = curColor.toWebString();
	}

	// For Character Editor
	public var colorChanged:Bool = false;

	// Make the colorwheel feel better
	static inline var hitBoxExtenstion:Float = 8;

	var selectedSprite = null;
	public override function update(elapsed:Float) {
		var mousePos = FlxG.mouse.getScreenPosition(__lastDrawCameras[0], FlxPoint.get());
		if (hovered && FlxG.mouse.justPressed) {
			for (sprite in [colorSlider]) {
				var spritePos:FlxPoint = sprite.getScreenPosition(FlxPoint.get(), __lastDrawCameras[0]);
				if (FlxMath.inBounds(mousePos.x, spritePos.x - (hitBoxExtenstion/2), spritePos.x - (hitBoxExtenstion/2) + (sprite.width + hitBoxExtenstion)) && FlxMath.inBounds(mousePos.y, spritePos.y - (hitBoxExtenstion/2), spritePos.y - (hitBoxExtenstion/2) + (sprite.height + hitBoxExtenstion))) {
					selectedSprite = sprite;
					break;
				}
			}
		}

		if (selectedSprite != null) {
			var spritePos:FlxPoint = selectedSprite.getScreenPosition(FlxPoint.get(), __lastDrawCameras[0]);
			mousePos -= FlxPoint.weak(spritePos.x, spritePos.y);
			mousePos.set(CoolUtil.bound(mousePos.x, 0, selectedSprite.width), CoolUtil.bound(mousePos.y, 0, selectedSprite.height));

			if (selectedSprite == colorSlider) updateColorSliderMouse(mousePos);
			updateColor();
			spritePos.put();

			if (FlxG.mouse.justReleased) selectedSprite = null;
		}
		mousePos.put();
		super.update(elapsed);
	}
}