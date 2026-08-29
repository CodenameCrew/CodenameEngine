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
import funkin.backend.system.console.ConsoleUI;
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
import extension.androidtools.content.Context;
import extension.androidtools.os.Build;
#end

#if IMGUI_ENABLED
import lime.tools.imgui.ImGuiFlags;
import lime.tools.imgui.ImGuiTypes;
#end

class Main extends Sprite
{
	public static var instance:Main;

	public static var modToLoad:String = null;
	public static var forceGPUOnlyBitmapsOff:Bool = false;
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
		#if sys
		funkin.backend.utils.NativeAPI.registerAsDPICompatible();
		funkin.backend.system.CommandLineHandler.parseCommandLine(Sys.args());
		funkin.backend.system.Main.fixWorkingDirectory();
		#end
	}

	public function new()
	{
		super();

		instance = this;

		#if IMGUI_ENABLED
		initImGui();
		addChild(ImGuiHandler.instance);
		#end
		CrashHandler.init();
		ConsoleUI.init();

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

	public static function loadGameSettings() {
		WindowUtils.init();
		SaveWarning.init();
		MemoryUtil.init();
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

		game.focusLostFramerate = 30;
		FlxG.fixedTimestep = false;
		FlxG.scaleMode = scaleMode = new FunkinRatioScaleMode();

		Conductor.init();
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
		#if !IMGUI_ENABLED
		if (PlayerSettings.solo.controls.DEV_CONSOLE)
			NativeAPI.allocConsole();
		#end

		if (PlayerSettings.solo.controls.FPS_COUNTER)
			Framerate.debugMode = (Framerate.debugMode + 1) % 3;
	}

	private static function onStateSwitchPost() {
		// manual asset clearing since base openfl one does'nt clear lime one
		// does'nt clear bitmaps since flixel fork does it auto

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

	private static function initImGui() {
		#if IMGUI_ENABLED
		//codename styled
		var vcrFont = ImGuiIO.fonts.addFontFromFileTTF("assets/fonts/vcr.ttf");
		ImGuiIO.fontDefault = vcrFont;
		var style = ImGui.getStyle();
		style.windowBorderSize = 2;
		style.childBorderSize = 2;
		style.popupBorderSize = 2;
		style.frameBorderSize = 2;
		style.windowRounding = 6;
		style.childRounding = 6;
		style.popupRounding = 6;
		style.frameRounding = 6;
		style.scrollbarRounding = 6;
		style.grabRounding = 6;
		style.setColor(ImGuiCol.WindowBg,               new ImVec4(0.11, 0.00, 0.16, 0.8));
		style.setColor(ImGuiCol.Border,                 new ImVec4(0.59, 0.59, 0.59, 0.50));
		style.setColor(ImGuiCol.FrameBg,                new ImVec4(0.13, 0.00, 0.19, 0.54));
		style.setColor(ImGuiCol.FrameBgHovered,         new ImVec4(0.33, 0.15, 0.42, 0.40));
		style.setColor(ImGuiCol.FrameBgActive,          new ImVec4(0.33, 0.15, 0.42, 0.67));
		style.setColor(ImGuiCol.TitleBg,                new ImVec4(0.38, 0.36, 0.40, 0.32));
		style.setColor(ImGuiCol.TitleBgActive,          new ImVec4(0.38, 0.36, 0.40, 0.72));
		style.setColor(ImGuiCol.CheckMark,              new ImVec4(0.80, 0.60, 1.00, 1.00));
		style.setColor(ImGuiCol.SliderGrab,             new ImVec4(0.33, 0.30, 0.35, 1.00));
		style.setColor(ImGuiCol.SliderGrabActive,       new ImVec4(0.80, 0.60, 1.00, 1.00));
		style.setColor(ImGuiCol.Button,                 new ImVec4(0.14, 0.13, 0.13, 0.99));
		style.setColor(ImGuiCol.ButtonHovered,          new ImVec4(0.39, 0.00, 0.59, 1.00));
		style.setColor(ImGuiCol.ButtonActive,           new ImVec4(0.76, 0.00, 1.00, 1.00));
		style.setColor(ImGuiCol.Header,                 new ImVec4(0.15, 0.13, 0.13, 0.8));
		style.setColor(ImGuiCol.HeaderHovered,          new ImVec4(0.39, 0.00, 0.59, 0.80));
		style.setColor(ImGuiCol.HeaderActive,           new ImVec4(0.76, 0.00, 1.00, 1.00));
		style.setColor(ImGuiCol.SeparatorHovered,       new ImVec4(0.39, 0.00, 0.59, 0.78));
		style.setColor(ImGuiCol.SeparatorActive,        new ImVec4(0.76, 0.00, 1.00, 1.00));
		style.setColor(ImGuiCol.ResizeGrip,             new ImVec4(0.15, 0.13, 0.13, 0.20));
		style.setColor(ImGuiCol.ResizeGripHovered,      new ImVec4(0.39, 0.00, 0.59, 0.67));
		style.setColor(ImGuiCol.ResizeGripActive,       new ImVec4(0.76, 0.00, 1.00, 0.95));
		style.setColor(ImGuiCol.InputTextCursor,        new ImVec4(0.68, 0.13, 0.96, 1.00));
		style.setColor(ImGuiCol.TabHovered,             new ImVec4(0.39, 0.00, 0.59, 0.80));
		style.setColor(ImGuiCol.Tab,                    new ImVec4(0.21, 0.19, 0.19, 0.86));
		style.setColor(ImGuiCol.TabSelected,            new ImVec4(0.76, 0.00, 1.00, 1.00));
		style.setColor(ImGuiCol.TabSelectedOverline,    new ImVec4(0.76, 0.00, 1.00, 1.00));
		style.setColor(ImGuiCol.TabDimmed,              new ImVec4(0.36, 0.18, 0.41, 1.00));
		style.setColor(ImGuiCol.TabDimmedSelected,      new ImVec4(0.46, 0.21, 0.54, 1.00));
		style.setColor(ImGuiCol.DockingPreview,         new ImVec4(0.56, 0.11, 0.71, 1.00));

		ImGuiHandler.instance.addCallback(function() {
			ImGui.dockSpaceOverViewport(0, null, ImGuiDockNodeFlags.PassthruCentralNode);
		});
		#end
	}
}
