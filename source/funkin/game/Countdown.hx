package funkin.game;

import flixel.tweens.misc.VarTween;
import flixel.tweens.FlxTween;
import flixel.sound.FlxSound;
import funkin.backend.scripting.events.gameplay.CountdownEvent;

enum CountdownAnimationPreset {

	// TODO: Documentation

	DEFAULT;
	CLASSIC;
	BEATING;

}

typedef CountdownParams = {

	// TODO: Documentation

	var event:CountdownEvent;

	var enabled:Bool;

	var playSound:Bool;

	var animationPreset:CountdownAnimationPreset;

	var duration:Float;

	var speed:Float;

}

class Countdown extends FlxTypedSpriteGroup<FlxSprite> {
	public var event:CountdownEvent;
	public var enabled:Bool;
	public var playSound:Bool;
	public var animationPreset:CountdownAnimationPreset;
	public var duration:Float;
	public var speed:Float;

	public function new(params:CountdownParams) {
		super();

		this.event = params.event;
		this.enabled = params.enabled;
		this.playSound = params.playSound;
		this.animationPreset = params.animationPreset;
		this.duration = params.duration;
		this.speed = params.speed;

		this.__createSprite();
	}

	@:noPrivateAccess
	private function __createSprite():Void {
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
				var targetSize:Float = defaultSize + ((!isBeatingPreset) ? 0.0 : 0.25);

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
						tween = __createTween(sprite, {alpha: 0});
					case BEATING:
						tween = __createTween(sprite, {alpha: 0, "scale.x": defaultSize, "scale.y": defaultSize});
					default: // DEFAULT
						tween = __createTween(sprite, {y: sprite.y + 100, alpha: 0});
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

	@:noPrivateAccess
	private function __createTween(sprite:FlxSprite, values:Dynamic):VarTween {
		return FlxTween.tween(sprite, values, (this.duration / this.speed), {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween) {
				sprite.destroy();
				remove(sprite, true);
			}
		});
	}
}
