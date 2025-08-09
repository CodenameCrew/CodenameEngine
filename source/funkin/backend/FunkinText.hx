package funkin.backend;

import flixel.text.FlxText;
import flixel.util.FlxColor;

class FunkinText extends FlxText {
	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 16, Border:Bool = true) {
		super(X, Y, FieldWidth, Text, Size);
		setFormat(Paths.font("vcr.ttf"), Size, FlxColor.WHITE);
		if (Border) {
			borderStyle = OUTLINE;
			borderSize = 1;
			borderColor = 0xFF000000;
		}
	}
}