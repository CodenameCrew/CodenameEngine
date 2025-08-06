package funkin.options.type;

import funkin.menus.ui.Slider;
import funkin.options.TreeMenu.ITreeFloatOption;

class SliderOption extends TextOption implements ITreeFloatOption {
	public var changedCallback:Float->Void;

	public var min:Float;
	public var max:Float;
	public var step:Float;

	public var currentValue:Float;

	public var parent:Dynamic;
	public var optionName:String;

	public var slider:Slider;
	public var dynamicWidth:Bool;

	var __mouseControl:Bool;

	function getValue():Float return (currentValue - min) / (max - min);

	override function set_text(v:String) {
		super.set_text(v);
		slider.x = __text.x + __text.width + 30;
		if (dynamicWidth) {
			slider.barWidth = 1100 - __text.width;
			slider.updateHitbox();
		}
		return v;
	}

	public function new(text:String, desc:String, min:Float, max:Float, step:Float = 1, ?segments:Int, ?optionName:String, barWidth = -1,
		?changedCallback:Float->Void = null, ?parent:Dynamic)
	{
		this.changedCallback = changedCallback;
		this.min = min;
		this.max = max;
		this.step = step;
		this.optionName = optionName;
		this.parent = parent = parent != null ? parent : Options;

		if (Reflect.field(parent, optionName) != null) currentValue = Reflect.field(parent, optionName);

		slider = new Slider(12, 0, getValue(), (dynamicWidth = barWidth < 0) ? 600 : barWidth, segments);
		slider.scale.set(0.75, 0.75);
		slider.updateHitbox();

		super(text, desc);
		add(slider);
		slider.y = Math.floor(__text.y + (__text.height - slider.height) * 0.5 + 2);
	}

	override function update(elapsed:Float) {
		if (slider.selected = selected && !locked) {
			if (__mouseControl && FlxG.mouse.justReleased) __mouseControl = false;
			else if (FlxG.mouse.justPressed) __mouseControl = slider.overlapsPoint(FlxG.mouse.getPosition(@:privateAccess flixel.input.FlxPointer._cachedPoint), true);

			if (__mouseControl) {
				var p = @:privateAccess flixel.input.FlxPointer._cachedPoint;
				if (!FlxG.mouse.justPressed) FlxG.mouse.getPosition(p);
				p.subtractPoint(camera.scroll);

				slider.getScreenPosition(_point, camera);
				changeValue((FlxMath.remapToRange(p.x - _point.x, 0, slider.width, min, max) - currentValue) / step);
			}
		}
		else
			__mouseControl = false;

		slider.value = getValue();
		//__text.x = slider.x + slider.width + 30;

		super.update(elapsed);
	}

	public function changeValue(change:Float):Void {
		if (locked) return;
		if (currentValue == (currentValue = FlxMath.bound(currentValue + change * step, min, max))) return;

		Reflect.setField(parent, optionName, currentValue);
		if (changedCallback != null) changedCallback(currentValue);
	}

	override function select() {}
}