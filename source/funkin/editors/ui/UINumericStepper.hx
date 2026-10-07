package funkin.editors.ui;

class UINumericStepper extends UITextBox {
	public var value(default, set):Float;
	public var precision:Int = 0;
	public var min:Null<Float> = null;
	public var max:Null<Float> = null;
	public var step:Float = 1;

	public function new(x:Float, y:Float, value:Float = 0, step:Float = 1, precision:Int = 0, ?min:Float, ?max:Float, w:Int = 180, h:Int = 32, small:Bool = false) {
		super(x, y, "", w - h, h, false, small);

		onChange = __onChange;

		this.precision = precision;
		this.min = min;
		this.max = max;
		this.step = step;

		set_value(value);

		// TODO: add stepper buttons
	}

	private function __onChange(text:String) {
		var f = Std.parseFloat(text);
		if (Math.isNaN(f))
			return;
		value = f;
	}

	private function set_value(v:Float) {
		if (min != null && max != null) {
			v = CoolUtil.bound(v, min, max);
		} else if (min != null) {
			v = Math.max(v, min);
		} else if (max != null) {
			v = Math.min(v, max);
		}
		label.text = Std.string(FlxMath.roundDecimal(v, precision));
		return value = v;
	}
}