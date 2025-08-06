package funkin.backend.utils;

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

	@:dox(hide) public static inline function init() {
		resetTitle();
		resetClosing();

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
		title = Flags.TITLE == null ? Lib.application.meta.get('name') : Flags.TITLE;
		resetAffixes();
	}

	/**
	 * Resets the prefix and suffix.
	**/
	public static inline function resetAffixes() {
		prefix = suffix = "";
		updateTitle();
	}

	/**
	 * Sets the window title and icon.
	 * @param title The title to set.
	 * @param image The image to set as the icon.
	**/
	public static inline function setWindow(?name:String, ?image:String)
	{			Lib.application.window.setIcon(lime.graphics.Image.fromBytes(Assets.getBytes(image != null ? image : Flags.MOD_ICON)));
		title = name != null ? name : Flags.MOD_NAME;
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
