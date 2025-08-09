package funkin.menus;

import flixel.util.FlxColor;
import flixel.text.FlxText;
import funkin.backend.FunkinText;

class WarningState extends MusicBeatState {
	var titleAlphabet:Alphabet;
	var disclaimer:FunkinText;

	var transitioning:Bool = false;

	public override function create() {

		titleAlphabet = new Alphabet(0, 0, "WARNING", true);
		titleAlphabet.screenCenter(X);
		add(titleAlphabet);

		disclaimer = new FunkinText(16, titleAlphabet.y + titleAlphabet.height + 10, FlxG.width - 32, "", 32);
		disclaimer.alignment = CENTER;
		disclaimer.text = "This is a warning state! Make a script #./data/states/WarningState.hx# to edit this text! \n\n Note: you can use *asterisks* or #hashtags# to highlight your text in *red* or #yellow#, or you can just make your own markup using postCreate (you have to change the text in create() to apply the default markup)";

		super.create();

		disclaimer.applyMarkup(disclaimer.text,
			[
				new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFF4444), "*"),
				new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFFF44), "#")
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