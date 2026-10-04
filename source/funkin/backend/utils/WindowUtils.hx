package funkin.backend.utils;

import lime.graphics.Image;
import openfl.Lib;
#if windows
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

	@:dox(hide) public static inline function init() {
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
	public static inline function resetTitle() {
		resetAffixes(false);
		title = Flags.WINDOW_TITLE_USE_MOD_NAME ? Flags.MOD_NAME : Flags.TITLE;
	}

	/**
	 * Resets the window icon to the application or mod default icons.
	**/
	public static inline function resetIcon() {
		if (Assets.exists(Flags.MOD_ICON)) Lib.application.window.setIcon(Image.fromBytes(Assets.getBytes(Flags.MOD_ICON)));

		#if windows
		inline function doIcon(big:Bool) {
			var metric = Windows.getWindowIconMetrics(big);

			var path:String;
			if (metric <= 16) path = Flags.MOD_ICON16;
			else if (metric <= 24) path = Flags.MOD_ICON24;
			else if (metric <= 32) path = Flags.MOD_ICON32;
			else {
				//path = Flags.MOD_ICON;
				path = null;
			}

			if (path != null && Assets.exists(path)) {
				var image = Image.fromBytes(Assets.getBytes(path));
				if (image != null) Windows.setWindowIconImage(big, Lib.application.window.title, image, true);
			}
		}

		doIcon(false);
		doIcon(true);
		#end
	}

	/**
	 * Resets the prefix and suffix.
	 * @param update Should it update window title.
	**/
	public static inline function resetAffixes(update = true) {
		prefix = suffix = "";
		if (update) updateTitle();
	}

	/**
	 * Sets the window title and icon.
	 * @param title The title to set.
	 * @param image The image to set as the icon.
	**/
	public static inline function setWindow(?title:String, ?image:String) {
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
