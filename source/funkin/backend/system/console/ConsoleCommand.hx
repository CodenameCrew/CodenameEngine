package funkin.backend.system.console;
import funkin.backend.system.console.ConsoleCommandManager;

class BaseCommand {
	public var name:String;
	public var argsDesc:String;
	public var desc:String;

	@:allow(funkin.backend.system.console.ConsoleCommandManager)
	private var _nameLower:String;

	public function new(name:String, argsDesc:String, desc:String, autoRegister:Bool = true) {
		this.name = name;
		this.argsDesc = argsDesc;
		this.desc = desc;
		_nameLower = name.toLowerCase();
		if (autoRegister) ConsoleCommandManager.registerCommand(this);
	}
	public function onRegister() {};
	public function onUnregister() {};
	public function execute(raw:String) {};

	public static function parseArgs(raw:String) {
		var args:Array<String> = [];
		if (raw == "") return args;

		var i:Int = 0;
		var curStr = "";
		var parseState = 0;
		while(true) {
			var char = raw.charAt(i);
			if (parseState == 0 && char == " ") {
				if (curStr != "") args.push(curStr);
				curStr = "";
			} else if (parseState == 0 && char == "\"") {
				parseState = 1;
			} else if (parseState == 1 && char == "\"") {
				parseState = 0;
			} else if (parseState == 0 && char == "'") {
				parseState = 2;
			} else if (parseState == 2 && char == "'") {
				parseState = 0;
			} else {
				curStr += char;
			}
			
			i++;
			if (i > raw.length-1) {
				if (curStr != "") args.push(curStr);
				break;
			}
		}
		return args;
	}
}

class FuncCommand extends BaseCommand {
	public var func:Array<String>->Void;
	override public function new (name:String, argsDesc:String, desc:String, func:Array<String>->Void, autoRegister:Bool = true) {
		super(name, argsDesc, desc, autoRegister);
		this.func = func;
	}
	override public function execute(raw:String) {
		func(BaseCommand.parseArgs(raw));
	}
}

//auto removed on mod switch, intended for mod global scripts
class ModFuncCommand extends FuncCommand {
	override public function onRegister() {
		Logs.infos("Registered modded command: " + name, LIGHTGRAY, "Console");
	}
	override public function onUnregister() {
		Logs.infos("Unregistered modded command: " + name, LIGHTGRAY, "Console");
	}
}
