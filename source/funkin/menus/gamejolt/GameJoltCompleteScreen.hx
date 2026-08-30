package funkin.menus.gamejolt;

import funkin.editors.ui.*;
import openfl.desktop.Clipboard;
import flixel.addons.display.FlxBackdrop;
import funkin.backend.system.gamejolt.*;
import funkin.backend.utils.GJUtil;
import funkin.menus.TitleState;

class GameJoltCompleteScreen extends UIState
{
	var bg:FlxBackdrop;
	var mainText:UIText;
	var copyText:UIText;
	var copyButton:UIButton;
	var continueText:UIText;

	override public function create()
	{
		super.create();
	
		add(bg = new FlxBackdrop());
		bg.loadGraphic(Paths.image('editors/bgs/default'));
		bg.antialiasing = true;
		bg.rotation = -5;
		bg.velocity.set(85, 0).degrees = bg.rotation;

		add(mainText = new UIText(0, 80, FlxG.width,
			'Hey there funkhead!
			Your GameJolt data was recognized and registered to your game\'s data store successfully.
			From here on, only ${GameJoltData.ownerUsername} will be able to change the global data. As for the XML - for security purposes, we took out the login info and game token. Feel free to discard the XML entirely, or keep it as a souvenir - your globals load from your game\'s data store now!
			Before you go: it\'s important to press the "Copy" button below and copy the following text into your mod\'s modpack.ini file. This is your game\'s security key encrypted uniquely for this build. Paste it in the "Common" section.',
			30));
		
		mainText.alignment = CENTER;
		mainText.antialiasing = true;

		add(copyText = new UIText(0, mainText.height + 120, FlxG.width, 'GAMEJOLT_ENCRYPTED_TOKEN=\'${Flags.MOD_GAMEJOLT_ENCRYPTED_TOKEN}\'', 16));
		copyText.alignment = CENTER;
		copyText.antialiasing = true;

		add(copyButton = new UIButton(0, copyText.y + copyText.height + 20, "Copy", () -> {
			Clipboard.generalClipboard.setData(TEXT_FORMAT, copyText.text);
		}));
		copyButton.color = 0xFF3F3FFF;
		copyButton.x = (FlxG.width / 2) - (copyButton.bWidth / 2);

		add(continueText = new UIText(0, copyButton.y + copyButton.bHeight + 30, FlxG.width, '~ Press ${controls.getKeyName(ACCEPT)} to continue ~'));
		continueText.alignment = CENTER;

		CoolUtil.playMusic(Paths.music('breakfast'));
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (controls.ACCEPT) {
			CoolUtil.playMenuSFX(CONFIRM);
			if (FlxG.save.data.gameJoltArray != null) {
				var gjDat:Array<String> = FlxG.save.data.gameJoltArray;
				GJUtil.attemptLogin(gjDat[0], gjDat[1]);
			}
			FlxG.switchState(new TitleState());
		}
	}
}