package funkin.backend.system.framerate;

import flixel.math.FlxPoint;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.events.KeyboardEvent;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;

class Framerate extends Sprite {
	public static var instance:Framerate;
	public static var isLoaded:Bool = false;

	public static var textFormat:TextFormat;
	public static var fpsCounter:FramerateCounter;
	public static var memoryCounter:MemoryCounter;
	#if SHOW_BUILD_ON_FPS
	public static var codenameBuildField:CodenameBuildField;
	#end
	public static var conductorInfo:ConductorInfo;
	public static var flixelInfo:FlixelInfo;
	public static var systemInfo:SystemInfo;
	public static var assetInfo:AssetTreeInfo;
	#if (gl_stats && !disable_cffi && (!html5 || !canvas))
	public static var statsInfo:StatsInfo;
	#end

	public static var defaultFontName(default, never):String = #if windows '${Sys.getEnv("windir")}\\Fonts\\consola.ttf' #else "_typewriter" #end;

	public static var fontName:String = defaultFontName;

	/**
	 * 0: FPS INVISIBLE
	 * 1: FPS VISIBLE
	 * 2: FPS & DEBUG INFO VISIBLE
	 */
	public static var debugMode:Int = Options.fpsCounter ? 1 : 0;
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

		x = 10;
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
		__addCategory(conductorInfo = new ConductorInfo());
		__addCategory(flixelInfo = new FlixelInfo());
		__addCategory(systemInfo = new SystemInfo());
		__addCategory(assetInfo = new AssetTreeInfo());

		#if (gl_stats && !disable_cffi && (!html5 || !canvas))
		__addCategory(statsInfo = new StatsInfo());
		#end
	}

	public function reload() {
		textFormat = new TextFormat(fontName, 12, -1);
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
		//spr.y += offset.y;
		__lastAddedSprite = spr;
		addChild(spr);
	}


	var debugAlpha:Float = 0;
	var lastSelectable:Null<Bool> = null;
	var lastBoundsWidth:Float = 0;
	var lastBoundsHeight:Float = 0;
	var refreshTimer:Int = 0;
	public override function __enterFrame(t:Float) {
		final targetAlpha:Float = debugMode > 0 ? 1 : 0;
		alpha = Math.abs(alpha - targetAlpha) < 0.005 ? targetAlpha : CoolUtil.fpsLerp(alpha, targetAlpha, 0.5);

		final targetDebugAlpha:Float = debugMode > 1 ? 1 : 0;
		debugAlpha = Math.abs(debugAlpha - targetDebugAlpha) < 0.005 ? targetDebugAlpha : CoolUtil.fpsLerp(debugAlpha, targetDebugAlpha, 0.5);

		if (alpha < 0.05) return;
		super.__enterFrame(t);
		bgSprite.alpha = debugAlpha * 0.5;

		x = Math.round(10 + offset.x * FlxG.scaleMode.scale.x);
		y = Math.round(2 + offset.y * FlxG.scaleMode.scale.y);

		if (fpsCounter.contentDirty || memoryCounter.contentDirty #if SHOW_BUILD_ON_FPS || codenameBuildField.contentDirty #end) {
			#if SHOW_BUILD_ON_FPS
			lastBoundsWidth = MathUtil.maxSmart(fpsCounter.width, memoryCounter.width, codenameBuildField.width);
			lastBoundsHeight = codenameBuildField.y + codenameBuildField.height;
			codenameBuildField.contentDirty = false;
			#else
			lastBoundsWidth = MathUtil.maxSmart(fpsCounter.width, memoryCounter.width);
			lastBoundsHeight = memoryCounter.y + memoryCounter.height;
			#end
			fpsCounter.contentDirty = memoryCounter.contentDirty = false;
		}

		if (++refreshTimer >= 60) {
			refreshTimer = 0;
			fpsCounter.refreshDisplay();
			memoryCounter.refreshDisplay();
			#if SHOW_BUILD_ON_FPS
			codenameBuildField.contentDirty = true;
			#end
		}

		final width = lastBoundsWidth + (x * 2);
		final height = lastBoundsHeight;
		bgSprite.x = -x;
		bgSprite.y = offset.x;
		bgSprite.scaleX = width;
		bgSprite.scaleY = height;

		final selectable = debugMode == 2;
		if (selectable != lastSelectable) {
			lastSelectable = selectable;
			memoryCounter.memoryText.selectable = memoryCounter.memoryPeakText.selectable =
			fpsCounter.fpsNum.selectable = fpsCounter.fpsLabel.selectable =
			#if SHOW_BUILD_ON_FPS codenameBuildField.selectable = #end selectable;
			cacheAsBitmap = !selectable;
		}

		var y:Float = height + 4;
		for(c in categories) {
			if (!c.visible) continue;
			if (debugAlpha <= 0.005) {
				c.alpha = 0;
				continue;
			}
			c.title.selectable = c.text.selectable = selectable;
			c.alpha = debugAlpha;
			c.x = FlxMath.lerp(-c.width - offset.x, 0, debugAlpha);
			c.y = y;
			y = c.y + c.height + 4;
		}
	}
}