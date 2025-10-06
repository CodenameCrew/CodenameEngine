package funkin.backend.scripting;

import flixel.FlxState;
import funkin.backend.assets.ModsFolder;
import funkin.backend.scripting.events.CancellableEvent;
import funkin.backend.system.Conductor;
import funkin.options.PlayerSettings;

#if GLOBAL_SCRIPT
/**
 * Class for THE Global Script, aka script that runs in the background at all times.
 */
class GlobalScript {
	public static var scripts:ScriptPack;

	private static var initialized:Bool = false;
	private static var reloading:Bool = false;
	private static var _lastAllow_Reload:Bool = false;

	public static function init() {
		if(initialized) return;
		initialized = true;
		#if MOD_SUPPORT
		ModsFolder.onModSwitch.add(onModSwitch);
		#end

		Conductor.onBeatHit.add(beatHit);
		Conductor.onStepHit.add(stepHit);

		FlxG.signals.focusGained.add(function() {
			call("focusGained");
		});
		FlxG.signals.focusLost.add(function() {
			call("focusLost");
		});
		FlxG.signals.gameResized.add(function(w:Int, h:Int) {
			call("gameResized", [w, h]);
		});
		FlxG.signals.postDraw.add(function() {
			call("postDraw");
		});
		FlxG.signals.postGameReset.add(function() {
			call("postGameReset");
		});
		FlxG.signals.postGameStart.add(function() {
			call("postGameStart");
		});
		FlxG.signals.postStateSwitch.add(function() {
			call("postStateSwitch");
		});
		FlxG.signals.postUpdate.add(function() {
			call("postUpdate", [FlxG.elapsed]);

			if (reloading) {
				reloading = false;
				MusicBeatState.ALLOW_DEV_RELOAD = _lastAllow_Reload;
			}

			if (PlayerSettings.solo.controls.DEV_CONSOLE)
				NativeAPI.allocConsole();
		});
		FlxG.signals.preDraw.add(function() {
			call("preDraw");
		});
		FlxG.signals.preGameReset.add(function() {
			call("preGameReset");
		});
		FlxG.signals.preGameStart.add(function() {
			call("preGameStart");
		});
		FlxG.signals.preStateCreate.add(function(state:FlxState) {
			call("preStateCreate", [state]);
		});
		FlxG.signals.preStateSwitch.add(function() {
			call("preStateSwitch", []);

			var stateName = Type.getClassName(Type.getClass(@:privateAccess FlxG.game._requestedState));
			stateName = stateName.substring(stateName.lastIndexOf(".") + 1);
			if (Flags.MOD_REDIRECT_STATES.exists(stateName)) {
				@:privateAccess {
					var classFromString = Type.resolveClass(Flags.MOD_REDIRECT_STATES.get(stateName));
					if (classFromString != null) FlxG.game._requestedState = Type.createInstance(classFromString, []);
					else FlxG.game._requestedState = new funkin.backend.scripting.ModState(Flags.MOD_REDIRECT_STATES.get(stateName));
				}
			}
		});

		FlxG.signals.preUpdate.add(function() {
			call("preUpdate", [FlxG.elapsed]);
			call("update", [FlxG.elapsed]);

			if (FlxG.keys.pressed.SHIFT) {
				// If we want, we could just make reseting GlobalScript it's own keybind, but for now this works.
				if (PlayerSettings.solo.controls.DEV_RELOAD) {
					reloading = true;
					Logs.trace("Reloading Global Scripts...", INFO, YELLOW);

					// yeah its a bit messy, sorry. This just prevents actually reloading the actual state.
					_lastAllow_Reload = MusicBeatState.ALLOW_DEV_RELOAD;
					MusicBeatState.ALLOW_DEV_RELOAD = false;

					// Would be better to just re-initalize GlobalScript so there aren't any lose ends.
					onModSwitch(#if MOD_SUPPORT ModsFolder.currentModFolder #else null #end);
				}
			}
		});
	}

	public static function onModSwitch(newMod:String) {
		destroy();
		scripts = new ScriptPack("GlobalScript");
		for (i in funkin.backend.assets.ModsFolder.getLoadedMods()) {
			var path = Paths.script('data/global/LIB_$i');
			var script = Script.create(path);
			if (script is DummyScript)
				continue;
			script.remappedNames.set(script.fileName, '$i:${script.fileName}');
			scripts.add(script);
			script.load();
		}
	}

	public static inline function event<T:CancellableEvent>(name:String, event:T):T {
		if (scripts != null)
			scripts.event(name, event);
		return event;
	}

	public static inline function call(name:String, ?args:Array<Dynamic>)
		if (scripts != null) scripts.call(name, args);

	public static inline function beatHit(curBeat:Int)
		call("beatHit", [curBeat]);

	public static inline function stepHit(curStep:Int)
		call("stepHit", [curStep]);

	public static inline function destroy() if (scripts != null) {
		call("destroy");
		scripts = FlxDestroyUtil.destroy(scripts);
	}
}
#end