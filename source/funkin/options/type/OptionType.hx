package funkin.options.type;

import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import funkin.backend.system.Controls;
import funkin.options.TreeMenu.ITreeOption;

/**
 * Base class for all option types.
 * Used in OptionsMenu.
**/
class OptionType extends FlxSpriteGroup implements ITreeOption {
	public var selected:Bool = false;
	public var locked(default, set):Bool;

	public var text(default, set):String;
	public var rawText(default, set):String;
	public var desc:String;
	public var rawDesc(default, set):String;

	public var itemHeight:Float = 120;

	public var editorFlashColor:FlxColor = FlxColor.WHITE;

	public function new(text:String, desc:String) {
		super();
		rawText = text;
		rawDesc = desc;
	}

	function set_locked(v:Bool) {
		if (locked == (locked = v)) return v;
		color = locked ? 0xFF7F7F7F : 0xFFFFFFFF;
		return v;
	}

	function set_text(v:String) return text = v;
	function set_rawText(v:String) {
		rawText = v;
		text = TU.exists(rawText) ? TU.translate(rawText) : rawText;
		return v;
	}

	function set_rawDesc(v:String) {
		rawDesc = v;
		desc = TU.exists(rawDesc) ? TU.translate(rawDesc) : rawDesc;
		return v;
	}

	public function reloadStrings() {
		rawText = rawText;
		rawDesc = rawDesc;
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		alpha = (selected ? 1 : 0.6);
	}

	public function changeSelection(change:Int) {}
	public function select() {}

	override function get_height() return itemHeight;
}