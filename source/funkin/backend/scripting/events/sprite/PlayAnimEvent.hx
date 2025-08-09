package funkin.backend.scripting.events.sprite;

final class PlayAnimEvent extends CancellableEvent {
	/**
		Name of the animation that's going to be played.
	**/
	public var animName:String;

	/**
		Whenever the animation will be forced or not (if it's null it will be forced based on the sprite's data xml, if it has one).
	**/
	public var force:Null<Bool>;

	/**
		Whenever the animation will play in reverse or not
	**/
	public var reverse:Bool;

	/**
		The frame at which the animation will start playing
	**/
	public var startingFrame:Int = 0;

	/**
		Context of the animation
	**/
	public var context:PlayAnimContext;
}