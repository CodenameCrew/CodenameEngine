package funkin.backend.chart;

import hscript.Parser;
import hscript.Interp;
import haxe.Json;
import openfl.Assets;
import haxe.io.Path;
import funkin.backend.assets.Paths;

using StringTools;

class EventsData {
	public static var defaultEventsList:Array<String> = ["HScript Call", "Camera Movement", "Add Camera Zoom", "Camera Modulo Change", "Camera Flash", "BPM Change", "Scroll Speed Change", "Alt Animation Toggle", "Play Animation"];
	public static var defaultEventsParams:Map<String, Array<EventParamInfo>> = [
		"HScript Call" => [
			{name: "Function Name", type: TString, defValue: "myFunc"},
			{name: "Function Parameters (String split with commas)", type: TString, defValue: ""}
		],
		"Camera Movement" => [{name: "Camera Target", type: TStrumLine, defValue: 0}],
		"Add Camera Zoom" => [
			{name: "Amount", type: TFloat(-10, 10, 0.01, 2), defValue: 0.05},
			{name: "Camera", type: TDropDown(['camGame', 'camHUD']), defValue: "camGame"}
		],
		"Camera Modulo Change" => [
			{name: "Modulo Interval (Beats)", type: TInt(1, 9999999, 1), defValue: 4},
			{name: "Bump Strength", type: TFloat(0.1, 10, 0.01, 2), defValue: 1}
		],
		"Camera Flash" => [
			{name: "Reversed?", type: TBool, defValue: false},
			{name: "Color", type: TColorWheel, defValue: "#FFFFFF"},
			{name: "Time (Steps)", type: TFloat(0.25, 9999, 0.25, 2), defValue: 4},
			{name: "Camera", type: TDropDown(['camGame', 'camHUD']), defValue: "camHUD"}
		],
		"BPM Change" => [{name: "Target BPM", type: TFloat(1.00, null, 0.001, 3), defValue: 100}],
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
				name: "Tween Type (ex: InOut)",
				type: TDropDown(['In', 'Out', 'InOut']),
				defValue: "In"
			}
		],
		"Alt Animation Toggle" => [{name: "Enable On Sing Poses", type: TBool, defValue: true}, {name: "Enable On Idle", type: TBool, defValue: true}, {name: "Strumline", type: TStrumLine, defValue: 0}],
		"Play Animation" => [{name: "Character", type: TStrumLine, defValue: 0}, {name: "Animation", type: TString, defValue: "animation"}, {name: "Is forced?", type: TBool, defValue: true}],
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
		hscriptInterp.variables.set("DropDown", Reflect.makeVarArgs((args) -> {return args.length > 0 ? TDropDown([for (arg in args) Std.string(arg)]) : TDropDown(["null"]);}));

		var hscriptParser:Parser = new Parser();
		hscriptParser.allowJSON = hscriptParser.allowMetadata = false;

		for (file in Paths.getFolderContent('data/events/', true, BOTH)) {
			if (Path.extension(file) != "json" && Path.extension(file) != "pack") continue;
			var eventName:String = Path.withoutExtension(Path.withoutDirectory(file));
			var fileTxt:String = Assets.getText(file);

			if (Path.extension(file) == "pack") {
				var arr = fileTxt.split("________PACKSEP________");
				eventName = Path.withoutExtension(arr[0]);
				fileTxt = arr[2];
			}

			if (fileTxt.trim() == "") continue;

			eventsList.push(eventName);
			eventsParams.set(eventName, []);

			try {
				var data:Dynamic = Json.parse(fileTxt);
				if (data == null || data.params == null) continue;

				var finalParams:Array<EventParamInfo> = [];
				for (paramData in cast(data.params, Array<Dynamic>)) {
					try {
						finalParams.push({name: paramData.name, type: hscriptInterp.expr(hscriptParser.parseString(paramData.type)), defValue: paramData.defaultValue});
					} catch (e) {trace('Error parsing event param ${paramData.name} - ${eventName}: $e'); finalParams.push(null);}
				}
				eventsParams.set(eventName, finalParams);
			} catch (e) {trace('Error parsing file $file: $e');}
		}

		hscriptInterp = null; hscriptParser = null;
	}
}

typedef EventInfo = {
	var params:Array<EventParamInfo>;
	var paramValues:Array<Dynamic>;
}

typedef EventParamInfo = {
	var name:String;
	var type:EventParamType;
	var defValue:Dynamic;
}

enum EventParamType {
	TBool;
	TInt(?min:Int, ?max:Int, ?step:Float);
	TFloat(?min:Float, ?max:Float, ?step:Float, ?precision:Int);
	TString;
	TStrumLine;
	TColorWheel;
	TDropDown(?options:Array<String>);
}
