package funkin.backend.scripting;

#if HARDCODED_SCRIPTS
@:autoBuild(funkin.backend.system.macros.HardcodedScriptVarMacro.build())
class HardcodedScript<T> extends Script {
	private var parent:T = null;
	private var instanceFields:Array<String> = [];
	private var handleErrors:Bool = true;
	private var publicVariables:Map<String, Dynamic> = [];
	private var dynamicVariables:Map<String, Dynamic> = [];

	public var importScript:String->Script = null;
	public var disableScript:Void->Void = null;

	public function new(path:String) {
		instanceFields = Type.getInstanceFields(Type.getClass(this));
		super(path);
	}

	public override function get(v:String) {
		if (instanceFields.contains(v) || instanceFields.contains("get_" + v)) return Reflect.getProperty(this, v);
		return dynamicVariables.get(v);
	}
	public override function set(v:String, v2:Dynamic) {
		if (v2 is Class) return;
		
		if (instanceFields.contains(v) || instanceFields.contains("set_" + v)) {
			Reflect.setProperty(this, v, v2);
			return;
		}
		dynamicVariables.set(v, v2);
	}

	public inline function getDynamic(v:String) { return dynamicVariables.get(v); }
	public inline function setDynamic(v:String, v2:Dynamic) { dynamicVariables.set(v, v2); }
	public inline function getPublic(v:String) { return publicVariables.get(v); }
	public inline function setPublic(v:String, v2:Dynamic) { publicVariables.set(v, v2); }
	public inline function getStatic(v:String) { return Script.staticVariables.get(v); }
	public inline function setStatic(v:String, v2:Dynamic) { Script.staticVariables.set(v, v2); }

	public override function setParent(variable:Dynamic) { parent = variable; }
	public override function setPublicMap(map:Map<String, Dynamic>) { publicVariables = map; }

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
		var fileName:String = "";
		var fileLine:Int = 0;
		var fileMethod:Null<String> = null;

		for (item in error.stack) {
			switch(item) {
				case FilePos(s, file, line, col):
					fileName = file;
					fileLine = line;
					switch(s) {
						case Method(classname, method):
							fileMethod = method;
						default:
					}
				default:
			}
			break;
		}

		Logs.traceColored([
			Logs.logText(fileName + (fileMethod != null ? ":" + fileMethod : "") + ":" + fileLine + ': ', GREEN),
			Logs.logText(error.toString(), RED)
		], ERROR);
		_onError();
	}

	public override function load() {
		if (!didLoad) {
			onCall("initVars", []); //initVars generated from HardcodedScriptVarMacro.hx
		}
		super.load();
	}
}
#end