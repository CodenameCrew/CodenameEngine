package funkin.backend.scripting;

import hscript.IHScriptCustomBehaviour;

class MultiThreadedScript implements IFlxDestroyable implements IHScriptCustomBehaviour {
	/**
	 * Script being ran.
	 */
	public var script:Script;

	private var __variables:Array<String>;

	/**
	 * Return value of the last call.
	 */
	public var returnValue:Dynamic = null;

	/**
	 * Whenever the current call has ended.
	 */
	public var callEnded:Bool = true;



	public function new(path:String, ?parentScript:Script) {
		script = Script.create(path);

		if (parentScript != null) {
			if (script is HScript && parentScript is HScript) {
				var hscript:HScript = cast script;
				var parentHScript:HScript = cast parentScript;

				hscript.interp.variables = parentHScript.interp.variables;
				hscript.interp.publicVariables = parentHScript.interp.publicVariables;
				hscript.interp.staticVariables = parentHScript.interp.staticVariables;

				script.setParent(parentHScript.interp.scriptObject);
			}
		}

		script.load();

		__variables = Type.getInstanceFields(Type.getClass(this));
	}

	public function hget(name:String):Dynamic
		return __variables.contains(name) ? Reflect.getProperty(this, name) : script.get(name);

	public function hset(name:String, val:Dynamic):Dynamic {
		if (__variables.contains(name))
			Reflect.setProperty(this, name, val);
		else
			script.set(name, val);
		return val;
	}

	public function call(func:String, args:Array<Dynamic>) {
		#if ALLOW_MULTITHREADING
		funkin.backend.utils.ThreadUtil.execAsync(() -> {
			callEnded = false;
			returnValue = script.call(func, args);
			callEnded = true;
		});
		#else
		returnValue = script.call(func, args);
		callEnded = true;
		#end
	}

	public function destroy() {
		if (script != null) {
			script.call("destroy");
			script.destroy();
		}
	}
}