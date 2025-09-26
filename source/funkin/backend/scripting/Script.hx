package funkin.backend.scripting;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.FlxStringUtil;
import haxe.io.Path;
import lime.app.Application;

@:allow(funkin.backend.scripting.ScriptPack)
/**
 * Class used for scripting.
 * Use `Script.create` to create a script.
 */
class Script extends FlxBasic implements IFlxDestroyable {
	/**
	 * Use "static var thing = true;" in hscript to use those!!
	 * are reset every mod switch so once you're done with them make sure to make them null!!
	 */
	public static var staticVariables:Map<String, Dynamic> = [];

	/**
	 * Gets the default variables for a script.
	 */
	public static function getDefaultVariables(?script:Script):Map<String, Dynamic> {
		return [
			// Haxe related stuff
			"Std"				=> Std,
			"Math"				=> Math,
			"Reflect"			=> Reflect,
			"StringTools"		=> StringTools,
			"Json"				=> haxe.Json,
			"Xml"				=> Xml,
			"Type"				=> Type,
			"Date"				=> Date,
			"Lambda"			=> Lambda,
			#if sys "Sys"		=> Sys, #end

			// OpenFL & Lime related stuff
			"Assets"			=> openfl.utils.Assets,
			"Application"		=> lime.app.Application,
			"Main"				=> funkin.backend.system.Main,
			"window"			=> lime.app.Application.current.window,

			// Flixel related stuff
			"state"				=> flixel.FlxG.state,
			"FlxG"				=> flixel.FlxG,
			"FlxSprite"			=> flixel.FlxSprite,
			"FlxBasic"			=> flixel.FlxBasic,
			"FlxCamera"			=> flixel.FlxCamera,
			"FlxEase"			=> flixel.tweens.FlxEase,
			"FlxTween"			=> flixel.tweens.FlxTween,
			"FlxSound"			=> flixel.sound.FlxSound,
			"FlxAssets"			=> flixel.system.FlxAssets,
			"FlxMath"			=> flixel.math.FlxMath,
			"FlxGroup"			=> flixel.group.FlxGroup,
			"FlxTypedGroup"		=> flixel.group.FlxGroup.FlxTypedGroup,
			"FlxSpriteGroup"	=> flixel.group.FlxSpriteGroup,
			"FlxTypeText"		=> flixel.addons.text.FlxTypeText,
			"FlxText"			=> flixel.text.FlxText,
			"FlxTimer"			=> flixel.util.FlxTimer,
			"FlxPoint"			=> CoolUtil.getMacroAbstractClass("flixel.math.FlxPoint"),
			"FlxAxes"			=> CoolUtil.getMacroAbstractClass("flixel.util.FlxAxes"),
			"FlxColor"			=> CoolUtil.getMacroAbstractClass("flixel.util.FlxColor"),

			// Engine related stuff
			"engine"			=> {
				commit: Flags.COMMIT_NUMBER,
				hash: Flags.COMMIT_HASH,
				build: 2675, // 2675 being the last build num before it was removed
				name: "Codename Engine"
			},
			"ModState"			=> funkin.backend.scripting.ModState,
			"ModSubState"		=> funkin.backend.scripting.ModSubState,
			"PlayState"			=> funkin.game.PlayState,
			"GameOverSubstate"	=> funkin.game.GameOverSubstate,
			"HealthIcon"		=> funkin.game.HealthIcon,
			"HudCamera"			=> funkin.game.HudCamera,
			"Note"				=> funkin.game.Note,
			"Strum"				=> funkin.game.Strum,
			"StrumLine"			=> funkin.game.StrumLine,
			"Character"			=> funkin.game.Character,
			"Boyfriend"			=> funkin.game.Character, // for compatibility
			"PauseSubstate"		=> funkin.menus.PauseSubState,
			"FreeplayState"		=> funkin.menus.FreeplayState,
			"MainMenuState"		=> funkin.menus.MainMenuState,
			"PauseSubState"		=> funkin.menus.PauseSubState,
			"StoryMenuState"	=> funkin.menus.StoryMenuState,
			"TitleState"		=> funkin.menus.TitleState,
			"Options"			=> funkin.options.Options,
			"Paths"				=> funkin.backend.assets.Paths,
			"Conductor"			=> funkin.backend.system.Conductor,
			"FunkinShader"		=> funkin.backend.shaders.FunkinShader,
			"CustomShader"		=> funkin.backend.shaders.CustomShader,
			"FunkinText"		=> funkin.backend.FunkinText,
			"FlxAnimate"		=> funkin.backend.FlxAnimate,
			"FunkinSprite"		=> funkin.backend.FunkinSprite,
			"Alphabet"			=> funkin.menus.ui.Alphabet,
			"Flags"				=> funkin.backend.system.Flags,

			"CoolUtil"			=> funkin.backend.utils.CoolUtil,
			"IniUtil"			=> funkin.backend.utils.IniUtil,
			"XMLUtil"			=> funkin.backend.utils.XMLUtil,
			#if sys "ZipUtil"	=> funkin.backend.utils.ZipUtil, #end
			"MarkdownUtil"		=> funkin.backend.utils.MarkdownUtil,
			"EngineUtil"		=> funkin.backend.utils.EngineUtil,
			"MemoryUtil"		=> funkin.backend.utils.MemoryUtil,
			"BitmapUtil"		=> funkin.backend.utils.BitmapUtil,

			#if TRANSLATIONS_SUPPORT
			"TranslationUtil"	=> funkin.backend.utils.TranslationUtil,
			"translate"		=> funkin.backend.utils.TranslationUtil.get,
			#end
		];
	}

	/**
	 * Used internally to keep backwards compatibility with old scripts.
	 * This gets set on `hscript.Interp.importRedirects`,
	 * if you wanna modify it, please edit `hscript.Interp.importRedirects` directly.
	**/
	public static function getDefaultImportRedirects():Map<String, String> {
		var redirects:Map<String, String> = [];

		// Events
		final events = "funkin.backend.scripting.events.";
		redirects[events + "CharacterNodeEvent"]			= events + "character.CharacterNodeEvent";
		redirects[events + "CharacterXMLEvent"]				= events + "character.CharacterXMLEvent";
		redirects[events + "DanceEvent"]					= events + "character.DanceEvent";
		redirects[events + "DirectionAnimEvent"]			= events + "character.DirectionAnimEvent";
		redirects[events + "DiscordPresenceUpdateEvent"]	= events + "discord.DiscordPresenceUpdateEvent";
		redirects[events + "GameOverCreationEvent"]			= events + "gameover.GameOverCreationEvent";
		redirects[events + "CamMoveEvent"]					= events + "gameplay.CamMoveEvent";
		redirects[events + "CountdownEvent"]				= events + "gameplay.CountdownEvent";
		redirects[events + "EventGameEvent"]				= events + "gameplay.EventGameEvent";
		redirects[events + "GameOverEvent"]					= events + "gameplay.GameOverEvent";
		redirects[events + "RatingUpdateEvent"]				= events + "gameplay.RatingUpdateEvent";
		redirects[events + "HealthIconChangeEvent"]			= events + "healthicon.HealthIconChangeEvent";
		redirects[events + "FreeplayAlphaUpdateEvent"]		= events + "menu.freeplay.FreeplayAlphaUpdateEvent";
		redirects[events + "FreeplaySongSelectEvent"]		= events + "menu.freeplay.FreeplaySongSelectEvent";
		redirects[events + "MenuChangeEvent"]				= events + "menu.MenuChangeEvent";
		redirects[events + "PauseCreationEvent"]			= events + "menu.pause.PauseCreationEvent";
		redirects[events + "WeekSelectEvent"]				= events + "menu.storymenu.WeekSelectEvent";
		redirects[events + "InputSystemEvent"]				= events + "note.InputSystemEvent";
		redirects[events + "NoteCreationEvent"]				= events + "note.NoteCreationEvent";
		redirects[events + "NoteHitEvent"]					= events + "note.NoteHitEvent";
		redirects[events + "NoteMissEvent"]					= events + "note.NoteMissEvent";
		redirects[events + "NoteUpdateEvent"]				= events + "note.NoteUpdateEvent";
		redirects[events + "SimpleNoteEvent"]				= events + "note.SimpleNoteEvent";
		redirects[events + "StrumCreationEvent"]			= events + "note.StrumCreationEvent";
		redirects[events + "SplashShowEvent"]				= events + "splash.SplashShowEvent";
		redirects[events + "PlayAnimContext"]				= events + "sprite.PlayAnimContext";
		redirects[events + "PlayAnimEvent"]					= events + "sprite.PlayAnimEvent";
		redirects[events + "StageNodeEvent"]				= events + "stage.StageNodeEvent";
		redirects[events + "StageXMLEvent"]					= events + "stage.StageXMLEvent";

		// Old State Names
		redirects["funkin.menus.BetaWarningState"] 			= "funkin.menus.WarningState";

		return redirects;
	}

	/**
	 * Gets the default defines for a script.
	 * Includes all of the defines that the build was compiled with.
	 */
	public static function getDefaultPreprocessors():Map<String, Dynamic> {
		var defines = funkin.backend.system.macros.DefinesMacro.defines;
		defines.set("CODENAME_ENGINE", true);
		defines.set("CODENAME_VER", Flags.VERSION);
		defines.set("CODENAME_BUILD", 2675); // 2675 being the last build num before it was removed
		defines.set("CODENAME_COMMIT", Flags.COMMIT_NUMBER);
		return defines;
	}
	/**
	 * All available script extensions
	 */
	public static var scriptExtensions:Array<String> = [
		"hx", "hscript", "hsc", "hxs",
		"pack", // combined file
		"lua" /** ACTUALLY NOT SUPPORTED, ONLY FOR THE MESSAGE **/
	];

	/**
	 * Currently executing script.
	 */
	public static var curScript:Script = null;

	/**
	 * Script name (with extension)
	 */
	public var fileName:String;

	/**
	 * Script Extension
	 */
	public var extension:String;

	/**
	 * Path to the script.
	 */
	public var path:String = null;

	private var rawPath:String = null;

	private var didLoad:Bool = false;

	/**
	 * Remapped filenames.
	 * Used for trace messages, to show what mod the script is from.
	 */
	public var remappedNames:Map<String, String> = [];

	/**
	 * Creates a script from the specified asset path. The language is automatically determined.
	 * @param path Path in assets
	 */
	public static function create(path:String):Script {
		if (Assets.exists(path)) {
			return switch(Path.extension(path).toLowerCase()) {
				case "hx" | "hscript" | "hsc" | "hxs":
					new HScript(path);
				case "pack":
					var arr = Assets.getText(path).split("________PACKSEP________");
					fromString(arr[1], arr[0]);
				case "lua":
					Logs.error("Lua is not supported in this engine. Use HScript instead.");
					new DummyScript(path);
				default:
					new DummyScript(path);
			}
		}
		return new DummyScript(path);
	}

	/**
	 * Creates a script from the string. The language is determined based on the path.
	 * @param code code
	 * @param path filename
	 */
	public static function fromString(code:String, path:String):Script {
		return switch(Path.extension(path).toLowerCase()) {
			case "hx" | "hscript" | "hsc" | "hxs":
				new HScript(path).loadFromString(code);
			case "lua":
				Logs.error("Lua is not supported in this engine. Use HScript instead.");
				new DummyScript(path).loadFromString(code);
			default:
				new DummyScript(path).loadFromString(code);
		}
	}

	/**
	 * Creates a new instance of the script class.
	 * @param path
	 */
	public function new(path:String) {
		super();

		rawPath = path;
		path = Paths.getFilenameFromLibFile(path);

		fileName = Path.withoutDirectory(path);
		extension = Path.extension(path);
		this.path = path;
		onCreate(path);
		for(k=>e in getDefaultVariables(this)) {
			set(k, e);
		}
		set("disableScript", () -> {
			active = false;
		});
		set("__script__", this);
	}


	/**
	 * Loads the script
	 */
	public function load() {
		if(didLoad) return;

		var oldScript = curScript;
		curScript = this;
		onLoad();
		curScript = oldScript;

		didLoad = true;
	}

	/**
	 * HSCRIPT ONLY FOR NOW
	 * Sets the "public" variables map for ScriptPack
	 */
	public function setPublicMap(map:Map<String, Dynamic>) {

	}

	/**
	 * Hot-reloads the script, if possible
	 */
	public function reload() {

	}

	/**
	 * Traces something as this script.
	 */
	public function trace(v:Dynamic) {
		var fileName = this.fileName;
		if(remappedNames.exists(fileName))
			fileName = remappedNames.get(fileName);
		Logs.traceColored([
			Logs.logText(fileName + ': ', GREEN),
			Logs.logText(Std.string(v))
		], TRACE);
	}


	/**
	 * Calls the function `func` defined in the script.
	 * @param func Name of the function
	 * @param parameters (Optional) Parameters of the function.
	 * @return Result (if void, then null)
	 */
	public function call(func:String, ?parameters:Array<Dynamic>):Dynamic {
		var oldScript = curScript;
		curScript = this;

		var result = onCall(func, parameters == null ? [] : parameters);

		curScript = oldScript;
		return result;
	}

	/**
	 * Loads the code from a string, doesn't really work after the script has been loaded
	 * @param code The code.
	 */
	public function loadFromString(code:String) {
		return this;
	}

	/**
	 * Sets a script's parent object so that its properties can be accessed easily. Ex: Passing `PlayState.instance` will allow `boyfriend` to be typed instead of `PlayState.instance.boyfriend`.
	 * @param variable Parent variable.
	 */
	public function setParent(variable:Dynamic) {}

	/**
	 * Gets the variable `variable` from the script's variables.
	 * @param variable Name of the variable.
	 * @return Variable (or null if it doesn't exists)
	 */
	public function get(variable:String):Dynamic {return null;}

	/**
	 * Sets the variable `variable` from the script's variables.
	 * @param variable Name of the variable.
	 * @return Variable (or null if it doesn't exists)
	 */
	public function set(variable:String, value:Dynamic):Void {}

	/**
	 * Shows an error from this script.
	 * @param text Text of the error (ex: Null Object Reference).
	 * @param additionalInfo Additional information you could provide.
	 */
	public function error(text:String, ?additionalInfo:Dynamic):Void {
		var fileName = this.fileName;
		if(remappedNames.exists(fileName))
			fileName = remappedNames.get(fileName);
		Logs.traceColored([
			Logs.logText(fileName, RED),
			Logs.logText(text)
		], ERROR);
	}

	override public function toString():String {
		return FlxStringUtil.getDebugString(didLoad ? [
			LabelValuePair.weak("path", path),
			LabelValuePair.weak("active", active),
		] : [
			LabelValuePair.weak("path", path),
			LabelValuePair.weak("active", active),
			LabelValuePair.weak("loaded", didLoad),
		]);
	}

	/**
	 * PRIVATE HANDLERS - DO NOT TOUCH
	 */
	private function onCall(func:String, parameters:Array<Dynamic>):Dynamic {
		return null;
	}
	/**
	 * Called when the script is created.
	 * @param path Path to the script
	 */
	public function onCreate(path:String) {}

	/**
	 * Called when the script is loaded.
	 */
	public function onLoad() {}
}
