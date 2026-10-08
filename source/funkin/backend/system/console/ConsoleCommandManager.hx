package funkin.backend.system.console;
import funkin.backend.system.Logs;
import funkin.backend.system.console.ConsoleCommand;

class ConsoleCommandManager {
	
	public static var commands:Map<String, BaseCommand> = [];
	public static var commandsStringList:Array<String> = [];

	public static function registerCommand(cmd:BaseCommand) {
		if (commands.exists(cmd._nameLower)) {
			Logs.warn("Trying to register console command that already exists! (" + cmd.name + ")");
			return;
		}
		cmd.onRegister();
		commands.set(cmd._nameLower, cmd);
		commandsStringList.push(cmd._nameLower);
	}

	public static function unregisterCommand(cmd:BaseCommand) {
		if (!commands.exists(cmd._nameLower)) {
			Logs.warn("Trying to unregister console command that isn't registered! (" + cmd.name + ")");
			return;
		}
		cmd.onUnregister();
		commandsStringList.remove(cmd._nameLower);
		commands.remove(cmd._nameLower);
	}

	public static function getCommand(name:String) {
		if (commands.exists(name.toLowerCase())) {
			return commands.get(name.toLowerCase());
		}
		return null;
	}

	public static function tryExecute(str:String) {
		var strLower = str.toLowerCase();
		var targetCmd = strLower;
		var rawArgs = "";
		if (strLower.indexOf(" ") != -1) {
			targetCmd = strLower.substring(0, strLower.indexOf(" "));
			rawArgs = str.substring(str.indexOf(" ")+1, str.length);
		}
		
		if (ConsoleCommandManager.commands.exists(targetCmd)) {
			Logs.infos("Executing command: " + str, LIGHTGRAY, "Console");
			ConsoleCommandManager.commands.get(targetCmd).execute(rawArgs);
			return true;
		}
		return false;
	}

	public static function unregisterModdedCommands() {
		var commandsToRemove:Array<BaseCommand> = [];
		for (name => cmd in commands) {
			if (cmd is ModFuncCommand) {
				unregisterCommand(cmd);
			}
		}
	}
}

