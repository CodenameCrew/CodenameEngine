package funkin.backend;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.system.Flags;

class FunkinText extends FlxText {
	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, ?Size:Int, Border:Bool = true) {
		if (Size == null) Size = Flags.DEFAULT_FONT_SIZE;

		super(X, Y, FieldWidth, Text, Size);
		setFormat(Paths.font(Flags.DEFAULT_FONT), Size, FlxColor.WHITE);
		if (Border) {
			borderStyle = OUTLINE;
			borderSize = 1;
			borderColor = 0xFF000000;
		}
	}
}