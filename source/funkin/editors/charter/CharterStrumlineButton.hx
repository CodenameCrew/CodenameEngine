package funkin.editors.charter;

import flixel.tweens.FlxTween;
import flixel.math.FlxPoint;

class CharterStrumlineButton extends UISprite {
	public var button:UISprite;
	public var text:UIText;

	public var onClick:Void->Void;
	public var animationOnClick:Bool = true;

	public override function new(imagePath:String, text:String) {
		super();

		scrollFactor.set(1, 0);
		alpha = 0;

		button = new UISprite();
		button.loadGraphic(Paths.image(imagePath), true, 71, 71);
		for(i in 0...button.frames.frames.length)
			button.animation.add(Std.string(i), [i]);
		button.animation.play("0", true);
		button.scale.set(0.85,0.85);
		button.updateHitbox();
		button.antialiasing = true;
		button.cursor = BUTTON;
		members.push(button);

		this.text = new UIText(0,0, 160, text);
		this.text.alignment = CENTER;
		members.push(this.text);

		textTweenColor = new FlxInterpolateColor(0xFFFFFFFF);
	}

	var buttonScale:FlxPoint = FlxPoint.get(0,0);
	var buttonScaleOffset:FlxPoint = FlxPoint.get(0,0);

	var buttonYOffset:Float = 0;
	var jumpTween:FlxTween;
	var scaleTween:FlxTween;
	var angleTween:FlxTween;

	var shakeTimer:Float = 0;

	public var textTweenColor:FlxInterpolateColor;
	public var textColorLerp:Float = 1;

	public override function update(elapsed:Float) {
		button.follow(this, ((40 * 4) - button.width) / 2, 20+buttonYOffset);
		text.follow(this, 0, 84);

		shakeTimer -= elapsed;
		if (shakeTimer > 0)
			for (spr in [button, text])
				{spr.x += FlxG.random.float(0, 3) * FlxG.random.sign(); spr.y += FlxG.random.float(0, 3) * FlxG.random.sign();}

		super.update(elapsed);

		if (UIState.state.curContextMenu == null && UIState.state.isOverlapping(button, button.__rect) && button.visible) {
			UIState.state.updateSpriteRect(button);
			buttonScale.set(0.95, 0.95);
			if (FlxG.mouse.justPressed && onClick != null) {
				onClick();
				if (animationOnClick) pressAnimation();
			}
		}
		else buttonScale.set(0.85, 0.85);

		button.scale.set(
			FlxMath.lerp(button.scale.x, buttonScale.x, 1/6),
			FlxMath.lerp(button.scale.y, buttonScale.y, 1/6)
		);
		button.scale += buttonScaleOffset;

		textTweenColor.fpsLerpTo(0xFFFFFFFF, (1/20) * textColorLerp);
		text.color = textTweenColor.color;
	}

	public override function destroy() {
		super.destroy();

		buttonScale.put();
		buttonScaleOffset.put();
	}

	public function pressAnimation(extra:Bool = false) {
		shakeTimer = 0.14;

		if (jumpTween != null) jumpTween.cancel(); buttonYOffset = 0;
		jumpTween = FlxTween.tween(this, {buttonYOffset: -10 + FlxG.random.float(-2, 2) + (extra ? -8 : 0)}, .12, {ease: FlxEase.circOut})
			.then(FlxTween.tween(this, {buttonYOffset: 0}, .1 + FlxG.random.float(.1, .3), {ease: FlxEase.circIn}));

		if (scaleTween != null) scaleTween.cancel(); buttonScaleOffset.set(0,0);
		scaleTween = FlxTween.tween(buttonScaleOffset, {x: .015 * (extra ? 3 : 1), y: .02 * (extra ? 3 : 1)}, .12, {ease: FlxEase.circOut})
			.then(FlxTween.tween(buttonScaleOffset, {x: 0, y: 0}, .1 + FlxG.random.float(.1, .3), {ease: FlxEase.circIn}));

		if (!extra) return;

		if (angleTween != null) angleTween.cancel(); button.angle = 0;
		angleTween = FlxTween.tween(button, {angle: 360}, .5, {ease: FlxEase.circInOut});
	}
}