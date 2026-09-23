package funkin.options.type;

import flixel.effects.FlxFlicker;

/**
 * Option type that has text.
**/
class TextOption extends OptionType {
	public var suffix(default, set):String;
	public var selectCallback:Void->Void;

	var __text:Alphabet;
	override function set_text(v:String) {
		__text.text = v + suffix;
		return text = v;
	}

	function set_suffix(v:String) {
		if (suffix == (suffix = v)) return v;
		__text.text = text + suffix;
		return v;
	}

	public function new(text:String, desc:String, ?suffix:String = "", ?selectCallback:Void->Void = null) {
		@:bypassAccessor this.suffix = suffix;
		this.selectCallback = selectCallback;

		__text = new Alphabet(20, 20, "", "bold");

		super(text, desc);
		add(__text);
	}

	override function select() {
		if (locked) return;
		CoolUtil.playMenuSFX(CONFIRM);
		FlxFlicker.flicker(this, 1, Options.flashingMenu ? 0.06 : 0.15, true, false);
		if (selectCallback != null) selectCallback();
	}
}