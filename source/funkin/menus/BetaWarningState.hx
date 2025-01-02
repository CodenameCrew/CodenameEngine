package funkin.menus;

import flixel.util.FlxColor;
import flixel.text.FlxText;
import funkin.backend.FunkinText;

class BetaWarningState extends MusicBeatState {
	var titleAlphabet:Alphabet;
	var disclaimer:FunkinText;

	var transitioning:Bool = false;

	public override function create() {
		super.create();

		titleAlphabet = new Alphabet(0, 0, "WARNING", true);
		titleAlphabet.screenCenter(X);
		add(titleAlphabet);

		disclaimer = new FunkinText(16, titleAlphabet.y + titleAlphabet.height + 10, FlxG.width - 32, "", 32);
		disclaimer.alignment = CENTER;
		disclaimer.applyMarkup('This engine is still in a *${Main.releaseCycle}* state. That means *majority of the features* are either *buggy* or *non finished*. If you find any bugs, please report them to the Codename Engine GitHub.\n\n${controls.touchC ? 'Tap Your Screen' : 'Press ENTER'} to continue',
			[
				new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFF4444), "*")
			]
		);
		add(disclaimer);

		var off = Std.int((FlxG.height - (disclaimer.y + disclaimer.height)) / 2);
		disclaimer.y += off;
		titleAlphabet.y += off;

		DiscordUtil.call("onMenuLoaded", ["Beta Warning"]);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed && transitioning) {
				FlxG.camera.stopFX(); FlxG.camera.visible = false;
				goToTitle();
			} else if (touch.justPressed && !transitioning) {
				transitioning = true;
				CoolUtil.playMenuSFX(CONFIRM);
				FlxG.camera.flash(FlxColor.WHITE, 1, function() {
					FlxG.camera.fade(FlxColor.BLACK, 2.5, false, goToTitle);
				});
			}
		}
		#end

		if (controls.ACCEPT && transitioning) {
			FlxG.camera.stopFX(); FlxG.camera.visible = false;
			goToTitle();
		}

		if (controls.ACCEPT && !transitioning) {
			transitioning = true;
			CoolUtil.playMenuSFX(CONFIRM);
			FlxG.camera.flash(FlxColor.WHITE, 1, function() {
				FlxG.camera.fade(FlxColor.BLACK, 2.5, false, goToTitle);
			});
		}
	}

	private function goToTitle() {
		MusicBeatState.skipTransIn = MusicBeatState.skipTransOut = true;
		FlxG.switchState(new TitleState());
	}
}