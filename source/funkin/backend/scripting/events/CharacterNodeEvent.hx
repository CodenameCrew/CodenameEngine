package funkin.backend.scripting.events;

import funkin.game.Character;
import haxe.xml.Access;

final class CharacterNodeEvent extends CancellableEvent {
	/**
	 * The character instance
	 */
	public var character:Character;

	/**
	 * The node which is currently being parsed
	 */
	public var node:Access;

	/**
	 * The name of the node, quicker access than e.node.name
	 */
	public var name:String;
}