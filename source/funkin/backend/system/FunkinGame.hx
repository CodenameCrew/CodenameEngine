package funkin.backend.system;

import flixel.FlxGame;
import flixel.FlxG;
import funkin.backend.system.modules.CrashHandler;
import openfl.events.KeyboardEvent;
import openfl.events.Event;

class FunkinGame extends FlxGame {
	var skipNextTickUpdate:Bool = false;
	var manualPause:Bool = false; //fake autopause

	#if (desktop || android)
	override function create(_):Void {
		super.create(_);

		if (stage == null) return;

		#if desktop
		// In the future, make it so any keybinds are able to toggle fullscreen instead of just F11
		stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent) {
			if (e.keyCode == 122) {
				FlxG.fullscreen = !FlxG.fullscreen;
			}
		});
		#end

		#if android
		stage.color = 0xFF000000;
		var w = stage.stageWidth > 0 ? stage.stageWidth : 1280;
		var h = stage.stageHeight > 0 ? stage.stageHeight : 720;
		resizeGame(w, h);
		#end
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
		// The state that threw must not update again, or it throws on every frame.
		if (CrashHandler.blocking) {
			ticks = getTicks();
			try {
				draw();
			} catch (_:Dynamic) {}
			return;
		}
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
		#if mobile
		return;
		#else
		if (manualPause) return;
		super.onFocusLost(event);
		#end
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
