package funkin.backend.system.framerate;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

class FramerateCounter extends Sprite {
	public var fpsNum:TextField;
	public var fpsLabel:TextField;
	public var lowFPS:TextField;
	public var lastFPS:Float = 0;

	private var frameCount:Int = 0;

	private var accumulatedTime:Float = openfl.Lib.getTimer();

	private final updateInterval:Float = 1 / 15;
	private var lastUpdateTime:Float = 0;

	private final history:Array<Float> = [];

	public function new() {
		super();

		fpsNum = new TextField();
		fpsLabel = new TextField();
		lowFPS = new TextField();
		history.resize(15);

		for (label in [fpsNum, fpsLabel, lowFPS]) {
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.text = "FPS";
			label.multiline = label.wordWrap = false;
			label.defaultTextFormat = new TextFormat(Framerate.fontName, label == fpsNum ? 18 : 12, -1);
			label.selectable = false;
			addChild(label);
		}

		lowFPS.alpha = 0.5;
	}

	public function reload() {
		for (label in [fpsNum, fpsLabel, lowFPS]) label.defaultTextFormat = new TextFormat(Framerate.fontName, label == fpsNum ? 18 : 12, -1);
		lastUpdateTime = 0;
	}

	public override function __enterFrame(t:Float) {
		if (alpha <= 0.001) return;

		super.__enterFrame(t);

		frameCount++;

		if ((lastUpdateTime += FlxG.rawElapsed) < updateInterval)
		{
			updateLabelPosition();
			return;
		}

		final timer = openfl.Lib.getTimer();
		final delta = timer - accumulatedTime;
		accumulatedTime = timer;

		history.shift();
		history.push(lastFPS = FlxMath.lerp(lastFPS, delta <= 0 ? 0 : (1000.0 / delta * frameCount), 1.0 - Math.pow(0.75, delta * 0.06)));

		var lowest = history[0];
		for (f in history) if (f < lowest || f == 0) lowest = f;
		lowFPS.text = "/1%: " + Math.round(lowest);

		fpsNum.text = Std.string(Math.round(lastFPS));
		lastUpdateTime = frameCount = 0;

		updateLabelPosition();
	}

	private inline function updateLabelPosition():Void
	{
		fpsLabel.x = fpsNum.x + fpsNum.width;
		fpsLabel.y = (fpsNum.y + fpsNum.height) - fpsLabel.height;

		lowFPS.x = fpsLabel.x + fpsLabel.width;
		lowFPS.y = (fpsLabel.y + fpsLabel.height) - lowFPS.height;
	}
}