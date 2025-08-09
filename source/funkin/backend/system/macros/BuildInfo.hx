package funkin.backend.system.macros;

using StringTools;

#if macro
class BuildInfo {
	public static function printBuildInfo() {
		if(haxe.macro.Context.defined("display") || haxe.macro.Context.defined("display-details")) return;
		var haxeVersion = haxe.macro.Context.definedValue("haxe").trim();
		var sleepChangeVersion = false;

		Sys.println('[ BUILD INFO ]');
		Sys.println('Haxe Version: ${haxeVersion}');
		try {
			var lastBuiltWith:Null<String> = null;
			var compiling = #if final "release" #elseif debug "debug" #else "release" #end;
			var target = #if hl "hl"
				#elseif html5 "html5"
				#elseif ios "ios"
				#elseif android "android"
				#elseif windows "windows"
				#elseif (mac || macos) "macos"
				#elseif linux "linux"
				#else ""
				#end;
			if(target == "") throw "Unknown target";
			var exportPath = Sys.getCwd() + "/export/" + compiling + "/" + target + "/";
			exportPath += "obj/Options.txt";

			var options = sys.io.File.getContent(exportPath);
			for(option in options.split("\n")) {
				if(option.startsWith("haxe=")) {
					lastBuiltWith = option.substr(5).trim();
					break;
				}
			}

			if(lastBuiltWith != null && lastBuiltWith.length > 0 && lastBuiltWith != haxeVersion) {
				Sys.println('Last Built With Haxe: ${lastBuiltWith} [!!!! MAKE SURE IF YOU SWITCHED VERSIONS YOU DELETE EXPORT FOLDERS !!!!]');
				sleepChangeVersion = true;
			}
		} catch(e) {}
		var targetPlatform = #if html5 "Web (HTML5)"
			#elseif ios "iOS"
			#elseif android "Android"
			#elseif windows "Windows"
			#elseif (mac || macos) "Mac"
			#elseif linux "Linux"
			#else "Unknown"
			#end;

		if(haxe.macro.Context.defined("hl")) {
			targetPlatform = "Hashlink (" + targetPlatform + ")";
		}
		Sys.println('Target Platform: ' + targetPlatform);
		Sys.println('Build Date: ${Date.now().toString()}');
		Sys.println('');

		if(sleepChangeVersion) {
			Sys.println('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
			Sys.println('!!!! MAKE SURE IF YOU SWITCHED VERSIONS YOU DELETE EXPORT FOLDERS !!!!');
			Sys.println('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
			Sys.println('');
			Sys.sleep(5);
		}
	}
}
#end