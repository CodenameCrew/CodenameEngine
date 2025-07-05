package funkin.backend.scripting.events;

import funkin.game.Note;
import funkin.game.Character;

final class NoteMissEvent extends CancellableEvent {
	@:dox(hide) public var animCancelled:Bool = false;
	@:dox(hide) public var deleteNote:Bool = true;
	@:dox(hide) public var stunned:Bool = true;
	@:dox(hide) public var resetCombo:Bool = true;
	@:dox(hide) public var playMissSound:Bool = true;

	/**
	 * Note that has been missed
	 */
	public var note:Note;
	public var score:Int;
	public var misses:Int;
	public var muteVocals:Bool;
	/**
	 * The amount of health that'll be gained from missing that note. If called from `onPlayerMiss`, the value will be negative.
	 */
	public var healthGain:Float;
	public var missSound:String;
	public var missVolume:Float;

	public var ghostMiss:Bool;
	public var gfSad:Bool;
	public var gfSadAnim:String;
	public var forceGfAnim:Bool;
	/**
	 * Whenever the animation should be forced to play (if it's null it will be forced based on the sprite's data xml, if it has one).
	 */
	public var forceAnim:Null<Bool>;
	/**
	 * Suffix of the animation. "miss" for miss notes, "-alt" for alt notes, "" for normal ones.
	 */
	public var animSuffix:String;

	/**
	 * Character that pressed the note.
	 */
	public var character(get, set):Character;
	/**
	 * Characters that pressed the note.
	 */
	public var characters:Array<Character>;
	/**
	 * Whenever the Character is a player
	 */
	public var playerID:Int;
	/**
	 * Note Type name (null if default note)
	 */
	public var noteType:String;
	/**
	 * Direction of the press (0 = Left, 1 = Down, 2 = Up, 3 = Right)
	 */
	public var direction:Int;
	/**
	 * Accuracy gained from pressing this note. From 0 to 1. null means no accuracy is gained.
	 */
	public var accuracy:Null<Float>;

	/**
	 * Prevents the miss sound from played.
	 */
	public function preventMissSound() {
		playMissSound = false;
	}

	@:dox(hide)
	public function cancelMissSound() {preventMissSound();}

	/**
	 * Prevents the combo from being reset.
	 */
	public function preventResetCombo() {
		resetCombo = false;
	}

	@:dox(hide)
	public function cancelResetCombo() {preventResetCombo();}

	/**
	 * Prevents the default sing animation from being played.
	 */
	public function preventStunned() {
		stunned = false;
	}

	@:dox(hide)
	public function cancelStunned() {preventStunned();}

	/**
	 * Prevents the default sing animation from being played.
	 */
	public function preventAnim() {
		animCancelled = true;
	}

	@:dox(hide)
	public function cancelAnim() {preventAnim();}

	/**
	 * Prevents the note from being deleted.
	 */
	public function preventDeletion() {
		deleteNote = false;
	}
	@:dox(hide)
	public function cancelDeletion() {preventDeletion();}

	/**
	 * Prevents the vocals volume from being set to 1 after pressing the note.
	 */
	public function preventVocalsUnmute() {
		muteVocals = true;
	}
	@:dox(hide)
	public function cancelVocalsUnmute() {preventVocalsUnmute();}

	/**
	 * Prevents the vocals volume from being muted in case its a parameter of `onPlayerMiss`
	 */
	public function preventVocalsMute() {
		muteVocals = false;
	}
	@:dox(hide)
	public function cancelVocalsMute() {preventVocalsMute();}

	private inline function get_character()
		return characters[0];
	private function set_character(char:Character) {
		characters = [char];
		return char;
	}
}
