package funkin.backend.scripting;

#if (cpp && scriptable)
import funkin.backend.scripting.cppia.CppiaModule;
import funkin.backend.system.Logs;

class CppiaScript extends Script
{
	/**
	 * The entry class instance all calls are forwarded to.
	 */
	public var instance:Dynamic;

	// declared fields of the entry class (Reflect.hasField isn't usable on cppia instances)
	var __fields:Map<String, Bool>;

	// last parent object received through setParent, re-applied after reload
	var __lastParent:Dynamic;

	/**
	 * Variables injected by the engine that have no matching instance field (ex: `disableScript` closures).
	 * Readable via `Script.get` but not accessible from compiled cppia code.
	 */
	var __extraVars:Map<String, Dynamic> = [];

	static function getEntryClassName(script:Script):String
	{
		var fileName = script.fileName;
		var dot = fileName.lastIndexOf(".");
		return dot < 0 ? fileName : fileName.substring(0, dot);
	}

	public override function onCreate(path:String) {
		super.onCreate(path);

		#if GLOBAL_SCRIPT
		funkin.backend.scripting.GlobalScript.call("onScriptCreated", [this, "cppia"]);
		#end

		// cppia has no top-level code
		var className = getEntryClassName(this);
		var cls = CppiaModule.resolve(rawPath, className);
		if (cls == null) {
			error('Failed to load cppia script (entry class "$className" not found)');
			return;
		}
		instance = Type.createInstance(cls, []);
		__fields = [for (f in Type.getInstanceFields(cls)) f => true];
	}

	private override function onCall(funcName:String, parameters:Array<Dynamic>):Dynamic {
		if (instance == null) return null;

		var func = Reflect.field(instance, funcName);
		if (func == null || !Reflect.isFunction(func))
			func = __extraVars.get(funcName);
		if (func != null && Reflect.isFunction(func))
			return Reflect.callMethod(instance, func, parameters == null ? Script._EMPTY_ARGS : parameters);

		return null;
	}

	public override function get(val:String):Dynamic {
		if (instance == null) return null;
		if (__fields.get(val) == true) {
			var v = Reflect.field(instance, val);
			// getter-only properties (ex: @:scriptParent forwarders like `dad`) return null here,
			// their physical getter method `get_<name>` is still reflectable
			if (v == null) {
				var getter = Reflect.field(instance, 'get_$val');
				if (getter != null && Reflect.isFunction(getter))
					return Reflect.callMethod(instance, getter, Script._EMPTY_ARGS);
			}
			return v;
		}
		return __extraVars.get(val);
	}

	public override function set(val:String, value:Dynamic):Void {
		if (instance == null) return;
		if (__fields.get(val) == true)
			Reflect.setProperty(instance, val, value);
		else
			__extraVars.set(val, value);
	}

	public override function setParent(variable:Dynamic) {
		super.setParent(variable);
		__lastParent = variable;
		if (instance != null && __fields != null && __fields.get("__parent") == true) {
			// validates against the macro-generated type tag
			var expected = Reflect.field(Type.getClass(instance), "__parentType");
			if (expected != null && variable != null && !Std.isOfType(variable, expected)) {
				Logs.warn('Parent type mismatch: expected ${Type.getClassName(expected)} but got ${Type.getClassName(Type.getClass(variable))}, parent forwarders are disabled', fileName);
				return;
			}
			Reflect.setProperty(instance, "__parent", variable);
		}
	}

	public override function reload() {
		if (rawPath == null) return;

		// CppiaModule's content-signature cache reloads the module if the file changed
		var className = getEntryClassName(this);
		var cls = CppiaModule.resolve(rawPath, className);
		if (cls == null) return;

		instance = null;
		__extraVars = [];
		instance = Type.createInstance(cls, []);
		__fields = [for (f in Type.getInstanceFields(cls)) f => true];
		// re-inject default variables, the new instance starts fresh
		for (k => e in Script.getDefaultVariables(this))
			set(k, e);
		// restore the parent object on the fresh instance
		if (__lastParent != null)
			setParent(__lastParent);
	}

	override public function destroy() {
		// the module itself is process-lifetime resident; only the instance is dropped here
		instance = null;
		__fields = null;
		__extraVars = [];
		super.destroy();
	}
}
#end
