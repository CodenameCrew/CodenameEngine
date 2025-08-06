package funkin.backend.scripting.events.note;

import funkin.game.StrumLine;

final class InputSystemEvent extends CancellableEvent {
	/**
	 * Array containing whenever a specific control is pressed or not.
	 * For example, `pressed[0]` will return whenever the left strum was pressed.
	 */
	public var pressed:Array<Bool>;

	/**
	 * Array containing whenever a specific control was pressed (not hold) this frame or not.
	 * For example, `justPressed[0]` will return whenever the left strum was just pressed.
	 */
	public var justPressed:Array<Bool>;

	/**
	 * Array containing whenever a specific control was released this frame or not.
	 * For example, `justReleased[0]` will return whenever the left strum was just released.
	 */
	public var justReleased:Array<Bool>;

	/**
	 * Strumline which input is being processed.
	 */
	public var strumLine:StrumLine;

	/**
	 * ID of the Strumline.
	 */
	public var strumLineID:Int;
}