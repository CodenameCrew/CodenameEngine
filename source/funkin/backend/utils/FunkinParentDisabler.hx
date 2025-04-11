package funkin.backend.utils;

import flixel.sound.FlxSound;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;

/**
 * FlxBasic allowing you to disable those elements from the parent state while this substate is opened
 * - Tweens
 * - Camera Movement
 * - Timers
 * - Sounds
 *
 * To use, add `add(new FunkinParentDisabler());` after `super.create();` in your `create` function.
 */
class FunkinParentDisabler extends FlxBasic {
	var __tweens:Array<FlxTween>;
	var __cameras:Array<FlxCamera>;
	var __timers:Array<FlxTimer>;
	var __sounds:Array<FlxSound>;
	var __replaceUponDestroy:Bool;
	var __restoreUponDestroy:Bool;
	public function new(replaceUponDestroy:Bool = false, restoreUponDestroy:Bool = true) {
		super();
		__replaceUponDestroy = replaceUponDestroy;
		__restoreUponDestroy = restoreUponDestroy;
		@:privateAccess {
			// tweens
			__tweens = FlxTween.globalManager._tweens.copy();
			FlxTween.globalManager._tweens = [];

			// timers
			__timers = FlxTimer.globalManager._timers.copy();
			FlxTimer.globalManager._timers = [];

			// cameras
			__cameras = [for(c in FlxG.cameras.list) if (!c.paused) c];
			for(c in __cameras) c.paused = true;

			// sounds
			__sounds = [for(s in FlxG.sound.list) if (s.playing) s];
			for(s in __sounds) s.pause();
		}
	}

	public override function draw() {}

	public function reset() {
		__tweens = [];
		__cameras = [];
		__timers = [];
		__sounds = [];
	}

	public override function destroy() {
		super.destroy();
		@:privateAccess {
			if (!__restoreUponDestroy) {
				for(t in __tweens) { t.cancel(); t.destroy(); };
				for(t in __timers) { t.cancel(); t.destroy(); };
				return;
			}
			if (__replaceUponDestroy) {
				FlxTween.globalManager._tweens = __tweens;
				FlxTimer.globalManager._timers = __timers;
			} else {
				for(t in __tweens) FlxTween.globalManager._tweens.push(t);
				for(t in __timers) FlxTimer.globalManager._timers.push(t);
			}
			for(c in __cameras) c.paused = false;
			for(s in __sounds) s.play();
		}
	}
}