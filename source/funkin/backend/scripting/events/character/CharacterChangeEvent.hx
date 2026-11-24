package funkin.backend.scripting.events.character;

import funkin.backend.chart.ChartData;
import funkin.game.Character;
import funkin.game.StrumLine;

/**
* Used for the "Character Change" event, to be used
* in character scripts just in case
*
* Cancelling this event does nothing.
*/
final class CharacterChangeEvent extends CancellableEvent {
	/**
	 * The character being replaced. Use cases include:
	 * - `event.oldChar == this`: This character is currently being removed.
	 */
	public var oldChar:Character;

	/**
	 * The character to replace the old one with.. Use cases include:
	 * - `event.newChar == this`: This character is currently being added.
	 */
	public var newChar:Character;

	/**
	 * The ChartEvent object, just to make it easy to access its parameters.
	 */
	public var event:ChartEvent;

	/**
	* The target StrumLine for this event.
	*/
	public var strumLine:StrumLine;
}