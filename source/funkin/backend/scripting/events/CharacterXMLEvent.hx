package funkin.backend.scripting.events;

import funkin.game.Character;
import haxe.xml.Access;

final class CharacterXMLEvent extends CancellableEvent {
	/**
	 * The character instance
	 */
	 public var character:Character;

	/**
	 * The xml
	 */
	public var xml:Access;
}