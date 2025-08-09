package funkin.backend.chart;

import funkin.backend.assets.Paths;
import haxe.Json;
import haxe.io.Path;
import hscript.Interp;
import hscript.Parser;
import openfl.Assets;

using StringTools;

class EventsData {
	public static var defaultEventsList:Array<String> = ["HScript Call", "Camera Movement", "Camera Position", "Add Camera Zoom", "Camera Bop", "Camera Zoom", "Camera Modulo Change", "Camera Flash", "BPM Change", "Continuous BPM Change", "Time Signature Change", "Scroll Speed Change", "Alt Animation Toggle", "Play Animation"];
	public static var defaultEventsParams:Map<String, Array<EventParamInfo>> = [
		"HScript Call" => [
			{name: "Function Name", type: TString, defValue: "myFunc"},
			{name: "Function Parameters (String split with commas)", type: TString, defValue: ""}
		],
		"Camera Movement" => [
			{name: "Camera Target", type: TStrumLine, defValue: 0},
			{name: "Tween Movement?", type: TBool, defValue: true, saveIfDefault: false},
			{name: "Tween Time (Steps, IF NOT CLASSIC)", type: TFloat(0.25, 9999, 0.25, 2), defValue: 4, saveIfDefault: false},
			{  // since its the most used event even by default, we'll set saveIfDefault false to avoid filling up with unnecessary parameters the files  - Nex
				name: "Tween Ease (ex: circ, quad, cube)",
				type: TDropDown(['CLASSIC', 'linear', 'back', 'bounce', 'circ', 'cube', 'elastic', 'expo', 'quad', 'quart', 'quint', 'sine', 'smoothStep', 'smootherStep']),
				defValue: "CLASSIC",
				saveIfDefault: false
			},
			{
				name: "Tween Type (excluded if CLASSIC or linear, ex: InOut)",
				type: TDropDown(['In', 'Out', 'InOut']),
				defValue: "In",
				saveIfDefault: false
			}
		],
		"Camera Position" => [
			{name: "X", type: TFloat(null, null, 10, 3), defValue: 0},
			{name: "Y", type: TFloat(null, null, 10, 3), defValue: 0},
			{name: "Tween Movement?", type: TBool, defValue: true, saveIfDefault: false},
			{name: "Tween Time (Steps, IF NOT CLASSIC)", type: TFloat(0.25, 9999, 0.25, 2), defValue: 4, saveIfDefault: false},
			{
				name: "Tween Ease (ex: circ, quad, cube)",
				type: TDropDown(['CLASSIC', 'linear', 'back', 'bounce', 'circ', 'cube', 'elastic', 'expo', 'quad', 'quart', 'quint', 'sine', 'smoothStep', 'smootherStep']),
				defValue: "CLASSIC",
				saveIfDefault: false
			},
			{
				name: "Tween Type (excluded if CLASSIC or linear, ex: InOut)",
				type: TDropDown(['In', 'Out', 'InOut']),
				defValue: "In",
				saveIfDefault: false
			},
			{name: "Is Offset?", type: TBool, defValue: false, saveIfDefault: false}
		],
		"Add Camera Zoom" => [
			{name: "Amount", type: TFloat(-10, 10, 0.01, 2), defValue: 0.05},
			{name: "Camera", type: TDropDown(['camGame', 'camHUD']), defValue: "camGame"}
		],
		"Camera Bop" => [
			{name: "Amount", type: TFloat(-10, 10, 0.1, 2), defValue: 0.1}
		],
		"Camera Zoom" => [
			{name: "Tween Zoom?", type: TBool, defValue: true},
			{name: "New Zoom", type: TFloat(-10, 10, 0.01, 2), defValue: 1},
			{name: "Camera", type: TDropDown(['camGame', 'camHUD']), defValue: "camGame"},
			{name: "Tween Time (Steps)", type: TFloat(0.25, 9999, 0.25, 2), defValue: 4},
			{
				name: "Tween Ease (ex: circ, quad, cube)",
				type: TDropDown(['linear', 'back', 'bounce', 'circ', 'cube', 'elastic', 'expo', 'quad', 'quart', 'quint', 'sine', 'smoothStep', 'smootherStep']),
				defValue: "linear"
			},
			{
				name: "Tween Type (excluded if linear, ex: InOut)",
				type: TDropDown(['In', 'Out', 'InOut']),
				defValue: "In"
			},
			{name: "Mode", type: TDropDown(['direct', 'stage']), defValue: "direct"},
			{name: "Multiplicative?", type: TBool, defValue: true}
		],
		"Camera Modulo Change" => [
			{name: "Modulo Interval", type: TInt(1, 9999999, 1), defValue: 4},
			{name: "Bump Strength", type: TFloat(0.1, 10, 0.01, 2), defValue: 1},
			{name: "Every Beat Type", type: TDropDown(['BEAT', 'MEASURE', 'STEP']), defValue: 'BEAT'},
			{name: "Beat Offset", type: TFloat(-10, 10, 0.25, 2), defValue: 0}
		],
		"Camera Flash" => [
			{name: "Reversed?", type: TBool, defValue: false},
			{name: "Color", type: TColorWheel, defValue: "#FFFFFF"},
			{name: "Time (Steps)", type: TFloat(0.25, 9999, 0.25, 2), defValue: 4},
			{name: "Camera", type: TDropDown(['camGame', 'camHUD']), defValue: "camHUD"}
		],
		"BPM Change" => [{name: "Target BPM", type: TFloat(1.00, 9999, 0.001, 3), defValue: 100}],
		"Continuous BPM Change" => [{name: "Target BPM", type: TFloat(1.00, 9999, 0.001, 3), defValue: 100}, {name: "Time (steps)", type: TFloat(0.25, 9999, 0.25, 2), defValue: 4}],
		"Time Signature Change" => [{name: "Target Numerator", type: TFloat(1), defValue: 4}, {name: "Target Denominator", type: TFloat(1), defValue: 4}, {name: "Denominator is Steps Per Beat", type: TBool, defValue: false}],
		"Scroll Speed Change" => [
			{name: "Tween Speed?", type: TBool, defValue: true},
			{name: "New Speed", type: TFloat(0.01, 99, 0.01, 2), defValue: 1.},
			{name: "Tween Time (Steps)", type: TFloat(0.25, 9999, 0.25, 2), defValue: 4},
			{
				name: "Tween Ease (ex: circ, quad, cube)",
				type: TDropDown(['linear', 'back', 'bounce', 'circ', 'cube', 'elastic', 'expo', 'quad', 'quart', 'quint', 'sine', 'smoothStep', 'smootherStep']),
				defValue: "linear"
			},
			{
				name: "Tween Type (excluded if linear, ex: InOut)",
				type: TDropDown(['In', 'Out', 'InOut']),
				defValue: "In"
			},
			{name: "Multiplicative?", type: TBool, defValue: false}
		],
		"Alt Animation Toggle" => [{name: "Enable On Sing Poses", type: TBool, defValue: true}, {name: "Enable On Idle", type: TBool, defValue: true}, {name: "Strumline", type: TStrumLine, defValue: 0}],
		"Play Animation" => [
			{name: "Character", type: TStrumLine, defValue: 0},
			{name: "Animation", type: TString, defValue: "animation"},
			{name: "Is forced?", type: TBool, defValue: true},
			{
				name: "Animation Context",
				type: TDropDown(["NONE", "SING", "DANCE", "MISS", "LOCK"]),
				defValue: "NONE"
			}
		],
	];

	public static var eventsList:Array<String> = defaultEventsList.copy();
	public static var eventsParams:Map<String, Array<EventParamInfo>> = defaultEventsParams.copy();

	public static function getEventParams(name:String):Array<EventParamInfo> {
		return eventsParams.exists(name) ? eventsParams.get(name) : [];
	}

	public static function reloadEvents() {
		eventsList = defaultEventsList.copy();
		eventsParams = defaultEventsParams.copy();

		var hscriptInterp:Interp = new Interp();
		hscriptInterp.variables.set("Bool", TBool);
		hscriptInterp.variables.set("Int", function (?min:Int, ?max:Int, ?step:Float):EventParamType {return TInt(min, max, step);});
		hscriptInterp.variables.set("Float", function (?min:Float, ?max:Float, ?step:Float, ?precision:Int):EventParamType {return TFloat(min, max, step, precision);});
		hscriptInterp.variables.set("String", TString);
		hscriptInterp.variables.set("StrumLine", TStrumLine);
		hscriptInterp.variables.set("ColorWheel", TColorWheel);
		hscriptInterp.variables.set("DropDown", Reflect.makeVarArgs(function(args:Array<Dynamic>):EventParamType {
			var flatArgs = CoolUtil.deepFlatten(args);
			if(flatArgs.length == 0) return TDropDown(["null"]);
			return TDropDown([for (arg in flatArgs) Std.string(arg)]);
		}));
		hscriptInterp.variables.set("Character", TCharacter);
		hscriptInterp.variables.set("Stage", TStage);

		var hscriptParser:Parser = new Parser();
		hscriptParser.allowJSON = hscriptParser.allowMetadata = false;

		for (file in Paths.getFolderContent('data/events/', true, BOTH)) {
			var ext = Path.extension(file);
			if (ext != "json" && ext != "pack") continue;
			var eventName:String = CoolUtil.getFilename(file);
			var fileTxt:String = Assets.getText(file);

			if (ext == "pack") {
				var arr = fileTxt.split("________PACKSEP________");
				eventName = Path.withoutExtension(arr[0]);
				fileTxt = arr[2];
			}

			if (fileTxt.trim() == "") continue;

			eventsList.push(eventName);
			eventsParams.set(eventName, []);

			try {
				var data:EventInfoFile = cast Json.parse(fileTxt);
				if (data == null || data.params == null) continue;

				var finalParams:Array<EventParamInfo> = [];
				for (paramData in data.params) {
					try {
						finalParams.push({
							name: paramData.name,
							type: hscriptInterp.expr(hscriptParser.parseString(paramData.type)),
							defValue: paramData.defaultValue
						});
					} catch (e) {trace('Error parsing event param ${paramData.name} - ${eventName}: $e'); finalParams.push(null);}
				}
				eventsParams.set(eventName, finalParams);
			} catch (e) {trace('Error parsing file $file: $e');}
		}

		hscriptInterp = null; hscriptParser = null;
	}
}

typedef EventInfoFile = {
	var params:Array<{
		var name:String;
		var type:String;
		var defaultValue:Dynamic;
	}>;
}

typedef EventInfo = {
	var params:Array<EventParamInfo>;
}

typedef EventParamInfo = {
	var name:String;
	var type:EventParamType;
	var defValue:Dynamic;
	var ?saveIfDefault:Bool;
}

enum EventParamType {
	TBool;
	TInt(?min:Int, ?max:Int, ?step:Float);
	TFloat(?min:Float, ?max:Float, ?step:Float, ?precision:Int);
	TString;
	TStrumLine;
	TColorWheel;
	TDropDown(?options:Array<String>);
	TCharacter;
	TStage;
}
