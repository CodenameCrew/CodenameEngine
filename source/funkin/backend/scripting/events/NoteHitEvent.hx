package funkin.backend.scripting.events;

import funkin.game.Note;
import funkin.game.Character;
import funkin.game.HealthIcon;

final class NoteHitEvent extends CancellableEvent {
	@:dox(hide) public var animCancelled:Bool = false;
	@:dox(hide) public var strumGlowCancelled:Bool = false;
	@:dox(hide) public var deleteNote:Bool = true;
	@:dox(hide) public var unmuteVocals:Bool = true;
	@:dox(hide) public var enableCamZooming:Bool = true;
	@:dox(hide) public var autoHitLastSustain:Bool = true;

	/**
	 * Whenever a miss should be added.
	 */
	public var misses:Bool = true;
	/**
	 * Whether this hit increases combo.
	 */
	public var countAsCombo:Bool = true;
	/**
	 * Whether this hit increases the score
	 */
	public var countScore:Bool = true;
	/**
	 * Whenever ratings (Rating sprite, Digits sprites and Combo sprite) should be shown or not.
	 *
	 * NOTE: Whether it's `true` use `displayRating` and `displayCombo` (plus `minDigitDisplay` in the PlayState class) to change what's going to pop up!
	 */
	public var showRating:Null<Bool> = null;
	/**
	 * Whenever the Rating sprites should be shown or not.
	 */
	public var displayRating:Bool;
	/**
	 * Whenever the Combo sprite should be shown or not (like old Week 7 patches).
	 */
	public var displayCombo:Bool;
	/**
	 * Note that has been pressed
	 */
	public var note:Note;
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
	public var player:Bool;
	/**
	 * Note Type name (null if default note)
	 */
	public var noteType:String;
	/**
	 * Suffix of the animation. "-alt" for alt notes, "" for normal ones.
	 */
	public var animSuffix:String;
	/**
	 * Prefix of the rating sprite path. Defaults to "game/score/"
	 */
	public var ratingPrefix:String;
	/**
	 * Suffix of the rating sprite path.
	 */
	public var ratingSuffix:String;
	/**
	 * Direction of the press (0 = Left, 1 = Down, 2 = Up, 3 = Right)
	 */
	public var direction:Int;
	/**
	 * Score gained after note press.
	 */
	public var score:Int;
	/**
	 * Accuracy gained from pressing this note. From 0 to 1. null means no accuracy is gained.
	 */
	public var accuracy:Null<Float>;
	/**
	 * The amount of health that'll be gained from pressing that note. If called from `onPlayerMiss`, the value will be negative.
	 */
	public var healthGain:Float;
	/**
	 * Rating name. Defaults to "sick", "good", "bad" and "shit". Customisable.
	 */
	public var rating:String = "sick";
	/**
	 * Whenever a splash should be shown when the note is hit.
	 */
	public var showSplash:Bool = false;
	/**
	 * Scale of combo numbers.
	 */
	public var numScale:Float = 0.5;
	/**
	 * Whenever antialiasing should be enabled on combo number.
	 */
	public var numAntialiasing:Bool = true;
	/**
	 * Scale of ratings.
	 */
	public var ratingScale:Float = 0.7;
	/**
	 * Whenever antialiasing should be enabled on ratings.
	 */
	public var ratingAntialiasing:Bool = true;
	/**
	 * Whenever the animation should be forced to play (if it's null it will be forced based on the sprite's data xml, if it has one).
	 */
	public var forceAnim:Null<Bool> = true;
	/**
	 * The attached healthIcon used distinction for icons amongst others
	 */
	public var healthIcon:HealthIcon;

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
	 * Forces the note to be deleted.
	**/
	public function forceDeletion() {
		deleteNote = true;
	}

	/**
	 * Prevents the vocals volume from being set to 1 after pressing the note.
	 */
	public function preventVocalsUnmute() {
		unmuteVocals = false;
	}
	@:dox(hide)
	public function cancelVocalsUnmute() {preventVocalsUnmute();}

	/**
	 * Prevents the vocals volume from being muted in case its a parameter of `onPlayerMiss`
	 */
	public function preventVocalsMute() {
		unmuteVocals = true;
	}
	@:dox(hide)
	public function cancelVocalsMute() {preventVocalsMute();}

	/**
	 * Prevents the camera zoom every 4 beats from enabling.
	 */
	public function preventCamZooming() {
		enableCamZooming = false;
	}
	@:dox(hide)
	public function cancelCamZooming() {preventCamZooming();}

	/**
	 * Prevents the sustain tail (the last one) from being automatically hit when the sustain before it is hit.
	 */
	public function preventLastSustainHit() {
		autoHitLastSustain = false;
	}
	@:dox(hide)
	public function cancelLastSustainHit() {preventLastSustainHit();}

	/**
	 * Prevents the strum from glowing after this note has been pressed.
	 */
	public function preventStrumGlow() {
		strumGlowCancelled = true;
	}
	@:dox(hide)
	public function cancelStrumGlow() {preventStrumGlow();}

	private inline function get_character()
		return characters[0];
	private function set_character(char:Character) {
		characters = [char];
		return char;
	}
}
