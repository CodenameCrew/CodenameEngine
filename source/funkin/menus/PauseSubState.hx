package funkin.menus;

import flixel.sound.FlxSound;
import funkin.backend.FunkinText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.backend.FunkinText;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.events.NameEvent;
import funkin.backend.scripting.events.menu.MenuChangeEvent;
import funkin.backend.scripting.events.menu.pause.*;
import funkin.backend.system.Conductor;
import funkin.backend.utils.FunkinParentDisabler;
import funkin.editors.charter.Charter;
import funkin.menus.StoryMenuState;
import funkin.options.OptionsMenu;
import funkin.options.keybinds.KeybindsOptions;

class PauseSubState extends MusicBeatSubstate
{
	public static var script:String = Flags.DEFAULT_PAUSE_SCRIPT;

	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var levelInfo:FunkinText;
	var levelDifficulty:FunkinText;
	var deathCounter:FunkinText;
	var multiplayerText:FunkinText;

	var menuItems:Array<String>;

	var curSelected:Int = 0;

	var pauseMusic:FlxSound;

	public var pauseScript:Script;
	public var selectCall:NameEvent->Void;  // Mainly for extern stuff that aren't scripts  - Nex

	public var game:PlayState = PlayState.instance; // shortcut

	private var __cancelDefault:Bool = false;

	public function new(?items:Array<String>, ?selectCall:NameEvent->Void) {
		super();
		menuItems = items != null ? items : Flags.DEFAULT_PAUSE_ITEMS.copy();
		this.selectCall = selectCall;
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

		var event = EventManager.get(PauseCreationEvent).recycle(Flags.DEFAULT_PAUSE_MENU_MUSIC, menuItems);
		pauseScript.call('create', [event]);

		menuItems = event.options;

		pauseMusic = FlxG.sound.load(Assets.getMusic(Paths.music(event.music)), 0, true);
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

		var multiplayerInfo:String = PlayState.opponentMode ? 'pause.coopMode' :
									 PlayState.coopMode ? 'pause.opponentMode' :
									 null;

		levelInfo = new FunkinText(20, 15, 0, PlayState.SONG.meta.displayName, 32, false);
		levelDifficulty = new FunkinText(20, 15, 0, TU.translateDiff(PlayState.difficulty).toUpperCase(), 32, false);
		deathCounter = new FunkinText(20, 15, 0, TU.translate("pause.deathCounter", [PlayState.deathCounter]), 32, false);
		multiplayerText = null;
		if(multiplayerInfo != null)
			multiplayerText = new FunkinText(20, 15, 0, TU.translate(multiplayerInfo), 32, false);

		for(k=>label in [levelInfo, levelDifficulty, deathCounter, multiplayerText]) {
			if(label == null) continue;
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
			var pauseId = "pause." + TU.raw2Id(menuItems[i]);
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, TU.translate(pauseId), "bold");
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
		if (selectCall != null) selectCall(event);
		pauseScript.call("onSelectOption", [event]);
		if (event.cancelled) return;

		switch (event.name)
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
				FlxG.switchState(new OptionsMenu((_) -> FlxG.switchState(new PlayState())));
			case "Exit to charter":
				FlxG.switchState(new Charter(PlayState.SONG.meta.name, PlayState.difficulty, PlayState.variation, false));
			case "Exit to menu":
				if (PlayState.chartingMode && Charter.undos.unsaved)
					game.saveWarn(false);
				else {
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
		if(camera != FlxG.camera && _cameras != null) {
			if(FlxG.cameras.list.contains(camera))
				FlxG.cameras.remove(camera, true);
		}
		pauseScript.call("destroy");
		pauseScript.destroy();

		if(pauseMusic != null) {
			@:privateAccess
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

			item.alpha = (item.targetY == 0) ? 1 : 0.6;
		}
	}
}
