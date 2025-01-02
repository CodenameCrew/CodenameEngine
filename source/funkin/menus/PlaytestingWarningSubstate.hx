package funkin.menus;

import flixel.tweens.FlxTween;
import funkin.editors.ui.UIWarningSubstate.WarningButton;
import flixel.util.FlxColor;
import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import funkin.backend.FunkinText;

class PlaytestingWarningSubstate extends MusicBeatSubstate
{
	var titleAlphabet:Alphabet;
	var disclaimer:FunkinText;

	var windowClosing:Bool = false;

	var curSelected:Int = 0;
	var options:Array<FunkinText> = [];
	var buttonsData:Array<WarningButton> = [];

	var indicator:FunkinText;

	public function new(closingWindow:Bool, buttons:Array<WarningButton>) {
		super();
		windowClosing = closingWindow;
		buttonsData = buttons;
	}

	override function create() {
		super.create();

		camera = new FlxCamera();
		camera.bgColor = 0;
		FlxG.cameras.add(camera, false);

		var bg:FlxSprite = new FlxSprite().makeSolid(FlxG.width + 100, FlxG.height + 100, FlxColor.BLACK);
		bg.updateHitbox();
		bg.alpha = .8;
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

		titleAlphabet = new Alphabet(0, 140, "UNSAVED CHANGES!", true);
		titleAlphabet.screenCenter(X);
		add(titleAlphabet);

		disclaimer = new FunkinText(16, titleAlphabet.y + titleAlphabet.height + 70, FlxG.width - 32, "", 32);
		disclaimer.alignment = CENTER;
		disclaimer.applyMarkup("Your changes will be *lost* if you don't save them. (Can't be recovered)\n\n\nWould you like to Cancel?",
			[
				new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFF4444), "*")
			]
		);
		disclaimer.borderSize = 4;
		add(disclaimer);

		for (buttonData in buttonsData) {
			var textOption:FunkinText = new FunkinText(0, disclaimer.y + disclaimer.height + 140, 0, buttonData.label, 24);
			textOption.borderSize = 4; if (buttonData.color != null) textOption.color = buttonData.color;
			options.push(cast add(textOption));
		}

		indicator = new FunkinText(0, disclaimer.y + disclaimer.height + 86, 0, "V", 22);
		indicator.borderSize = 4;
		add(indicator);

		FlxTween.tween(indicator.offset, {y: -7.5}, {ease: FlxEase.quadInOut, type: PINGPONG});

		curSelected = options.length-1;
		changeSelection(0);

		addVirtualPad('LEFT_RIGHT', 'A');
	}

	var sinner:Float = 0;
	var __firstFrame:Bool = true;
	override function update(elapsed:Float) {
		super.update(elapsed); sinner += elapsed;

		titleAlphabet.offset.y = FlxMath.fastSin(sinner) * 12;
		disclaimer.offset.y = FlxMath.fastSin(sinner+.8) * 8;

		if (controls.RIGHT_P) changeSelection(1);
		if (controls.LEFT_P) changeSelection(-1);

		for (i => option in options) {
			option.x = FlxG.width * ((1+i)/4) - (option.fieldWidth/2);
			switch(i) {
				case 1: option.x -= 20;
			}
			if (i == curSelected) indicator.x = option.x + (option.fieldWidth/2) - (indicator.fieldWidth/2);
			option.alpha = i == curSelected ? 1 : 0.4;
			option.y = disclaimer.y + disclaimer.height + 140 + (FlxMath.fastSin((sinner*2)+1.2+(.3*i)) * 4);
			option.offset.y = CoolUtil.fpsLerp(option.offset.y, i == curSelected ? 10 : -10, 1/6);
		}

		if (controls.ACCEPT && !__firstFrame) {
			buttonsData[curSelected].onClick(null);
			close();
		}

		__firstFrame = false;
	}

	function changeSelection(change:Int) {
		CoolUtil.playMenuSFX(SCROLL, 0.7);
		curSelected = FlxMath.wrap(curSelected+change, 0, options.length-1);
	}

	override function destroy() {
		if(FlxG.cameras.list.contains(camera))
			FlxG.cameras.remove(camera, true);
		super.destroy();
	}
}