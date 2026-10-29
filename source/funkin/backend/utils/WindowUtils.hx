package funkin.backend.utils;

import lime.graphics.Image;
import openfl.Lib;
#if windows
import funkin.backend.utils.native.Windows;
#end

final class WindowUtils {
	/**
	 * Text title of the game application window.
	**/
	public static var title(default, set):String;
	private static function set_title(value:String):String {
		title = value;
		updateTitle();
		return value;
	}

	/**
	 * The text to add before the title window.
	**/
	public static var prefix(default, set):String = "";
	private static function set_prefix(value:String):String {
		prefix = value;
		updateTitle();
		return value;
	}

	/**
	 * The text to add after the title window.
	**/
	public static var suffix(default, set):String = "";
	private static function set_suffix(value:String):String {
		suffix = value;
		updateTitle();
		return value;
	}

	/**
	 * Whether or not to prevent the main game application window from closing first time,
	 * call WindowUtils.resetClosing in WindowUtils.onClosing to keep preventing the game window from closing.
	**/
	public static var preventClosing:Bool = true;

	/**
	 * The callback when the main game application window is closing.
	**/
	public static var onClosing:Void->Void;

	/**
	 * Resets the preventClosing to keep prevent the main game application window from closing.
	 * see WindowUtils.preventClosing
	**/
	public static inline function resetClosing() __triedClosing = false;
	static var __triedClosing:Bool = false;

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
		if (Flags.modIconImages.length > 0) Lib.application.window.setIcon(Flags.modIconImages[0]);

		#if windows
		final smallMetric = Windows.getWindowIconMetrics(false);

		var image:Image = Flags.modIconImages[0], i = Flags.modIconImages.length;
		while (i-- > 0)
			if (smallMetric <= Math.max((image = Flags.modIconImages[i]).width, image.height)) break;

		if (image != null && (image != Flags.modIconImages[0] || smallMetric == Math.max(image.width, image.height)))
			Windows.setWindowIconImage(false, Lib.application.window.title, image);
		#end
	}

	/**
	 * Changes the window resolution.
	 * @param width The window's resolution width (Defaults to Flags.GAME_WIDTH or 1280).
	 * @param height The window's resolution height (Defaults to Flags.GAME_HEIGHT or 720).
	 * @param updateWindow Should it also update the window size and re-centers the position.
	**/
	public static function setResolution(?width:Int, ?height:Int, updateWindow = true) @:privateAccess {
		if (width == null) width = Flags.GAME_WIDTH;
		if (height == null) height = Flags.GAME_HEIGHT;

		if (FlxG.width == width && FlxG.height == height) return;

		FlxG.width = FlxG.initialWidth = width;
		FlxG.height = FlxG.initialHeight = height;

		if (updateWindow) {
			final window = Lib.application.window;
			final scale = MathUtil.minSmart(window.display.bounds.width / width, window.display.bounds.height / height, 1.0);

			window.resize(Std.int(width * scale), Std.int(height * scale));
			window.move(
				Std.int(window.display.safeArea.x + (window.display.safeArea.width - window.width) * 0.5),
				Std.int(window.display.safeArea.y + (window.display.safeArea.height - window.height) * 0.5)
			);
		}

		if (FlxG.scaleMode != null) FlxG.scaleMode.onMeasure(width, height);
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
}
