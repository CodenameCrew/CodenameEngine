package funkin.backend.system.console;

#if IMGUI_ENABLED
import lime.tools.imgui.ImGui;
import lime.tools.imgui.ImGuiIO;
import lime.tools.imgui.ImGuiStyle;
import lime.tools.imgui.ImGuiHandler;
import lime.tools.imgui.ImGuiFlags;
import lime.tools.imgui.ImGuiTypes;
import lime.tools.imgui.ImGuiPtr;
import lime.tools.imgui.ImGuiInputTextCallbackData;
#end
import openfl.Lib;
import funkin.backend.system.Logs;
import funkin.backend.utils.NativeAPI.ConsoleColor;

using funkin.backend.utils.ImGuiUtil;

typedef ConsoleSearchData = {
	var name:String;
	var desc:String;
	var ?argsDesc:String;
	var searchIndex:Int;
	var isCommand:Bool;
	var ?autoComplete:String;
}

typedef ConsoleLogData = {
	var log:Array<LogText>;
	var times:Int;
}

class ConsoleUI {

	static final CONSOLE_BG_COLOR = 0xFF380051;
	static final SEARCH_HIGHLIGHT_COLOR = 0xFF00FF00;
	static final SEARCH_SELECTED_COLOR = 0xFFE2D302;
	static final SEARCH_DESC_COLOR = 0xFF636363;
	static final SEARCH_ARGS_COLOR = 0xFF58804F;

	static final CONSOLE_MAX_OUPUT = 100;
	static final SEARCH_MAX_OUTPUT = 25;

	public static var instance(default, null):ConsoleUI;

	private var active:Bool = false;
	#if IMGUI_ENABLED
	private var style:ImGuiStyle;
	#end
	private var consoleHscript:ConsoleHscript;
	private var consoleInspector:ConsoleInspector;

	var commandSearch:Array<ConsoleSearchData> = [];
	var prevCommands:Array<String> = [];
	var forceFocusTextInput = false;
	var cyclingCommands = false;
	var cyclingPrevCommands = false;
	var cycleIndex = 0;

	#if IMGUI_ENABLED
	var consoleInputString:ImGuiStringPtr = new ImGuiStringPtr("");
	var consoleInputTextCallback:ImGuiInputTextCallback;
	#end
	var consoleOutput:Array<ConsoleLogData> = [];
	var consoleOutputCurrentIndex:Int = 0;
	var wrapConsoleOutput = false;
	var autoScrollNextFrame = false;


	#if IMGUI_ENABLED
	var settingsOpen:ImGuiBoolPtr = new ImGuiBoolPtr(false);

	var timeFilter:ImGuiBoolPtr = new ImGuiBoolPtr(true);
	var typeFilter:ImGuiBoolPtr = new ImGuiBoolPtr(true);

	var infoFilter:ImGuiBoolPtr = new ImGuiBoolPtr(true);
	var warningFilter:ImGuiBoolPtr = new ImGuiBoolPtr(true);
	var errorFilter:ImGuiBoolPtr = new ImGuiBoolPtr(true);
	var traceFilter:ImGuiBoolPtr = new ImGuiBoolPtr(true);
	var verboseFilter:ImGuiBoolPtr = new ImGuiBoolPtr(true);

	var commandsFilter:ImGuiBoolPtr = new ImGuiBoolPtr(true);
	var hscriptClassFilter:ImGuiBoolPtr = new ImGuiBoolPtr(true);
	var hscriptFunctionFilter:ImGuiBoolPtr = new ImGuiBoolPtr(true);
	var hscriptBasicTypesFilter:ImGuiBoolPtr = new ImGuiBoolPtr(true);
	var hscriptObjectsFilter:ImGuiBoolPtr = new ImGuiBoolPtr(true);
	var hscriptScriptsFilter:ImGuiBoolPtr = new ImGuiBoolPtr(true);

	var countDuplicatedOutput:ImGuiBoolPtr = new ImGuiBoolPtr(false);

	function saveSettings() {
		Options.consoleTimeFilter = timeFilter.value;
		Options.consoleTypeFilter = typeFilter.value;
		Options.consoleInfoFilter = infoFilter.value;
		Options.consoleWarningFilter = warningFilter.value;
		Options.consoleErrorFilter = errorFilter.value;
		Options.consoleTraceFilter = traceFilter.value;
		Options.consoleVerboseFilter = verboseFilter.value;
		Options.consoleCommandsFilter = commandsFilter.value;
		Options.consoleClassFilter = hscriptClassFilter.value;
		Options.consoleFunctionFilter = hscriptFunctionFilter.value;
		Options.consoleBasicTypesFilter = hscriptBasicTypesFilter.value;
		Options.consoleObjectsFilter = hscriptObjectsFilter.value;
		Options.consoleScriptsFilter = hscriptScriptsFilter.value;
		Options.consoleCountDuplicatedOutput = countDuplicatedOutput.value;
	}
	function loadSettings() {
		//console is created before options are loaded
		timeFilter.value = Options.consoleTimeFilter;
		typeFilter.value = Options.consoleTypeFilter;
		infoFilter.value = Options.consoleInfoFilter;
		warningFilter.value = Options.consoleWarningFilter;
		errorFilter.value = Options.consoleErrorFilter;
		traceFilter.value = Options.consoleTraceFilter;
		verboseFilter.value = Options.consoleVerboseFilter;
		commandsFilter.value = Options.consoleCommandsFilter;
		hscriptClassFilter.value = Options.consoleClassFilter;
		hscriptFunctionFilter.value = Options.consoleFunctionFilter;
		hscriptBasicTypesFilter.value = Options.consoleBasicTypesFilter;
		hscriptObjectsFilter.value = Options.consoleObjectsFilter;
		hscriptScriptsFilter.value = Options.consoleScriptsFilter;
		countDuplicatedOutput.value = false; //Options.consoleCountDuplicatedOutput; //temp disable
	}
	#end

	public static function init() {
		ConsoleUI.instance = new ConsoleUI();
		#if IMGUI_ENABLED
		ImGuiHandler.instance.addCallback(ConsoleUI.instance.displayUI);
		#end
	}

	public function new() {
		#if IMGUI_ENABLED
		style = ImGui.getStyle();
		consoleInputTextCallback = new ImGuiInputTextCallback(onInputTextCallback);
		#end

		for (i in 0...CONSOLE_MAX_OUPUT) {
			consoleOutput.push({log: [], times: 0});
		}
	};

	private function addToConsole(text:Array<LogText>) {
		#if IMGUI_ENABLED
		//check for repeats
		var min = consoleOutputCurrentIndex-10;
		if (min < 0) min = 0;
		if (countDuplicatedOutput.value) //currently disabled
		{
			for (i in min...consoleOutputCurrentIndex) {
				var matching = true;
				if (text.length > 4 && text.length == consoleOutput[i].log.length) {
					for (textIndex in 3...consoleOutput[i].log.length) {
						if (text[textIndex].text != consoleOutput[i].log[textIndex].text) matching = false;
					}
				} else {
					matching = false;
				}
				if (matching) {
					consoleOutput[i].log = text;
					consoleOutput[i].times++;
					if (i != consoleOutputCurrentIndex-1) { //TODO: this should push to bottom instead of swapping since it doesnt always work
						var temp = consoleOutput[consoleOutputCurrentIndex-1];
						consoleOutput[consoleOutputCurrentIndex-1] = consoleOutput[i];
						consoleOutput[i] = temp;
					}
					return;
				}
			}
		}
		addToConsoleOutput(text);
		autoScrollNextFrame = true;
		#end
	}

	private inline function addToConsoleOutput(text:Array<LogText>) {
		consoleOutput[consoleOutputCurrentIndex] = {log: text, times: 1};
		consoleOutputCurrentIndex++;

		if (consoleOutputCurrentIndex >= CONSOLE_MAX_OUPUT) { //wrap around like a ring buffer
			consoleOutputCurrentIndex = 0;
			wrapConsoleOutput = true;
		}
	}

	public function toggleUI() {
		#if IMGUI_ENABLED
		active = !active;

		if (active) {
			FlxG.autoPause = false;
			FlxG.game.focusLostFramerate = 60;
			loadSettings();
			forceFocusTextInput = true;
			if (consoleHscript == null) consoleHscript = new ConsoleHscript();
			if (consoleInspector == null) consoleInspector = new ConsoleInspector(consoleHscript);
		} else {
			FlxG.autoPause = Options.autoPause;
			ImGui.setKeyboardFocusHere(0);
		}
		#end
	}

	public function displayUI() {
		#if IMGUI_ENABLED
		if (!Options.devMode) {
			if (active) toggleUI();
			return;
		}
		var toggled:Bool = false;
		for (key in Options.SOLO_DEV_CONSOLE) {
			if (ImGui.isKeyPressed(key.toImGuiKey(), false)) toggled = true;
		}
		if (toggled) toggleUI();
		if (!active) return;

		//consoleInspector.displayUI();

		if (settingsOpen.value) {
			ImGui.setNextWindowPos(Lib.application.window.x + Lib.application.window.width - 240, Lib.application.window.y, ImGuiCond.FirstUseEver);
			ImGui.setNextWindowSize(240, 405, ImGuiCond.FirstUseEver);
			if (ImGui.begin("Console Settings", settingsOpen, 0)) {
				//ImGui.checkbox("Count duplicated output##Console Settings", countDuplicatedOutput); ImGui.setItemTooltip("Toggles if duplicated logs add a counter instead of displaying again");
				ImGui.separatorText("Log Filter:");
				ImGui.checkbox("Time##Console Settings", timeFilter); ImGui.setItemTooltip("Toggles if timestamp shows in each log");
				ImGui.checkbox("Type##Console Settings", typeFilter); ImGui.setItemTooltip("Toggles if the type shows in each log");
				ImGui.separator();
				ImGui.checkbox("Info##Console Settings", infoFilter); ImGui.setItemTooltip("Toggles if info logs show");
				ImGui.checkbox("Warning##Console Settings", warningFilter); ImGui.setItemTooltip("Toggles if warning logs show");
				ImGui.checkbox("Error##Console Settings", errorFilter); ImGui.setItemTooltip("Toggles if error logs show");
				ImGui.checkbox("Trace##Console Settings", traceFilter); ImGui.setItemTooltip("Toggles if trace logs show");
				ImGui.checkbox("Verbose##Console Settings", verboseFilter); ImGui.setItemTooltip("Toggles if verbose logs show");
				ImGui.separatorText("Search Filter:");
				ImGui.checkbox("Commands##Console Settings", commandsFilter); ImGui.setItemTooltip("Toggles if commands show in the autofill");
				ImGui.checkbox("Classes##Console Settings", hscriptClassFilter); ImGui.setItemTooltip("Toggles if classes show in the autofill");
				ImGui.checkbox("Functions##Console Settings", hscriptFunctionFilter); ImGui.setItemTooltip("Toggles if functions show in the autofill");
				ImGui.checkbox("Basic Types##Console Settings", hscriptBasicTypesFilter); ImGui.setItemTooltip("Toggles if basic types (Int, Float, String) show in the autofill");
				ImGui.checkbox("Objects##Console Settings", hscriptObjectsFilter); ImGui.setItemTooltip("Toggles if objects show in the autofill");
				ImGui.checkbox("Script Variables##Console Settings", hscriptScriptsFilter); ImGui.setItemTooltip("Toggles if script variables show in the autofill");
			}
			ImGui.end();
			saveSettings();
		}

		ImGui.setNextWindowPos(Lib.application.window.x, Lib.application.window.y + (Lib.application.window.height-250), ImGuiCond.FirstUseEver);
		ImGui.setNextWindowSize(Lib.application.window.width, 250, ImGuiCond.FirstUseEver);
		ImGui.setNextWindowDockID(0, ImGuiCond.FirstUseEver);
		if (ImGui.begin("Console", null, ImGuiWindowFlags.NoScrollbar)) {
			displayOutput();
			ImGui.separator();
			displayInput();
		}
		ImGui.end();
		#end
	}

	#if IMGUI_ENABLED
	private function displayOutput() {
		var windowWidth = ImGui.getWindowWidth();
		var windowHeight = ImGui.getWindowHeight();
		var outputHeight = windowHeight - (40 * style.fontScaleDpi); //I think scaling the dpi should be good enough?	//TODO: should probably look at this again
		//var outputHeight = windowHeight - (ImGui.getFrameHeightWithSpacing()*2);
		//if (ImGui.isWindowDocked()) windowHeight -= ImGui.getFrameHeightWithSpacing();
		if (outputHeight > 0) {
			ImGui.pushTextWrapPos();
			if (ImGui.beginChild("Console output", windowWidth, outputHeight)) {
				if (wrapConsoleOutput) {
					outputLog(consoleOutputCurrentIndex, CONSOLE_MAX_OUPUT);
				}
				outputLog(0, consoleOutputCurrentIndex);
			}
			if (autoScrollNextFrame) {
				ImGui.setScrollHereY(1.0);
				autoScrollNextFrame = false;
			}
			ImGui.endChild();
			ImGui.popTextWrapPos();
		}
	}

	private inline function outputLog(start:Int, end:Int) {
		var indicesToIgnore:Array<Int> = [];
		if (!timeFilter.value && !typeFilter.value) indicesToIgnore = [0, 1, 2, 3, 4];
		else if (!timeFilter.value) indicesToIgnore = [1, 2];
		else if (!typeFilter.value) indicesToIgnore = [2, 3];

		var i = start;
		while (i < end) {
			if (consoleOutput[i].log.length > 0) {
				var type = consoleOutput[i].log[0].level;
				switch(type) {
					case INFO:
						if (!infoFilter.value) { i++; continue; }
					case WARNING:
						if (!warningFilter.value) { i++; continue; }
					case ERROR:
						if (!errorFilter.value) { i++; continue; }
					case TRACE:
						if (!traceFilter.value) { i++; continue; }
					case VERBOSE:
						if (!verboseFilter.value) { i++; continue; }
					default:

				}
			}

			for (textIndex => t in consoleOutput[i].log) {
				if (indicesToIgnore.contains(textIndex)) continue;
				if (!timeFilter.value && textIndex == 0) { //fix padding
					ImGui.sameLine(0, 0);
					ImGui.pushStyleColor(ImGuiCol.Text, consoleColorToImColor(t.color));
					ImGui.textUnformatted("[");
					ImGui.popStyleColor();
					continue;
				} else if (!typeFilter.value && textIndex == 4) {
					ImGui.sameLine(0, 0);
					ImGui.pushStyleColor(ImGuiCol.Text, consoleColorToImColor(t.color));
					ImGui.textUnformatted("  ] ");
					ImGui.popStyleColor();
					continue;
				}

				ImGui.sameLine(0, 0);
				ImGui.pushStyleColor(ImGuiCol.Text, consoleColorToImColor(t.color));
				var lines = t.text.split("\n");
				for (i => l in lines) {
					ImGui.textUnformatted(l);
				}
				ImGui.popStyleColor();
			}

			if (countDuplicatedOutput.value && consoleOutput[i].times > 1) {
				ImGui.sameLine(0, 0);
				ImGui.textUnformatted("  ("+consoleOutput[i].times +"x)");
			}

			ImGui.newLine();
			i++;
		}
	}

	private function displayInput() {
		var inputTextCursorPos = ImGui.getCursorScreenPos();
		var currentInputString = consoleInputString.value;
		final flags = ImGuiInputTextFlags.EnterReturnsTrue | ImGuiInputTextFlags.CallbackCompletion | ImGuiInputTextFlags.CallbackHistory | ImGuiInputTextFlags.CallbackEdit | ImGuiInputTextFlags.CallbackAlways;
		if (ImGui.inputText("Input##Console", consoleInputString, flags | (forceFocusTextInput ? ImGuiInputTextFlags.ReadOnly : 0), consoleInputTextCallback)) {
			if (consoleInputString.value != "") {
				tryExecuteCommand(consoleInputString.value);
				if (prevCommands[0] != consoleInputString.value) prevCommands.insert(0, consoleInputString.value);
				consoleInputString.value = "";
				ImGui.setKeyboardFocusHere(-1);
				autoScrollNextFrame = true;
				cyclingCommands = false;
				cyclingPrevCommands = false;
				commandSearch = [];
			}
		}
		if (forceFocusTextInput) {
			ImGui.setKeyboardFocusHere(-1);
			forceFocusTextInput = false;
		}
		
		if (consoleInputString.value != currentInputString) {
			if ((cyclingCommands && getConsoleInputStringForSearch(commandSearch[cycleIndex]) == getCommandSearchAutoComplete(commandSearch[cycleIndex])) || (cyclingPrevCommands && consoleInputString.value == prevCommands[cycleIndex])) {
				
			} else {
				searchCommands(consoleInputString.value, consoleInputString.value.length < currentInputString.length || currentInputString.length == 0);
			}
		}
		ImGui.setScrollHereY(1.0);

		ImGui.sameLine();
		var settingButtonWidth = ImGui.calcTextSize("Settings").x + style.framePaddingX * 2;
		var pos = ImGui.getCursorPos();
		ImGui.setCursorPos(pos.x + ImGui.getContentRegionAvail().x - settingButtonWidth, pos.y);
		if (ImGui.button("Settings")) {
			settingsOpen.value = !settingsOpen.value;
		}

		if (commandSearch.length > 0) {
			var targetIndex = cyclingCommands ? cycleIndex : commandSearch.length;
			var start = targetIndex - (SEARCH_MAX_OUTPUT-1);
			var end = targetIndex+1;
			if (start < 0) start = 0;
			if (end < SEARCH_MAX_OUTPUT) end = SEARCH_MAX_OUTPUT;
			if (end > commandSearch.length) end = commandSearch.length;

			ImGui.pushStyleColor(ImGuiCol.WindowBg, CONSOLE_BG_COLOR);
			ImGui.setNextWindowPos(inputTextCursorPos.x, inputTextCursorPos.y - (ImGui.getTextLineHeightWithSpacing() * (end-start))-12);
			if (ImGui.begin("Command Search window", null, ImGuiWindowFlags.NoDecoration | ImGuiWindowFlags.AlwaysAutoResize | ImGuiWindowFlags.NoInputs | ImGuiWindowFlags.NoFocusOnAppearing)) {
				for (i in start...end) {
					var cmd = commandSearch[i];
					if (!cyclingCommands) {
						var cmdName:String = cmd.name;
						var inputName:String = getConsoleInputStringForSearch(cmd);
						var before:String = cmdName.substring(0, cmd.searchIndex);
						var after:String = cmdName.substring(cmd.searchIndex+inputName.length, cmdName.length);

						if (before != "") {
							if (i == commandSearch.length-1) ImGui.pushStyleColor(ImGuiCol.Text, SEARCH_SELECTED_COLOR);
							ImGui.textUnformatted(before);
							ImGui.sameLine(0, 0);
							if (i == commandSearch.length-1) ImGui.popStyleColor();
						}
						ImGui.pushStyleColor(ImGuiCol.Text, SEARCH_HIGHLIGHT_COLOR);
						ImGui.textUnformatted(cmdName.substring(cmd.searchIndex, cmd.searchIndex+inputName.length));
						ImGui.popStyleColor();
						if (after != "") {
							if (i == commandSearch.length-1) ImGui.pushStyleColor(ImGuiCol.Text, SEARCH_SELECTED_COLOR);
							ImGui.sameLine(0, 0);
							ImGui.textUnformatted(after);
							if (i == commandSearch.length-1) ImGui.popStyleColor();
						}

						if (inputName.length == cmd.name.length && cmd.autoComplete != null) {
							ImGui.sameLine();
							ImGui.textUnformatted("(TAB to Autocomplete)");
						}
					} else {
						if (i == cycleIndex) ImGui.pushStyleColor(ImGuiCol.Text, SEARCH_SELECTED_COLOR);
						ImGui.textUnformatted(cmd.name);
						if (i == cycleIndex) ImGui.popStyleColor();
					}

					if (cmd.argsDesc != null && cmd.argsDesc != "") {
						ImGui.sameLine();
						ImGui.pushStyleColor(ImGuiCol.Text, SEARCH_ARGS_COLOR);
						ImGui.textUnformatted(cmd.argsDesc);
						ImGui.popStyleColor();
					}
					if (cmd.desc != "") {
						ImGui.sameLine();
						ImGui.pushStyleColor(ImGuiCol.Text, SEARCH_DESC_COLOR);
						ImGui.textUnformatted(cmd.desc);
						ImGui.popStyleColor();
					}
				}
			}
			ImGui.popStyleColor();
			ImGui.end();
		}
	}

	var thingsThatMeanTheresANewThing = " +-*/=|();,"; //TODO: name this something better
	var currentCursorPos = 0;
	var currentHscriptVarStart = 0;
	var currentHscriptVarEnd = 0;

	private function searchCommands(str:String, fullSearch:Bool) {
		cyclingCommands = false;
		cyclingPrevCommands = false;
		if (fullSearch) commandSearch = [];
		if (str == "") return;

		//for commands only, allow any case
		var strLower = str.toLowerCase();
		if (strLower.indexOf(" ") != -1) {
			strLower = strLower.substring(0, strLower.indexOf(" "));
		}
		
		//figure out the current hscript variable where the cursor is
		var pos:Int = currentCursorPos;
		if (pos < 0) pos = 0;
		if (pos > str.length-1) pos = str.length-1;
		var begin:Int = 0;
		var end:Int = str.length;
		for (i in 0...thingsThatMeanTheresANewThing.length) {
			var c = thingsThatMeanTheresANewThing.charAt(i);
			var b = str.lastIndexOf(c, pos);
			var e = str.indexOf(c, pos);
			if (b != -1 && b+1 > begin+1) begin = b+1;
			if (e != -1 && e < end) end = e;
		}
		var scriptVarStr = str.substring(begin, end);
		currentHscriptVarStart = begin;
		currentHscriptVarEnd = end;
		

		if (!fullSearch) {	//TODO: something better to restore search when pressing backspace
			var prev = commandSearch;
			commandSearch = [];
			for (cmd in prev) {
				cmd.searchIndex = cmd.isCommand ? cmd.name.toLowerCase().indexOf(strLower) : cmd.name.indexOf(scriptVarStr);
				if (cmd.searchIndex != -1) {
					commandSearch.push(cmd);
				}
			}
		} else {
			if (commandsFilter.value) for (cmdName in ConsoleCommandManager.commandsStringList) {
				var searchIndex = cmdName.indexOf(strLower);
				if (searchIndex != -1) {
					var cmd = ConsoleCommandManager.commands.get(cmdName);
					commandSearch.push({
						name: cmd.name,
						desc: cmd.desc,
						argsDesc: cmd.argsDesc,
						searchIndex: searchIndex,
						isCommand: true
					});
				}
			}
		}

		//root hscript variables/classes
		if (fullSearch || scriptVarStr.length == 1) if (scriptVarStr.indexOf(".") == -1) {
			for (f in consoleHscript.variableFields) {
				if (!hscriptScriptsFilter.value && f.isScriptVar) continue;
				if (f.isStatic) {
					if (!hscriptClassFilter.value) continue;
				} else if (f.type == "Function") {
					if (!hscriptFunctionFilter.value) continue;
				} else if (f.type == "Int" || f.type == "Float" || f.type == "String") {
					if (!hscriptBasicTypesFilter.value) continue;
				} else {
					if (!hscriptObjectsFilter.value) continue;
				}

				var searchIndex = f.name.indexOf(scriptVarStr);
				if (searchIndex != -1) {
					commandSearch.push({
						name: f.name,
						desc: (f.isStatic ? "Class (" + f.type + ")" : f.type) + (f.value != "" ? " (" + f.value + ")" : "") + (f.extraDesc != null ? " (" + f.extraDesc + ")" : ""),
						searchIndex: searchIndex,
						isCommand: false,
						autoComplete: f.autoComplete
					});
				}
			}
		}

		//hscript var fields (after pressing .)
		if (scriptVarStr.charAt(scriptVarStr.length-1) == ".") {
			var fields = consoleHscript.tryGetFields(scriptVarStr.substr(0, -1));
			for (f in fields) {
				if (f.isStatic) {
					if (!hscriptClassFilter.value) continue;
				} else if (f.type == "Function") {
					if (!hscriptFunctionFilter.value) continue;
				} else if (f.type == "Int" || f.type == "Float" || f.type == "String") {
					if (!hscriptBasicTypesFilter.value) continue;
				} else {
					if (!hscriptObjectsFilter.value) continue;
				}
				var full = scriptVarStr + f.name;
				var searchIndex = full.indexOf(scriptVarStr);
				if (searchIndex != -1) {
					commandSearch.push({
						name: full,
						desc: f.type + (f.value != "" ? " (" + f.value + ")" : "") + (f.extraDesc != null ? " (" + f.extraDesc + ")" : ""),
						searchIndex: searchIndex,
						isCommand: false
					});
				}
			}
		}
		commandSearch.sort(function(a, b) {
			if (a.searchIndex < b.searchIndex) return 1;
			else if (a.searchIndex > b.searchIndex) return -1;
			else {
				if (a.name.length < b.name.length) return 1;
				else if (a.name.length > b.name.length) return -1;
				else return 0;
			}
		});
	}

	private inline function getCommandSearchAutoComplete(cmd:ConsoleSearchData) {
		return cmd.autoComplete != null ? cmd.autoComplete : cmd.name;
	}
	private inline function getConsoleInputStringForSearch(cmd:ConsoleSearchData) {
		return cmd.isCommand ? consoleInputString.value : consoleInputString.value.substring(currentHscriptVarStart, currentHscriptVarEnd);
	}

	private function onInputTextCallback(data:ImGuiInputTextCallbackData) {

		if (data.eventFlag == ImGuiInputTextFlags.CallbackHistory) { //when pressing up/down

			var justStartedCycling = false;
			if (commandSearch.length > 0 && !cyclingCommands && !cyclingPrevCommands) {
				cyclingCommands = true;
				cycleIndex = (data.eventKey == ImGuiKey.DownArrow) ? commandSearch.length-1 : 0;
				justStartedCycling = true;
			} else if (commandSearch.length == 0 && !cyclingPrevCommands && !cyclingCommands && consoleInputString.value == "" && prevCommands.length > 0 && data.eventKey == ImGuiKey.UpArrow) {
				cyclingPrevCommands = true;
				cycleIndex = 0;
				justStartedCycling = true;
			}

			if (cyclingCommands) {
				if (data.eventKey == ImGuiKey.UpArrow) {
					cycleIndex--;
					if (cycleIndex < 0) cycleIndex = commandSearch.length-1;
					if (justStartedCycling && commandSearch.length > 1) cycleIndex = commandSearch.length-2; //feels better to go the next one above
				} else {
					cycleIndex++;
					if (cycleIndex > commandSearch.length-1) cycleIndex = 0;
				}

				var autoComplete = getCommandSearchAutoComplete(commandSearch[cycleIndex]);
				if (commandSearch[cycleIndex].isCommand) {
					data.deleteChars(0, data.bufTextLen);
					data.insertChars(0, autoComplete);
					data.setSelection(data.bufTextLen, data.bufTextLen);
					currentHscriptVarEnd = currentHscriptVarStart+autoComplete.length;
				} else {
					data.deleteChars(currentHscriptVarStart, currentHscriptVarEnd-currentHscriptVarStart);
					data.insertChars(currentHscriptVarStart, autoComplete);
					currentHscriptVarEnd = currentHscriptVarStart+autoComplete.length;
					data.setSelection(currentHscriptVarEnd, currentHscriptVarEnd);
				}
			}
			if (cyclingPrevCommands) {
				if (data.eventKey == ImGuiKey.DownArrow) {
					if (!justStartedCycling) cycleIndex--;
					if (cycleIndex < 0) cycleIndex = 0;
				} else {
					if (!justStartedCycling) cycleIndex++;
					if (cycleIndex > prevCommands.length-1) cycleIndex = prevCommands.length-1;
				}
				data.deleteChars(0, data.bufTextLen);
				data.insertChars(0, prevCommands[cycleIndex]);
				data.setSelection(data.bufTextLen, data.bufTextLen);
			}
		}
		else if (data.eventFlag == ImGuiInputTextFlags.CallbackCompletion) { //when pressing tab
			if (commandSearch.length > 0 && consoleInputString.value != getCommandSearchAutoComplete(commandSearch[commandSearch.length-1])) {
				var autoComplete = getCommandSearchAutoComplete(commandSearch[commandSearch.length-1]);
				if (commandSearch[commandSearch.length-1].isCommand) {
					data.deleteChars(0, data.bufTextLen);
					data.insertChars(0, autoComplete);
					data.setSelection(data.bufTextLen, data.bufTextLen);
				} else {
					data.deleteChars(currentHscriptVarStart, currentHscriptVarEnd-currentHscriptVarStart);
					data.insertChars(currentHscriptVarStart, autoComplete);
					currentHscriptVarEnd = currentHscriptVarStart+autoComplete.length;
					data.setSelection(currentHscriptVarEnd, currentHscriptVarEnd);
				}
			}
		}
		else if (data.eventFlag == ImGuiInputTextFlags.CallbackEdit) {
			cyclingCommands = false;
			cyclingPrevCommands = false;
		} else if (data.eventFlag == ImGuiInputTextFlags.CallbackAlways) {
			currentCursorPos = data.cursorPos;
		}
	}
	#end

	private function clearConsole() {
		commandSearch = [];
		consoleOutputCurrentIndex = 0;
		wrapConsoleOutput = false;
	}

	private function tryExecuteCommand(str:String) {
		if (!ConsoleCommandManager.tryExecute(str)) { //run hscript if there was no command
			Logs.infos("Executing hscript: " + str, LIGHTGRAY, "Console");
			Logs.infos(Std.string(consoleHscript.tryExecute(str)), LIGHTGRAY, "Console");
		}
	}

	public static function consoleColorToImColor(color:ConsoleColor) {
		return switch(color) {
			case BLACK:			0xFF000000;
			case DARKBLUE:		0xFF0909C3;
			case DARKGREEN:		0xFF008800;
			case DARKCYAN:		0xFF008888;
			case DARKRED:		0xFF880000;
			case DARKMAGENTA:	0xFF9A1CC5;
			case DARKYELLOW:	0xFFBCBC00;
			case LIGHTGRAY:		0xFFD4D4D4;
			case GRAY:			0xFFA4A4A4;
			case BLUE:			0xFF2A4AEA;
			case GREEN:			0xFF00FF00;
			case CYAN:			0xFF008CFF;
			case RED:			0xFFFF0000;
			case MAGENTA:		0xFFFF00FF;
			case YELLOW:		0xFFFFFF00;
			case WHITE | _:		0xFFFFFFFF;
		}
	}
}