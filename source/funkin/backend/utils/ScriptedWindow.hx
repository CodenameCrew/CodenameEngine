package funkin.backend.utils;

import funkin.backend.scripting.Script;

import funkin.backend.system.FunkinGame;

import hscript.IHScriptCustomBehaviour;

import openfl.Lib;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.display.Window;

import openfl.events.Event;

/* https://github.com/openfl/lime/blob/develop/src/lime/ui/WindowAttributes.hx */
import lime.ui.WindowAttributes;

class ScriptedWindow
implements IFlxDestroyable implements IHScriptCustomBehaviour {

	public static var default_arguments:Dynamic = {
		title: "Codename Engine - Scripted Window",
		width: 1280,
		height: 720,
		frameRate: Options.framerate,
	};

	public var window:Window;

	public var script:Script;
	
	private var __variables:Array<String>;

	public var game:Sprite = new Sprite();

	public var _closeWhenMainWindowClosed:Bool = true;

	public function new(path:String, ?attributes:Dynamic, ?shouldCloseAutomatically:Bool = true) {
		
		_closeWhenMainWindowClosed = shouldCloseAutomatically;

		if (attributes == null) attributes = ScriptedWindow.default_arguments;
		if (attributes.title == null) attributes.title = ScriptedWindow.default_arguments.title;
		if (attributes.width == null) attributes.width = ScriptedWindow.default_arguments.width;
		if (attributes.height == null) attributes.height = ScriptedWindow.default_arguments.height;
		if (attributes.frameRate == null) attributes.frameRate = Options.framerate; // so it will constantly update regardless default_framerate

		window = Lib.application.createWindow(attributes);
		window.stage.addChild(game);
		window.onClose.add(onWindowClose);

		// Ok so if you close the main window it stops the main thread, so be careful 🥶
		Lib.application.window.onClose.add(() -> {
			if (_closeWhenMainWindowClosed) window.close();
		});

		script = Script.create(path);
		script.setParent(window);
		
		script.set("game", game);
		script.set("addAsBitmap", addAsBitmap);
		script.load();

		FlxG.signals.preUpdate.add(function() {
			script.call("preUpdate", [FlxG.elapsed]);
			script.call("update", [FlxG.elapsed]);
		});

		FlxG.signals.postUpdate.add(function() {
			script.call("postUpdate", [FlxG.elapsed]);
		});
		
		__variables = Type.getInstanceFields(Type.getClass(this));
	}

	private inline function addAsBitmap(path:String):Bitmap {
		var bitmap:Bitmap = new Bitmap(BitmapData.fromBytes(Assets.getBytes(path)));
		game.addChild(bitmap);
		return bitmap;
	}

	public function hget(name:String):Dynamic
		return __variables.contains(name) ? Reflect.getProperty(this, name) : script.get(name);

	public function hset(name:String, val:Dynamic):Dynamic {
		if (__variables.contains(name))
			Reflect.setProperty(this, name, val);
		else
			script.set(name, val);
		return val;
	}

	private function onWindowClose() {
		destroy();
	}

	inline public function close() window.close();

	public function destroy() {
		script.call("destroy");
		FlxDestroyUtil.destroy(script);
	}

	public function toString():String {
		return 'ScriptedWindow (${script.path})';
	}
}