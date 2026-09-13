package funkin.backend.system;

import flixel.FlxGame;
import flixel.FlxG;
import openfl.events.KeyboardEvent;
import openfl.events.Event;

class FunkinGame extends FlxGame {
	var skipNextTickUpdate:Bool = false;
	var manualPause:Bool = false; //fake autopause

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
		ticks = getTicks();
		skipNextTickUpdate = true;
	}

	override function __enterFrame(deltaTime:Float) {
		if (skipNextTickUpdate != (skipNextTickUpdate = false)) ticks = getTicks();
		if (manualPause) {
			var prevAutoPause = FlxG.autoPause;
			FlxG.autoPause = true;
			super.__enterFrame(deltaTime);
			FlxG.autoPause = prevAutoPause;
			draw();
			return;
		}
		super.__enterFrame(deltaTime);
	}


	override public function onFocus(_):Void {
		if (manualPause) return;
		super.onFocus(_);
	}

	override public function onFocusLost(event:Event):Void {
		if (manualPause) return;
		super.onFocusLost(event);
	}

	public function toggleManualPause() {
		var prevAutoPause = FlxG.autoPause;
		FlxG.autoPause = true;

		if (!manualPause) {
			onFocusLost(null);
			manualPause = true;
		} else {
			manualPause = false;
			onFocus(null);
		}
		FlxG.autoPause = prevAutoPause;
	}
}
