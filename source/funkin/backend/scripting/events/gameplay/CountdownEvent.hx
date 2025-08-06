package funkin.backend.scripting.events.gameplay;

import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;

final class CountdownEvent extends CancellableEvent {
	/**
	 * At which count the countdown is. Normally goes 0-1-2-3-4 unless `PlayState.instance.introLength` is changed.
	 */
	public var swagCounter:Int;
	/**
	 * Volume at which the intro countdown sound will play.
	 */
	public var volume:Float;
	/**
	 * Path of the intro sound that'll be played.
	 */
	public var soundPath:String;
	/**
	 * Path to the sprite path that'll be shown.
	 */
	public var spritePath:String;
	/**
	 * Scale of the sprite.
	 */
	public var scale:Float;
	/**
	 * Whenever antialiasing is enabled or not.
	 */
	public var antialiasing:Bool;


	/**
	 * Created sprite, only available in `onPostCountdown`
	 */
	public var sprite:FlxSprite;
	/**
	 * Created tween for the sprite, only available in `onPostCountdown`
	 */
	public var spriteTween:FlxTween;
	/**
	 * Created sound, only available in `onPostCountdown`
	 */
	public var sound:FlxSound;
}