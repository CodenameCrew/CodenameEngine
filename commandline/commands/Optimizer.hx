package commands;

import sys.io.File;

class Optimizer {
	public static function main(args:Array<String>) {
		final args = ArgParser.parse(args);
		final saveOld = !args.existsOption("no-old");

		if(args.length == 0) {
			Sys.println(Main.curCommand.dDoc);
			return;
		}

		final filename = args.get(0);

		final data = File.getContent(filename);
		var json = null;
		try {
			json = haxe.Json.parse(data);
		} catch(e:Dynamic) {
			Sys.println("Error parsing JSON file.");
			Sys.println(e);
			return;
		}

		if(saveOld)
			File.saveContent(filename + ".old", data);
		File.saveContent(filename, haxe.Json.stringify(json));
	}
}