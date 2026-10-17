package funkin.backend.system;

import flixel.system.debug.log.LogStyle;
import flixel.system.frontEnds.LogFrontEnd;
import funkin.backend.system.console.ConsoleUI;
import funkin.backend.utils.NativeAPI.ConsoleColor;
import funkin.backend.utils.NativeAPI;
import haxe.Log;

final class Logs {
	private static var __showing:Bool = false;

	public static final LOG_WARNING_TEXT =     '   WARNING   ';
	public static final LOG_ERROR_TEXT =       '    ERROR    ';
	public static final LOG_TRACE_TEXT =       '    TRACE    ';
	public static final LOG_VERBOSE_TEXT =     '   VERBOSE   ';
	public static final LOG_SUCCESS_TEXT =     '   SUCCESS   ';
	public static final LOG_FAILURE_TEXT =     '   FAILURE   ';
	public static final LOG_INFORMATION_TEXT = ' INFORMATION ';

	public static var nativeTrace = Log.trace;
	public static function init() {
		Log.trace = function(v:Dynamic, ?infos:Null<haxe.PosInfos>) {
			var data = [
				logText('${infos.fileName}:${infos.lineNumber}: ', CYAN, TRACE),
				logText(Std.string(v), LIGHTGRAY, TRACE)
			];

			if (infos.customParams != null) {
				for (i in infos.customParams) {
					data.push(
						logText("," + Std.string(i), LIGHTGRAY, TRACE)
					);
				}
			}
			traceColored(data, TRACE);
		};

		LogFrontEnd.onLogs = function(data, style, fireOnce) {
			var prefix = "[FLIXEL]";
			var color:ConsoleColor = LIGHTGRAY;
			var level:Level = INFO;
			if (style == LogStyle.CONSOLE)  // cant place a switch here as these aren't inline values  - Nex
			{
				prefix = "> ";
				color = WHITE;
				level = INFO;
			}
			else if (style == LogStyle.ERROR)
			{
				prefix = "[FLIXEL]";
				color = RED;
				level = ERROR;
			}
			else if (style == LogStyle.NORMAL)
			{
				prefix = "[FLIXEL]";
				color = WHITE;
				level = INFO;
			}
			else if (style == LogStyle.NOTICE)
			{
				prefix = "[FLIXEL]";
				color = GREEN;
				level = VERBOSE;
			}
			else if (style == LogStyle.WARNING)
			{
				prefix = "[FLIXEL]";
				color = YELLOW;
				level = WARNING;
			}

			var d:Dynamic = data;
			if (!(d is Array))
				d = [d];
			var a:Array<Dynamic> = d;
			var strs = [for(e in a) Std.string(e)];
			for(e in strs)
			{
				Logs.trace('$prefix $e', level, color);
			}
		};
	}

	public static function prepareColoredTrace(text:Array<LogText>, level:Level = INFO) {
		var time = Date.now();
		var superCoolText = [
			logText('[  ', LIGHTGRAY, level),
			logText('${Std.string(time.getHours()).addZeros(2)}:${Std.string(time.getMinutes()).addZeros(2)}:${Std.string(time.getSeconds()).addZeros(2)}', DARKMAGENTA, level),
			logText('  |', LIGHTGRAY, level),
			switch (level)
			{
				case WARNING:	logText(LOG_WARNING_TEXT, DARKYELLOW, level);
				case ERROR:		logText(LOG_ERROR_TEXT, DARKRED, level);
				case TRACE:		logText(LOG_TRACE_TEXT, GRAY, level);
				case VERBOSE:	logText(LOG_VERBOSE_TEXT, DARKMAGENTA, level);
				case SUCCESS:	logText(LOG_SUCCESS_TEXT, GREEN, level);
				case FAILURE:	logText(LOG_FAILURE_TEXT, RED, level);
				default:		logText(LOG_INFORMATION_TEXT, CYAN, level);
			},
			logText('] ', LIGHTGRAY, level)
		];
		for(k=>e in superCoolText)
			text.insert(k, e);
		return text;
	}

	public static function logText(text:String, color:ConsoleColor = LIGHTGRAY, level:Level = INFO):LogText {
		return {
			text: text,
			color: color,
			level: level
		};
	}

	public static function __showInConsole(text:Array<LogText>) {
		#if (sys && !mobile)
		while(__showing) {
			Sys.sleep(0.05);
		}
		__showing = true;
		for(t in text) {
			NativeAPI.setConsoleColors(t.color);
			Sys.print(t.text);
		}
		NativeAPI.setConsoleColors();
		Sys.println("\r");
		__showing = false;
		#elseif mobile
		while(__showing) {
			Sys.sleep(0.05);
		}
		__showing = true;
		@:privateAccess
		Sys.print([for(t in text) t.text].join(""));
		__showing = false;
		#else
		@:privateAccess
		nativeTrace([for(t in text) t.text].join(""));
		#end

		#if IMGUI_ENABLED
		@:privateAccess
		ConsoleUI.instance.addToConsole(text);
		#end
	}

	public inline static function traceColored(text:Array<LogText>, level:Level = INFO)
		__showInConsole(prepareColoredTrace(text, level));

	public static function trace(text:String, level:Level = INFO, color:ConsoleColor = LIGHTGRAY, ?prefix:String) {
		var text = [logText(text, color, level)];
		if(prefix != null) text.insert(0, getPrefix(prefix, level));
		traceColored(text, level);
	}

	public inline static function getPrefix(prefix:String, level:Level = INFO)
		return logText('[${prefix}] ', BLUE, level);

	public inline static function infos(text:String, color:ConsoleColor = LIGHTGRAY, ?prefix:String)
		Logs.trace(text, INFO, color, prefix);

	public inline static function verbose(text:String, color:ConsoleColor = LIGHTGRAY, ?prefix:String)
		if (Main.verbose) Logs.trace(text, VERBOSE, color, prefix);

	public inline static function warn(text:String, color:ConsoleColor = YELLOW, ?prefix:String)
		Logs.trace(text, WARNING, color, prefix);

	public inline static function error(text:String, color:ConsoleColor = RED, ?prefix:String)
		Logs.trace(text, ERROR, color, prefix);
}

enum abstract Level(Int) {
	var INFO = 0;
	var WARNING = 1;
	var ERROR = 2;
	var TRACE = 3;
	var VERBOSE = 4;
	var SUCCESS = 5;
	var FAILURE = 6;
}

typedef LogText = {
	var text:String;
	var color:ConsoleColor;
	var level:Level;
}
