package funkin.backend.utils;

/**
 * Small util that allows you to load any function from ndlls via `getFunction`.
 *
 * NDLLs must be in your mod's "ndlls" folder, and must follow this name scheme:
 * - `name-windows.ndll` for Windows targeted ndlls
 * - `name-linux.ndll` for Linux targeted ndlls
 * - `name-mac.ndll` for Mac targeted ndlls
 *
 * If:
 * - The platform does not support NDLLs
 * - The NDLL is not found
 * - The Function cannot be found in the NDLL
 * then an empty function will be returned instead, and a message will be shown in logs.
 */
final class NdllUtil {
	#if NDLLS_SUPPORTED
		#if windows   public static final os:String = "windows";   #end
		#if linux     public static final os:String = "linux";     #end
		#if macos     public static final os:String = "mac";       #end
		#if android   public static final os:String = "android";   #end
		#if ios       public static final os:String = "ios";       #end
	#end

	/**
	 * Returns an function from a Haxe NDLL.
	 * Limited to 25 argument due to a limitation
	 *
	 * @param ndll Name of the NDLL.
	 * @param name Name of the function.
	 * @param args Number of arguments of that function.
	 */
	public static function getFunction(ndll:String, name:String, args:Int):Dynamic {
		#if NDLLS_SUPPORTED
		var func:Dynamic = getFunctionFromPath(Paths.ndll('$ndll-$os'), name, args);

		return Reflect.makeVarArgs(function(a:Array<Dynamic>) {
			// This generates horrific code
			return funkin.backend.system.macros.Utils.generateReflectionLike(25, "func", "a");
			//return Reflect.callMethod(null, func, a); // wouldn't work for some reason, maybe cause like c++ functions doesn't have reflection enabled
		});
		#else
		Logs.warn('NDLLs are not supported on this platform.');
		return noop;
		#end
	}

	/**
	 * Returns an function from a Haxe NDLL at specified path.
	 *
	 * @param ndll Asset path to the NDLL.
	 * @param name Name of the function.
	 * @param args Number of arguments of that function.
	 */
	public static function getFunctionFromPath(ndll:String, name:String, args:Int):Dynamic {
		#if NDLLS_SUPPORTED
		if (!Assets.exists(ndll)) {
			Logs.warn('Couldn\'t find ndll at ${ndll}.');
			return noop;
		}
		var func = lime.system.CFFI.load(Assets.getPath(ndll), name, args);

		if (func == null) {
			Logs.error('Method ${name} in ndll ${ndll} with ${args} args was not found.');
			return noop;
		}
		return func;
		#else
		Logs.warn('NDLLs are not supported on this platform.');
		return noop;
		#end
	}

	@:dox(hide) @:noCompletion static function noop() {}
}
