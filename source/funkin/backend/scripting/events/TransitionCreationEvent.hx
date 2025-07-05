package funkin.backend.scripting.events;

import flixel.FlxState;

/**
 * CANCEL this event to prevent default behaviour!
 */
final class TransitionCreationEvent extends CancellableEvent {
	/**
	 * If the transition is going out into another state
	 */
	public var transOut:Bool;

	/**
	 * The state that is about to be loaded (only on trans out)
	 */
	public var newState:FlxState;
}