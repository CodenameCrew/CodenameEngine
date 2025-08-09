package funkin.backend.scripting.events;

import flixel.FlxState;

final class StateEvent extends CancellableEvent {
	/**
	 * Substate or State that is about to be opened/closed
	 */
	public var substate:FlxState;  // WHY is it named substate :sob:  - Nex
}