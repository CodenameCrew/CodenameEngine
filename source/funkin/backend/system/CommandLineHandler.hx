package funkin.backend.system;

#if sys
import sys.FileSystem;
final class CommandLineHandler {
	public static function parseCommandLine(cmd:Array<String>) {
		var i:Int = 0;
		while(i < cmd.length) {
			switch(cmd[i]) {
				case null:
					break;
				case "-h" | "-help" | "help":
					Sys.println("-- Codename Engine Command Line help --");
					Sys.println("-help                | Show this help");
					#if MOD_SUPPORT
					Sys.println("-mod [mod name]      | Load a specific mod");
					Sys.println("-modfolder [path]    | Sets the mod folder path");
					Sys.println("-addonsfolder [path] | Sets the addons folder path");
					#end
					Sys.println("-nocolor             | Disables colors in the terminal");
					Sys.println("-nogpubitmap         | Forces GPU only bitmaps off");
					Sys.println("-nocwdfix            | Turns off automatic working directory fix");
					Sys.exit(0);
				#if MOD_SUPPORT
				case "-m" | "-mod" | "-currentmod":
					i++;
					var arg = cmd[i];
					if (arg == null) {
						Sys.println("[ERROR] You need to specify the mod name");
						Sys.exit(1);
					} else {
						Main.modToLoad = arg.trim();
					}
				case "-modfolder":
					i++;
					var arg = cmd[i];
					if (arg == null) {
						Sys.println("[ERROR] You need to specify the mod folder path");
						Sys.exit(1);
					} else if (FileSystem.exists(arg)) {
						funkin.backend.assets.ModsFolder.modsPath = arg;
					} else {
						Sys.println('[ERROR] Mod folder at "${arg}" does not exist.');
						Sys.exit(1);
					}
				case "-addonsfolder":
					i++;
					var arg = cmd[i];
					if (arg == null) {
						Sys.println("[ERROR] You need to specify the addon folder path");
						Sys.exit(1);
					} else if (FileSystem.exists(arg)) {
						funkin.backend.assets.ModsFolder.addonsPath = arg;
					} else {
						Sys.println('[ERROR] Addons folder at "${arg}" does not exist.');
						Sys.exit(1);
					}
				#end
				case "-nocolor":
					Main.noTerminalColor = true;
				case "-nogpubitmap":
					Main.forceGPUOnlyBitmapsOff = true;
				case "-nocwdfix":
					Main.noCwdFix = true;
				case "-livereload":
					// do nothing
				case "-v" | "-verbose" | "--verbose":
					Main.verbose = true;
				default:
					Sys.println("Unknown command");
			}
			i++;
		}
	}
}
#end