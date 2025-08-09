package funkin.backend.scripting.events.sprite;

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