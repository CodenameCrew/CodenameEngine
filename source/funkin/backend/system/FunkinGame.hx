package funkin.backend.system;

import flixel.FlxGame;

class FunkinGame extends FlxGame {
	var skipNextTickUpdate:Bool = false;
	public override function switchState() {
		super.switchState();
		// draw once to put all images in gpu then put the last update time to now to prevent lag spikes or whatever
		draw();
		ticks = getTicks();
		skipNextTickUpdate = true;
	}

	override function __enterFrame(deltaTime:Float) {
		if (skipNextTickUpdate != (skipNextTickUpdate = false)) ticks = getTicks();
		super.__enterFrame(deltaTime);
	}
}