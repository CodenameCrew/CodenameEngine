package funkin.backend.scripting;

import flixel.util.FlxStringUtil;
import funkin.backend.scripting.events.CancellableEvent;

/**
 * Used to group multiple scripts together, and easily be able to call them.
**/
@:access(CancellableEvent)
class ScriptPack extends Script {
	public var scripts:Array<Script> = [];
	public var additionalDefaultVariables:Map<String, Dynamic> = [];
	public var publicVariables:Map<String, Dynamic> = [];
	public var parent:Dynamic = null;

	/**
	 * Loads all scripts in the pack.
	**/
	public override function load() {
		for(e in scripts) {
			e.load();
		}
	}

	/**
	 * Checks if the script pack contains a script with a specific path.
	 * @param path Path to check
	 */
	public function contains(path:String) {
		for(e in scripts)
			if (e.path == path)
				return true;
		return false;
	}
	public function new(name:String) {
		additionalDefaultVariables["importScript"] = importScript;
		super(name);
	}

	/**
	 * Gets a script by path.
	 * @param name Path to the script
	**/
	public function getByPath(name:String) {
		for(s in scripts)
			if (s.path == name)
				return s;
		return null;
	}

	/**
	 * Gets a script by name.
	 * @param name Name of the script
	**/
	public function getByName(name:String) {
		for(s in scripts)
			if (s.fileName == name)
				return s;
		return null;
	}

	/**
	 * Imports a script by path.
	 * @param path Path to the script
	 * @throws Error if the script does not exist
	**/
	public function importScript(path:String):Script {
		var script = Script.create(Paths.script(path));
		if (script is DummyScript) {
			throw 'Script at ${path} does not exist.';
			return null;
		}
		add(script);
		script.load();
		return script;
	}

	/**
	 * Calls a function on every single script.
	 * Only calls on scripts that are active.
	 * @param func Function to call
	 * @param parameters Parameters to pass to the function
	**/
	public override function call(func:String, ?parameters:Array<Dynamic>):Dynamic {
		for(e in scripts)
			if (e.active)
				e.call(func, parameters);
		return null;
	}

	/**
	 * Sends an event to every single script, and returns the event.
	 * @param func Function to call
	 * @param event Event (will be the first parameter of the function)
	 * @return (modified by scripts)
	 */
	public inline function event<T:CancellableEvent>(func:String, event:T):T {
		for(e in scripts) {
			if(!e.active) continue;

			e.call(func, [event]);
			if (event.cancelled && !event.__continueCalls) break;
		}
		return event;
	}

	/**
	 * Gets the first script that has a variable with a specific name.
	 * @param val Name of the variable
	**/
	public override function get(val:String):Dynamic {
		for(e in scripts) {
			var v = e.get(val);
			if (v != null) return v;
		}
		return null;
	}

	/**
	 * Reloads all scripts in the pack.
	**/
	public override function reload() {
		for(e in scripts) e.reload();
	}

	/**
	 * Sets a variable in every script.
	**/
	public override function set(val:String, value:Dynamic) {
		for(e in scripts) e.set(val, value);
	}

	/**
	 * Sets the parent/this of every script in the pack.
	 */
	public override function setParent(parent:Dynamic) {
		this.parent = parent;
		for(e in scripts) e.setParent(parent);
	}

	/**
	 * Destroys all scripts in the pack.
	**/
	public override function destroy() {
		super.destroy();
		for(e in scripts) e.destroy();
	}

	@:dox(hide) public override function onCreate(path:String) {}

	/**
	 * Adds a script to the pack, and sets the parent/this of the script.
	**/
	public function add(script:Script) {
		scripts.push(script);
		__configureNewScript(script);
	}

	/**
	 * Removes a script from the pack.
	 * Does not reset the parent/this.
	**/
	public function remove(script:Script) {
		scripts.remove(script);
	}

	/**
	 * Inserts a script into the pack, and sets the parent/this of the script.
	**/
	public function insert(pos:Int, script:Script) {
		scripts.insert(pos, script);
		__configureNewScript(script);
	}

	/**
	 * Configures a new script.
	 * @param script Script to configure
	**/
	private function __configureNewScript(script:Script) {
		if (parent != null) script.setParent(parent);
		script.setPublicMap(publicVariables);
		for(k=>e in additionalDefaultVariables) script.set(k, e);
	}

	override public function toString():String {
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("parent", FlxStringUtil.getClassName(parent, true)),
			LabelValuePair.weak("total", scripts.length),
		]);
	}
}