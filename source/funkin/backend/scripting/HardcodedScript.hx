package funkin.backend.scripting;

#if HARDCODED_SCRIPTS
class HardcodedScript<T> extends Script {
	private var parent:T = null;
	private var handleErrors:Bool = true;
	private var disableAfterError:Bool = false;
	private var publicVariables:Map<String, Dynamic> = [];
	private var dynamicVariables:Map<String, Dynamic> = [];

	public override function get(v:String) {
		if (Reflect.getProperty(this, v) != null) return Reflect.getProperty(this, v);
		if (Reflect.getProperty(parent, v) != null) return Reflect.getProperty(parent, v);
		return dynamicVariables.get(v);
	}
	public override function set(v:String, v2:Dynamic) {
		if (v2 is Class) return;
		
		if (Reflect.getProperty(this, v) != null) {
			Reflect.setProperty(this, v, v2);
			return;
		}
		if (Reflect.getProperty(parent, v) != null) {
			Reflect.setProperty(parent, v, v2);
			return;
		}
		dynamicVariables.set(v, v2);
	}

	public function getDynamic(v:String) {
		return dynamicVariables.get(v);
	}
	public function setDynamic(v:String, v2:Dynamic) {
		dynamicVariables.set(v, v2);
	}
	public function getPublic(v:String) {
		return publicVariables.get(v);
	}
	public function setPublic(v:String, v2:Dynamic) {
		publicVariables.set(v, v2);
	}
	public function getStatic(v:String) {
		return Script.staticVariables.get(v);
	}
	public function setStatic(v:String, v2:Dynamic) {
		Script.staticVariables.set(v, v2);
	}
	/*public function importScript(path:String) {
		//TODO
	}*/

	public override function setParent(variable:Dynamic) { parent = variable; }
	public override function setPublicMap(map:Map<String, Dynamic>) { this.publicVariables = map; }

	public override function onCall(method:String, parameters:Array<Dynamic>):Dynamic {
		var func = Reflect.getProperty(this, method);
		if (Reflect.isFunction(func)) {
			if (handleErrors) {
				var ret = null;
				try {
					ret = (parameters != null && parameters.length > 0) ? Reflect.callMethod(null, func, parameters) : func();
				} catch(e) {
					_errorHandler(e);
				}
				return ret;
			}
			return (parameters != null && parameters.length > 0) ? Reflect.callMethod(null, func, parameters) : func();
		}
		return null;
	}
	private function _errorHandler(error:haxe.Exception) {
		var fileName = this.fileName;
		for (item in error.stack) {
			switch(item) {
				case FilePos(s, file, line, col):
					fileName = file + ":" + line;
				default:
			}
			break;
		}

		Logs.traceColored([
			Logs.logText(fileName + ': ', GREEN),
			Logs.logText(error.toString(), RED)
		], ERROR);

		if (disableAfterError) {
			active = false;
		}
	}

	public override function load() {
		if (!didLoad) {
			onCall("initVars", []); //initVars generated from HardcodedScriptVarMacro.hx
		}
		super.load();
	}
}
#end