package funkin.backend.system;

import flixel.util.FlxColor;
import funkin.backend.assets.ModsFolder;
import funkin.backend.assets.IModsAssetLibrary;
import funkin.backend.assets.ScriptedAssetLibrary;
import funkin.backend.system.macros.GitCommitMacro;
import funkin.backend.utils.IniUtil;
import lime.app.Application;
import lime.utils.AssetLibrary as LimeAssetLibrary;
import lime.utils.AssetType;

/**
 * A class that reads the `flags.ini` file, allowing to read settable Flags (customs too).
 */
@:build(funkin.backend.system.macros.FlagMacro.build())
class Flags {
	// -- Codename's Addon Config --
	@:bypass public static var addonFlags:Map<String, Dynamic> = [];

	// -- Codename's Mod Config --
	public static var MOD_NAME:String = "";
	public static var MOD_DESCRIPTION:String = "";
	public static var MOD_AUTHOR:String = "";
	public static var MOD_API_VERSION:Int = 1;
	public static var MOD_DOWNLOAD_LINK:String  = "";
	public static var MOD_DEPENDENCIES:Array<String> = [];

	@:noCompletion public static var MOD_ICON32:String = "";
	@:noCompletion public static var MOD_ICON24:String = "";
	@:noCompletion public static var MOD_ICON16:String = "";
	public static var MOD_ICON:String = "";

	public static var MOD_DISCORD_CLIENT_ID:String = "";
	public static var MOD_DISCORD_LOGO_KEY:String = "";
	public static var MOD_DISCORD_LOGO_TEXT:String = "";

	public static var MOD_REDIRECT_STATES:Map<String, String> = [];

	// -- Codename's Default Flags --
	@:lazy public static var SAVE_PATH:String = haxe.macro.Compiler.getDefine("SAVE_PATH");
	@:lazy public static var SAVE_NAME:String = haxe.macro.Compiler.getDefine("SAVE_NAME");

	public static var CURRENT_API_VERSION:Int = 1;
	public static var COMMIT_NUMBER:Int = GitCommitMacro.commitNumber;
	public static var COMMIT_HASH:String = GitCommitMacro.commitHash;
	public static var COMMIT_MESSAGE:String = 'Commit $COMMIT_NUMBER ($COMMIT_HASH)';

	@:bypass public static var WINDOW_TITLE_USE_MOD_NAME:Bool = false;
	@:lazy public static var TITLE:String = Application.current.meta.get('name');
	@:lazy public static var VERSION:String = Application.current.meta.get('version');

	@:lazy public static var VERSION_MESSAGE:String = 'Codename Engine v$VERSION';

	public static var REPO_NAME:String = "CodenameEngine";
	public static var REPO_OWNER:String = "CodenameCrew";
	public static var REPO_URL:String = 'https://github.com/$REPO_OWNER/$REPO_NAME';

	public static var SOUND_EXTENSIONS:Array<String> = [
		#if web "mp3" #else "ogg" #end,
		"opus"
	];

	/**
	 * Preferred sound extension for the game's audio files.
	 * Currently is set to `mp3` for web targets, and `ogg` for other targets.
	 */
	public static var SOUND_EXT:String = #if web "mp3" #else "ogg" #end; // we also support wav
	public static var VIDEO_EXT:String = "mp4";
	public static var IMAGE_EXT:String = "png"; // we also support jpg

	public static var DEFAULT_DISCORD_LOGO_KEY:String = "icon";
	public static var DEFAULT_DISCORD_CLIENT_ID:String = "1383853614589673472";
	public static var DEFAULT_DISCORD_LOGO_TEXT:String = "Codename Engine";

	@:also(funkin.game.Character.FALLBACK_CHARACTER)
	public static var DEFAULT_CHARACTER:String = "bf";
	public static var DEFAULT_GIRLFRIEND:String = "gf";
	public static var DEFAULT_OPPONENT:String = "dad";

	@:also(funkin.game.PlayState.difficulty)
	public static var DEFAULT_DIFFICULTY:String = "normal";
	public static var DEFAULT_STAGE:String = "stage";
	public static var DEFAULT_SCROLL_SPEED:Float = 2.0;
	public static var DEFAULT_HEALTH_ICON:String = "face";

	public static var SONGS_LIST_MOD_MODE:Allow<"prepend", "override", "append"> = "override";
	public static var WEEKS_LIST_MOD_MODE:Allow<"prepend", "override", "append"> = "override";

	// Translations system //
	public static var DEFAULT_LANGUAGE:String = "en";
	public static var DEFAULT_LANGUAGE_NAME:String = "English";
	/**
	 * **NOTICE:** This will only contain the id of the language, not the full name.
	 * If you blacklist the default language, you will need to change DEFAULT_LANGUAGE and DEFAULT_LANGUAGE_NAME.
	 */
	public static var BLACKLISTED_LANGUAGES:Array<String> = [];
	/**
	 * **NOTICE:** This will only contain the id of the language, not the full name.
	 * If this list is not empty, the languages listed will be the only ones able to be used.
	 */
	public static var WHITELISTED_LANGUAGES:Array<String> = [];

	// Internal stuff
	public static var DEFAULT_BPM:Float = 100.0;
	public static var DEFAULT_BEATS_PER_MEASURE:Int = 4;
	public static var DEFAULT_STEPS_PER_BEAT:Int = 4;
	public static var DEFAULT_LOOP_TIME:Float = 0.0;

	public static var SUPPORTED_CHART_RUNTIME_FORMATS:Array<String> = ["Legacy", "Psych Engine"];
	public static var SUPPORTED_CHART_FORMATS:Array<String> = ["BaseGame"];

	public static var VSLICE_SONG_METADATA_VERSION:String = "2.2.2";
	public static var VSLICE_SONG_CHART_DATA_VERSION:String = "2.0.0";
	public static var VSLICE_DEFAULT_NOTE_STYLE:String = 'funkin';
	public static var VSLICE_DEFAULT_ALBUM_ID:String = 'volume1';
	public static var VSLICE_DEFAULT_PREVIEW_START:Int = 0;
	public static var VSLICE_DEFAULT_PREVIEW_END:Int = 15000;

	/**
	 * Default background colors for songs or more without bg color
	 */
	public static var DEFAULT_COLOR:FlxColor = 0xFF9271FD;
	public static var DEFAULT_WEEK_COLOR:FlxColor = 0xFFF9CF51;
	public static var DEFAULT_COOP_ALLOWED:Bool = false;
	public static var DEFAULT_OPPONENT_MODE_ALLOWED:Bool = false;

	@:also(funkin.game.PlayState.coopMode)
	public static var DEFAULT_COOP_MODE:Bool = false; // used in playstate if it doesn't find it
	@:also(funkin.game.PlayState.opponentMode)
	public static var DEFAULT_OPPONENT_MODE:Bool = false;

	public static var DEFAULT_NOTE_MS_LIMIT:Float = 1500;
	public static var DEFAULT_NOTE_SCALE:Float = 0.7;
	#if MODCHARTING_FEATURES
	public static var DEFAULT_MODCHART_HOLD_SUBDIVISIONS:Int = 4;
	#end

	@:also(funkin.game.Character.FALLBACK_DEAD_CHARACTER)
	public static var DEFAULT_GAMEOVER_CHARACTER:String = "bf-dead";

	public static var DEFAULT_CAM_ZOOM_INTERVAL:Int = 1;
	public static var DEFAULT_CAM_ZOOM_OFFSET:Float = 0;
	//public static var DEFAULT_CAM_ZOOM_EVERY:BeatType = MEASURE;
	public static var DEFAULT_CAM_ZOOM_STRENGTH:Int = 1;
	public static var DEFAULT_CAM_ZOOM:Float = 1.05; // what zoom level it defaults to
	public static var DEFAULT_HUD_ZOOM:Float = 1.0;
	public static var DEFAULT_ZOOM:Float = 1.0;
	public static var DEFAULT_ZOOM_LERP:Float = 0.05;
	public static var MAX_CAMERA_ZOOM_MULT:Float = 10;
	public static var USE_CAM_ZOOM_MULT:Bool = true;
	public static var DEFAULT_CAM_ZOOM_MULT:Float = 0.015;
	public static var DEFAULT_HUD_ZOOM_MULT:Float = 0.03;
	public static var DEFAULT_CAM_ZOOM_LERP:Float = 0.05;
	public static var DEFAULT_HUD_ZOOM_LERP:Float = 0.05;

	// to translate these you need to convert them into ids
	// Resume -> pause.resume
	// Restart Song -> pause.restart
	// Change Controls -> pause.changeControls
	// Change Options -> pause.changeOptions
	// Exit to menu -> pause.exitToMenu
	// Exit to charter -> pause.exitToCharter
	// Resume Cutscene -> pause.resumeCutscene
	// Skip Cutscene -> pause.skipCutscene
	// Restart Cutscene -> pause.restartCutscene
	public static var DEFAULT_PAUSE_ITEMS:Array<String> = ['Resume', 'Restart Song', 'Change Controls', 'Change Options', 'Exit to menu', "Exit to charter"];
	public static var DEFAULT_CUTSCENE_PAUSE_ITEMS:Array<String> = ['Resume Cutscene', 'Skip Cutscene', 'Restart Cutscene', 'Exit to menu'];
	public static var DEFAULT_GITAROO:Bool = true;
	public static var GITAROO_CHANCE:Float = 0.1;
	public static var DEFAULT_MUTE_VOCALS_ON_MISS:Bool = true;

	public static var DEFAULT_MAX_HEALTH:Float = 2.0;
	public static var DEFAULT_HEALTH:Null<Float> = null;//DEFAULT_MAX_HEALTH / 2.0;
	public static var DEFAULT_ICONBOP:Bool = true;
	public static var BOP_ICON_SCALE:Float = 1.2;
	public static var ICON_OFFSET:Float = 26;
	public static var ICON_LERP:Float = 0.33;

	public static var DEFAULT_INTRO_LENGTH:Int = 5;
	public static var DEFAULT_INTRO_SPRITES:Array<String> = [null, 'game/ready', 'game/set', 'game/go'];

	public static var MAX_SPLASHES:Int = 8;
	public static var STUNNED_TIME:Float = 5 / 60;

	@:also(funkin.game.PlayState.daPixelZoom)
	public static var PIXEL_ART_SCALE:Float = 6.0;

	public static var DEFAULT_COMBO_GROUP_MAX_SIZE:Int = 25;

	public static var DEFAULT_STRUM_AMOUNT:Int = 4;
	public static var DEFAULT_CAMERA_FOLLOW_SPEED:Float = 0.04;

	public static var VOCAL_OFFSET_VIOLATION_THRESHOLD:Float = 25;

	// Usage: Codename Credits
	public static var MAIN_DEVS_COLOR:FlxColor = 0xFF9C35D5;
	public static var MIN_CONTRIBUTIONS_COLOR:FlxColor = 0xFFB4A7DA;

	public static var UNDO_PREFIX:String = "* ";
	public static var JSON_PRETTY_PRINT:String = "\t";

	public static var DISABLE_EDITORS:Bool = false;
	public static var DISABLE_WARNING_SCREEN:Bool = true;
	public static var DISABLE_TRANSITIONS:Bool = false;
	public static var DISABLE_LANGUAGES:Bool = false;
	public static var DISABLE_AUTOUPDATER:Bool = false;

	@:also(funkin.backend.MusicBeatTransition.script)
	public static var DEFAULT_TRANSITION_SCRIPT:String = "";
	@:also(funkin.menus.PauseSubState.script)
	public static var DEFAULT_PAUSE_SCRIPT:String = "";
	@:also(funkin.game.GameOverSubstate.script)
	public static var DEFAULT_GAMEOVER_SCRIPT:String = "";

	public static var URL_WIKI:String = "https://codename-engine.com/";
	public static var URL_EDITOR_FALLBACK:String = "https://www.youtube.com/watch?v=9Youam7GYdQ";
	public static var URL_FNF_ITCH:String = "https://ninja-muffin24.itch.io/funkin";

	/**
	 * Default audio paths
	 */
	public static var DEFAULT_MENU_MUSIC:String = "freakyMenu";
	public static var DEFAULT_PAUSE_MENU_MUSIC:String = "breakfast";
	public static var DEFAULT_GAMEOVER_MUSIC:String = "gameOver";

	public static var DEFAULT_MISS_SOUNDS:Array<String> = ["missnote1", "missnote2", "missnote3"];
	public static var DEFAULT_INTRO_SOUNDS:Array<String> = ["intro3", "intro2", "intro1", "introGo"];
	public static var DEFAULT_GAMEOVERSFX_SOUND:String = "gameOverSFX";
	public static var DEFAULT_GAMEOVEREND_SOUND:String = "gameOverEnd";

	public static var DEFAULT_MENU_SCROLL_SOUND:String = "menu/scroll";
	public static var DEFAULT_MENU_CONFIRM_SOUND:String = "menu/confirm";
	public static var DEFAULT_MENU_CANCEL_SOUND:String = "menu/cancel";
	public static var DEFAULT_MENU_VOLUME_SOUND:String = "menu/volume";

	public static var DEFAULT_EDITOR_CHECKBOXCHECKED_SOUND:String = "editors/checkboxChecked";
	public static var DEFAULT_EDITOR_CHECKBOXUNCHECKED_SOUND:String = "editors/checkboxUnchecked";
	public static var DEFAULT_EDITOR_WARNING_SOUND:String = "editors/warningMenu";
	public static var DEFAULT_EDITOR_AUTOSAVE_SOUND:String = "editors/autosave";
	public static var DEFAULT_EDITOR_BUTTONCLICK_SOUND:String = "editors/buttonClick";
	public static var DEFAULT_EDITOR_CLICK_SOUND:String = "editors/click";
	public static var DEFAULT_EDITOR_COPY_SOUND:String = "editors/copy";
	public static var DEFAULT_EDITOR_CUT_SOUND:String = "editors/cut";
	public static var DEFAULT_EDITOR_DELETE_SOUND:String = "editors/delete";
	public static var DEFAULT_EDITOR_OFFSETDRAG_SOUND:String = "editors/offsetDrag";
	public static var DEFAULT_EDITOR_PASTE_SOUND:String = "editors/paste";
	public static var DEFAULT_EDITOR_REDO_SOUND:String = "editors/redo";
	public static var DEFAULT_EDITOR_SAVE_SOUND:String = "editors/save";
	public static var DEFAULT_EDITOR_TEXTREMOVE_SOUND:String= "editors/textRemove";
	public static var DEFAULT_EDITOR_TEXTTYPE_SOUND:String = "editors/textType";
	public static var DEFAULT_EDITOR_UNDO_SOUND:String = "editors/undo";
	public static var DEFAULT_EDITOR_WINDOWAPPEAR_SOUND:String = "editors/windowAppear";
	public static var DEFAULT_EDITOR_WINDOWCLOSE_SOUND:String = "editors/windowClose";
	public static var DEFAULT_EDITOR_DROPDOWNAPPEAR_SOUND:String = "editors/dropdownAppear";
	public static var DEFAULT_CHARTER_HITSOUND_SOUND:String = "editors/charter/hitsound";
	public static var DEFAULT_CHARTER_METRONOME_SOUND:String = "editors/charter/metronome";
	public static var DEFAULT_CHARTER_NOTEDELETE_SOUND:String = "editors/charter/noteDelete";
	public static var DEFAULT_CHARTER_NOTEPLACE_SOUND:String = "editors/charter/notePlace";
	public static var DEFAULT_CHARTER_SCROLL_SOUND:String = "editors/charter/scroll";
	public static var DEFAULT_CHARTER_SNAPPINGCHANGE_SOUND:String = "editors/charter/snappingChange";
	public static var DEFAULT_CHARTER_STRUMLOCK_SOUND:String = "editors/charter/strumLock";
	public static var DEFAULT_CHARTER_STRUMUNLOCK_SOUND:String = "editors/charter/strumUnlock";
	public static var DEFAULT_CHARTER_SUSTAINADD_SOUND:String = "editors/charter/sustainAdd";
	public static var DEFAULT_CHARTER_SUSTAINDELETE_SOUND:String = "editors/charter/sustainDelete";
	public static var DEFAULT_CHARACTER_GHOSTDISABLE_SOUND:String = "editors/character/ghostDisable";
	public static var DEFAULT_CHARACTER_GHOSTENABLE_SOUND:String = "editors/character/ghostEnable";

	public static var DEFAULT_GLSL_VERSION:String = "120";
	@:also(funkin.backend.utils.HttpUtil.userAgent)
	public static var USER_AGENT:String = 'request';
	// -- End of Codename's Default Flags --

	/**
	 * Flags that Codename couldn't recognize as it's own defaults (they can only be `string`! due to them being unparsed).
	 */
	@:bypass public static var customFlags:Map<String, String> = [];

	public static function loadFromData(flags:Map<String, String>, data:String) {
		WINDOW_TITLE_USE_MOD_NAME = false;

		if (!(data.length > 0)) return;
		var res = IniUtil.parseString(data);

		for (name => section in res) {
			switch (name) {
				case "Common": for (key => value in section) flags["MOD_" + key] = value;
				case "Discord": for (key => value in section) flags["MOD_DISCORD_" + key] = value;
				case "Flags": for (key => value in section) flags[key] = value;
				case "StateRedirects.force": for (key => value in section) MOD_REDIRECT_STATES.set(key, value);
				case "StateRedirects": for (key => value in section) if (!MOD_REDIRECT_STATES.exists(key)) MOD_REDIRECT_STATES.set(key, value);
				case "Global": // do nothing
				default:
					if (Std.isOfType(Reflect.field(Flags, name), haxe.ds.StringMap)) Reflect.setProperty(Flags, name, section);
					else trace('Invalid section $name');
			}
		}

		if (!flags.exists("WINDOW_TITLE_USE_MOD_NAME")) WINDOW_TITLE_USE_MOD_NAME = !flags.exists('TITLE') && flags.exists('MOD_NAME');
		else WINDOW_TITLE_USE_MOD_NAME = parseBool(flags.get("WINDOW_TITLE_USE_MOD_NAME"));

		flags.remove("WINDOW_TITLE_USE_MOD_NAME");
	}

	public static function loadFromDatas(datas:Array<String>) {
		var flags:Map<String, String> = [];
		for(data in datas) {
			if(data != null)
				loadFromData(flags, data);
		}
		return flags;
	}

	public static function parseFlags(flags:Map<String, String>) {
		for(name=>value in flags)
			if(!parse(name, value))
				customFlags.set(name, value);

		Options.modchartingHoldSubdivisions = DEFAULT_MODCHART_HOLD_SUBDIVISIONS;
	}

	/**
	 * Loads the flags from the assets.
	**/
	public static function load(?libs:Array<LimeAssetLibrary> = null) {
		if (libs == null) {
			libs = Paths.assetsTree.libraries.copy();
			libs.reverse();
		}
		for(lib in libs) {
			var l = lib;
			if (l is openfl.utils.AssetLibrary) {
				@:privateAccess
				l = cast(l, openfl.utils.AssetLibrary).__proxy;
			}
			if(lib is funkin.backend.assets.TranslatedAssetLibrary) {
				// skip translations since it would be useless, if you wanna modify it set the flags inside of global.hx
				continue;
			}

			if (l is IModsAssetLibrary) {
				var flagsTxt = "";
				if (l.exists(Paths.ini("config/modpack"), AssetType.TEXT))
					flagsTxt = l.getAsset(Paths.ini("config/modpack"), AssetType.TEXT);
				if (cast(l, IModsAssetLibrary).modName == "assets") continue;
				if (cast(l, IModsAssetLibrary).modName == "source") continue;

				if (cast(l, IModsAssetLibrary).modName == ModsFolder.currentModFolder) {
					var flags:Map<String, String> = [];
					loadFromData(flags, flagsTxt);
					parseFlags(flags);
				}
				else {
					var flags:Map<String, String> = [];
					loadFromData(flags, flagsTxt);
					addonFlags.set(cast(l, IModsAssetLibrary).modName.toLowerCase().replace(" ", "").trim(), flags);
				}
			}
			else {
				var flagsTxt = "";
				if (l.exists(Paths.getPath("data/config/flags.ini"), AssetType.TEXT))
					flagsTxt = l.getAsset(Paths.getPath("data/config/flags.ini"), AssetType.TEXT);
				var flags:Map<String, String> = [];
				loadFromData(flags, flagsTxt);
				parseFlags(flags);
			}
		}
	}
}