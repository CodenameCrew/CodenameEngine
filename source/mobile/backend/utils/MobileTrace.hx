package mobile.backend.utils;

import flixel.FlxG;
import flixel.text.FlxText;

class MobileTrace
{
	public static var text:FlxText;
	public static var logs:Array<String> = [];

	public static var enabled:Bool = false;

	public static function init()
	{
		if (text != null) return;

		text = new FlxText(4, 4, FlxG.width - 8, "");

		text.setFormat(null, 16, 0xFFFFFF00, LEFT);

		text.alpha = 0.7;

		text.scrollFactor.set();

		text.borderSize = 1;
		text.borderColor = 0xFF000000;

		text.cameras = [FlxG.cameras.list[0]];

		FlxG.state.add(text);
	}

	public static function log(v:Dynamic)
	{
		if (!enabled) return;

		if (text == null)
			init();

		logs.push(Std.string(v));

		while (logs.length > 10)
			logs.shift();

		text.text = logs.join("\n");
	}
}
