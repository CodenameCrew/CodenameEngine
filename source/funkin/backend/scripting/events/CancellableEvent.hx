package funkin.backend.scripting.events;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;

@:allow(funkin.backend.scripting.ScriptPack)
@:autoBuild(funkin.backend.system.macros.EventMacro.build())
class CancellableEvent implements IFlxDestroyable {
	@:dox(hide) public var cancelled:Bool = false;
	@:dox(hide) private var __continueCalls:Bool = true;

	/**
	 * Additional data if used in scripts
	 */
	public var data:Dynamic = {};

	/**
	 * Prevents default action from occurring.
	 * @param c Whenever the scripts following this one should be called or not. (Defaults to `true`)
	 */
	public function preventDefault(c:Bool = false) {
		cancelled = true;
		__continueCalls = c;
	}

	@:dox(hide)
	public function cancel(c:Bool = true) {preventDefault(c);}

	/**
	 * Creates a new cancellable event.
	 * This allows scripts to call `cancel()` to cancel the event.
	 */
	public function new() {}

	public function recycleBase() {
		data = {};
		cancelled = false;
		__continueCalls = true;
	}

	/**
	 * Returns a string representation of the event, in this format:
	 * `[CancellableEvent]`
	 * `[CancellableEvent (Cancelled)]`
	 * @return String
	 */
	public function toString():String {
		var fields = Reflect.fields(this);
		var claName = Type.getClassName(Type.getClass(this)).split(".");
		var rep = '[${claName[claName.length-1]}${cancelled ? " (Cancelled)" : ""}]';
		return rep;
	}

	public function destroy() {
		data = null;
	}
}
