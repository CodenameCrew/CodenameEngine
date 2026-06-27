package funkin.backend.scripting.events.gameplay;

import flixel.math.FlxPoint;

final class RatingsShowEvent extends CancellableEvent 
{
	/**
	 * Rating sprite (may be null)
	*/
	public var ratingSprite:Null<FlxSprite>;
	/**
	 * Number sprite (may be null)
	*/
	public var numberSprite:Null<FlxSprite>;
	/**
	 * Combo sprite (may be null)
	*/
	public var comboSprite:Null<FlxSprite>;
	/**
	 * Scale of combo numbers. (may be null)
	 */
	public var numScale:Null<Float> = 0.5;
	/**
	 * Whenever antialiasing should be enabled on combo numbers. (may be null)
	 */
	public var numAntialiasing:Null<Bool> = true;
	/**
	 * Scale of the rating sprites. (may be null)
	 */
	public var ratingScale:Null<Float> = 0.7;
	/**
	 * Whenever antialiasing should be enabled on ratings. (may be null)
	 */
	public var ratingAntialiasing:Null<Bool> = true;
	/**
	 * Prefix of the rating sprite path. Defaults to "game/score/"
	 */
	public var ratingPrefix:String;
	/**
	 * Suffix of the rating sprite path.
	 */
	public var ratingSuffix:String;
	/**
	 * The sprite's acceleration.
	 */
	public var acceleration:Float;
	/**
	 * A FlxPoint which x or y properties preposition the sprites current velocity.
	 */
	public var velocity:FlxPoint;
	/**
	 * The duration of the sprite's alpha tween.
	 */
	public var tweenDuration:Float;
	/**
	 * The start delay of the sprite's alpha tween.
	 */
	public var startDelay:Float;
	/**
	 * Whenever the Rating sprites should be shown or not.
	 */
	public var displayRating:Bool;
	/**
	 * Whenever the Rating sprites should be shown or not.
	 */
	public var displayNumbers:Bool;
	/**
	 * Whenever the Combo sprite should be shown or not (like old Week 7 patches).
	 */
	public var displayCombo:Bool;
	/**
	 * Whether the sprite should be tweened or not.
	 */
	public var tween:Bool;
	/**
	 * The amount of spacing for the combo numbers. (may be null)
	 */
	public var numSpacing:Null<Float>;
	/**
	 * The position of the sprite.
	 */
	public var position:FlxPoint;
	/**
  	 * Whether to reset the sprite or not.
     */
	public var resetSprite:Bool;
	/**
     * The rating name of the rating sprite. (may be null)
	 */
	public var rating:Null<String>;
}
