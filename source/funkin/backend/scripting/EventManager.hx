package funkin.backend.scripting;

import flixel.FlxState;
import funkin.backend.scripting.events.*;

final class EventManager {
	public static var eventCache:Map<String, CancellableEvent> = [];

	#if cpp
	public static var cppEventCache:haxe.ds.ObjectMap<Dynamic, CancellableEvent> = new haxe.ds.ObjectMap();

	public static inline function get<T:CancellableEvent>(cl:Class<T>):T {
		var event:CancellableEvent = cppEventCache.get(cl);
		if (event == null) {
			event = Type.createInstance(cl, []);
			cppEventCache.set(cl, event);
		}
		return cast event;
	}
	#else
	public static inline function get<T:CancellableEvent>(cl:Class<T>):T {
		var className = Type.getClassName(cl);
		var event = eventCache.get(className);
		if (event == null) {
			event = Type.createInstance(cl, []);
			eventCache.set(className, event);
		}
		return cast event;
	}
	#end

	public static function reset() {
		#if cpp
		cppEventCache = new haxe.ds.ObjectMap();
		#else
		for (event in eventCache) {
			event.destroy();
		}
		eventCache = [];
		#end
	}

	public static function init() {
		FlxG.signals.preStateCreate.add(onStateSwitch);
	}

	private static inline function onStateSwitch(newState:FlxState)
		reset();
}
