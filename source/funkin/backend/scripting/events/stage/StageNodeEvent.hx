package funkin.backend.scripting.events.stage;

import funkin.game.Stage;
import haxe.xml.Access;

final class StageNodeEvent extends CancellableEvent {
	/**
	 * The stage instance
	 */
	public var stage:Stage;

	/**
	 * The node which is currently being parsed
	 */
	public var node:Access;

	/**
	 * The sprite which was parsed
	 */
	public var sprite:Dynamic;

	/**
	 * The name of the node, quicker access than e.node.name
	 */
	public var name:String;
}