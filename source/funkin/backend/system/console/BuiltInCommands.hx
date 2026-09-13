package funkin.backend.system.console;
import funkin.backend.scripting.ModState;
import funkin.menus.credits.CreditsMain;
import funkin.editors.stage.StageEditor;
import funkin.game.Stage;
import funkin.game.Character;
import funkin.editors.character.CharacterEditor;
import funkin.options.OptionsMenu;
import funkin.editors.charter.Charter;
import funkin.backend.chart.Chart;
import funkin.menus.TitleState;
import funkin.menus.MainMenuState;
import funkin.menus.FreeplayState;
import funkin.menus.StoryMenuState;
import funkin.backend.system.console.ConsoleCommand;


class BuiltInCommands {
	static var help = new FuncCommand("help", "[object]", "(Shows full list of commands or list of fields on an object or class)", function(args) {
		if (args.length == 0) {
			var strBuf:StringBuf = new StringBuf();
			strBuf.add("\nCommands:");
			for (cmdName in ConsoleCommandManager.commandsStringList) { //use list to go in order
				var cmd = ConsoleCommandManager.getCommand(cmdName);
				strBuf.add("\n\t");
				strBuf.add(cmd.name);
				strBuf.add(" ");
				strBuf.add(cmd.argsDesc);
				strBuf.add("\n\t\t");
				strBuf.add(cmd.desc);
			}
			Logs.infos(strBuf.toString());
		} else {
			@:privateAccess
			var fields = ConsoleUI.instance.consoleHscript.tryGetFields(args[0]);
			if (fields.length == 0) {
				Logs.infos("Failed to find fields for: " + args[0]);
				return;
			}
			var strBuf:StringBuf = new StringBuf();
			strBuf.add("\n");
			strBuf.add(args[0]);
			strBuf.add(":");
			for (f in fields) {
				strBuf.add("\n\t");
				strBuf.add(f.name);
				strBuf.add(":");
				strBuf.add(f.type);
				if (f.value != "") {
					strBuf.add(" = ");
					strBuf.add(f.value);
				}
			}
			Logs.infos(strBuf.toString());
		}
	});
	static var clear = new FuncCommand("clear", "", "(Clears the console log)", function(args) { @:privateAccess ConsoleUI.instance.clearConsole(); });
	static var pause = new FuncCommand("pause", "", "(Toggles pause on game)", function(args) { 
		var game:FunkinGame = cast FlxG.game;
		game.toggleManualPause();
	});
	static var loadSong = new FuncCommand("loadSong", "[song] [diff] [variation] [opponentMode] [coopMode]", "(Loads a new song and switches to PlayState)", function(args) {
		if (args.length == 0) {
			Logs.error("Can't load a song with no name!");
			return;
		}

		var name:String = args[0];
		var diff:String = args[1];
		var variation:String = args[2] != null ? (args[2] == "default" ? null : args[2]) : null;

		var chartPath:String = Paths.chart(name, diff, variation);
		if (Assets.exists(chartPath)) {
			PlayState.loadSong(name, diff, variation, args[3] != null ? args[3] == "true" : false, args[4] != null ? args[4] == "true" : false);
			FlxG.switchState(new PlayState());
		} else {
			Logs.error('Chart for song $name at "$chartPath" was not found.');
		}
	});
	static var endSong = new FuncCommand("endSong", "", "(Ends the current song if in PlayState)", function(args) {
		if (PlayState.instance != null) {
			PlayState.instance.endSong();
		}
	});
	static var loadWeek = new FuncCommand("loadWeek", "[name] [diff]", "(Loads a new week and switches to PlayState)", function(args) {
		if (args.length == 0) return;
		var weeklist = StoryWeeklist.get(true, false);
		for (w in weeklist.weeks) {
			if (args[0] == w.id) {
				var diff = args[1] != null ? args[1] : w.difficulties[w.difficulties.length-1];
				if (w.difficulties.contains(diff)) {
					PlayState.loadWeek(w, diff);
					FlxG.switchState(new PlayState());
					return;
				}
				Logs.error('Difficulty $diff for week ${w.id} was not found.');
				return;
			}
		}
		Logs.error('Week with id ${args[0]} was not found.');
	});
	static var switchMod = new FuncCommand("switchMod", "[name]", "(Switches to another mod, inputting nothing will disable mod)", function(args) { funkin.backend.assets.ModsFolder.switchMod(args[0]); });
	static var reloadMod = new FuncCommand("reloadMod", "", "(Reload current mod)", function(args) { funkin.backend.assets.ModsFolder.reloadMods(); });

	static var reloadState = new FuncCommand("reloadState", "", "(Reload current state)", function(args) { FlxG.resetState(); });
	static var goToPlayState = new FuncCommand("goToPlayState", "", "(switches state to PlayState, only works if a song is already loaded)", function(args) { if (PlayState.SONG != null) FlxG.switchState(new PlayState()); });
	static var goToMainMenu = new FuncCommand("goToMainMenu", "", "(switches state to MainMenuState)", function(args) { FlxG.switchState(new MainMenuState()); });
	static var goToStoryMode = new FuncCommand("goToStoryMode", "", "(switches state to StoryMenuState)", function(args) { FlxG.switchState(new StoryMenuState()); });
	static var goToFreeplay = new FuncCommand("goToFreeplay", "", "(switches state to FreeplayState)", function(args) { FlxG.switchState(new FreeplayState()); });
	static var goToOptions = new FuncCommand("goToOptions", "", "(switches state to OptionsMenu)", function(args) { FlxG.switchState(new OptionsMenu()); });
	static var goToCredits = new FuncCommand("goToCredits", "", "(switches state to CreditsMain)", function(args) { FlxG.switchState(new CreditsMain()); });
	static var goToTitle = new FuncCommand("goToTitle", "[reset]", "(switches state to TitleState)", function(args) {
		@:privateAccess
		if (args[0] != null && args[0] == "true") TitleState.initialized = false;
		FlxG.switchState(new TitleState());
	});
	static var goToModState = new FuncCommand("goToModState", "[name]", "(switches state to a custom ModState)", function(args) {
		FlxG.switchState(new ModState(args[0]));
	});

	static var goToCharter = new FuncCommand("goToCharter", "[song] [diff] [variation]", "(opens chart editor, inputting nothing will load existing song)", function(args) {
		if (args.length == 0) {
			if (PlayState.SONG == null) {
				Logs.error("Charter doesn't have any song data loaded!");
			} else {
				@:privateAccess
				if (Charter.__song == null || (PlayState.SONG != null && PlayState.SONG.meta != null && PlayState.SONG.meta.name != Charter.__song) || PlayState.difficulty != Charter.__diff || PlayState.variation != Charter.__variant) {
					FlxG.switchState(new Charter(PlayState.SONG.meta.name, PlayState.difficulty, PlayState.variation)); //load fresh charter, can't load previous because PlayState.SONG probably changed
				} else {
					@:privateAccess
					FlxG.switchState(new Charter(Charter.__song, Charter.__diff, Charter.__variant, false));
				}
			}
			return;
		}

		var name:String = args[0];
		var diff:String = args[1];
		var variation:String = args[2] != null ? (args[2] == "default" ? null : args[2]) : null;

		var chartPath:String = Paths.chart(name, diff, variation);
		if (Assets.exists(chartPath)) {
			FlxG.switchState(new Charter(name, diff, variation));
		} else {
			Logs.error('Chart for song $name at "$chartPath" was not found.');
		}
	});

	static var goToCharacterEditor = new FuncCommand("goToCharacterEditor", "[name]", "(opens character editor)", function(args) {
		if (args.length == 0) {
			Logs.error("Can't load a character with no name!");
			return;
		}
		var name:String = args[0];
		var list = Character.getList(false, false, null, true);
		if (!list.contains(name)) {
			Logs.error('Character $name was not found.');
			return;
		}

		FlxG.switchState(new CharacterEditor(name));
	});

	static var goToStageEditor = new FuncCommand("goToStageEditor", "[name]", "(opens stage editor)", function(args) {
		if (args.length == 0) {
			Logs.error("Can't load a stage with no name!");
			return;
		}
		var name:String = args[0];
		var list = Stage.getList(false, true);
		if (!list.contains(name)) {
			Logs.error('stage $name was not found.');
			return;
		}

		FlxG.switchState(new StageEditor(name));
	});
}