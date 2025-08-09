package funkin.backend.system.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class DefinesMacro {
	/**
	 * Returns the defined values
	 */
	public static var defines(get, never):Map<String, Dynamic>;

	// GETTERS
	#if REGION
	private static inline function get_defines()
		return __getDefines();
	#end

	// INTERNAL MACROS
	#if REGION
	private static macro function __getDefines() {
		#if display
		return macro $v{[]};
		#else
		return macro $v{Context.getDefines()};
		#end
	}
	#end
}