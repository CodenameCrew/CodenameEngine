package funkin.backend.system.console;
import haxe.io.Path;
import funkin.backend.scripting.HScript;
import funkin.backend.scripting.ScriptPack;
import funkin.backend.scripting.Script;

import hscript.*;
import hscript.Expr.Error;
import hscript.Parser;
import hscript.CustomClass;

typedef ConsoleHscriptField = {
	var name:String;
	var type:String;
	var isStatic:Bool;
	var isScriptVar:Bool;
	var value:String;
	var ?autoComplete:String;
	var ?extraDesc:String;
};

class ConsoleHscript {
	//mods can add their own imports if needed
	public static var extraImports:Map<String, Dynamic> = [
		"Script" => Script
	];

	private static final scriptVariableBlackList:Array<String> = ["__script__", "importScript", "true", "false", "null", "disableScript", "trace"];
	private static final customClassVariableBlacklist:Array<String> = ["hset", "hget"];

	public var interp:Interp;
	public var parser:Parser;
	public var expr:Expr;
	public var variableFields:Array<ConsoleHscriptField> = [];

	public function new() {
		parser = new Parser();
		parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
		
		interp = new Interp();
		interp.importEnabled = false;

		resetVariables();
		FlxG.signals.postStateSwitch.add(function() {
			resetVariables();
		});
	}

	private function resetVariables() {
		@:privateAccess
		interp.resetVariables();
		variableFields = [];
		var defaults = Script.getDefaultVariables(null);
		for(k=>e in defaults) {
			set(k, e);
		}
		for (k=>e in extraImports) {
			set(k, e);
		}

		var scriptPacks:Array<ScriptPack> = [];
		var scriptPackPaths:Array<String> = [];
		if (FlxG.state is MusicBeatState) {
			var state:MusicBeatState = cast FlxG.state;
			scriptPacks.push(state.stateScripts);
			scriptPackPaths.push("stateScripts");
			set("stateScripts", state.stateScripts);
			if (PlayState.instance != null) {
				scriptPacks.push(PlayState.instance.scripts);
				scriptPackPaths.push("scripts");
				set("scripts", PlayState.instance.scripts);
			}
		}

		for (k=>e in Script.staticVariables) {
			variableFields.push({
				name: k,
				type: getFieldTypeName(e),
				isStatic: false,
				isScriptVar: true,
				value: getFieldTypeValue(e),
				autoComplete: "Script.staticVariables[\"" + k + "\"]",
				extraDesc: "Static"
			});
		}

		for (i => s in scriptPacks) {
			for (k=>e in s.publicVariables) {
				variableFields.push({
					name: k,
					type: getFieldTypeName(e),
					isStatic: false,
					isScriptVar: true,
					value: getFieldTypeValue(e),
					autoComplete: scriptPackPaths[i] + ".publicVariables[\"" + k + "\"]",
					extraDesc: "Public, " + scriptPackPaths[i]
				});
			}

			for (scriptIndex => script in s.scripts) {
				if (script is HScript) {
					var hscript:HScript = cast script;
					var name = "_"+Path.withoutExtension(script.fileName);
					while(interp.varExists(name)) name += "0"; //hopefully prevent duplicates
					name = name.replace(" ", "_");
					name = name.replace(".", "_");
					set(name, hscript.interp.variables);
					for (k=>e in hscript.interp.variables) {
						if (!defaults.exists(k) && !(e is Class) && !scriptVariableBlackList.contains(k)) {
							variableFields.push({
								name: k,
								type: getFieldTypeName(e),
								isStatic: false,
								isScriptVar: true,
								value: getFieldTypeValue(e),
								autoComplete: name + "[\"" + k + "\"]",
								extraDesc: "Local, " + script.fileName
							});
						}
					}
				}
				
			}
		}
	}

	public function set(val:String, value:Dynamic) {
		interp.variables.set(val, value);
		variableFields.push({
			name: val,
			type: value is Class ? Type.getClassName(value) : getFieldTypeName(value),
			isStatic: (value is Class),
			isScriptVar: false,
			value: ""
		});
	}

	public function prepareString(str:String) {
		if (str.endsWith(";")) str = str.substr(0, -1);
		return str;
	}
	public function getObj(str:String) {
		var obj:Dynamic = null;
		try {
			obj = interp.expr(parser.parseString(str, "console"));
		} catch(e:Error) {
			//ignore errors while getting fields
		} catch(e) {
			
		}
		return obj;
	}

	public function getFieldTypeName(obj:Dynamic) {
		switch(Type.typeof(obj)) {
			case TBool:
				return "Bool";
			case TInt:
				return "Int";
			case TFloat:
				return "Float";
			case TFunction:
				return "Function";
			case TObject:
				return "Dynamic";
			case TEnum(c):
				return Type.getEnumName(c);
			case TClass(c):
				return Type.getClassName(c);
			default:
				return Type.getClassName(Type.getClass(obj));
		}
		return "Unknown";
	}

	public function getFieldTypeValue(obj:Dynamic) {
		switch(Type.typeof(obj)) {
			case TBool:
				return Std.string(obj);
			case TInt:
				return Std.string(obj);
			case TFloat:
				return Std.string(obj);
			case TFunction:
				return "";
			case TObject:
				return "";
			case TEnum(c):
				return Std.string(obj);
			case TClass(c):
				if (getFieldTypeName(obj) == "Array" && obj != null) {
					return "Length: " + obj.length + (obj.length > 0 ? ", " + getFieldTypeName(obj[0]) : ""); //guess the type based on first element
				} else if (getFieldTypeName(obj) == "String") {
					return "\"" + Std.string(obj) + "\"";
				} else if (Reflect.hasField(obj, "toString")) {
					return Std.string(obj);
				}
			default:
				return "";
		}
		return "";
	}

	public function tryGetFields(str:String) {
		var obj:Dynamic = getObj(prepareString(str));
		if (obj == null) return [];

		var returnFields:Array<ConsoleHscriptField> = [];
		var fields:Array<String> = [];
		var isStatic = (obj is Class);
		var isEnum = (obj is Enum);
		var isObject = Reflect.isObject(obj);
		var hasClass = Type.getClass(obj) != null;

		if (isStatic) {
			fields = Type.getClassFields(obj);
		} else if (isEnum) {
			fields = Type.getEnumConstructs(obj);
		} else if (obj is CustomClass) {
			var customClass:CustomClass = cast obj;
			@:privateAccess
			for (f in customClass.getSuperFields()) {
				if (!f.startsWith("_HX_SUPER__") && !customClassVariableBlacklist.contains(f)) {
					fields.push(f);
				}
			}
		} else if (hasClass) {
			fields = Type.getInstanceFields(Type.getClass(obj));
		} else if (isObject) { //usually for dynamic structs
			fields = Reflect.fields(obj);
		}

		var filteredFields:Array<String> = [];
		for (field in fields) {
			if (field.startsWith("get_") || field.startsWith("set_")) {
				var name = field.substr(4);
				if (!fields.contains(name) && !filteredFields.contains(name))
					filteredFields.push(name);
			}
			else {
				filteredFields.push(field);
			}
		}

		for (field in filteredFields) {
			var fieldObj = getObj(prepareString(str) + "." + field);
			if (fieldObj != null) {
				returnFields.push({
					name: field,
					type: getFieldTypeName(fieldObj),
					isStatic: isStatic,
					isScriptVar: false,
					value: getFieldTypeValue(fieldObj)
				});
			} else {
				returnFields.push({
					name: field,
					type: "Unknown",
					isStatic: isStatic,
					isScriptVar: false,
					value: ""
				});
			}
		}
		return returnFields;
	}

	public function tryExecute(cmd:String) {
		cmd = cmd.trim();
		if (!cmd.endsWith(";")) cmd += ";";
		var ret = null;
		try {
			ret = interp.execute(parser.parseString(cmd, "console"));
		} catch(e:Error) {
			ret = e.toString();
		} catch(e) {
			ret = e.toString();
		}
		return ret;
	}
}