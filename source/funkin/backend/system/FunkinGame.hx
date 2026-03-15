package funkin.backend.system;

import flixel.FlxGame;
import flixel.FlxG;
import flixel.FlxState;
import openfl.events.KeyboardEvent;

class FunkinGame extends FlxGame {
	var skipNextTickUpdate:Bool = false;

	#if desktop
	var fullscreenListener:KeyboardEvent->Void;
	
	public function new(gameWidth:Int, gameHeight:Int, entryState:Class<FlxState>, updateFramerate:Int = 60, drawFramerate:Int = 60, skipSplash:Bool = false, startFullscreen:Bool = false) {
		super(gameWidth, gameHeight, entryState, updateFramerate, drawFramerate, skipSplash, startFullscreen);
		
		fullscreenListener = function(e:KeyboardEvent) {
			if (e.keyCode == 122) {
				FlxG.fullscreen = !FlxG.fullscreen;
			}
		};
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, fullscreenListener);
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
		if (skipNextTickUpdate != (skipNextTickUpdate = false))
			_total = ticks = getTicks();
		super.onEnterFrame(t);
	}
}