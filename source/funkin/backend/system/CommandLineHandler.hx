package funkin.backend.system;

#if sys
import sys.FileSystem;
final class CommandLineHandler {
	@:noPrivateAccess
	private static function __showHelpText():Void {
		// Just put it all in a string array =)

		final STRINGS:Array<String> = [
			"--- Codename Engine Command Line Help ---",
			"",
			"-help                | Show this help",
			#if MOD_SUPPORT
			"-mod [mod name]      | Load a specific mod",
			"-modfolder [path]    | Sets the mod folder path",
			"-addonsfolder [path] | Sets the addons folder path",
			#end
			"-nocolor             | Disables colors in the terminal",
			"-nogpubitmap         | Forces GPU only bitmaps off",
			"-nocwdfix            | Turns off automatic working directory fix"
		];

		for (s in STRINGS) {
			Sys.println(s);
		}
	}

	public static function parseCommandLine(cmd:Array<String>) {
		var i:Int = 0;
		while(i < cmd.length) {
			switch(cmd[i]) {
				case null:
					break;
				case "-h" | "-help" | "help":
					__showHelpText();
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