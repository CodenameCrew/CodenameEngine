package funkin.backend.system.framerate;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import flixel.math.FlxPoint;
import openfl.events.KeyboardEvent;
import openfl.display.DisplayObject;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
import flixel.util.FlxTimer;

class Framerate extends Sprite {
	public static var instance:Framerate;
	public static var isLoaded:Bool = false;

	public static var textFormat:TextFormat;
	public static var fpsCounter:FramerateCounter;
	public static var memoryCounter:MemoryCounter;
	#if SHOW_BUILD_ON_FPS
	public static var codenameBuildField:CodenameBuildField;
	#end

	public static var fontName:String = #if windows '${Sys.getEnv("windir")}\\Fonts\\consola.ttf' #else "_sans" #end;

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

	#if mobile
	#if android public var presses:Int = 0; #end
	public var sillyTimer:FlxTimer = new FlxTimer();
	#end

	public function new() {
		super();
		if (instance != null) throw "Cannot create another instance";
		instance = this;
		textFormat = new TextFormat("Consolas", 12, -1);

		isLoaded = true;

		x = 10;
		y = 2;

		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent) {
			switch(e.keyCode) {
				case #if web Keyboard.NUMBER_3 #else Keyboard.F3 #end: // 3 on web or F3 on windows, linux and other things that runs code
					debugMode = (debugMode + 1) % 3;
			}
		});

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
	public override function __enterFrame(t:Int) {
		alpha = CoolUtil.fpsLerp(alpha, debugMode > 0 ? 1 : 0, 0.5);
		debugAlpha = CoolUtil.fpsLerp(debugAlpha, debugMode > 1 ? 1 : 0, 0.5);
		#if android
		if(FlxG.android.justReleased.BACK){
			sillyTimer.cancel();
			++presses;
			if(presses >= 3){
				debugMode = (debugMode + 1) % 3;
				presses = 0;
				return;
			}
			sillyTimer.start(0.3, (tmr:FlxTimer) -> presses = 0);
		}
		#elseif ios
		for(camera in FlxG.cameras.list) {
			var pos = FlxG.mouse.getScreenPosition(camera);
			if (pos.x >= FlxG.game.x + 10 + offset.x &&
				pos.x <= FlxG.game.x + offset.x + 80 &&
				pos.y >= FlxG.game.y + 2 + offset.y &&
				pos.y <= FlxG.game.y + 2 + offset.y + 60)
			{
				if(FlxG.mouse.justPressed)
					sillyTimer.start(0.4, (tmr:FlxTimer) -> debugMode = (debugMode + 1) % 3);

				if(FlxG.mouse.justReleased)
					sillyTimer.cancel();
			} else if(sillyTimer.active && !sillyTimer.finished)
				sillyTimer.cancel();
		}
		#end

		if (alpha < 0.05) return;
		super.__enterFrame(t);
		bgSprite.alpha = debugAlpha * 0.5;

		x = #if mobile FlxG.game.x + #end 10 + offset.x;
		y = #if mobile FlxG.game.y + #end 2 + offset.y;

		var width = Math.max(fpsCounter.width, #if SHOW_BUILD_ON_FPS Math.max(memoryCounter.width, codenameBuildField.width) #else memoryCounter.width #end) + (x*2);
		var height = #if SHOW_BUILD_ON_FPS codenameBuildField.y + codenameBuildField.height #else memoryCounter.y + memoryCounter.height #end;
		bgSprite.x = -x;
		bgSprite.y = offset.x;
		bgSprite.scaleX = width;
		bgSprite.scaleY = height;

		var selectable = debugMode == 2;
		{  // idk i tried to make it more lookable:sob:  - Nex
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

	#if mobile
	public inline function setScale(?scale:Float){
		if(scale == null)
			scale = Math.min(FlxG.stage.window.width / FlxG.width, FlxG.stage.window.height / FlxG.height);
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
	}
	#end
}
