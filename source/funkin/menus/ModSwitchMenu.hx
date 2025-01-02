package funkin.menus;

#if MOD_SUPPORT
import haxe.io.Path;
import funkin.backend.assets.ModsFolder;
import sys.FileSystem;
import flixel.tweens.FlxTween;

class ModSwitchMenu extends MusicBeatSubstate {
	var mods:Array<String> = [];
	var alphabets:FlxTypedGroup<Alphabet>;
	var curSelected:Int = 0;

	public override function create() {
		super.create();

		var bg = new FlxSprite(0, 0).makeSolid(FlxG.width, FlxG.height, 0xFF000000);
		bg.updateHitbox();
		bg.scrollFactor.set();
		add(bg);

		bg.alpha = 0;
		FlxTween.tween(bg, {alpha: 0.5}, 0.25, {ease: FlxEase.cubeOut});

		mods = ModsFolder.getModsList();
		mods.push(null);

		alphabets = new FlxTypedGroup<Alphabet>();
		for(mod in mods) {
			var a = new Alphabet(0, 0, mod == null ? "DISABLE MODS" : mod, true);
			a.isMenuItem = true;
			a.scrollFactor.set();
			alphabets.add(a);
		}
		add(alphabets);
		changeSelection(0, true);

		addVirtualPad('UP_DOWN', 'A_B');
		addVirtualPadCamera(); // dawg wtf
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		changeSelection((controls.DOWN_P ? 1 : 0) + (controls.UP_P ? -1 : 0) - FlxG.mouse.wheel);

		if (controls.ACCEPT) {
			ModsFolder.switchMod(mods[curSelected]);
			close();
		}

		if (controls.BACK)
			close();
	}

	public function changeSelection(change:Int, force:Bool = false) {
		if (change == 0 && !force) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, alphabets.length-1);

		CoolUtil.playMenuSFX(SCROLL, 0.7);

		for(k=>alphabet in alphabets.members) {
			alphabet.alpha = 0.6;
			alphabet.targetY = k - curSelected;
		}
		alphabets.members[curSelected].alpha = 1;
	}
}
#end
