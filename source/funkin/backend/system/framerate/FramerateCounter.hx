package funkin.backend.system.framerate;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

class FramerateCounter extends Sprite {
	public var fpsNum:TextField;
	public var fpsLabel:TextField;
	public var lastFPS:Float = 0;

	private final updateInterval:Float = 1000 / 15;
	private var lastUpdateTime:Float = 0;

	public function new() {
		super();

		fpsNum = new TextField();
		fpsLabel = new TextField();

		for(label in [fpsNum, fpsLabel]) {
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.text = "FPS";
			label.multiline = label.wordWrap = false;
			label.defaultTextFormat = new TextFormat(Framerate.fontName, label == fpsNum ? 18 : 12, -1);
			label.selectable = false;
			addChild(label);
		}
	}

	public function reload() {
		lastUpdateTime = 0;
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		super.__enterFrame(t);

		lastFPS = FlxMath.lerp(lastFPS, t <= 0 ? 0 : (1000 / t), 1.0 - Math.pow(0.75, t * 0.06));

		if ((lastUpdateTime += t) >= updateInterval) {
			fpsNum.text = Std.string(Math.floor(lastFPS));
			lastUpdateTime = 0;
		}

		fpsLabel.x = fpsNum.x + fpsNum.width;
		fpsLabel.y = (fpsNum.y + fpsNum.height) - fpsLabel.height;
	}
}