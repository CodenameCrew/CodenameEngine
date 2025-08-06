package funkin.options.type;

import flixel.math.FlxPoint;
import funkin.options.TreeMenuScreen;

class RadioButton extends TextOption {
	public var radio:FlxSprite;
	public var checked(default, set):Bool;

	public var parent:Dynamic;
	public var optionName:String;

	public var screen:TreeMenuScreen;
	public var forId:String;
	public var value:Dynamic;

	private var offsets:Map<String, FlxPoint> = [
		"unchecked" => FlxPoint.get(0, -65),
		"checked" => FlxPoint.get(0, -65),
		"unchecking" => FlxPoint.get(15, -55),
		"checking" => FlxPoint.get(17, -40)
	];

	public function new(?screen:TreeMenuScreen, text:String, desc:String, ?optionName:String, value:Dynamic, ?selectCallback:Void->Void, ?parent:Dynamic, ?forId:String) {
		super(text, desc, selectCallback);
		this.screen = screen;
		this.optionName = optionName;
		this.parent = parent = parent != null ? parent : Options;
		this.forId = forId = forId == null ? optionName : forId;
		this.value = value;

		radio = new FlxSprite(10, -23);
		radio.frames = Paths.getFrames('menus/options/radioCrank');
		radio.animation.addByPrefix("unchecked", "Radio unselected0", 24);
		radio.animation.addByPrefix("checked", "Radio Selected Static0", 24);
		radio.animation.addByPrefix("unchecking", "Radio deselect animation0", 24, false);
		radio.animation.addByPrefix("checking", "Radio selecting animation0", 24, false);
		radio.antialiasing = true;
		radio.scale.set(0.75, 0.75);
		radio.updateHitbox();
		add(radio);

		__text.x = 100;

		if (optionName != null) checked = Reflect.field(parent, optionName) == value;
		else checked = false;
	}

	public var firstFrame:Bool = true;

	override function update(elapsed:Float) {
		if (radio.animation.curAnim == null) radio.animation.play(checked ? "checked" : "unchecked", true);
		super.update(elapsed);

		if (radio.animation.curAnim.finished) switch(radio.animation.curAnim.name) {
			case "unchecking": radio.animation.play("unchecked", true);
			case "checking": radio.animation.play("checked", true);
		}

		firstFrame = false;
	}

	override function draw() {
		if (radio.animation.curAnim != null) {
			var offset = offsets[radio.animation.curAnim.name];
			if (offset != null) radio.frameOffset.set(offset.x, offset.y);
		}
		super.draw();
	}

	function set_checked(v:Bool) {
		if (checked == (checked = v)) return v;

		if (!firstFrame) radio.animation.play(checked ? "checking" : "unchecking", true);
		return v;
	}

	override function select() {
		if (locked) return;

		checked = true;
		if (optionName != null) Reflect.setField(parent, optionName, value);

		CoolUtil.playMenuSFX(CHECKED);

		if (screen != null) {
			for (item in screen.members) if (item != null && item != this && item is RadioButton) cast(item, RadioButton).checked = false;
		}

		if (selectCallback != null) selectCallback();
	}

	override function destroy() {
		super.destroy();
		for (e in offsets) e.put();
	}
}