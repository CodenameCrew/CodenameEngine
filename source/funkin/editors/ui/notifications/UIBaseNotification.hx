package funkin.editors.ui.notifications;

import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

using flixel.util.FlxSpriteUtil;

class UIBaseNotification extends UISliceSprite {
	public var textField:UIText;
	public var closeButton:UIButton;

	public var onRemove:(notif:UIBaseNotification)->Void = null;

	public var showedAnimation:Bool = false;
	public var closed:Bool = false;

	public function new(text:String, showTimer:Float = 5, corner:Corner = BOTTOM_LEFT) {
		super(x, y, 340, 46, "editors/ui/inputbox");

		closeButton = new UIButton(0, 0, "X", () -> {
			if (closed) return;
			closed = true;

			(new FlxTimer()).start(0.2, (_) -> {disappearAnimation();});
		}, 32, 32);
		closeButton.hoverCallback = () -> {
			closeButton.color = 0xFFAC3D3D;
			closeButton.field.color = 0xFFffffff;
			//closeButton.field.color = closeButton.hovered ? 0xFFffffff : 0xFF7f7f7f;
		}
		closeButton.autoAlpha = false;
		closeButton.alpha = 0.0;

		textField = new UIText(0, 0, 0, text, 14);
		textField.alignment = LEFT;
		textField.fieldWidth = bWidth - 32 - 8;
		members.push(textField);

		if(textField.height > bHeight)
			bHeight = Std.int(textField.height);

		alpha = 0;
		textField.alpha = 0;

		showingTimer = showTimer;

		members.push(closeButton);

		var margin = 20;

		switch(corner) {
			case TOP_LEFT:
				x = margin;
				y = margin;
			case TOP_RIGHT:
				x = FlxG.width - bWidth - margin;
				y = margin;
			case BOTTOM_LEFT:
				x = margin;
				y = FlxG.height - bHeight - margin;
			case BOTTOM_RIGHT:
				x = FlxG.width - bWidth - margin;
				y = FlxG.height - bHeight - margin;
		}

		defaultX = x;
		defaultY = y;

		switch(corner) {
			case TOP_LEFT | BOTTOM_LEFT:
				x -= bWidth - margin - 20;
			case TOP_RIGHT | BOTTOM_RIGHT:
				x += bWidth - margin - 20;
		}

		closingX = x;
		closingY = y;

		alpha = 0;
	}

	public var defaultX:Float = 0;
	public var defaultY:Float = 0;

	public var closingX:Float = 0;
	public var closingY:Float = 0;

	public var showingTimer:Float = 5;
	public var timerActive:Bool = false;

	public var progress:Float = 0;
	public override function update(elapsed:Float) {
		closeButton.color = 0xFFFFFFFF;
		closeButton.field.color = 0xFF7f7f7f;
		super.update(elapsed);

		if(timerActive) {
			showingTimer -= elapsed;
			if(showingTimer <= 0) {
				timerActive = false;
				idleDisappearAnimation();
			}
		}

		textField.follow(this, 5, bHeight / 2 - textField.height / 2);
		closeButton.follow(this, bWidth-closeButton.bWidth - 7, bHeight / 2 - closeButton.bHeight / 2);
		closeButton.field.alpha = alpha * .7;
		//closeButton.alpha = alpha;
		textField.alpha = alpha;
	}

	public function appearAnimation() {
		x = closingX; alpha=0; FlxTween.cancelTweensOf(this, ["x", "alpha"]);
		FlxTween.tween(this, {x: defaultX}, .4, {ease: FlxEase.circInOut});
		FlxTween.tween(this, {alpha: 1}, .3, {ease: FlxEase.sineOut, startDelay: .1, onComplete: (_) -> {
			if(showingTimer > 0) timerActive = true;
		}});

		showedAnimation = true;
	}

	public var isClosing:Bool = false;

	public function disappearAnimation() {
		if (isClosing) return;
		isClosing = true;

		// TODO: make it so you can click through the notification
		closeButton.active = false;
		closeButton.selectable = false;
		closeButton.canBeHovered = false;
		selectable = false;
		canBeHovered = false;

		x = defaultX; alpha = 1; FlxTween.cancelTweensOf(this, ["x", "alpha"]);
		FlxTween.tween(this, {alpha: 0}, .3, {ease: FlxEase.sineOut, onComplete: (_) -> {
			if(onRemove != null) onRemove(this);
			destroy();
		}});

		showedAnimation = false;
	}

	public function idleDisappearAnimation() {
		if (isClosing) return;
		isClosing = true;

		x = defaultX; alpha = 1; FlxTween.cancelTweensOf(this, ["x", "alpha"]);
		FlxTween.tween(this, {alpha: 0}, .3, {ease: FlxEase.sineOut});
		FlxTween.tween(this, {x: closingX}, .4, {ease: FlxEase.circInOut, onComplete: (_) -> {
			if(onRemove != null) onRemove(this);
			destroy();
		}});

		showedAnimation = false;
	}
}

enum abstract Corner(Int) {
	var TOP_LEFT = 0;
	var TOP_RIGHT = 1;
	var BOTTOM_LEFT = 2;
	var BOTTOM_RIGHT = 3;
}