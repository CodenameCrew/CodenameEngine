package funkin.backend.system.framerate;

import funkin.backend.system.Logs;
import funkin.backend.utils.MemoryUtil;
import funkin.backend.utils.native.HiddenProcess;
import funkin.backend.system.macros.GitCommitMacro;
import funkin.backend.assets.AssetsLibraryList;
import funkin.backend.assets.IModsAssetLibrary;
import funkin.backend.assets.ScriptedAssetLibrary;
import funkin.backend.scripting.ModState;
import funkin.options.Options;

import flixel.math.FlxPoint;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.Lib;
import openfl.events.Event;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFormat;

#if TRANSLATIONS_SUPPORT
import funkin.backend.assets.TranslatedAssetLibrary;
#end

#if cpp
import cpp.Float64;
import cpp.UInt64;
#end

#if (gl_stats && !disable_cffi && (!html5 || !canvas))
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end

using StringTools;

class FramerateCategory extends Sprite {
	public var title:TextField;
	public var text:TextField;
	public var bgSprite:Bitmap;

	public var offsetX:Float = 4;
	public var offsetY:Float = 10;

	private var _text:String = "";

	public function new(title:String, text:String = "") {
		super();

		this.title = new TextField();
		this.text = new TextField();

		bgSprite = new Bitmap(Framerate.__bitmap);
		bgSprite.alpha = 0.5;
		addChild(bgSprite);

		for(label in [this.title, this.text]) {
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.defaultTextFormat = new TextFormat(Framerate.fontName, label == this.title ? 18 : 12, -1);
			label.selectable = false;
			addChild(label);
		}
		this.title.text = title;
		this.title.multiline = this.title.wordWrap = false;
		this.text.multiline = true;

		this.text.y = this.title.y + this.title.height + 2;

		updateScale();
		addEventListener(Event.ADDED_TO_STAGE, function(_) {
			stage.addEventListener(Event.RESIZE, onResize);
		});
	}

	function onResize(_) updateScale();

	function updateScale() {
		var userScale:Float = Options.fpsSize;
		var screenScale = Math.min(Lib.current.stage.stageWidth / 1280, Lib.current.stage.stageHeight / 720);
		scaleX = scaleY = userScale * screenScale;
	}

	public function reload() {}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		updateScale();
		super.__enterFrame(t);

		if (flixel.FlxG.game != null) {
			this.x = flixel.FlxG.game.x + (offsetX * scaleX);
			this.y = flixel.FlxG.game.y + (offsetY * scaleY);
		}

		var width = Math.max(this.title.width, this.text.width) + (Framerate.instance.x * 2);
		var height = this.text.height + this.text.y;
		bgSprite.x = -Framerate.instance.x;
		bgSprite.scaleX = width;
		bgSprite.scaleY = height;
	}
}

class SystemInfo extends FramerateCategory {
	public static var osInfo:String = "Unknown";
	public static var gpuName:String = "Unknown";
	public static var vRAM:String = "Unknown";
	public static var cpuName:String = "Unknown";
	public static var totalMem:String = "Unknown";
	public static var memType:String = "Unknown";
	public static var gpuMaxSize:String = "Unknown";

	static var __formattedSysText:String = "";

	public static function init() {
		#if linux
		var process = new HiddenProcess("cat", ["/etc/os-release"]);
		if (process.exitCode() != 0) Logs.error('Unable to grab OS Label');
		else {
			var osName = "";
			var osVersion = "";
			for (line in process.stdout.readAll().toString().split("\n")) {
				if (line.startsWith("PRETTY_NAME=")) {
					var index = line.indexOf('"');
					if (index != -1) osName = line.substring(index + 1, line.lastIndexOf('"'));
					else {
						var arr = line.split("=");
						arr.shift();
						osName = arr.join("=");
					}
				}
				if (line.startsWith("VERSION=")) {
					var index = line.indexOf('"');
					if (index != -1) osVersion = line.substring(index + 1, line.lastIndexOf('"'));
					else {
						var arr = line.split("=");
						arr.shift();
						osVersion = arr.join("=");
					}
				}
			}
			if (osName != "") osInfo = '${osName} ${osVersion}'.trim();
		}
		#elseif windows
		var windowsCurrentVersionPath = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion";
		var buildNumber = Std.parseInt(RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, "CurrentBuildNumber"));
		var edition = RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, "ProductName");
		var lcuKey = (buildNumber >= 22000) ? "LCUVer" : "WinREVersion";
		if (buildNumber >= 22000) edition = edition.replace("Windows 10", "Windows 11");

		var lcuVersion = RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, lcuKey);
		osInfo = edition;
		if (lcuVersion != null && lcuVersion != "") osInfo += ' ${lcuVersion}';
		else if (lime.system.System.platformVersion != null && lime.system.System.platformVersion != "") osInfo += ' ${lime.system.System.platformVersion}';
		#else
		if (lime.system.System.platformLabel != null && lime.system.System.platformLabel != "" && lime.system.System.platformVersion != null && lime.system.System.platformVersion != "")
			osInfo = '${lime.system.System.platformLabel.replace(lime.system.System.platformVersion, "").trim()} ${lime.system.System.platformVersion}';
		else Logs.error('Unable to grab OS Label');
		#end

		try {
			#if windows cpuName = RegistryUtil.get(HKEY_LOCAL_MACHINE, "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0", "ProcessorNameString");
			#elseif mac
			var process = new HiddenProcess("sysctl -a | grep brand_string");
			if (process.exitCode() == 0) cpuName = process.stdout.readAll().toString().trim().split(":")[1].trim();
			#elseif linux
			var process = new HiddenProcess("cat", ["/proc/cpuinfo"]);
			for (line in process.stdout.readAll().toString().split("\n")) {
				if (line.indexOf("model name") == 0) { cpuName = line.substring(line.indexOf(":") + 2); break; }
			}
			#end
		} catch (e) { Logs.error('Unable to grab CPU Name: $e'); }

		@:privateAccess if(flixel.FlxG.renderTile) {
			if (flixel.FlxG.stage.context3D != null && flixel.FlxG.stage.context3D.gl != null) {
				gpuName = Std.string(flixel.FlxG.stage.context3D.gl.getParameter(flixel.FlxG.stage.context3D.gl.RENDERER)).split("/")[0].trim();
				#if !flash
				var size = flixel.FlxG.bitmap.maxTextureSize;
				gpuMaxSize = size+"x"+size;
				#end
				if(openfl.display3D.Context3D.__glMemoryTotalAvailable != -1) {
					var vRAMBytes:Int = cast flixel.FlxG.stage.context3D.gl.getParameter(openfl.display3D.Context3D.__glMemoryTotalAvailable);
					if (vRAMBytes > 1000) vRAM = getSizeString(vRAMBytes / 1024);
				}
			}
		}
		#if cpp totalMem = Std.string(MemoryUtil.getTotalMem() / 1024) + " GB"; #end
		try { memType = MemoryUtil.getMemType(); } catch (e) {}
		formatSysInfo();
	}

	static function formatSysInfo() {
		__formattedSysText = "";
		if (osInfo != "Unknown") __formattedSysText += 'System: $osInfo';
		if (cpuName != "Unknown") __formattedSysText += '\nCPU: $cpuName ${openfl.system.Capabilities.cpuArchitecture} ${(openfl.system.Capabilities.supports64BitProcesses ? '64-Bit' : '32-Bit')}';
		if (gpuName != "Unknown" || vRAM != "Unknown") {
			__formattedSysText += "\n";
			if(gpuName != "Unknown") __formattedSysText += 'GPU: $gpuName';
			if(gpuName != "Unknown" && vRAM != "Unknown") __formattedSysText += " | ";
			if(vRAM != "Unknown") __formattedSysText += 'VRAM: $vRAM';
		}
		if (totalMem != "Unknown" && memType != "Unknown") __formattedSysText += '\nTotal MEM: $totalMem $memType';
	}

	static function getSizeString(size:Float):String {
		if (size < 1024) return Std.int(size) + " MB";
		if (size < 1024 * 1024) return Std.int(size / 1024) + " GB";
		var tb = size / (1024 * 1024);
		return Std.int(tb) + "." + CoolUtil.addZeros(Std.string(Std.int((tb % 1) * 100)), 2) + " TB";
	}

	public function new() { super("System Info"); }

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		_text = __formattedSysText;
		_text += '${__formattedSysText == "" ? "" : "\n"}Garbage Collector: ${MemoryUtil.disableCount > 0 ? "OFF" : "ON"} (${MemoryUtil.disableCount})';
		this.text.text = _text;
		super.__enterFrame(t);
	}
}

class AssetTreeInfo extends FramerateCategory {
	private var lastUpdateTime:Float = 1;
	public function new() { super("Asset Libraries Tree Info"); }
	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		if ((lastUpdateTime += flixel.FlxG.rawElapsed) < 1) { super.__enterFrame(t); return; }
		lastUpdateTime = 0;
		var text = 'Not initialized yet\n';
		if (Paths.assetsTree != null){
			text = "";
			for(l in Paths.assetsTree.libraries) {
				var l = AssetsLibraryList.getCleanLibrary(l);
				text += '[${l.tag.toString().toUpperCase()}] ';
				var className = Type.getClassName(Type.getClass(l)).split(".").pop();
				#if TRANSLATIONS_SUPPORT
				if (l is TranslatedAssetLibrary) text += '${className} - ${cast(l, TranslatedAssetLibrary).langFolder} for (${cast(l, TranslatedAssetLibrary).modName})\n';
				else #end if (l is ScriptedAssetLibrary) text += '${className} - ${cast(l, ScriptedAssetLibrary).scriptName} (${cast(l, ScriptedAssetLibrary).modName})\n';
				else if (l is IModsAssetLibrary) text += '${className} - ${cast(l, IModsAssetLibrary).modName} - ${cast(l, IModsAssetLibrary).libName}\n';
				else text += Std.string(l) + '\n';
			}
		}
		if (text != "") text = text.substr(0, text.length-1);
		this.text.text = text;
		super.__enterFrame(t);
	}
}

class ConductorInfo extends FramerateCategory {
	public function new() { super("Conductor Info"); }
	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		_text = 'Current Song Position: ${Math.floor(Conductor.songPosition * 1000) / 1000}';
		_text += '\n - ${Conductor.curBeat} beats\n - ${Conductor.curStep} steps\n - ${Conductor.curMeasure} measures';
		_text += '\nCurrent BPM: ${Conductor.bpm}\nTime Signature: ${Conductor.beatsPerMeasure}/${Conductor.denominator}';
		this.text.text = _text;
		super.__enterFrame(t);
	}
}

class FlixelInfo extends FramerateCategory {
	public function new() { super("Flixel Info"); }
	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		@:privateAccess {
			if((flixel.FlxG.state is ModState)) _text = "Mod State: " + cast(flixel.FlxG.state, ModState).scriptName;
			else _text = 'State: ${Type.getClassName(Type.getClass(flixel.FlxG.state))}';
			_text += '\nObject Count: ${flixel.FlxG.state.members.length}\nCamera Count: ${flixel.FlxG.cameras.list.length}';
			_text += '\nBitmaps Count: ${Lambda.count(flixel.FlxG.bitmap._cache)}\nSounds Count: ${flixel.FlxG.sound.list.length}';
		}
		this.text.text = _text;
		super.__enterFrame(t);
	}
}

#if (gl_stats && !disable_cffi && (!html5 || !canvas))
class StatsInfo extends FramerateCategory {
	public function new() { super("GL Stats"); }
	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		_text = "totalDC: " + Context3DStats.totalDrawCalls() + "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
		this.text.text = _text;
		super.__enterFrame(t);
	}
}
#end

class MemoryCounter extends Sprite {
	public var memoryText:TextField;
	public var memoryPeakText:TextField;
	public var memory:Float = 0;
	public var memoryPeak:Float = 0;

	public var offsetX:Float = 4;
	public var offsetY:Float = 36;

	public function new() {
		super();
		memoryText = new TextField();
		memoryPeakText = new TextField();
		for(label in [memoryText, memoryPeakText]) {
			label.autoSize = LEFT;
			label.defaultTextFormat = new TextFormat(Framerate.fontName, 12, -1);
			label.selectable = false;
			addChild(label);
		}
		memoryPeakText.alpha = 0.5;

		reload();
		addEventListener(Event.ADDED_TO_STAGE, function(_) stage.addEventListener(Event.RESIZE, onResize));
	}

	public function reload() {
		for(label in [memoryText, memoryPeakText]) {
			label.defaultTextFormat = new TextFormat(Framerate.fontName, 12, -1);
		}
		updateScale();
	}

	function onResize(_) updateScale();
	function updateScale() {
		var screenScale = Math.min(Lib.current.stage.stageWidth / 1280, Lib.current.stage.stageHeight / 720);
		scaleX = scaleY = Options.fpsSize * screenScale;
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		updateScale();
		super.__enterFrame(t);

		if (flixel.FlxG.game != null) {
			this.x = flixel.FlxG.game.x + (offsetX * scaleX);
			this.y = flixel.FlxG.game.y + (offsetY * scaleY);
		}

		final mem = MemoryUtil.currentMemUsage();
		if (mem != memory) {
			memory = mem;
			if (memoryPeak < memory) memoryPeak = memory;
			memoryText.text = CoolUtil.getSizeString(memory);
			memoryPeakText.text = ' / ${CoolUtil.getSizeString(memoryPeak)}';
		}
		memoryPeakText.x = memoryText.x + memoryText.width;
	}
}

class FramerateCounter extends Sprite {
	public var fpsNum:TextField;
	public var fpsLabel:TextField;
	public var lastFPS:Float = 0;
	private var frameCount:Int = 0;
	private var accumulatedTime:Float = Lib.getTimer();
	private var lastUpdateTime:Float = 0;

	public var offsetX:Float = 4;
	public var offsetY:Float = 10;

	public function new() {
		super();
		fpsNum = new TextField();
		fpsLabel = new TextField();
		for(label in [fpsNum, fpsLabel]) {
			label.autoSize = LEFT;
			label.selectable = false;
			addChild(label);
		}
		reload();
		addEventListener(Event.ADDED_TO_STAGE, function(_) stage.addEventListener(Event.RESIZE, onResize));
	}

	public function reload() {
		fpsNum.defaultTextFormat = new TextFormat(Framerate.fontName, 18, -1);
		fpsLabel.defaultTextFormat = new TextFormat(Framerate.fontName, 12, -1);
		fpsLabel.text = "FPS";
		updateScale();
	}

	function onResize(_) updateScale();
	function updateScale() {
		var screenScale = Math.min(Lib.current.stage.stageWidth / 1280, Lib.current.stage.stageHeight / 720);
		scaleX = scaleY = Options.fpsSize * screenScale;
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		updateScale();
		super.__enterFrame(t);

		if (flixel.FlxG.game != null) {
			this.x = flixel.FlxG.game.x + (offsetX * scaleX);
			this.y = flixel.FlxG.game.y + (offsetY * scaleY);
		}

		frameCount++;
		if ((lastUpdateTime += flixel.FlxG.rawElapsed) < (1/15)) { updatePosition(); return; }
		final timer = Lib.getTimer();
		final time = timer - accumulatedTime;
		accumulatedTime = timer;
		lastFPS = flixel.math.FlxMath.lerp(lastFPS, time <= 0 ? 0 : (1000 / time * frameCount), 1.0 - Math.pow(0.75, time * 0.06));
		fpsNum.text = Std.string(Math.round(lastFPS));
		lastUpdateTime = frameCount = 0;
		updatePosition();
	}

	private inline function updatePosition() {
		fpsLabel.x = fpsNum.x + fpsNum.width;
		fpsLabel.y = (fpsNum.y + fpsNum.height) - fpsLabel.height - 2;
	}
}

class CodenameBuildField extends TextField {
	public var offsetX:Float = 4;
	public var offsetY:Float = 54;
	
	public function new() {
		super();
		defaultTextFormat = Framerate.textFormat;
		autoSize = LEFT;
		multiline = true;
		reload();
		updateScale();
		addEventListener(Event.ADDED_TO_STAGE, function(_) stage.addEventListener(Event.RESIZE, onResize));
	}

	function onResize(_) updateScale();
	function updateScale() {
		var screenScale = Math.min(Lib.current.stage.stageWidth / 1280, Lib.current.stage.stageHeight / 720);
		scaleX = scaleY = Options.fpsSize * screenScale;
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		updateScale();
		super.__enterFrame(t);
		if (flixel.FlxG.game != null) {
			this.x = flixel.FlxG.game.x + (offsetX * scaleX);
			this.y = flixel.FlxG.game.y + (offsetY * scaleY);
		}
	}

	public function reload() {
		text = '${Flags.VERSION_MESSAGE}';
		#if debug text += '\n${Flags.COMMIT_MESSAGE}'; #end
		#if DEVBUILD text += '\nDev Build'; #end
	}
}

class Framerate extends Sprite {
	public static var instance:Framerate;
	public static var isLoaded:Bool = false;

	public static var textFormat:TextFormat;
	public static var fpsCounter:FramerateCounter;
	public static var memoryCounter:MemoryCounter;
	#if SHOW_BUILD_ON_FPS
	public static var codenameBuildField:CodenameBuildField;
	#end

	public static var fontName:String = #if windows '${Sys.getEnv("windir")}\\Fonts\\consola.ttf' #else "_typewriter" #end;

	/**
	 * 0: FPS INVISIBLE
	 * 1: FPS VISIBLE
	 * 2: FPS & DEBUG INFO VISIBLE
	 */
	public static var debugMode:Int = 1;
	public static var offset:FlxPoint = new FlxPoint();

	public var bgSprite:Bitmap;

	public var categories:Array<FramerateCategory> = [];

	@:isVar public static var __bitmap(get, null):BitmapData = null;

	private static function get___bitmap():BitmapData {
		if (__bitmap == null)
			__bitmap = new BitmapData(1, 1, 0xFF000000);
		return __bitmap;
	}

	public function new() {
		super();
		if (instance != null) throw "Cannot create another instance";
		instance = this;
		textFormat = new TextFormat(fontName, 12, -1);

		isLoaded = true;

		x = 4;
		y = 2;

		if (__bitmap == null)
			__bitmap = new BitmapData(1, 1, 0xFF000000);

		bgSprite = new Bitmap(__bitmap);
		bgSprite.alpha = 0;
		addChild(bgSprite);

		__addToList(fpsCounter = new FramerateCounter());
		__addToList(memoryCounter = new MemoryCounter());
		#if SHOW_BUILD_ON_FPS
		__addToList(codenameBuildField = new CodenameBuildField());
		#end
		__addCategory(new ConductorInfo());
		__addCategory(new FlixelInfo());
		__addCategory(new SystemInfo());
		__addCategory(new AssetTreeInfo());

		#if (gl_stats && !disable_cffi && (!html5 || !canvas))
		__addCategory(new StatsInfo());
		#end
	}

	public function reload() {
		for(c in categories)
			c.reload();
		#if SHOW_BUILD_ON_FPS
		codenameBuildField.reload();
		#end
		memoryCounter.reload();
		fpsCounter.reload();
	}

	private function __addCategory(category:FramerateCategory) {
		categories.push(category);
		__addToList(category);
	}
	private var __lastAddedSprite:DisplayObject = null;
	private function __addToList(spr:DisplayObject) {
		spr.x = 0;
		spr.y = __lastAddedSprite != null ? (__lastAddedSprite.y + __lastAddedSprite.height) : 4;
		__lastAddedSprite = spr;
		addChild(spr);
	}


	var debugAlpha:Float = 0;
	public override function __enterFrame(t:Int) {
		var shouldBeVisible = (debugMode > 0 && Options.fpsSize > 0);
		var shouldDebugBeVisible = (debugMode > 1 && Options.fpsSize > 0);

		alpha = CoolUtil.fpsLerp(alpha, shouldBeVisible ? 1 : 0, 0.5);
		debugAlpha = CoolUtil.fpsLerp(debugAlpha, shouldDebugBeVisible ? 1 : 0, 0.5);

		if (alpha < 0.05) return;
		super.__enterFrame(t);
		bgSprite.alpha = debugAlpha * 0.5;

		x = 10 + offset.x;
		y = 2 + offset.y;

		var width = MathUtil.maxSmart(fpsCounter.width, memoryCounter.width #if SHOW_BUILD_ON_FPS , codenameBuildField.width #end) + (x*2);
		var height = #if SHOW_BUILD_ON_FPS codenameBuildField.y + codenameBuildField.height #else memoryCounter.y + memoryCounter.height #end;
		bgSprite.x = -x;
		bgSprite.y = offset.x;
		bgSprite.scaleX = width;
		bgSprite.scaleY = height;

		var selectable = debugMode == 2;
		{
			memoryCounter.memoryText.selectable = memoryCounter.memoryPeakText.selectable =
			fpsCounter.fpsNum.selectable = fpsCounter.fpsLabel.selectable =
			#if SHOW_BUILD_ON_FPS codenameBuildField.selectable = #end selectable;
		}

		var y:Float = height + 4;
		for(c in categories) {
			c.title.selectable = c.text.selectable = selectable;
			c.alpha = debugAlpha;
			c.x = FlxMath.lerp(-c.width - offset.x, 0, debugAlpha);
			c.y = y;
			y = c.y + c.height + 4;
		}
	}
}
