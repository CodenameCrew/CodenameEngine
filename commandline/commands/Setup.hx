package commands;

import haxe.xml.Access;
import haxe.Json;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class Setup {
	private static function recursiveDelete(path:String) {
		for(file in FileSystem.readDirectory(path)) {
			var p = '$path/$file';
			if(FileSystem.isDirectory(p))
				recursiveDelete(p);
			else
				FileSystem.deleteFile(p);
		}
		FileSystem.deleteDirectory(path);
	}

	public static function addMissingFolders(path:String):String {
		#if sys
		var folders:Array<String> = path.split("/");
		var currentPath:String = "";

		for (folder in folders) {
			currentPath += folder + "/";
			if (!FileSystem.exists(currentPath))
				FileSystem.createDirectory(currentPath);
		}
		#end
		return path;
	}

	public static function main(args:Array<String>) {
		var args = ArgParser.parse(args, [
			"s" => "silent-progress",
			"S" => "silent-progress",
			"silent" => "silent-progress",
			"f" => "fast",
			"F" => "fast"
		]);
		var CHECK_VSTUDIO = !args.existsOption("no-vscheck");
		var REINSTALL_ALL = args.existsOption("reinstall");
		var SILENT = args.existsOption("silent-progress");
		var FAST = args.existsOption("fast");
		// TODO: add only install missing libs

		// to prevent messing with currently installed libs
		if (!FileSystem.exists('.haxelib'))
			FileSystem.createDirectory('.haxelib');

		if (REINSTALL_ALL) {
			recursiveDelete('.haxelib');
			FileSystem.createDirectory('.haxelib');
		}

		var libFile = "./building/libs.xml";
		if(args.existsOption("lib")) {
			libFile = args.getOption("lib");
			if(libFile == null) {
				Sys.println('Please specify a file with the --lib option as --lib=path/to/libs.xml');
				return;
			}
		}
		if(!FileSystem.exists(libFile)) {
			Sys.println('File $libFile does not exist.');
			return;
		}

		final events:Array<Event> = [];
		final libsXML:Access = new Access(Xml.parse(File.getContent(libFile)).firstElement());

		function handleLib(libNode:Access) {
			switch(libNode.name) {
				case "lib" | "git" | "custom":
					final lib:Library = {
						name: libNode.att.name,
						type: libNode.name,
						skipDeps: libNode.has.skipDeps ? libNode.att.skipDeps == "true" : false,
					};
					if (libNode.has.global) lib.global = libNode.att.global;
					switch (lib.type) {
						case "lib":
							if (libNode.has.version) lib.version = libNode.att.version;
						case "git":
							if (libNode.has.url) lib.url = libNode.att.url;
							if (libNode.has.ref) lib.ref = libNode.att.ref;
					}
					events.push({
						type: INSTALL,
						data: lib
					});
				case "cmd":
					events.push({
						type: CMD,
						data: {
							inLib: libNode.has.inLib ? libNode.att.inLib : null,
							dir: libNode.has.dir ? libNode.att.dir : null,
							lines: {
								if(Lambda.count(libNode.nodes.line) > 0)
								[
									for(line in libNode.nodes.line)
										line.innerData
								];
								else
								[
									libNode.has.cmd ? libNode.att.cmd : "echo 'No command specified'"
								];
							}
						}
					});
				case "print":
					events.push({
						type: PRINT,
						data: {
							text: libNode.innerData,
							pretty: libNode.has.pretty && libNode.att.pretty == "true"
						}
					});
				default:
					Sys.println('Unknown library type ${libNode.name}');
			}
		}

		final platform = switch(Sys.systemName()) {
			case "Windows": "windows";
			case "Mac": "mac";
			case "Linux": "linux";
			case def: def.toLowerCase();
		}

		final defines = args.args.copy();
		defines.push(platform);
		defines.push("true");
		if(args.args.length == 0) defines.push("all");

		function parse(libNode:Access) {
			if(libNode.name == "if" || libNode.name == "unless") {
				var cond = libNode.att.cond;
				if(Utils.evaluateArgsCondition(cond, defines) != (libNode.name == "if")) {
					return;
				}

				for(child in libNode.elements) {
					parse(child);
				}
			} else {
				handleLib(libNode);
			}
		}

		final shouldCheckHaxeVersion = !libsXML.has.checkVersion || Utils.evaluateArgsCondition(libsXML.att.checkVersion, defines);

		for (libNode in libsXML.elements) {
			parse(libNode);
		}

		var commandSuffix = " --always";
		if (SILENT) commandSuffix += " --quiet";

		function command(cmd:String) {
			Sys.println(cmd); // TODO: ansi color
			Sys.command(cmd);
		}

		for(event in events) {
			switch(event.type) {
				case INSTALL:
					var lib:Library = event.data;
					var globalSuffix:Null<String> = lib.global == "true" ? " --global" : "";
					var skipDeps = lib.skipDeps ? " --skip-dependencies" : "";
					var commandPrefix = commandSuffix + globalSuffix + skipDeps;// + " --no-timeout";
					switch(lib.type) {
						case "lib":
							prettyPrint((lib.global == "true" ? "Globally installing" : "Locally installing") + ' "${lib.name}"...');
							command('haxelib$commandPrefix install ${lib.name} ${lib.version != null ? " " + lib.version : " "}');
						case "git":
							prettyPrint((lib.global == "true" ? "Globally installing" : "Locally installing") + ' "${lib.name}" from git url "${lib.url}"');
							if(FAST) {
								var oldcwd = Sys.getCwd();
								var newCwd = oldcwd + "/.haxelib/" + lib.name + "/";
								var newCwdGit = newCwd + "git/";
								addMissingFolders(newCwdGit);
								Sys.setCwd(newCwd);
								File.saveContent(".current", "git");
								if(FileSystem.exists(newCwdGit)) recursiveDelete(newCwdGit);
								command('git clone ${lib.url} ${lib.name} --depth 1${lib.ref != null ? " --branch " + lib.ref : ""} --progress');
								FileSystem.rename(newCwd + lib.name, newCwdGit);
								Sys.setCwd(oldcwd);
							} else {
								command('haxelib$commandPrefix git ${lib.name} ${lib.url}${lib.ref != null ? ' ${lib.ref}' : ''}');
							}
						case "custom":
							command('haxelib$commandPrefix dev ${lib.name} "./libraries/${lib.name}"');
						default:
							prettyPrint('Cannot resolve library of type "${lib.type}"');
					}
				case CMD:
					var cmd:CmdData = event.data;
					var lib = cmd.inLib;
					var dir = "";
					if(cmd.dir != null) {
						dir = "/" + cmd.dir;
					}
					var oldCwd = Sys.getCwd();
					if(lib != null) {
						final libPrefix = '.haxelib/$lib';
						if(FileSystem.exists(libPrefix)) {
							if(FileSystem.exists(libPrefix + '/.dev')) { // haxelib dev
								final devPath = File.getContent(libPrefix + '/.dev');
								if(!FileSystem.exists(devPath)) {
									Sys.println('Cannot find dev path $devPath for $lib');
									Sys.setCwd(oldCwd);
									continue;
								}
								Sys.setCwd(devPath + dir);
							} else if(FileSystem.exists(libPrefix + '/.current')) {
								final version = StringTools.replace(File.getContent(libPrefix + '/.current'), ".", ",");
								if(!FileSystem.exists(libPrefix + '/$version')) {
									Sys.println('Cannot find version $version of $lib');
									Sys.setCwd(oldCwd);
									continue;
								}
								Sys.setCwd(libPrefix + '/$version' + dir);
							} else {
								Sys.println('Cannot find .dev or .current file in $libPrefix');
								Sys.setCwd(oldCwd);
								continue;
							}
						}
					}
					for(line in cmd.lines) {
						final line = StringTools.replace(line, "$PLATFORM", platform);
						//Sys.println(line);
						command(line);
					}
					Sys.setCwd(oldCwd);
				case PRINT:
					final data:PrintData = event.data;
					if(data.pretty)
						prettyPrint(data.text);
					else
						Sys.println(data.text);
			}
		}

		if(shouldCheckHaxeVersion) {
			final proc = new Process('haxe --version');
			proc.exitCode(true);
			final haxeVer = proc.stdout.readLine();

			// check for outdated haxe
			final curHaxeVer = [for(v in haxeVer.split(".")) Std.parseInt(v)];
			final minumumVersion = [4, 3, 7];
			for(i in 0...minumumVersion.length) {
				if (curHaxeVer[i] > minumumVersion[i]) break;
				if (curHaxeVer[i] < minumumVersion[i]) {
					prettyPrint([
						"!! WARNING !!",
						"Your current Haxe version is outdated.",
						'You\'re using ${haxeVer}, whilst the required version is 4.3.7 or newer.',
						'The engine may not compile with your current version of Haxe.',
						'We recommend upgrading to 4.3.7 or newer'
					].join("\n"));
					break;
				}
			}
		}

		// vswhere.exe is used to find any visual studio related installations on the system, including full visual studio ide installations, visual studio build tools installations, and other related components  - Nex
		if (CHECK_VSTUDIO && Compiler.getBuildTarget().toLowerCase() == "windows" && new Process('"C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -requires Microsoft.VisualStudio.Component.Windows10SDK.19041 -property installationPath').exitCode(true) != 0) {
			prettyPrint("Installing Microsoft Visual Studio Community (Dependency)");

			// thanks to @crowplexus for these two lines!  - Nex
			command("curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe");
			command("vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p");
			FileSystem.deleteFile("vs_Community.exe");

			prettyPrint("Because of this component, if you want to compile, you need to restart the device.");
			Sys.print("Do you wish to do it now [y/n]? ");
			if(Sys.stdin().readLine().toLowerCase() == "y") command("shutdown /r /t 0 /f");
		}
	}

	public static function prettyPrint(text:String) {
		final lines = text.split("\n");
		var length = -1;
		for(line in lines)
			if(line.length > length)
				length = line.length;
		var header = "══════";
		for(i in 0...length)
			header += "═";
		Sys.println("");
		Sys.println('╔$header╗');
		for(line in lines) {
			Sys.println('║   ${centerText(line, length)}   ║');
		}
		Sys.println('╚$header╝');
	}


	public static function centerText(text:String, width:Int):String {
		final centerOffset = (width - text.length) / 2;
		final left = repeat(' ', Math.floor(centerOffset));
		final right = repeat(' ', Math.ceil(centerOffset));
		return left + text + right;
	}

	public static inline function repeat(ch:String, amt:Int) {
		var str = "";
		for(i in 0...amt)
			str += ch;
		return str;
	}
}

typedef Library = {
	var name:String;
	var type:String;
	var skipDeps:Bool;
	var ?global:String;
	var ?recursive:String;
	var ?version:String;
	var ?ref:String;
	var ?url:String;
}

typedef Event = {
	var type:EventType;
	var data:Dynamic;
}

typedef CmdData = {
	var inLib:String;
	var dir:String;
	var lines:Array<String>;
}

typedef PrintData = {
	var text:String;
	var ?pretty:Bool;
}

enum abstract EventType(Int) {
	var INSTALL = 0;
	var CMD = 1;
	var PRINT = 2;
}