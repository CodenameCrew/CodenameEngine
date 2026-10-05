package funkin.backend.utils;

import lime.graphics.Image;
import openfl.Lib;
#if windows
import openfl.system.Capabilities;
import funkin.backend.utils.native.Windows;
#end

final class WindowUtils {
	public static var title(default, set):String;
	private static function set_title(value:String):String {
		title = value;
		updateTitle();
		return value;
	}
	public static var prefix(default, set):String = "";
	private static function set_prefix(value:String):String {
		prefix = value;
		updateTitle();
		return value;
	}
	public static var suffix(default, set):String = "";
	private static function set_suffix(value:String):String {
		suffix = value;
		updateTitle();
		return value;
	}

	public static var preventClosing:Bool = true;
	public static var onClosing:Void->Void;

	static var __triedClosing:Bool = false;
	public static inline function resetClosing() __triedClosing = false;

	@:dox(hide) public static function init() {
		Lib.application.window.onClose.add(function () {
			if (preventClosing && !__triedClosing) {
				Lib.application.window.onClose.cancel();
				__triedClosing = true;
			}
			if (onClosing != null) onClosing();
		});
	}

	/**
	 * Resets the window title to the application name and resets the prefix and suffix.
	**/
	public static function resetTitle() {
		resetAffixes(false);
		title = Flags.WINDOW_TITLE_USE_MOD_NAME ? Flags.MOD_NAME : Flags.TITLE;
	}

	/**
	 * Resets the window icon to the application or mod default icons.
	**/
	public static function resetIcon() {
		if (Assets.exists(Flags.MOD_ICON)) Lib.application.window.setIcon(Flags.modIconImages[0]);

		#if windows
		final smallMetric = Windows.getWindowIconMetrics(false);

		var image:Image = Flags.modIconImages[0], i = Flags.modIconImages.length;
		while (i-- > 0)
			if (smallMetric <= Math.max((image = Flags.modIconImages[i]).width, image.height)) break;

		if (image != Flags.modIconImages[0])
			Windows.setWindowIconImage(false, Lib.application.window.title, image);
		#end
	}

	/**
	 * Changes the window resolution.
	 * @param width The window's resolution width (Defaults to 1280).
	 * @param height The window's resolution height (Defaults to 720).
	 * @param changeSize Should it also update the window size.
	**/
	public static function setResolution(?width:Int, ?height:Int, changeSize = true) {

		var w = width == null ? Flags.GAME_WIDTH : width;
		var h = height == null ? Flags.GAME_HEIGHT : height;

		if(FlxG.width == w && FlxG.height == h)
			return;

		var win = Lib.application.window;

		@:privateAccess {
			#if windows
				if(changeSize){
					win.resize(w, h);
					win.move(Std.int((Capabilities.screenResolutionX / 2) - (w / 2)), Std.int((Capabilities.screenResolutionY / 2) - (h / 2)));
				}
			#end
			
			FlxG.width = FlxG.initialWidth = w; FlxG.height = FlxG.initialHeight = h;
		}
	}

	/**
	 * Resets the prefix and suffix.
	 * @param update Should it update window title.
	**/
	public static function resetAffixes(update = true) {
		prefix = suffix = "";
		if (update) updateTitle();
	}

	/**
	 * Sets the window title and icon.
	 * @param title The title to set.
	 * @param image The image to set as the icon.
	**/
	public static function setWindow(?title:String, ?image:String) {
		WindowUtils.title = title != null ? title : (Flags.WINDOW_TITLE_USE_MOD_NAME ? Flags.MOD_NAME : Flags.TITLE);

		if (image != null && Assets.exists(image = Paths.image(image)))
			Lib.application.window.setIcon(Image.fromBytes(Assets.getBytes(image)));
	}

	/**
	 * Updates the window title to have the current title and prefix/suffix.
	**/
	public static inline function updateTitle()
		Lib.application.window.title = '$prefix$title$suffix';

	// backwards compat
	@:noCompletion public static var endfix(get, set):String;
	@:noCompletion private inline static function set_endfix(value:String):String {
		return suffix = value;
	}
	@:noCompletion private inline static function get_endfix():String {
		return suffix;
	}

	@:noCompletion public static var winTitle(get, set):String;
	@:noCompletion private inline static function get_winTitle():String {
		return title;
	}
	@:noCompletion private inline static function set_winTitle(value:String):String {
		return title = value;
	}
}
