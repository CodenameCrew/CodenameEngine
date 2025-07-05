package funkin.backend.system.macros;

#if macro
@:dox(hide)
class NewHaxeWarning {
	public static function warn() {
		/*#if (haxe >= "4.3.0")
			Sys.println("====================");
			Sys.println("[ WARNING ]");
			Sys.println("Compiling with Haxe 4.3.0 isnt fully recommended yet, but it does work.");
			Sys.println("We recommend building the project using Haxe 4.2.5.");
			Sys.println("You can download it here -> https://haxe.org/download/version/4.2.5/");
			Sys.println("====================");
		#end*/
	}
}
#end