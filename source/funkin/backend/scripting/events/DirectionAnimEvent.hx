package funkin.backend.scripting.events;

import funkin.backend.scripting.events.PlayAnimEvent.PlayAnimContext;

final class DirectionAnimEvent extends CancellableEvent {
	/**
		Default animation that will be played
	**/
	public var animName:String;
	/**
		In which direction the animation will be played
	**/
	public var direction:Int;
	/**
		The suffix of the animation (ex: "-alt") - Defaults to ""
	**/
	public var suffix:String;
	/**
		Context of the animation. Is either equal to `SING` or `MISS`.
	**/
	public var context:PlayAnimContext;
	/**
		Whenever the animation will play reversed or not.
	**/
	public var reversed:Bool;
	/**
		At what frame the animation will start playing
	**/
	public var frame:Int;
	/**
		Force the animation to replay even if it's already playing  (if it's null it will be forced based on the sprite's data xml, if it has one).
	**/
	public var force:Null<Bool>;
}
