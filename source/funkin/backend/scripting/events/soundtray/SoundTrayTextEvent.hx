package funkin.backend.scripting.events.soundtray;

final class SoundTrayTextEvent extends CancellableEvent
{
	public var checkIfNull:Bool;

	public var reloadDefaultTextFormat:Bool;

	public var displayTxt:String;

	public var y:Float;
}