package funkin.backend.scripting.cppia;

#if (cpp && scriptable)
import cpp.cppia.Module;
import funkin.backend.system.Logs;
import funkin.backend.utils.NativeAPI.ConsoleColor;
import lime.utils.Assets as LimeAssets;

@:headerCode('#include <hx/Scriptable.h>')
class CppiaModule
{
	private static var __modules:Map<String, Module> = [];
	private static var __failedModules:Map<String, String> = [];

	public static function load(assetPath:String):Module
	{
		if (__modules.exists(assetPath))
			return __modules.get(assetPath);
		if (__failedModules.exists(assetPath))
			return null;

		try {
			if (!LimeAssets.exists(assetPath))
				return null;

			var module = Module.fromData(LimeAssets.getBytes(assetPath).getData());
			module.boot();
			__modules.set(assetPath, module);
			return module;
		} catch(e) {
			var reason = Std.string(e);
			__failedModules.set(assetPath, reason);
			Logs.traceColored([
				Logs.logText(assetPath, GREEN),
				Logs.logText('Error while loading cppia module: $reason', RED)
			], ERROR);
			return null;
		}
	}

	public static function resolve(assetPath:String, className:String):Class<Dynamic>
	{
		var module = load(assetPath);
		if (module == null)
			return null;

		return module.resolveClass(className);
	}

	// modules can't actually be unloaded
	public static function clearCache():Void
	{
		__modules = [];
		__failedModules = [];
	}
}
#end
