package funkin.backend.scripting.events;

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

/**
	Contains all contexts possible for `PlayAnimEvent`.
**/
enum abstract PlayAnimContext(String) {
	/**
		No context was given for the animation.
		The character won't dance until the animation is finished
	**/
	var NONE = null;

	/**
		Whenever a note is hit and a sing animation will be played.
		The character will only dance after their holdTime is reached.
	**/
	var SING = "SING";

	/**
		Whenever a dance animation is played.
		The character's dancing wont be blocked.
	**/
	var DANCE = "DANCE";

	/**
		Whenever a note is missed and a miss animation will be played.
		Only for scripting, since it has the same effects as SING.
	**/
	var MISS = "MISS";

	/**
		Locks the character's animation.
		Prevents the character from dancing, even if the animation ended.
	**/
	var LOCK = "LOCK";
}