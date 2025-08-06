package funkin.menus;

import funkin.editors.charter.Charter;

class GitarooPause extends MusicBeatState
{
	var replayButton:FlxSprite;
	var cancelButton:FlxSprite;

	var replaySelect:Bool = false;

	public function new():Void
	{
		super();
	}

	override function create()
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		var bg:FlxSprite = new FlxSprite().loadAnimatedGraphic(Paths.image('menus/pauseAlt/pauseBG'));
		add(bg);

		var bf:FlxSprite = new FlxSprite(0, 30);
		bf.frames = Paths.getFrames('menus/pauseAlt/bfLol');
		bf.animation.addByPrefix('lol', "funnyThing", 13);
		bf.animation.play('lol');
		add(bf);
		bf.screenCenter(X);

		replayButton = new FlxSprite(FlxG.width * 0.28, FlxG.height * 0.7);
		replayButton.frames = Paths.getFrames('menus/pauseAlt/pauseUI');
		replayButton.animation.addByPrefix('selected', 'bluereplay', 0, false);
		replayButton.animation.appendByPrefix('selected', 'yellowreplay');
		replayButton.animation.play('selected');
		add(replayButton);

		cancelButton = new FlxSprite(FlxG.width * 0.58, replayButton.y);
		cancelButton.frames = Paths.getFrames('menus/pauseAlt/pauseUI');
		cancelButton.animation.addByPrefix('selected', 'bluecancel', 0, false);
		cancelButton.animation.appendByPrefix('selected', 'cancelyellow');
		cancelButton.animation.play('selected');
		add(cancelButton);

		changeThing();

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.LEFT_P || controls.RIGHT_P)
			changeThing();

		if (controls.ACCEPT)
		{
			if (PlayState.instance != null && PlayState.chartingMode && Charter.undos.unsaved)
				PlayState.instance.saveWarn(false);
			else {
				if (replaySelect)
				{
					FlxG.switchState(new PlayState());
				}
				else
				{
					if (Charter.instance != null) Charter.instance.__clearStatics();
					FlxG.switchState(new MainMenuState());
				}
			}
		}

		super.update(elapsed);
	}

	function changeThing():Void
	{
		replaySelect = !replaySelect;

		if (replaySelect)
		{
			cancelButton.animation.curAnim.curFrame = 0;
			replayButton.animation.curAnim.curFrame = 1;
		}
		else
		{
			cancelButton.animation.curAnim.curFrame = 1;
			replayButton.animation.curAnim.curFrame = 0;
		}
	}
}
