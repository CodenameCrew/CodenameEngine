package funkin.game;

import flixel.tweens.misc.VarTween;
import flixel.tweens.FlxTween;
import flixel.sound.FlxSound;
import funkin.backend.scripting.events.gameplay.CountdownEvent;

enum CountdownAnimationPreset {

	/**
	 * The default animation for Codename Engine's countdown.
	 */
	DEFAULT;

	/**
	 * The classic animation, similar to Funkin's countdown.
	 */
	CLASSIC;

	/**
	 * A more enhanced version of Funkin's countdown animation.
	 */
	BEATING;

}

typedef CountdownParams = {

	/**
	 * The CountdownEvent to be used.
	 */
	var event:CountdownEvent;

	/**
	 * Whether the countdown should be visible or not.
	 */
	var enabled:Bool;

	/**
	 * Whether each tick from the countdown should play a sound.
	 */
	var playSound:Bool;

	/**
	 * The animation preset to be used for the countdown.
	 */
	var animationPreset:CountdownAnimationPreset;

	/**
	 * The duration of the countdown's animation.
	 */
	var duration:Float;

	/**
	 * The speed of the countdown's animation. The lower it is, the slower it goes and vice-versa.
	 */
	var speed:Float;

}

class Countdown extends FlxTypedSpriteGroup<FlxSprite> {
	public var event:CountdownEvent;
	public var enabled:Bool;
	public var playSound:Bool;
	public var animationPreset:CountdownAnimationPreset;
	public var duration:Float;
	public var speed:Float;

	/**
	 * Create a new Countdown component.
	 * @param params
	 */
	public function new(params:CountdownParams) {
		super();

		this.event = params.event;
		this.enabled = params.enabled;
		this.playSound = params.playSound;
		this.animationPreset = params.animationPreset;
		this.duration = params.duration;
		this.speed = params.speed;

		this.makeSprite();
	}

	public function makeSprite():Void {
		if (!this.enabled) {
			return;
		}

		var sprite:FlxSprite = null;
		var sound:FlxSound = null;
		var tween:FlxTween = null;

		if (!this.event.cancelled) {
			if (this.event.spritePath != null) {
				// Add 1.0 to defaultSize if animationPreset is BEATING.
				var defaultSize:Float = this.event.scale;
				var isBeatingPreset:Bool = (this.animationPreset == BEATING);
				var targetSize:Float = defaultSize + ((!isBeatingPreset) ? 0.0 : 0.15);

				var spr = this.event.spritePath;

				if (!Assets.exists(spr)) {
					spr = Paths.image('$spr');
				}

				sprite = new FunkinSprite().loadAnimatedGraphic(spr);
				sprite.scale.set(targetSize, targetSize);
				sprite.scrollFactor.set();
				sprite.antialiasing = this.event.antialiasing;
				sprite.updateHitbox();
				sprite.screenCenter();
				add(sprite);

				switch(this.animationPreset) {
					case CLASSIC:
						tween = makeTween(sprite, {alpha: 0}, FlxEase.cubeInOut);
					case BEATING:
						tween = makeTween(sprite, {alpha: 0, "scale.x": defaultSize, "scale.y": defaultSize}, FlxEase.expoOut);
					default: // DEFAULT
						tween = makeTween(sprite, {y: sprite.y + 100, alpha: 0}, FlxEase.cubeInOut);
				}
			}

			if (this.event.soundPath != null && this.playSound) {
				var sfx = this.event.soundPath;
				if (!Assets.exists(sfx)) {
					sfx = Paths.sound(sfx);
				}
				sound = FlxG.sound.play(sfx, this.event.volume);
			}

			this.event.sprite = sprite;
			this.event.sound = sound;
			this.event.spriteTween = tween;
			this.event.cancelled = false;
		}
	}
	
	public function makeTween(sprite:FlxSprite, values:Dynamic, easing:EaseFunction):VarTween {
		return FlxTween.tween(sprite, values, (this.duration / this.speed), {
			ease: easing,
			onComplete: function(twn:FlxTween) {
				sprite.destroy();
				remove(sprite, true);
			}
		});
	}
}
