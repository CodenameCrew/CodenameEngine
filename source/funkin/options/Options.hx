package funkin.options;

import openfl.Lib;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;

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
	public static var week6PixelPerfect:Bool = true;
	public static var gameplayShaders:Bool = true;
	public static var colorHealthBar:Bool = true;
	public static var lowMemoryMode:Bool = false;
	public static var betaUpdates:Bool = false;
	public static var splashesEnabled:Bool = true;
	public static var hitWindow:Float = 250;
	public static var songOffset:Float = 0;
	public static var framerate:Int = 120;
	public static var gpuOnlyBitmaps:Bool = #if (mac || web) false #else true #end; // causes issues on mac and web

	public static var lastLoadedMod:String = null;

	/**
	 * EDITORS SETTINGS
	 */
	public static var intensiveBlur:Bool = true;
	public static var editorSFX:Bool = true;
	public static var editorPrettyPrint:Bool = false;
	public static var maxUndos:Int = 120;

	/**
	 * QOL FEATURES
	 */
	public static var freeplayLastSong:String = null;
	public static var freeplayLastDifficulty:String = "normal";
	public static var contributors:Array<funkin.backend.system.github.GitHubContributor> = [];
	public static var mainDevs:Array<Int> = [];  // IDs
	public static var lastUpdated:Null<Float>;

	/**
	 * CHARTER
	 */
	public static var charterMetronomeEnabled:Bool = false;
	public static var charterShowSections:Bool = true;
	public static var charterShowBeats:Bool = true;
	public static var charterEnablePlaytestScripts:Bool = true;
	public static var charterLowDetailWaveforms:Bool = false;
	public static var charterAutoSaves:Bool = true;
	public static var charterAutoSaveTime:Float = 60*5;
	public static var charterAutoSaveWarningTime:Float = 5;
	public static var charterAutoSavesSeperateFolder:Bool = false;

	/**
	* PLAYER 1 CONTROLS
	*/

	// Notes
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

	// Misc
	public static var P1_RESET:Array<FlxKey> = [R];
	public static var P1_SWITCHMOD:Array<FlxKey> = [TAB];
	public static var P1_VOLUME_UP:Array<FlxKey> = [];
	public static var P1_VOLUME_DOWN:Array<FlxKey> = [];
	public static var P1_VOLUME_MUTE:Array<FlxKey> = [];

	// Debugs
	public static var P1_DEBUG_RELOAD:Array<FlxKey> = [F5];

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

	// Misc
	public static var P2_RESET:Array<FlxKey> = [];
	public static var P2_SWITCHMOD:Array<FlxKey> = [];
	public static var P2_VOLUME_UP:Array<FlxKey> = [NUMPADPLUS];
	public static var P2_VOLUME_DOWN:Array<FlxKey> = [NUMPADMINUS];
	public static var P2_VOLUME_MUTE:Array<FlxKey> = [NUMPADZERO];

	// Debugs
	public static var P2_DEBUG_RELOAD:Array<FlxKey> = [];

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

	// Misc
	public static var SOLO_RESET(get, null):Array<FlxKey>;
	public static var SOLO_SWITCHMOD(get, null):Array<FlxKey>;
	public static var SOLO_VOLUME_UP(get, null):Array<FlxKey>;
	public static var SOLO_VOLUME_DOWN(get, null):Array<FlxKey>;
	public static var SOLO_VOLUME_MUTE(get, null):Array<FlxKey>;

	// Debugs
	public static var SOLO_DEBUG_RELOAD(get, null):Array<FlxKey>;

	public static function load() {
		if (__save == null) __save = new FlxSave();
		__save.bind("options", "CodenameEngine");
		__load();

		if (!__eventAdded) {
			Lib.application.onExit.add(function(i:Int) {
				trace("Saving settings...");
				save();
			});
			__eventAdded = true;
		}
		FlxG.sound.volume = volume;
		applySettings();
	}

	public static function applySettings() {
		applyKeybinds();
		FlxG.game.stage.quality = (FlxG.enableAntialiasing = antialiasing) ? LOW : BEST;
		FlxG.autoPause = autoPause;
		FlxG.drawFramerate = FlxG.updateFramerate = framerate;
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
