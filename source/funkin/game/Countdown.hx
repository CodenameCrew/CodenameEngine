package funkin.game;

import flixel.tweens.FlxTween;
import flixel.sound.FlxSound;
import funkin.backend.scripting.events.gameplay.CountdownEvent;

enum CountdownAnimationPreset {

	// TODO: Documentation

	DEFAULT;
	CLASSIC;
	PULSING;

}

typedef CountdownParams = {

	// TODO: Documentation

	var event:CountdownEvent;

	var enabled:Bool;

	var playSound:Bool;

	var animationPreset:CountdownAnimationPreset;

	var speed:Float;

}

class Countdown extends FlxTypedSpriteGroup<FlxSprite> {

	public var event:CountdownEvent;
	public var enabled:Bool;
	public var playSound:Bool;
	public var animationPreset:CountdownAnimationPreset;
	public var speed:Float;

	public function new(params:CountdownParams) {

		super();

		this.event = params.event;
		this.enabled = params.enabled;
		this.playSound = params.playSound;
		this.animationPreset = params.animationPreset;
		this.speed = params.speed;

		this.__createSprite();

	}

	@:noPrivateAccess
	private function __createSprite():Void {
		if (!this.enabled)
			return;

		var sprite:FlxSprite = null;
		var sound:FlxSound = null;
		var tween:FlxTween = null;

		if (!this.event.cancelled) {
			if (this.event.spritePath != null) {
				var spr = this.event.spritePath;

				if (!Assets.exists(spr))
					spr = Paths.image('$spr');

				sprite = new FunkinSprite().loadAnimatedGraphic(spr);
				sprite.scale.set(this.event.scale, this.event.scale);
				sprite.scrollFactor.set();
				sprite.antialiasing = this.event.antialiasing;
				sprite.updateHitbox();
				sprite.screenCenter();

				add(sprite);

				switch(this.animationPreset) {
					case CLASSIC:
						tween = FlxTween.tween(sprite, {alpha: 0}, this.speed, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween) {
								sprite.destroy();
								remove(sprite, true);
							}
						});
					case PULSING:
						tween = FlxTween.tween(sprite, {alpha: 0}, this.speed, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween) {
								sprite.destroy();
								remove(sprite, true);
							}
						});
					default: // DEFAULT
						tween = FlxTween.tween(sprite, {y: sprite.y + 100, alpha: 0}, this.speed, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween) {
								sprite.destroy();
								remove(sprite, true);
							}
						});
				}
			}

			if (this.event.soundPath != null && playSound) {
				var sfx = this.event.soundPath;
				if (!Assets.exists(sfx)) sfx = Paths.sound(sfx);
				sound = FlxG.sound.play(sfx, this.event.volume);
			}

			this.event.sprite = sprite;
			this.event.sound = sound;
			this.event.spriteTween = tween;
			this.event.cancelled = false;
		}

	}

}
