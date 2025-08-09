package funkin.options;

import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;
import openfl.Lib;

/**
 * The save data of the engine.
 * Mod save data is stored in `FlxG.save.data`.
**/
@:build(funkin.backend.system.macros.OptionsMacro.build())
@:build(funkin.backend.system.macros.FunkinSaveMacro.build("__save", "__flush", "__load"))
class Options
{
	@:dox(hide) @:doNotSave
	public static var __save:FlxSave;
	@:dox(hide) @:doNotSave
	private static var __eventAdded = false;

	/**
	 * SETTINGS
	 */
	public static var naughtyness:Bool = true;
	public static var downscroll:Bool = false;
	public static var ghostTapping:Bool = true;
	public static var flashingMenu:Bool = true;
	public static var camZoomOnBeat:Bool = true;
	public static var fpsCounter:Bool = true;
	public static var autoPause:Bool = true;
	public static var antialiasing:Bool = true;
	public static var volume:Float = 1;
	public static var volumeMusic:Float = 1;
	public static var volumeSFX:Float = 1;
	public static var week6PixelPerfect:Bool = true;
	public static var gameplayShaders:Bool = true;
	public static var colorHealthBar:Bool = true;
	public static var lowMemoryMode:Bool = false;
	public static var devMode:Bool = false;
	public static var betaUpdates:Bool = false;
	public static var splashesEnabled:Bool = true;
	public static var hitWindow:Float = 250;
	public static var songOffset:Float = 0;
	public static var framerate:Int = 120;
	public static var gpuOnlyBitmaps:Bool = #if (mac || web) false #else true #end; // causes issues on mac and web
	public static var language = "en"; // default to english, Flags.DEFAULT_LANGUAGE should not modify this
	public static var streamedMusic:Bool = true;
	public static var streamedVocals:Bool = false;
	public static var quality:Int = 1;
	public static var allowConfigWarning:Bool = true;
	#if MODCHARTING_FEATURES
	public static var modchartingHoldSubdivisions:Int = 4;
	#end

	public static var lastLoadedMod:String = null;

	/**
	 * EDITORS SETTINGS
	 */
	public static var intensiveBlur:Bool = true;
	public static var editorSFX:Bool = true;

	public static var editorCharterPrettyPrint:Bool = false;
	public static var editorCharacterPrettyPrint:Bool = true;
	public static var editorStagePrettyPrint:Bool = true;

	public static var editorsResizable:Bool = true;
	public static var bypassEditorsResize:Bool = false;
	public static var maxUndos:Int = 120;
	public static var songOffsetAffectEditors:Bool = false;

	/**
	 * QOL FEATURES
	 */
	public static var freeplayLastSong:String = null;
	public static var freeplayLastDifficulty:String = "normal";
	public static var contributors:Array<funkin.backend.system.github.GitHubContributor.CreditsGitHubContributor> = [];
	public static var mainDevs:Array<Int> = [];  // IDs
	public static var lastUpdated:Null<Float>;

	/**
	 * CHARTER
	 */
	public static var charterMetronomeEnabled:Bool = false;
	public static var charterShowSections:Bool = true;
	public static var charterShowBeats:Bool = true;
	public static var charterEnablePlaytestScripts:Bool = true;
	public static var charterRainbowWaveforms:Bool = false;
	public static var charterLowDetailWaveforms:Bool = false;
	public static var charterAutoSaves:Bool = true;
	public static var charterAutoSaveTime:Float = 60*5;
	public static var charterAutoSaveWarningTime:Float = 5;
	public static var charterAutoSavesSeparateFolder:Bool = false;

	/**
	 * CHARACTER EDITOR
	 */
	public static var stageSelected:String = null;
	public static var characterHitbox:Bool = true;
	public static var characterCamera:Bool = true;
	public static var characterAxis:Bool = true;
	public static var characterDragging:Bool = true;
	public static var playAnimOnOffset:Bool = false;

	/**
	 * PLAYER 1 CONTROLS
	 */
	public static var P1_NOTE_LEFT:Array<FlxKey> = [A];
	public static var P1_NOTE_DOWN:Array<FlxKey> = [S];
	public static var P1_NOTE_UP:Array<FlxKey> = [W];
	public static var P1_NOTE_RIGHT:Array<FlxKey> = [D];

	// Menus
	public static var P1_LEFT:Array<FlxKey> = [A];
	public static var P1_DOWN:Array<FlxKey> = [S];
	public static var P1_UP:Array<FlxKey> = [W];
	public static var P1_RIGHT:Array<FlxKey> = [D];
	public static var P1_ACCEPT:Array<FlxKey> = [ENTER];
	public static var P1_BACK:Array<FlxKey> = [BACKSPACE];
	public static var P1_PAUSE:Array<FlxKey> = [ENTER];
	public static var P1_CHANGE_MODE:Array<FlxKey> = [TAB];

	// Misc
	public static var P1_RESET:Array<FlxKey> = [R];
	public static var P1_SWITCHMOD:Array<FlxKey> = [TAB];
	public static var P1_VOLUME_UP:Array<FlxKey> = [PLUS];
	public static var P1_VOLUME_DOWN:Array<FlxKey> = [MINUS];
	public static var P1_VOLUME_MUTE:Array<FlxKey> = [ZERO];

	// Debugs
	public static var P1_DEV_ACCESS:Array<FlxKey> = [SEVEN];
	public static var P1_DEV_CONSOLE:Array<FlxKey> = [F2];
	public static var P1_DEV_RELOAD:Array<FlxKey> = [F5];

	/**
	* PLAYER 2 CONTROLS (ALT)
	*/

	// Notes
	public static var P2_NOTE_LEFT:Array<FlxKey> = [LEFT];
	public static var P2_NOTE_DOWN:Array<FlxKey> = [DOWN];
	public static var P2_NOTE_UP:Array<FlxKey> = [UP];
	public static var P2_NOTE_RIGHT:Array<FlxKey> = [RIGHT];

	// Menus
	public static var P2_LEFT:Array<FlxKey> = [LEFT];
	public static var P2_DOWN:Array<FlxKey> = [DOWN];
	public static var P2_UP:Array<FlxKey> = [UP];
	public static var P2_RIGHT:Array<FlxKey> = [RIGHT];
	public static var P2_ACCEPT:Array<FlxKey> = [SPACE];
	public static var P2_BACK:Array<FlxKey> = [ESCAPE];
	public static var P2_PAUSE:Array<FlxKey> = [ESCAPE];
	public static var P2_CHANGE_MODE:Array<FlxKey> = [];

	// Misc
	public static var P2_RESET:Array<FlxKey> = [];
	public static var P2_SWITCHMOD:Array<FlxKey> = [];
	public static var P2_VOLUME_UP:Array<FlxKey> = [NUMPADPLUS];
	public static var P2_VOLUME_DOWN:Array<FlxKey> = [NUMPADMINUS];
	public static var P2_VOLUME_MUTE:Array<FlxKey> = [NUMPADZERO];

	// Debugs
	public static var P2_DEV_ACCESS:Array<FlxKey> = [];
	public static var P2_DEV_CONSOLE:Array<FlxKey> = [];
	public static var P2_DEV_RELOAD:Array<FlxKey> = [];

	/**
	* SOLO GETTERS
	*/

	// Notes
	public static var SOLO_NOTE_LEFT(get, null):Array<FlxKey>;
	public static var SOLO_NOTE_DOWN(get, null):Array<FlxKey>;
	public static var SOLO_NOTE_UP(get, null):Array<FlxKey>;
	public static var SOLO_NOTE_RIGHT(get, null):Array<FlxKey>;

	// Menus
	public static var SOLO_LEFT(get, null):Array<FlxKey>;
	public static var SOLO_DOWN(get, null):Array<FlxKey>;
	public static var SOLO_UP(get, null):Array<FlxKey>;
	public static var SOLO_RIGHT(get, null):Array<FlxKey>;
	public static var SOLO_ACCEPT(get, null):Array<FlxKey>;
	public static var SOLO_BACK(get, null):Array<FlxKey>;
	public static var SOLO_PAUSE(get, null):Array<FlxKey>;
	public static var SOLO_CHANGE_MODE(get, null):Array<FlxKey>;

	// Misc
	public static var SOLO_RESET(get, null):Array<FlxKey>;
	public static var SOLO_SWITCHMOD(get, null):Array<FlxKey>;
	public static var SOLO_VOLUME_UP(get, null):Array<FlxKey>;
	public static var SOLO_VOLUME_DOWN(get, null):Array<FlxKey>;
	public static var SOLO_VOLUME_MUTE(get, null):Array<FlxKey>;

	// Debugs
	public static var SOLO_DEV_ACCESS(get, null):Array<FlxKey>;
	public static var SOLO_DEV_CONSOLE(get, null):Array<FlxKey>;
	public static var SOLO_DEV_RELOAD(get, null):Array<FlxKey>;

	public static function load() {
		var path = haxe.macro.Compiler.getDefine("SAVE_OPTIONS_PATH"), name = haxe.macro.Compiler.getDefine("SAVE_OPTIONS_NAME");
		if (path == null) path = 'CodenameEngine';
		if (name == null) name = 'options';

		if (__save == null) __save = new FlxSave();
		__save.bind(name, path);
		__load();

		if (!__eventAdded) {
			Lib.application.onExit.add(function(i:Int) {
				Logs.traceColored([
					Logs.getPrefix("Options"),
					Logs.logText("Saving "),
					Logs.logText("settings", GREEN),
					Logs.logText("...")
				], VERBOSE);
				save();
			});
			__eventAdded = true;
		}
		FlxG.sound.volume = volume;
		applySettings();
	}

	public static function applySettings() {
		applyKeybinds();

		switch (quality) {
			case 0:
				antialiasing = false;
				lowMemoryMode = true;
				gameplayShaders = false;
			case 1:
				antialiasing = true;
				lowMemoryMode = false;
				gameplayShaders = true;
		}

		FlxG.sound.defaultMusicGroup.volume = volumeMusic;
		FlxG.game.stage.quality = (FlxG.enableAntialiasing = antialiasing) ? BEST : LOW;
		FlxG.autoPause = autoPause;
		if (FlxG.updateFramerate < framerate) FlxG.drawFramerate = FlxG.updateFramerate = framerate;
		else FlxG.updateFramerate = FlxG.drawFramerate = framerate;
	}

	public static function applyKeybinds() {
		PlayerSettings.solo.setKeyboardScheme(Solo);
		PlayerSettings.player1.setKeyboardScheme(Duo(true));
		PlayerSettings.player2.setKeyboardScheme(Duo(false));

		FlxG.sound.volumeUpKeys = SOLO_VOLUME_UP;
		FlxG.sound.volumeDownKeys = SOLO_VOLUME_DOWN;
		FlxG.sound.muteKeys = SOLO_VOLUME_MUTE;
	}

	public static function save() {
		volume = FlxG.sound.volume;
		__flush();
	}
}
