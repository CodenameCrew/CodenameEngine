package funkin.backend.scripting.events.gameover;

/**
 * CANCEL this event to prevent default behaviour!
 */
final class GameOverCreationEvent extends CancellableEvent
{
	// TODO: documentation
	public var x:Float;

	public var y:Float;

	public var character:String;

	public var player:Bool;

	public var gameOverSong:String;

	public var bpm:Float;

	public var lossSFX:String;

	public var retrySFX:String;
}
