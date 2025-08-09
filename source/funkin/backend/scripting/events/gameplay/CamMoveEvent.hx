package funkin.backend.scripting.events.gameplay;

import flixel.math.FlxPoint;
import funkin.game.StrumLine;

final class CamMoveEvent extends CancellableEvent {
	/**
	 * Final camera position.
	 */
	public var position:FlxPoint;

	/**
	 * Currently focused strumline.
	 */
	public var strumLine:StrumLine;

	/**
	 * Number of focused characters
	 */
	public var focusedCharacters:Int;
}