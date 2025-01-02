package funkin.game;

import funkin.editors.charter.Charter;
import funkin.backend.scripting.events.GameOverCreationEvent;
import funkin.backend.scripting.events.CancellableEvent;
import funkin.backend.scripting.Script;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.menus.StoryMenuState;
import funkin.menus.FreeplayState;
import funkin.backend.system.Conductor;

class GameOverSubstate extends MusicBeatSubstate
{
	var character:Character;

	public var characterName:String;
	public var gameOverSong:String;
	public var gameOverSongBPM:Float;
	public var lossSFXName:String;
	public var retrySFX:String;
	public var player:Bool;

	var camFollow:FlxObject;

	public static var script:String = "";

	public var gameoverScript:Script;
	public var game:PlayState = PlayState.instance; // shortcut

	private var __cancelDefault:Bool = false;

	var x:Float = 0;
	var y:Float = 0;

	public var lossSFX:FlxSound;

	public function new(x:Float, y:Float, character:String = "bf-dead", player:Bool = true, gameOverSong:String = "gameOver", lossSFX:String = "gameOverSFX", retrySFX:String = "gameOverEnd")
	{
		super();
		this.x = x;
		this.y = y;
		this.characterName = character;
		this.player = player;
		this.gameOverSong = gameOverSong;
		this.lossSFXName = lossSFX;
		this.retrySFX = retrySFX;
	}

	public override function create()
	{
		super.create();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		gameoverScript = Script.create(Paths.script(script));
		gameoverScript.setParent(this);
		gameoverScript.load();

		var event = EventManager.get(GameOverCreationEvent).recycle(x, y, characterName, player, gameOverSong, gameOverSongBPM, lossSFXName, retrySFX);
		gameoverScript.call('create', [event]);

		x = event.x;
		y = event.y;
		characterName = event.character;
		player = event.player;
		gameOverSong = event.gameOverSong;
		gameOverSongBPM = event.bpm;
		lossSFXName = event.lossSFX;
		retrySFX = event.retrySFX;

		if (__cancelDefault = event.cancelled)
			return;

		character = new Character(x, y, characterName, player);
		character.danceOnBeat = false;
		character.playAnim('firstDeath');
		add(character);

		var camPos = character.getCameraPosition();
		camFollow = new FlxObject(camPos.x, camPos.y, 1, 1);
		add(camFollow);
		FlxG.camera.target = camFollow;

		lossSFX = FlxG.sound.play(Paths.sound(lossSFXName));
		Conductor.changeBPM(gameOverSongBPM);

		DiscordUtil.call("onGameOver", []);
		gameoverScript.call("postCreate");

		addVirtualPad('NONE', 'A_B');
		addVirtualPadCamera();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		gameoverScript.call("update", [elapsed]);

		if (__cancelDefault)
			return;

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			if (PlayState.chartingMode && Charter.undos.unsaved)
				game.saveWarn(false);
			else {
				PlayState.resetSongInfos();
				if (Charter.instance != null) Charter.instance.__clearStatics();

				if (FlxG.sound.music != null)
					FlxG.sound.music.stop();
				FlxG.sound.music = null;

				if (PlayState.isStoryMode)
					FlxG.switchState(new StoryMenuState());
				else
					FlxG.switchState(new FreeplayState());
			}

		}

		if (!isEnding && ((!lossSFX.playing) || (character.getAnimName() == "firstDeath" && character.isAnimFinished())) && (FlxG.sound.music == null || !FlxG.sound.music.playing))
		{
			CoolUtil.playMusic(Paths.music(gameOverSong), false, 1, true, 100);
			beatHit(0);
		}
	}

	override function beatHit(curBeat:Int)
	{
		super.beatHit(curBeat);

		gameoverScript.call("beatHit", [curBeat]);

		if (__cancelDefault)
			return;

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			character.playAnim("deathLoop", true, DANCE);
	}

	override function stepHit(curStep:Int)
	{
		super.stepHit(curStep);
		gameoverScript.call("stepHit", [curStep]);
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (isEnding)
			return;
		isEnding = true;

		var event = new CancellableEvent();
		gameoverScript.call('onEnd', [event]);

		if (event.cancelled)
			return;

		character.playAnim('deathConfirm', true);
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
		FlxG.sound.music = null;

		var sound = FlxG.sound.play(Paths.sound(retrySFX));

		var secsLength:Float = sound.length / 1000;
		var waitTime = 0.7;
		var fadeOutTime = secsLength - 0.7;

		if (fadeOutTime < 0.5)
		{
			fadeOutTime = secsLength;
			waitTime = 0;
		}

		new FlxTimer().start(waitTime, function(tmr:FlxTimer)
		{
			FlxG.camera.fade(FlxColor.BLACK, fadeOutTime, false, function()
			{
				MusicBeatState.skipTransOut = true;
				FlxG.switchState(new PlayState());
			});
		});
	}

	override function destroy()
	{
		gameoverScript.call("destroy");
		gameoverScript.destroy();

		super.destroy();
	}
}