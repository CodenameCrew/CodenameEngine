package funkin.options.type;

import flixel.math.FlxPoint;

/**
 * Option type that allows you to toggle a checkbox.
**/
class Checkbox extends TextOption {
	public var checkbox:FlxSprite;
	public var checked(default, set):Bool;

	public var parent:Dynamic;
	public var optionName:String;

	private var offsets:Map<String, FlxPoint> = [
		"unchecked" => FlxPoint.get(0, -70),
		"checked" => FlxPoint.get(23, -32),
		"unchecking" => FlxPoint.get(25, -12),
		"checking" => FlxPoint.get(35, 29)
	];

	override function set_text(v:String) {
		super.set_text(v);
		checkbox.x = __text.x + __text.width + 26;
		return v;
	}

	public function new(text:String, desc:String, ?optionName:String, ?selectCallback:Void->Void, ?parent:Dynamic) {
		this.optionName = optionName;
		this.parent = parent = parent != null ? parent : Options;

		checkbox = new FlxSprite(10, -30);
		checkbox.frames = Paths.getFrames('menus/options/checkboxThingie');
		checkbox.animation.addByPrefix("unchecked", "Check Box unselected0", 24);
		checkbox.animation.addByPrefix("checked", "Check Box Selected Static0", 24);
		checkbox.animation.addByPrefix("unchecking", "Check Box deselect animation0", 24, false);
		checkbox.animation.addByPrefix("checking", "Check Box selecting animation0", 24, false);
		checkbox.antialiasing = true;
		checkbox.scale.set(0.75, 0.75);
		checkbox.updateHitbox();

		//__text.x = 100;

		if (optionName != null) checked = Reflect.field(parent, optionName);
		else checked = false;

		super(text, desc, selectCallback);
		add(checkbox);
	}

	public var firstFrame:Bool = true;

	override function update(elapsed:Float) {
		if (checkbox.animation.curAnim == null) checkbox.animation.play(checked ? "checked" : "unchecked", true);
		super.update(elapsed);

		if (checkbox.animation.curAnim.finished) switch(checkbox.animation.curAnim.name) {
			case "unchecking": checkbox.animation.play("unchecked", true);
			case "checking": checkbox.animation.play("checked", true);
		}

		firstFrame = false;
	}

	override function draw() {
		if (checkbox.animation.curAnim != null) {
			var offset = offsets[checkbox.animation.curAnim.name];
			if (offset != null) checkbox.frameOffset.set(offset.x, offset.y);
		}
		super.draw();
	}

	function set_checked(v:Bool) {
		if (checked == (checked = v)) return v;

		if (!firstFrame) checkbox.animation.play(checked ? "checking" : "unchecking", true);
		return v;
	}

	override function select() {
		if (locked) return;

		checked = !checked;
		if (optionName != null) Reflect.setField(parent, optionName, checked);

		if (checked) CoolUtil.playMenuSFX(CHECKED);
		else CoolUtil.playMenuSFX(UNCHECKED);

		if (selectCallback != null) selectCallback();
	}

	override function destroy() {
		super.destroy();
		for (e in offsets) e.put();
	}
}