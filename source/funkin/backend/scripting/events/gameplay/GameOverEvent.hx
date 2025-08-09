package funkin.backend.scripting.events.gameplay;

import funkin.game.Character;

final class GameOverEvent extends CancellableEvent {
	/**
	 * The X pos of where the gameover character will be.
	 */
	public var x:Float;

	/**
	 * The Y pos of where the gameover character will be.
	 */
	public var y:Float;

	/**
	 * Character which died. Default to `boyfriend`.
	 */
	public var character:Character;

	/**
	 * Character ID (name) for game over. Default to whatever is specified in the character's XML.
	 */
	public var deathCharID:String;

	/**
	 * If the character has isPlayer
	 */
	public var isPlayer:Bool;

	/**
	 * Song for the game over screen. Default to `this.gameOverSong` (`gameOver`)
	 */
	public var gameOverSong:String;

	/**
	 * SFX at the beginning of the game over (Mic drop). Default to `this.lossSFX` (`gameOverSFX`)
	 */
	public var lossSFX:String;

	/**
	 * SFX played whenever the player retries. Defaults to `retrySFX` (`gameOverEnd`)
	 */
	public var retrySFX:String;
}