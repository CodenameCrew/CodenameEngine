package funkin.backend.system;

import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.ui.FlxSoundTray;
import funkin.backend.assets.AssetSource;
import funkin.backend.assets.AssetsLibraryList;
import funkin.backend.assets.ModsFolder;
import funkin.backend.system.framerate.Framerate;
import funkin.backend.system.framerate.SystemInfo;
import funkin.backend.system.modules.*;
import funkin.backend.utils.ThreadUtil;
import funkin.editors.SaveWarning;
import funkin.options.PlayerSettings;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.text.TextFormat;
import openfl.utils.AssetLibrary;
import sys.FileSystem;
import sys.io.File;
#if android
import android.content.Context;
import android.os.Build;
#end

class Main extends Sprite
{
	public static var instance:Main;

	public static var modToLoad:String = null;
	public static var forceGPUOnlyBitmapsOff:Bool = #if desktop false #else true #end;
	public static var noTerminalColor:Bool = false;
	public static var verbose:Bool = false;

	public static var scaleMode:FunkinRatioScaleMode;
	#if !mobile
	public static var framerateSprite:Framerate;
	#end

	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels).
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var game:FunkinGame;

	/**
	 * The time since the game was focused last time in seconds.
	 */
	public static var timeSinceFocus(get, never):Float;
	public static var time:Int = 0;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function preInit() {
		funkin.backend.utils.NativeAPI.registerAsDPICompatible();
		funkin.backend.system.CommandLineHandler.parseCommandLine(Sys.args());
		funkin.backend.system.Main.fixWorkingDirectory();
	}

	public function new()
	{
		super();

		instance = this;

		CrashHandler.init();

		addChild(game = new FunkinGame(gameWidth, gameHeight, MainState, Options.framerate, Options.framerate, skipSplash, startFullscreen));

		#if (!mobile && !web)
		addChild(framerateSprite = new Framerate());
		SystemInfo.init();
		#end
	}

	@:dox(hide)
	public static var audioDisconnected:Bool = false;

	public static var changeID:Int = 0;
	public static var pathBack = #if (windows || linux)
			"../../../../"
		#elseif mac
			"../../../../../../../"
		#else
			"../../../../"
		#end;
	public static var startedFromSource:Bool = #if TEST_BUILD true #else false #end;

	// DEPRECATED
	@:dox(hide) public static function execAsync(func:Void->Void) ThreadUtil.execAsync(func);

	private static function getTimer():Int {
		return time = Lib.getTimer();
	}

	public static function loadGameSettings() {
		WindowUtils.init();
		SaveWarning.init();
		MemoryUtil.init();
		@:privateAccess
		FlxG.game.getTimer = getTimer;
		FunkinCache.init();
		Paths.assetsTree = new AssetsLibraryList();

		#if UPDATE_CHECKING
		funkin.backend.system.updating.UpdateUtil.init();
		#end
		ShaderResizeFix.init();
		Logs.init();
		Paths.init();

		hscript.Interp.importRedirects = funkin.backend.scripting.Script.getDefaultImportRedirects();

		#if GLOBAL_SCRIPT
		funkin.backend.scripting.GlobalScript.init();
		#end

		var lib = new AssetLibrary();
		@:privateAccess
		lib.__proxy = Paths.assetsTree;
		Assets.registerLibrary('default', lib);

		funkin.options.PlayerSettings.init();
		Options.load();

		FlxG.fixedTimestep = false;

		FlxG.scaleMode = scaleMode = new FunkinRatioScaleMode();

		Conductor.init();
		AudioSwitchFix.init();
		EventManager.init();
		FlxG.signals.focusGained.add(onFocus);
		FlxG.signals.preStateSwitch.add(onStateSwitch);
		FlxG.signals.postStateSwitch.add(onStateSwitchPost);
		FlxG.signals.postUpdate.add(onUpdate);

		FlxG.mouse.useSystemCursor = true;
		#if DARK_MODE_WINDOW
		if(funkin.backend.utils.NativeAPI.hasVersion("Windows 10")) funkin.backend.utils.NativeAPI.redrawWindowHeader();
		#end

		ModsFolder.init();
		#if MOD_SUPPORT
		if (FileSystem.exists("mods/autoload.txt"))
			modToLoad = File.getContent("mods/autoload.txt").trim();

		ModsFolder.switchMod(modToLoad.getDefault(Options.lastLoadedMod));
		#end

		initTransition();
	}

	public static function refreshAssets() @:privateAccess {
		FunkinCache.instance.clearSecondLayer();

		var game = FlxG.game;
		var daSndTray = Type.createInstance(game._customSoundTray = funkin.menus.ui.FunkinSoundTray, []);
		var index:Int = game.numChildren - 1;

		if(game.soundTray != null)
		{
			var newIndex:Int = game.getChildIndex(game.soundTray);
			if(newIndex != -1) index = newIndex;
			game.removeChild(game.soundTray);
			game.soundTray.__cleanup();
		}

		game.addChildAt(game.soundTray = daSndTray, index);
	}

	public static function initTransition() {
		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;

		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, 0xFF000000, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
			new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, 0xFF000000, 0.7, new FlxPoint(0, 1),
			{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
	}

	public static function onFocus() {
		_tickFocused = FlxG.game.ticks;
	}

	private static function onStateSwitch() {
		scaleMode.resetSize();
	}

	public static function onUpdate() {
		if (PlayerSettings.solo.controls.DEV_CONSOLE)
			NativeAPI.allocConsole();

		if (PlayerSettings.solo.controls.FPS_COUNTER)
			Framerate.debugMode = (Framerate.debugMode + 1) % 3;
	}

	private static function onStateSwitchPost() {
		// manual asset clearing since base openfl one does'nt clear lime one
		// does'nt clear bitmaps since flixel fork does it auto

		@:privateAccess {
			// clear uint8 pools
			for(length=>pool in openfl.display3D.utils.UInt8Buff._pools) {
				for(b in pool.clear())
					b.destroy();
			}

			openfl.display3D.utils.UInt8Buff._pools.clear();
		}

		MemoryUtil.clearMajor();
	}

	public static var noCwdFix:Bool = false;
	public static function fixWorkingDirectory() {
		#if windows
		if (!noCwdFix && !sys.FileSystem.exists('manifest/default.json')) {
			Sys.setCwd(haxe.io.Path.directory(Sys.programPath()));
		}
		#elseif android
		Sys.setCwd(haxe.io.Path.addTrailingSlash(VERSION.SDK_INT > 30 ? Context.getObbDir() : Context.getExternalFilesDir()));
		#elseif (ios || switch)
		Sys.setCwd(haxe.io.Path.addTrailingSlash(openfl.filesystem.File.applicationStorageDirectory.nativePath));
		#end
	}

	private static var _tickFocused:Float = 0;
	public static function get_timeSinceFocus():Float {
		return (FlxG.game.ticks - _tickFocused) / 1000;
	}
}
