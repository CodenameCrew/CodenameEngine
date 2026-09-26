package funkin.backend.scripting.cppia;

#if (cpp && scriptable)
import cpp.cppia.Module;
import funkin.backend.system.Logs;
import lime.utils.Assets as LimeAssets;

@:headerCode('#include <hx/Scriptable.h>')
class CppiaModule
{
	private static var __modules:Map<String, Module> = [];
	private static var __signatures:Map<String, String> = [];

	static function getSignature(bytes:haxe.io.Bytes):String
		return bytes.length + ":" + haxe.crypto.Md5.make(bytes).toHex();

	/**
	 * Enables the CPPIA JIT compiler.
	 * Not enabled by default, since the current hxcpp JIT silently swallows thrown errors and crashes on generated code.
	 */
	@:functionCode('hx::gEnableJit = inEnable;')
	public static function enableJit(inEnable:Bool):Void {}

	public static function load(assetPath:String):Module
	{
		try {
			if (!LimeAssets.exists(assetPath))
				return null;

			var bytes = LimeAssets.getBytes(assetPath);
			var signature = getSignature(bytes);

			if (__signatures.get(assetPath) == signature)
				return __modules.get(assetPath);

			var module = Module.fromData(bytes.getData());
			module.boot();
			__modules.set(assetPath, module);
			__signatures.set(assetPath, signature);
			return module;
		} catch(e) {
			var reason = Std.string(e);
			// prevent the application from crashing outright
			try __signatures.set(assetPath, getSignature(LimeAssets.getBytes(assetPath))) catch(_) {}
			Logs.error('Error while loading cppia module $assetPath: $reason');
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
		__signatures = [];
	}
}
#end
