package funkin.backend.system.interfaces;

import funkin.backend.scripting.ScriptPack;

interface IStateScript {
	public var scriptVariables:Map<String, Dynamic>;
	public var stateScripts:ScriptPack;
}