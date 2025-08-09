package funkin.editors.charter;

import flixel.math.FlxRect;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

using flixel.util.FlxSpriteUtil;

class CharterAutoSaveUI extends UISliceSprite {
	public var icon:FlxSprite;
	public var autosavingText:UIText;
	public var progressBarBack:FlxSprite;
	public var progressBar:FlxSprite;

	public var cancelButton:UIButton;
	public var cancelIcon:FlxSprite;

	public var showedAnimation:Bool = false;
	public var cancelled:Bool = false;

	public function new(x:Float, y:Float) {
		super(x, y, 300, 46, "editors/ui/inputbox");

		icon = new FlxSprite(x+12, y+9).loadGraphic(Paths.image("editors/autosave-icons"), true, 10, 10);
		icon.animation.add("icon", [for(i in 0...3) i], 0, true);
		icon.animation.play("icon"); icon.animation.curAnim.curFrame = 0;
		members.push(icon);

		members.push(autosavingText = new UIText(x+12+10+4, y+8, 0, TU.translate("editor.autosavingIn", ["?", "..."]), 12));

		progressBarBack = new FlxSprite(x + 10, y + bHeight - 20).makeGraphic(Std.int(bWidth-20), 10, 0x00000000, true);
		progressBarBack.drawRoundRect(0, 0, progressBarBack.width, progressBarBack.height, 4, 6, 0xFF727272, null, {smoothing: false});
		progressBarBack.drawRoundRect(1, 1, progressBarBack.width-2, progressBarBack.height-2, 4, 6, 0xFF0D0D0D, null, {smoothing: false});
		members.push(progressBarBack); progressBarBack.antialiasing = false;

		progressBar = new FlxSprite(x + 10, y + bHeight - 20).makeGraphic(Std.int(bWidth-20), 10, 0x00000000, true);
		progressBar.drawRoundRect(0, 0, progressBar.width, progressBar.height, 4, 6, 0xFF727272, null, {smoothing: false});
		progressBar.drawRoundRect(1, 1, progressBar.width-2, progressBar.height-2, 4, 6, 0xFFFFFFFF, null, {smoothing: false});
		progressBar.antialiasing = false; progressBar.clipRect = new FlxRect(0, 0, progressBar.width, progressBar.height);
		members.push(progressBar);

		cancelButton = new UIButton(x-(10+16), y+8, null, () -> {
			if (cancelled || !showedAnimation) return;
			cancelled = true; __timer.cancel(); __tween.cancel();

			icon.animation.curAnim.curFrame = 2;
			(new FlxTimer()).start(1, (_) -> {disappearAnimation(true);});
			autosavingText.text += " " + TU.translate("editor.autosavingCanceledSuffix");
			cancelButton.visible = false;
			for (member in [this, autosavingText]) member.color = 0xFFE67F7F;
			for (member in [progressBar, progressBarBack]) member.color = 0xFFE67F7F;
		}, 24, 14);
		cancelButton.frames = Paths.getFrames("editors/ui/grayscale-button");
		cancelButton.color = 0xFFAC3D3D; cancelButton.alpha = 0.2;
		members.push(cancelButton); cancelButton.visible = false;

		cancelIcon = new FlxSprite(x-(10+16), y+8).loadGraphic(Paths.image("editors/autosave-delete"));
		cancelIcon.color = 0xFFD60E0E;
		members.push(cancelIcon);

		alpha = 0;
	}

	var __timer:FlxTimer;
	var __tween:FlxTween;

	public function startAutoSave(time:Float, successText:String) {
		appearAnimation();

		__tween = FlxTween.num(0, 1, time, null, (v:Float) -> {
			if ((progress = v) < .95) {
				autosavingText.text = TU.translate("editor.autosavingIn", [
					Math.min(Math.round(time), 1+Math.floor(Math.abs(time-(progress*time)))),
					".".repeat(Math.floor((progress*time*3)%4))
				]);
			}
		});
		__timer = new FlxTimer();
		__timer.start(time, (_) -> {
			autosavingText.text = successText; cancelButton.visible = false;

			icon.animation.curAnim.curFrame = 1;
			for (member in [this, progressBar, progressBarBack, autosavingText]) member.color = 0xFFA3EC95;

			FlxG.sound.play(Paths.sound(Flags.DEFAULT_EDITOR_AUTOSAVE_SOUND));

			(new FlxTimer()).start(1, (_) -> {disappearAnimation();});
		});
	}

	public var progress:Float = 0;
	public override function update(elapsed:Float) {
		super.update(elapsed);

		cancelButton.follow(this, bWidth-(10+24), 7);
		cancelButton.alpha = alpha * .7;

		cancelIcon.follow(cancelButton, 3.5+1, 2);
		cancelIcon.alpha = alpha;

		cancelIcon.visible = cancelButton.visible;

		icon.follow(this, 12, 9);
		icon.alpha = alpha;

		autosavingText.follow(this, 12+10+4, 8);
		autosavingText.alpha = alpha;

		for (bar in [progressBar, progressBarBack]) {
			bar.follow(this, 10, bHeight-20);
			bar.alpha = alpha;
		}
		progressBar.rawClipRect = progressBar.rawClipRect.set(0, 0, progressBar.frameWidth*progress,progressBar.frameHeight);
	}

	public function appearAnimation() {
		progress = 0; icon.animation.curAnim.curFrame = 0;
		for (member in [this, autosavingText, progressBar, progressBarBack]) member.color = 0xFFFFFFFF;

		x = -(320); alpha=0; FlxTween.cancelTweensOf(this); cancelled = false; cancelButton.visible = true;
		FlxTween.tween(this, {x: 20}, .4, {ease: FlxEase.circInOut});
		FlxTween.tween(this, {alpha: 1}, .3, {ease: FlxEase.sineOut, startDelay: .1});

		showedAnimation = true;
	}

	public function disappearAnimation(?canned:Bool = false) {
		x = 20; alpha = 1; FlxTween.cancelTweensOf(this);
		if (canned) FlxTween.tween(this, {x: -320}, .4, {ease: FlxEase.circInOut});
		FlxTween.tween(this, {alpha: 0}, .3, {ease: FlxEase.sineOut});

		showedAnimation = false;
	}
}