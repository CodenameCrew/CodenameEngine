package lime.utils;

import haxe.PosInfos;
#if !macro
import funkin.backend.system.Logs as FunkinLogs;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class Log
{
	public static var level:LogLevel;
	public static var throwErrors:Bool = false;

	public static function debug(message:Dynamic, ?info:PosInfos):Void
	{
		if (level >= LogLevel.DEBUG)
		{
			#if js
			untyped js.Syntax.code ("console").debug("[" + info.className + "] " + message);
			#elseif !macro
			FunkinLogs.trace('[${info.className}] $message', INFO, LIGHTGRAY);
			#else
			println("[" + info.className + "] " + Std.string(message));
			#end
		}
	}

	public static function error(message:Dynamic, ?info:PosInfos):Void
	{
		if (level >= LogLevel.ERROR)
		{
			if (throwErrors)
			{
				#if webassembly
				println(message);
				#end
				throw message;
			}
			else
			{
				#if !macro
				FunkinLogs.trace('[${info.className}] $message', ERROR, RED);
				#else
				println("[" + info.className + "] ERROR: " + message);
				#end
			}
		}
	}

	public static function info(message:Dynamic, ?info:PosInfos):Void
	{
		if (level >= LogLevel.INFO)
		{
			#if !macro
			FunkinLogs.trace('[${info.className}] $message', INFO, CYAN);
			#else
			println("[" + info.className + "] " + Std.string(message));
			#end
		}
	}

	public static inline function print(message:Dynamic):Void
	{
		#if sys
		Sys.print(Std.string(message));
		#elseif js
		untyped js.Syntax.code ("console").log(message);
		#else
		trace(message);
		#end
	}

	public static inline function println(message:Dynamic):Void
	{
		#if sys
		Sys.println(Std.string(message));
		#elseif js
		untyped js.Syntax.code ("console").log(message);
		#else
		trace(Std.string(message));
		#end
	}

	public static function verbose(message:Dynamic, ?info:PosInfos):Void
	{
		if (level >= LogLevel.VERBOSE)
		{
			#if !macro
			FunkinLogs.trace('[${info.className}] $message', VERBOSE);
			#else
			println("[" + info.className + "] " + message);
			#end
		}
	}

	public static function warn(message:Dynamic, ?info:PosInfos):Void
	{
		if (level >= LogLevel.WARN)
		{
			#if !macro
			FunkinLogs.trace('[${info.className}] $message', WARNING, YELLOW);
			#else
			println("[" + info.className + "] WARNING: " + Std.string(message));
			#end
		}
	}

	private static function __init__():Void
	{
		#if no_traces
		level = NONE;
		#elseif verbose
		level = VERBOSE;
		#else
		#if sys
		var args = Sys.args();
		if (args.indexOf("-v") > -1 || args.indexOf("-verbose") > -1)
		{
			level = VERBOSE;
		}
		else
		#end
		{
			#if debug
			level = DEBUG;
			#else
			level = INFO;
			#end
		}
		#end

		#if js
		if (untyped js.Syntax.code ("typeof console") == "undefined")
		{
			untyped js.Syntax.code ("console = {}");
		}
		if (untyped js.Syntax.code ("console").log == null)
		{
			untyped js.Syntax.code ("console").log = function() {};
		}
		#end
	}
}
