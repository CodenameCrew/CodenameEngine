package funkin.backend.scripting.events.note;

import funkin.game.Note;

final class NoteCreationEvent extends CancellableEvent {
	/**
	 * Note that is being created
	 */
	public var note:Note;

	/**
	 * ID of the strum (from 0 to 3)
	 */
	public var strumID:Int;

	/**
	 * Note Type (ex: "My Super Cool Note", or "Mine")
	 */
	public var noteType:String;

	/**
	 * ID of the note type.
	 */
	public var noteTypeID:Int;

	/**
	 * ID of the player.
	 */
	public var strumLineID:Int;

	/**
	 * Whenever the note will need to be hit by the player
	 */
	public var mustHit:Bool;

	/**
	 * Note sprite, if you only want to replace the sprite.
	 */
	public var noteSprite:String;

	/**
	 * Note scale, if you only want to replace the scale.
	 */
	public var noteScale:Float;

	/**
	 * Sing animation suffix. "-alt" for alt anim or "" for normal notes.
	 */
	public var animSuffix:String;
}