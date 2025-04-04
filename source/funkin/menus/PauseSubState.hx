package funkin.menus;

import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.backend.FunkinText;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.events.MenuChangeEvent;
import funkin.backend.scripting.events.NameEvent;
import funkin.backend.scripting.events.PauseCreationEvent;
import funkin.backend.system.Conductor;
import funkin.backend.utils.FunkinParentDisabler;
import funkin.editors.charter.Charter;
import funkin.menus.StoryMenuState;
import funkin.options.OptionsMenu;
import funkin.options.TreeMenu;
import funkin.options.keybinds.KeybindsOptions;

class PauseSubState extends MusicBeatSubstate
{
	public static var script:String = "";

	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var levelInfo:FunkinText;
	var levelDifficulty:FunkinText;
	var deathCounter:FunkinText;
	var multiplayerText:FunkinText;

	var menuItems:Array<String> = ['Resume', 'Restart Song', 'Change Controls', 'Change Options', 'Exit to menu', "Exit to charter"];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;

	public var pauseScript:Script;

	public var game:PlayState = PlayState.instance; // shortcut

	private var __cancelDefault:Bool = false;

	public function new(x:Float = 0, y:Float = 0) {
		super();
	}

	var parentDisabler:FunkinParentDisabler;
	override function create()
	{
		super.create();

		if (menuItems.contains("Exit to charter") && !PlayState.chartingMode)
			menuItems.remove("Exit to charter");

		add(parentDisabler = new FunkinParentDisabler());

		pauseScript = Script.create(Paths.script(script));
		pauseScript.setParent(this);
		pauseScript.load();

		var event = EventManager.get(PauseCreationEvent).recycle('breakfast', menuItems);
		pauseScript.call('create', [event]);

		menuItems = event.options;

		pauseMusic = FlxG.sound.load(Paths.music(event.music), 0, true);
		pauseMusic.persist = false;
		pauseMusic.group = FlxG.sound.defaultMusicGroup;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		if (__cancelDefault = event.cancelled) return;

		var bg:FlxSprite = new FlxSprite().makeSolid(FlxG.width + 100, FlxG.height + 100, FlxColor.BLACK);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

		levelInfo = new FunkinText(20, 15, 0, PlayState.SONG.meta.displayName, 32, false);
		levelDifficulty = new FunkinText(20, 15, 0, PlayState.difficulty.toUpperCase(), 32, false);
		deathCounter = new FunkinText(20, 15, 0, "Blue balled: " + PlayState.deathCounter, 32, false);
		multiplayerText = new FunkinText(20, 15, 0, PlayState.opponentMode ? 'OPPONENT MODE' : (PlayState.coopMode ? 'CO-OP MODE' : ''), 32, false);

		for(k=>label in [levelInfo, levelDifficulty, deathCounter, multiplayerText]) {
			label.scrollFactor.set();
			label.alpha = 0;
			label.x = FlxG.width - (label.width + 20);
			label.y = 15 + (32 * k);
			FlxTween.tween(label, {alpha: 1, y: label.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3 * (k+1)});
			add(label);
		}

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		changeSelection();

		camera = new FlxCamera();
		camera.bgColor = 0;
		FlxG.cameras.add(camera, false);

		pauseScript.call("postCreate");

		game.updateDiscordPresence();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		pauseScript.call("update", [elapsed]);

		if (__cancelDefault) return;

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var scroll = FlxG.mouse.wheel;

		if (upP || downP || scroll != 0)  // like this we wont break mods that expect a 0 change event when calling sometimes  - Nex
			changeSelection((upP ? -1 : 0) + (downP ? 1 : 0) - scroll);

		if (controls.ACCEPT)
			selectOption();
	}

	public function selectOption() {
		var event = EventManager.get(NameEvent).recycle(menuItems[curSelected]);
		pauseScript.call("onSelectOption", [event]);

		if (event.cancelled) return;

		var daSelected:String = event.name;

		switch (daSelected)
		{
			case "Resume":
				close();
			case "Restart Song":
				parentDisabler.reset();
				game.registerSmoothTransition();
				FlxG.resetState();
			case "Change Controls":
				persistentDraw = false;
				openSubState(new KeybindsOptions());
			case "Change Options":
				TreeMenu.lastState = PlayState;
				FlxG.switchState(new OptionsMenu());
			case "Exit to charter":
				FlxG.switchState(new funkin.editors.charter.Charter(PlayState.SONG.meta.name, PlayState.difficulty, false));
			case "Exit to menu":
				if (PlayState.chartingMode && Charter.undos.unsaved)
					game.saveWarn(false);
				else {
					PlayState.resetSongInfos();
					if (Charter.instance != null) Charter.instance.__clearStatics();

					// prevents certain notes to disappear early when exiting  - Nex
					game.strumLines.forEachAlive(function(grp) grp.notes.__forcedSongPos = Conductor.songPosition);

					CoolUtil.playMenuSong();
					FlxG.switchState(PlayState.isStoryMode ? new StoryMenuState() : new FreeplayState());
				}

		}
	}
	override function destroy()
	{
		if(FlxG.cameras.list.contains(camera))
			FlxG.cameras.remove(camera, true);
		pauseScript.call("destroy");
		pauseScript.destroy();

		if (pauseMusic != null)
			@:privateAccess {
				FlxG.sound.destroySound(pauseMusic);
			}

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		var event = EventManager.get(MenuChangeEvent).recycle(curSelected, FlxMath.wrap(curSelected + change, 0, menuItems.length-1), change, change != 0);
		pauseScript.call("onChangeItem", [event]);
		if (event.cancelled) return;

		curSelected = event.value;

		for (i=>item in grpMenuShit.members)
		{
			item.targetY = i - curSelected;

			if (item.targetY == 0)
				item.alpha = 1;
			else
				item.alpha = 0.6;
		}
	}
}
