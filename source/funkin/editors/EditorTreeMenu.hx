package funkin.editors;

import funkin.menus.MainMenuState;
import flixel.addons.display.FlxBackdrop;
import funkin.options.*;

class EditorTreeMenu extends TreeMenu {
	public var bg:FlxBackdrop;
	public var bgType:String = "default";
	public var bgMovement:FlxPoint = new FlxPoint();

	public override function create() {
		super.create();

		FlxG.camera.fade(0xFF000000, 0.5, true);

		bg = new FlxBackdrop();
		bg.loadGraphic(Paths.image('editors/bgs/${bgType}'));
		bg.antialiasing = true;
		setBackgroundRotation(-5);
		add(bg);
	}

	public inline function setBackgroundRotation(rotation:Float) {
		bg.rotation = rotation;
		bg.velocity.set(85, 0).degrees = bg.rotation;
	}

	public override function exit() {
		FlxG.switchState(new MainMenuState());
	}
}