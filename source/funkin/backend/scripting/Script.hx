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
class Script extends FlxBasic implements IFlxDestroyable
{
	/**
	 * Use "static var thing = true;" in hscript to use those!!
	 * are reset every mod switch so once you're done with them make sure to make them null!!
	 */
	public static var staticVariables:Map<String, Dynamic> = [];

	/**
	 * Gets the default variables for a script.
	 */
	public static function getDefaultVariables(?script:Script):Map<String, Dynamic>
	{
		var vars = _defaultVariablesTemplate != null ? _defaultVariablesTemplate : (_defaultVariablesTemplate = buildDefaultVariables());
		var copy = vars.copy();
		copy.set("state", flixel.FlxG.state); // `state` changes on state switch, so it can't be cached
		copy.set("window", lime.app.Application.current.window); // same for `window`: evaluated at script creation time like before
		return copy;
	}

	/**
	 * Cached template of the default variables.
	 * Built once (including the `Type.resolveClass` lookups) and shallow-copied per script.
	 */
	private static var _defaultVariablesTemplate:Map<String, Dynamic> = null;

	private static function buildDefaultVariables():Map<String, Dynamic>
	{
		return generateDefaultVariables();
	}

	private static macro function generateDefaultVariables():Expr
	{
		return macro [
			$a{getHaxeDefaultsVariables()},
			$a{getOpenFLDefaultsVariables()},
			$a{getFlixelDefaultsVariables()},
			$a{getFoxliteDefaultsVariables()},
			$a{getCNEDefaultsVariables()},
		];
	}

	// Haxe related stuff
	private static function getHaxeDefaultsVariables():Array<Expr>
	{
		return [
			macro "Std" => Std,
			macro "Math" => Math,
			macro "Reflect" => Reflect,
			macro "StringTools" => StringTools,
			macro "Json" => haxe.Json,
			macro "Xml" => Xml,
			macro "Type" => Type,
			macro "Date" => Date,
			macro "Lambda" => Lambda,
			#if sys macro "Sys" => Sys, #end
		];
	}

	// OpenFL related stuff
	private static function getOpenFLDefaultsVariables():Array<Expr>
	{
		return [
			macro "BlendMode" => CoolUtil.getMacroAbstractClass("openfl.display.BlendMode"),
			macro "Assets" => openfl.utils.Assets,
			macro "Application" => lime.app.Application,
			macro "Main" => funkin.backend.system.Main,
		];
	}

	// Flixel related stuff
	private static function getFlixelDefaultsVariables():Array<Expr>
	{
		return [
			macro "FlxG" => flixel.FlxG,
			macro "FlxSprite" => flixel.FlxSprite,
			macro "FlxBasic" => flixel.FlxBasic,
			macro "FlxCamera" => flixel.FlxCamera,
			macro "FlxEase" => flixel.tweens.FlxEase,
			macro "FlxTween" => flixel.tweens.FlxTween,
			macro "FlxSound" => flixel.sound.FlxSound,
			macro "FlxAssets" => flixel.system.FlxAssets,
			macro "FlxMath" => flixel.math.FlxMath,
			macro "FlxGroup" => flixel.group.FlxGroup,
			macro "FlxTypedGroup" => flixel.group.FlxGroup.FlxTypedGroup,
			macro "FlxSpriteGroup" => flixel.group.FlxSpriteGroup,
			macro "FlxTypeText" => flixel.addons.text.FlxTypeText,
			macro "FlxText" => flixel.text.FlxText,
			macro "FlxTimer" => flixel.util.FlxTimer,
			macro "FlxPoint" => CoolUtil.getMacroAbstractClass("flixel.math.FlxPoint"),
			macro "FlxAxes" => CoolUtil.getMacroAbstractClass("flixel.util.FlxAxes"),
			macro "FlxColor" => CoolUtil.getMacroAbstractClass("flixel.util.FlxColor"),
		];
	}

	// Foxlite related stuff
	private static function getFoxliteDefaultsVariables():Array<Expr>
	{
		return [
			macro "FoxScene" => foxlite.FoxScene,
			macro "FoxCamera" => foxlite.FoxCamera,
			macro "FoxFPSCamera" => foxlite.extras.FoxFPSCamera,
			macro "FoxRenderer" => foxlite.renderer.FoxRenderer,
			macro "FoxLoaderUtil" => foxlite.loaders.FoxLoaderUtil,
			macro "FoxModel" => foxlite.FoxModel,
			macro "FoxQuadMesh" => foxlite.mesh.FoxQuadMesh,
			macro "FoxCubeMesh" => foxlite.mesh.FoxCubeMesh,
			macro "FoxMaterial" => foxlite.material.FoxMaterial,
			macro "FoxShader" => foxlite.FoxShader,
			macro "FoxTexture" => foxlite.texture.FoxTexture,
			macro "FoxCache" => foxlite.FoxCache,
			macro "FoxRenderMetrics" => foxlite.flixel.FoxRenderMetrics,
			macro "FoxFunkinSprite" => foxlite.funkin.FoxFunkinSprite,
			macro "FoxFlxSprite" => foxlite.flixel.FoxFlxSprite,
			macro "FoxPanoramaSky" => foxlite.sky.FoxPanoramaSky,
			macro "FoxStencilAction" => foxlite.stencil.FoxStencilAction,
			macro "FoxOBJLoader" => foxlite.loaders.FoxOBJLoader,
			macro "FoxMTLLoader" => foxlite.loaders.FoxMTLLoader,
			macro "FoxDirectionalLight" => foxlite.lights.FoxDirectionalLight,
			macro "FoxLayer" => CoolUtil.getMacroAbstractClass("foxlite.FoxLayer"),
			macro "FoxEaseType" => CoolUtil.getMacroAbstractClass("foxlite.animation.FoxEaseType"),
			macro "FoxInstanceUpdateMode" => CoolUtil.getMacroAbstractClass("foxlite.instancing.FoxInstanceUpdateMode"),
			macro "FoxAreaLightShape" => CoolUtil.getMacroAbstractClass("foxlite.lights.FoxAreaLightShape"),
			macro "FoxLightType" => CoolUtil.getMacroAbstractClass("foxlite.lights.FoxLightType"),
			macro "FoxBlendMode" => CoolUtil.getMacroAbstractClass("foxlite.material.FoxBlendMode"),
			macro "FoxDepthCompareMode" => CoolUtil.getMacroAbstractClass("foxlite.material.FoxDepthCompareMode"),
			macro "FoxStencilCompareMode" => CoolUtil.getMacroAbstractClass("foxlite.stencil.FoxStencilCompareMode"),
			macro "FoxTriangleFace" => CoolUtil.getMacroAbstractClass("foxlite.material.FoxTriangleFace"),
			macro "FoxMeshBufferType" => CoolUtil.getMacroAbstractClass("foxlite.mesh.FoxMeshBufferType"),
			macro "FoxQuadFace" => CoolUtil.getMacroAbstractClass("foxlite.mesh.FoxQuadFace"),
			macro "FoxStencilActionType" => CoolUtil.getMacroAbstractClass("foxlite.stencil.FoxStencilActionType"),
			macro "FoxCubemapSide" => CoolUtil.getMacroAbstractClass("foxlite.texture.FoxCubemapSide"),
			macro "FoxMipFilter" => CoolUtil.getMacroAbstractClass("foxlite.texture.FoxMipFilter"),
			macro "FoxTextureFilter" => CoolUtil.getMacroAbstractClass("foxlite.texture.FoxTextureFilter"),
			macro "FoxWrapMode" => CoolUtil.getMacroAbstractClass("foxlite.texture.FoxWrapMode"),
		];
	}

	private static function getCNEDefaultsVariables():Array<Expr>
	{
		return [
			macro "engine" => {
				commit: Flags.COMMIT_NUMBER,
				hash: Flags.COMMIT_HASH,
				build: 2675, // 2675 being the last build num before it was removed
				name: "Codename Engine"
			},
			macro "ModState" => funkin.backend.scripting.ModState,
			macro "ModSubState" => funkin.backend.scripting.ModSubState,
			macro "PlayState" => funkin.game.PlayState,
			macro "GameOverSubstate" => funkin.game.GameOverSubstate,
			macro "HealthIcon" => funkin.game.HealthIcon,
			macro "HudCamera" => funkin.game.HudCamera,
			macro "Note" => funkin.game.Note,
			macro "Strum" => funkin.game.Strum,
			macro "StrumLine" => funkin.game.StrumLine,
			macro "Character" => funkin.game.Character,
			macro "Boyfriend" => funkin.game.Character, // for compatibility
			macro "PauseSubState" => funkin.menus.PauseSubState,
			macro "PauseSubstate" => funkin.menus.PauseSubState, // miss-spelling
			macro "FreeplayState" => funkin.menus.FreeplayState,
			macro "MainMenuState" => funkin.menus.MainMenuState,
			macro "StoryMenuState" => funkin.menus.StoryMenuState,
			macro "TitleState" => funkin.menus.TitleState,
			macro "Options" => funkin.options.Options,
			macro "Paths" => funkin.backend.assets.Paths,
			macro "Conductor" => funkin.backend.system.Conductor,
			macro "FunkinShader" => funkin.backend.shaders.FunkinShader,
			macro "CustomShader" => funkin.backend.shaders.CustomShader, // deprecated
			macro "FunkinText" => funkin.backend.FunkinText,
			macro "FlxAnimate" => animate.FlxAnimate,
			macro "FunkinSprite" => funkin.backend.FunkinSprite,
			macro "Alphabet" => funkin.menus.ui.Alphabet,
			macro "Flags" => funkin.backend.system.Flags,

			macro "CoolUtil" => funkin.backend.utils.CoolUtil,
			macro "IniUtil" => funkin.backend.utils.IniUtil,
			macro "XMLUtil" => funkin.backend.utils.XMLUtil,
			#if sys macro "ZipUtil" => funkin.backend.utils.ZipUtil, #end
			macro "MarkdownUtil" => funkin.backend.utils.MarkdownUtil,
			macro "EngineUtil" => funkin.backend.utils.EngineUtil,
			macro "ThreadUtil" => funkin.backend.utils.ThreadUtil,
			macro "MemoryUtil" => funkin.backend.utils.MemoryUtil,
			macro "BitmapUtil" => funkin.backend.utils.BitmapUtil,

			#if TRANSLATIONS_SUPPORT
			macro "TranslationUtil" => funkin.backend.utils.TranslationUtil, macro "translate" => funkin.backend.utils.TranslationUtil.get,
			#end
		];
	}

	/**
	 * Used internally to keep backwards compatibility with old scripts.
	 * This gets set on `hscript.Interp.importRedirects`,
	 * if you wanna modify it, please edit `hscript.Interp.importRedirects` directly.
	**/
	public static function getDefaultImportRedirects():Map<String, String>
	{
		var redirects:Map<String, String> = [];

		// Events
		final events = "funkin.backend.scripting.events.";
		redirects[events + "CharacterNodeEvent"] = events + "character.CharacterNodeEvent";
		redirects[events + "CharacterXMLEvent"] = events + "character.CharacterXMLEvent";
		redirects[events + "DanceEvent"] = events + "character.DanceEvent";
		redirects[events + "DirectionAnimEvent"] = events + "character.DirectionAnimEvent";
		redirects[events + "DiscordPresenceUpdateEvent"] = events + "discord.DiscordPresenceUpdateEvent";
		redirects[events + "GameOverCreationEvent"] = events + "gameover.GameOverCreationEvent";
		redirects[events + "CamMoveEvent"] = events + "gameplay.CamMoveEvent";
		redirects[events + "CountdownEvent"] = events + "gameplay.CountdownEvent";
		redirects[events + "EventGameEvent"] = events + "gameplay.EventGameEvent";
		redirects[events + "GameOverEvent"] = events + "gameplay.GameOverEvent";
		redirects[events + "RatingUpdateEvent"] = events + "gameplay.RatingUpdateEvent";
		redirects[events + "HealthIconChangeEvent"] = events + "healthicon.HealthIconChangeEvent";
		redirects[events + "FreeplayAlphaUpdateEvent"] = events + "menu.freeplay.FreeplayAlphaUpdateEvent";
		redirects[events + "FreeplaySongSelectEvent"] = events + "menu.freeplay.FreeplaySongSelectEvent";
		redirects[events + "MenuChangeEvent"] = events + "menu.MenuChangeEvent";
		redirects[events + "PauseCreationEvent"] = events + "menu.pause.PauseCreationEvent";
		redirects[events + "WeekSelectEvent"] = events + "menu.storymenu.WeekSelectEvent";
		redirects[events + "InputSystemEvent"] = events + "note.InputSystemEvent";
		redirects[events + "NoteCreationEvent"] = events + "note.NoteCreationEvent";
		redirects[events + "NoteHitEvent"] = events + "note.NoteHitEvent";
		redirects[events + "NoteMissEvent"] = events + "note.NoteMissEvent";
		redirects[events + "NoteUpdateEvent"] = events + "note.NoteUpdateEvent";
		redirects[events + "SimpleNoteEvent"] = events + "note.SimpleNoteEvent";
		redirects[events + "StrumCreationEvent"] = events + "note.StrumCreationEvent";
		redirects[events + "SplashShowEvent"] = events + "splash.SplashShowEvent";
		redirects[events + "PlayAnimContext"] = events + "sprite.PlayAnimContext";
		redirects[events + "PlayAnimEvent"] = events + "sprite.PlayAnimEvent";
		redirects[events + "StageNodeEvent"] = events + "stage.StageNodeEvent";
		redirects[events + "StageXMLEvent"] = events + "stage.StageXMLEvent";

		// Old State Names
		redirects["funkin.menus.BetaWarningState"] = "funkin.menus.WarningState";

		return redirects;
	}

	/**
	 * Gets the default defines for a script.
	 * Includes all of the defines that the build was compiled with.
	 */
	public static function getDefaultPreprocessors():Map<String, Dynamic>
	{
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
		"hx",
		"hscript",
		"hsc",
		"hxs",
		"pack", // combined file
		"lua" /** ACTUALLY NOT SUPPORTED, ONLY FOR THE MESSAGE **/];

	/**
	 * Currently executing script.
	 */
	public static var curScript:Script = null;

	/**
	 * Shared empty argument array, used when calling scripts without parameters (avoids allocations).
	 */
	private static var _EMPTY_ARGS:Array<Dynamic> = [];

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
	public static function create(path:String):Script
	{
		if (Assets.exists(path))
		{
			return switch (Path.extension(path).toLowerCase())
			{
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
	public static function fromString(code:String, path:String):Script
	{
		return switch (Path.extension(path).toLowerCase())
		{
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
	public function new(path:String)
	{
		super();

		rawPath = path;
		path = Paths.getFilenameFromLibFile(path);

		fileName = Path.withoutDirectory(path);
		extension = Path.extension(path);
		this.path = path;
		onCreate(path);
		for (k => e in getDefaultVariables(this))
		{
			set(k, e);
		}
		set("disableScript", () ->
		{
			active = false;
		});
		set("__script__", this);
	}

	/**
	 * Loads the script
	 */
	public function load()
	{
		if (didLoad)
			return;

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
	public function setPublicMap(map:Map<String, Dynamic>)
	{
	}

	/**
	 * Hot-reloads the script, if possible
	 */
	public function reload()
	{
	}

	/**
	 * Traces something as this script.
	 */
	public function trace(v:Dynamic)
	{
		var fileName = this.fileName;
		if (remappedNames.exists(fileName))
			fileName = remappedNames.get(fileName);
		Logs.traceColored([Logs.logText(fileName + ': ', GREEN), Logs.logText(Std.string(v))], TRACE);
	}

	/**
	 * Calls the function `func` defined in the script.
	 * @param func Name of the function
	 * @param parameters (Optional) Parameters of the function.
	 * @return Result (if void, then null)
	 */
	public function call(func:String, ?parameters:Array<Dynamic>):Dynamic
	{
		var oldScript = curScript;
		curScript = this;

		var result = onCall(func, parameters);

		curScript = oldScript;
		return result;
	}

	/**
	 * Loads the code from a string, doesn't really work after the script has been loaded
	 * @param code The code.
	 */
	public function loadFromString(code:String)
	{
		return this;
	}

	/**
	 * Sets a script's parent object so that its properties can be accessed easily. Ex: Passing `PlayState.instance` will allow `boyfriend` to be typed instead of `PlayState.instance.boyfriend`.
	 * @param variable Parent variable.
	 */
	public function setParent(variable:Dynamic)
	{
	}

	/**
	 * Gets the variable `variable` from the script's variables.
	 * @param variable Name of the variable.
	 * @return Variable (or null if it doesn't exists)
	 */
	public function get(variable:String):Dynamic
	{
		return null;
	}

	/**
	 * Sets the variable `variable` from the script's variables.
	 * @param variable Name of the variable.
	 * @return Variable (or null if it doesn't exists)
	 */
	public function set(variable:String, value:Dynamic):Void
	{
	}

	/**
	 * Shows an error from this script.
	 * @param text Text of the error (ex: Null Object Reference).
	 * @param additionalInfo Additional information you could provide.
	 */
	public function error(text:String, ?additionalInfo:Dynamic):Void
	{
		var fileName = this.fileName;
		if (remappedNames.exists(fileName))
			fileName = remappedNames.get(fileName);
		Logs.traceColored([Logs.logText(fileName, RED), Logs.logText(text)], ERROR);
	}

	override public function toString():String
	{
		return FlxStringUtil.getDebugString(didLoad ? [LabelValuePair.weak("path", path), LabelValuePair.weak("active", active),] : [
			LabelValuePair.weak("path", path),
			LabelValuePair.weak("active", active),
			LabelValuePair.weak("loaded", didLoad),
		]);
	}

	/**
	 * PRIVATE HANDLERS - DO NOT TOUCH
	 */
	private function onCall(func:String, parameters:Array<Dynamic>):Dynamic
	{
		return null;
	}

	/**
	 * Called when the script is created.
	 * @param path Path to the script
	 */
	public function onCreate(path:String)
	{
	}

	/**
	 * Called when the script is loaded.
	 */
	public function onLoad()
	{
	}
}
