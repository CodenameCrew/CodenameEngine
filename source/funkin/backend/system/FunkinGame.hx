package funkin.backend.system;

import flixel.FlxGame;
import flixel.FlxG;
import openfl.events.KeyboardEvent;

class FunkinGame extends FlxGame {
	var skipNextTickUpdate:Bool = false;

	#if desktop
	var fullscreenListener:KeyboardEvent->Void;

	override function create(_):Void {
		super.create(_);

		if (stage == null) return;

		// In the future, make it so any keybinds are able to toggle fullscreen instead of just F11
		stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent) {
			if (e.keyCode == 122) {
				FlxG.fullscreen = !FlxG.fullscreen;
			}
		});
	}
	#end
	
	public override function switchState() {
		super.switchState();
		// draw once to put all images in gpu then put the last update time to now to prevent lag spikes or whatever
		draw();
		_total = ticks = getTicks();
		skipNextTickUpdate = true;
	}

	public override function onEnterFrame(t) {
		if (skipNextTickUpdate != (skipNextTickUpdate = false)) _total = ticks = getTicks();
		super.onEnterFrame(t);
	}
}
