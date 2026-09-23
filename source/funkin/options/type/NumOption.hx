package funkin.options.type;

/**
 * Option type that allows stepping through a number.
**/
class NumOption extends TextOption {
	public var changedCallback:Float->Void;

	public var min:Float;
	public var max:Float;
	public var step:Float;

	public var currentValue(default, set):Float;

	public var parent:Dynamic;
	public var optionName:String;

	var __number:Alphabet;

	function set_currentValue(v:Float):Float {
		if (__number != null) __number.text = ': $v';
		return currentValue = v;
	}

	override function set_text(v:String):String {
		super.set_text(v);
		__number.x = __text.x + __text.width + 12;
		return v;
	}

	public function new(text:String, desc:String, min:Float, max:Float, step:Float = 1, ?optionName:String, ?changedCallback:Float->Void = null, ?parent:Dynamic) {
		this.changedCallback = changedCallback;
		this.min = min;
		this.max = max;
		this.step = step;
		this.optionName = optionName;
		this.parent = parent = parent != null ? parent : Options;

		if (Reflect.field(parent, optionName) != null) currentValue = Reflect.field(parent, optionName);
	
		__number = new Alphabet(0, 20, ': $currentValue', 'bold');
		super(text, desc);
		add(__number);
	}

	override function changeSelection(change:Int):Void {
		if (locked) return;
		if (currentValue == (currentValue = FlxMath.bound(currentValue + change * step, min, max))) return;

		Reflect.setField(parent, optionName, currentValue);
		if (changedCallback != null) changedCallback(currentValue);

		CoolUtil.playMenuSFX(SCROLL);
	}

	override function select() {}
}