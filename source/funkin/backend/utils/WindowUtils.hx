package funkin.backend.utils;

import funkin.backend.system.Logs;
import openfl.Lib;

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
		var window = Lib.application != null ? Lib.application.window : null;
		if (window == null || window.onClose == null) return;
		window.onClose.add(function () {
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
		title = Flags.TITLE;
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
	public static inline function setWindow(?title:String, ?image:String)
	{
		// TODO: Implement ICON SIZES in Flags.
		WindowUtils.title = title != null ? title : (Flags.WINDOW_TITLE_USE_MOD_NAME ? Flags.MOD_NAME : Flags.TITLE);

		var iconPath = image != null ? image : Flags.MOD_ICON;
		try {
			if (Lib.application != null && Lib.application.window != null && Assets.exists(Paths.image(iconPath)))
				Lib.application.window.setIcon(lime.graphics.Image.fromBytes(Assets.getBytes(Paths.image(iconPath))));
		} catch (e:Dynamic) {
			Logs.warn('Window icon failed: $e');
		}
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
