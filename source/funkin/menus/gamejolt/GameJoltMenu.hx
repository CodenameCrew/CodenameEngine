package funkin.menus.gamejolt;

import funkin.editors.ui.UIState;
import funkin.editors.ui.UIButton;
import funkin.editors.ui.UIText;
import funkin.menus.gamejolt.GameJoltLoginWindow;

class GameJoltMenu extends UIState
{
	var mainGroup:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();

	override function create()
	{
		super.create();

		add(new FlxSprite().loadAnimatedGraphic(Paths.image('menus/menuDesat')));

		createPages();
	}

	function createPages()
	{
		var lgIn:Bool = GJUtil.loggedIn;

		mainGroup.add(new UIButton((FlxG.width / 2) - 60, FlxG.height - 200, "Login", () -> {
			openSubState(new GameJoltLoginWindow());
		}));

		add(mainGroup);

		var daGroup:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();

		daGroup.add(new UIText(0, 0, FlxG.width, "NOT LOGGED IN"));

		add(daGroup);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.BACK) {
			CoolUtil.playMenuSFX(CANCEL, 0.7);
			FlxG.switchState(new MainMenuState());
		}
	}
}