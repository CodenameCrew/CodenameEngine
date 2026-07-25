package funkin.backend.scripting;

import haxe.io.Path;

#if HARDCODED_SCRIPTS
@:rtti
@:build(funkin.backend.system.macros.HardcodedScriptRegistryMacro.build())
class HardcodedScriptRegistry {

	private static var data:Map<String, String> = null;
	
	public static function getRegisteredScripts():Map<String, String> {
		if (data == null) {
			data = [];

			var rtti = haxe.rtti.Rtti.getRtti(HardcodedScriptRegistry);
			var registeredScripts:Array<String> = [];
			var registeredClasses:Array<String> = [];
			for (metadata in rtti.meta) {
				if (metadata.name == "registeredScripts") {
					registeredScripts = metadata.params;
				} else if (metadata.name == "registeredClasses") {
					registeredClasses = metadata.params;
				}
			}
			for (i in 0...registeredScripts.length) {
				var scriptPath = registeredScripts[i].replace("\"", "").trim();
				var classPath = registeredClasses[i].replace("\"", "").trim();
				if (scriptPath.endsWith(".hx")) scriptPath = Path.withoutExtension(scriptPath);
				data.set(scriptPath, classPath);
			}
		}
		return data;	
	}

	public static function getFolderScripts(path:String):Array<String> {
		var registeredScripts = getRegisteredScripts();
		var scripts:Array<String> = [];
		path = Path.addTrailingSlash(path);
		for (key => val in registeredScripts) {
			if (Path.addTrailingSlash(Path.directory(key)) == path) scripts.push(key);
		}
		return scripts;
	}
}
#end


