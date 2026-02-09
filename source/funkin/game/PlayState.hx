package funkin.game;

import flixel.FlxState;
import flixel.FlxSubState;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.VarTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import funkin.backend.FunkinText;
import funkin.backend.chart.Chart;
import funkin.backend.chart.ChartData;
import funkin.backend.chart.EventsData;
import funkin.backend.scripting.DummyScript;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.ScriptPack;
import funkin.backend.scripting.events.*;
import funkin.backend.scripting.events.gameplay.*;
import funkin.backend.scripting.events.note.*;
import funkin.backend.system.Conductor;
import funkin.backend.system.RotatingSpriteGroup;
import funkin.editors.SaveWarning;
import funkin.editors.charter.Charter;
import funkin.editors.charter.CharterSelection;
import funkin.game.SplashHandler;
import funkin.game.cutscenes.*;
import funkin.game.scoring.*;
import funkin.game.scoring.RatingManager.Rating;
import funkin.menus.*;
import funkin.backend.week.WeekData;
import funkin.savedata.FunkinSave;
import haxe.io.Path;

using StringTools;

@:access(flixel.text.FlxText.FlxTextFormatRange)
@:access(funkin.game.StrumLine)
class PlayState extends MusicBeatState
{
	/**
	 * Current PlayState instance.
	 */
	public static var instance:PlayState = null;

	/**
	 * SONG DATA (Chart, Metadata).
	 */
	public static var SONG:ChartData;
	/**
	 * Whenever the song is being played in Story Mode.
	 */
	public static var isStoryMode:Bool = false;
	/**
	 * The week data of the current week
	 */
	public static var storyWeek:WeekData = null;
	/**
	 * The remaining songs in the Story Mode playlist.
	 */
	public static var storyPlaylist:Array<String> = [];
	/**
	 * The remaining variations to play with the Story Mode
	 */
	public static var storyVariations:Array<String> = [];
	/**
	 * The selected difficulty name.
	 */
	public static var difficulty:String = Flags.DEFAULT_DIFFICULTY;
	/**
	 * The selected variation name. (It can be null)
	 */
	public static var variation:Null<String>;
	/**
	 * Whenever the week is coming from the mods folder or not.
	 */
	public static var fromMods:Bool = false;
	/**
	 * Whenever Charting Mode is enabled for this song.
	 */
	public static var chartingMode:Bool = false;
	/**
	 * Whenever the song is started with opponent mode on.
	 */
	public static var opponentMode:Bool = Flags.DEFAULT_OPPONENT_MODE;
	/**
	 * Whenever the song is started with co-op mode on.
	 */
	public static var coopMode:Bool = Flags.DEFAULT_COOP_MODE;

	/**
	 * Script Pack of all the scripts being ran.
	 */
	public var scripts:ScriptPack;

	/**
	 * Array of all the players in the stage.
	 */
	public var strumLines:FlxTypedGroup<StrumLine> = new FlxTypedGroup<StrumLine>();

	/**
	 * Death counter on current week (or song if from freeplay).
	 */
	public static var deathCounter:Int = 0;
	/**
	 * Game Over Song. (assets/music/gameOver.ogg).
	 */
	public var gameOverSong:String = Flags.DEFAULT_GAMEOVER_MUSIC;
	/**
	 * Game Over Song. (assets/sounds/gameOverSFX.ogg).
	 */
	public var lossSFX:String = Flags.DEFAULT_GAMEOVERSFX_SOUND;
	/**
	 * Game Over End SFX, used when retrying. (assets/sounds/gameOverEnd.ogg).
	 */
	public var retrySFX:String = Flags.DEFAULT_GAMEOVEREND_SOUND;

	/**
	 * Current Stage.
	 */
	public var stage:Stage;
	/**
	 * Whenever the score will save when you beat the song.
	 */
	public var validScore:Bool = true;
	/**
	 * Whenever the player can die.
	 */
	public var canDie:Bool = !opponentMode && !coopMode;
	/**
	 * Whenever Ghost Tapping is enabled.
	 */
	public var ghostTapping:Bool = Options.ghostTapping;
	/**
	 * Whenever the opponent can die.
	 */
	public var canDadDie:Bool = opponentMode && !coopMode;
	/**
	 * Current scroll speed for all strums.
	 * To set a scroll speed for a specific strum, use `strum.scrollSpeed`.
	 */
	public var scrollSpeed:Float = 0;
	/**
	 * Whenever the game is in downscroll or not. (Can be set)
	 */
	public var downscroll(get, set):Bool;

	private inline function set_downscroll(v:Bool) return camHUD.downscroll = v;
	private inline function get_downscroll():Bool return camHUD.downscroll;

	/**
	 * Instrumental sound (Inst.ogg).
	 */
	public var inst:FlxSound;
	/**
	 * Vocals sound (Vocals.ogg).
	 */
	public var vocals:FlxSound;

	/**
	 * Dad character.
	 */
	public var dad(get, set):Character;
	/**
	 * Girlfriend character.
	 */
	public var gf(get, set):Character;
	/**
	 * Boyfriend character.
	 */
	public var boyfriend(get, set):Character;
	/**
	 * Boyfriend character.
	 * Same as boyfriend, just shorter.
	**/
	public var bf(get, set):Character;

	/**
	 * Strum line position.
	 */
	public var strumLine:FlxObject;
	/**
	 * Number of ratings.
	 */
	public var ratingNum:Int = 0;

	/**
	 * Object defining the camera follow target.
	 */
	public var camFollow:FlxObject;

	/**
	 * Previous cam follow.
	 */
	private static var smoothTransitionData:PlayStateTransitionData;
	/**
	 * Player strums.
	 */
	public var playerStrums(get, set):StrumLine;
	/**
	 * CPU strums.
	 */
	public var cpuStrums(get, set):StrumLine;
	/**
	 * Shortcut to `playerStrums`.
	 */
	public var player(get, set):StrumLine;
	/**
	 * Shortcut to `cpuStrums`.
	 */
	public var cpu(get, set):StrumLine;

	/**
	 * Note splashes container.
	 */
	public var splashHandler:SplashHandler;

	/**
	 * Whenever the vocals should be muted when a note is missed.
	 */
	public var muteVocalsOnMiss:Bool = Flags.DEFAULT_MUTE_VOCALS_ON_MISS;
	/**
	 * Whenever the player can press 7, 8 or 9 to access the debug menus.
	 */
	public var canAccessDebugMenus:Bool = !Flags.DISABLE_EDITORS;
	/**
	 * Whether or not to show the secret gitaroo pause.
	 */
	public var allowGitaroo:Bool = Flags.DEFAULT_GITAROO;
	/**
	 * Whether or not to bop the icons on beat.
	 */
	public var doIconBop:Bool = Flags.DEFAULT_ICONBOP;

	/**
	 * Current song name (lowercase).
	 */
	public var curSong:String = "";
	/**
	 * Current song name (lowercase and spaces to dashes).
	 */
	public var curSongID:String = "";
	/**
	 * Current stage name.
	 */
	public var curStage(get, set):String;

	/**
	 * Interval at which Girlfriend dances.
	 */
	public var gfSpeed(get, set):Int;

	/**
	 * Current health. Goes from 0 to maxHealth (defaults to 2).
	 */
	public var health(default, set):Float = 1;

	/**
	 * Maximum health the player can have. Defaults to 2.
	 */
	public var maxHealth(default, set):Float = Flags.DEFAULT_MAX_HEALTH;
	/**
	 * Current combo.
	 */
	public var combo:Int = 0;

	/**
	 * Whenever the misses should show "Combo Breaks" instead of "Misses".
	 */
	public var comboBreaks:Bool = !Options.ghostTapping;
	/**
	 * Health bar background.
	 */
	public var healthBarBG:FlxSprite;
	/**
	 * Health bar.
	 */
	public var healthBar:FlxBar;

	/**
	 * Whenever the music has been generated.
	 */
	public var generatedMusic:Bool = false;
	/**
	 * Whenever the song is currently being started.
	 */
	public var startingSong:Bool = false;

	/**
	 * Player's icon.
	 */
	public var iconP1:HealthIcon;
	/**
	 * Opponent's icon.
	 */
	public var iconP2:HealthIcon;
	/**
	 * Every active icon that will be updated during gameplay (defaults to `iconP1` and `iconP1` between `create` and `postCreate` in scripts).
	 */
	public var iconArray:Array<HealthIcon> = [];

	/**
	 * Camera for the HUD (notes, misses).
	 */
	public var camHUD:HudCamera;
	/**
	 * Camera for the game (stages, characters).
	 */
	public var camGame:FlxCamera;

	/**
	 * The player's current score.
	 */
	public var songScore:Int = 0;
	/**
	 * The player's amount of misses.
	 */
	public var misses:Int = 0;
	/**
	 * The player's accuracy (shortcut to `accuracyPressedNotes / totalAccuracyAmount`).
	 */
	public var accuracy(get, set):Float;
	/**
	 * The number of pressed notes.
	 */
	public var accuracyPressedNotes:Float = 0;
	/**
	 * The total accuracy amount.
	 */
	public var totalAccuracyAmount:Float = 0;
	/**
	 * Tracks how much of each rating was received.
	 */
	public var hits:Map<String, Int> = [];

	/**
	 * FunkinText that shows your score.
	 */
	public var scoreTxt:FunkinText;
	/**
	 * FunkinText that shows your amount of misses.
	 */
	public var missesTxt:FunkinText;
	/**
	 * FunkinText that shows your accuracy.
	 */
	public var accuracyTxt:FunkinText;

	/**
	 * Score for the current week.
	 */
	public static var campaignScore:Int = 0;

	/**
	 * Misses for the current week.
	 */
	public static var campaignMisses:Int = 0;

	/**
	 * Accuracy for the current week.
	 */
	public static var campaignAccuracy(get, never):Float;

	public static var campaignAccuracyTotal:Float = 0;
	public static var campaignAccuracyCount:Float = 0;

	/**
	 * Number of each rating received for the current week.
	 */
	public static var campaignHits:Map<String, Int> = [];

	/**
	 * Camera zoom at which the game lerps to.
	 */
	public var defaultCamZoom:Float = Flags.DEFAULT_CAM_ZOOM;
	/**
	 * Speed at which the game camera zoom lerps to.
	 */
	public var camGameZoomLerp:Float = Flags.DEFAULT_CAM_ZOOM_LERP;
	/**
	 * The current multiplier for game camera zooming.
	 */
	public var camGameZoomMult:Float = Flags.DEFAULT_CAM_ZOOM_MULT;

	/**
	 * Camera zoom at which the hud lerps to.
	 */
	public var defaultHudZoom:Float = Flags.DEFAULT_HUD_ZOOM;
	/**
	 * Speed at which the hud camera zoom lerps to.
	 */
	public var camHUDZoomLerp:Float = Flags.DEFAULT_HUD_ZOOM_LERP;
	/**
	 * The current multiplier for game camera zooming.
	 */
	public var camHUDZoomMult:Float = Flags.DEFAULT_HUD_ZOOM_MULT;

	/**
	 * Camera zoom at which the cameras that zooms lerps to.
	 * (Only used if useCamZoomMult is on).
	 */
	public var defaultZoom:Float = Flags.DEFAULT_ZOOM;
	/**
	 * Speed at which the cameras that zooms zoom lerps to.
	 * (Only used if useCamZoomMult is on).
	 */
	public var camZoomLerp:Float = Flags.DEFAULT_ZOOM_LERP;

	/**
	 * Whenever cam zooming is enabled, enables on a note hit if not cancelled.
	 */
	public var camZooming:Bool = false;
	/**
	 * Interval of cam zooming (in conductor values).
	 * Example: If Interval is 1 and Beat Type is on MEASURE, it'll zoom every a measure.
	 * NOTE: Will set to 4 if not found any other time signatures unlike 4/4.
	 */
	public var camZoomingInterval:Float = Flags.DEFAULT_CAM_ZOOM_INTERVAL;
	/**
	 * Number of Conductor values to offset camZooming by.
	 */
	public var camZoomingOffset:Float = Flags.DEFAULT_CAM_ZOOM_OFFSET;
	/**
	 * Beat type for interval of cam zooming.
	 * Example: If Beat Type is on STEP and Interval is 2, it'll zoom every 2 steps.
	 * NOTE: Will set to BEAT if not found any other time signatures unlike 4/4.
	 */
	public var camZoomingEvery:BeatType = MEASURE;
	/**
	 * Stores what was the last beat for the cam zooming intervals.
	 */
	public var camZoomingLastBeat:Float;
	/**
	 * How strong the cam zooms should be (defaults to 1).
	 */
	public var camZoomingStrength:Float = Flags.DEFAULT_CAM_ZOOM_STRENGTH;
	/**
	 * Default multiplier for `maxCamZoom`.
	 */
	public var maxCamZoomMult:Float = Flags.MAX_CAMERA_ZOOM_MULT;
	/**
	 * Whether it should use a implementation where it multiplies the current camera zoom instead.
	 */
	public var useCamZoomMult:Bool = Flags.USE_CAM_ZOOM_MULT;
	/**
	 * The current multiplier for camera zooming.
	 * (Only used if useCamZoomMult is on).
	 */
	public var camZoomingMult:Float = Flags.DEFAULT_ZOOM;
	/**
	 * Maximum amount of zoom for the camera (based on `maxCamZoomMult` and the camera's zoom IF not set).
	 */
	public var maxCamZoom(get, default):Float = Math.NaN;

	private inline function get_maxCamZoom() return Math.isNaN(maxCamZoom) ? defaultCamZoom + (camZoomingMult * camGameZoomMult) : maxCamZoom;

	/**
	 * Zoom for the pixel assets.
	 */
	public static var daPixelZoom:Float = Flags.PIXEL_ART_SCALE;

	/**
	 * Whenever the game is currently in a cutscene or not.
	 */
	public var inCutscene:Bool = false;
	/**
	 * Whenever the game should play the cutscenes. Defaults to whenever the game is currently in Story Mode or not.
	 */
	public var playCutscenes:Bool = isStoryMode;
	/**
	 * Whenever the game has already played a specific cutscene for the current song. Check `startCutscene` for more details.
	 */
	public static var seenCutscene:Bool = false;
	/**
	 * Cutscene script path.
	 */
	public var cutscene:String = null;
	/**
	 * End cutscene script path.
	 */
	public var endCutscene:String = null;

	/**
	 * Last rating (may be null).
	 */
	public var curRating:ComboRating;

	/**
	 * Timer for the start countdown.
	 */
	public var startTimer:FlxTimer;
	/**
	 * Remaining events.
	 */
	public var events:Array<ChartEvent> = [];
	/**
	 * Current camera target. -1 means no automatic camera targeting.
	 */
	public var curCameraTarget:Int = 0;
	/**
	 * Length of the intro countdown.
	 */
	public var introLength:Int = Flags.DEFAULT_INTRO_LENGTH;
	/**
	 * Array of sprites for the intro.
	 */
	public var introSprites:Array<String> = Flags.DEFAULT_INTRO_SPRITES.copy();
	/**
	 * Array of sounds for the intro.
	 */
	public var introSounds:Array<String> = Flags.DEFAULT_INTRO_SOUNDS.copy();

	/**
	 * Whenever the game is paused or not.
	 */
	public var paused:Bool = false;
	/**
	 * Whenever the countdown has started or not.
	 */
	public var startedCountdown:Bool = false;
	/**
	 * Whenever the game can be paused or not.
	 */
	public var canPause:Bool = true;

	/**
	 * Format for the accuracy rating.
	 */
	public var accFormat:FlxTextFormat = new FlxTextFormat(0xFF888888, false, false, 0);
	/**
	 * Whenever the song is ending or not.
	 */
	public var endingSong:Bool = false;

	/**
	 * Group containing all of the combo sprites.
	 */
	public var comboGroup:RotatingSpriteGroup;
	/**
	 * Manager that helps judge note hits to return ratings.
	 */
	public var ratingManager:RatingManager = new RatingManager();
	/**
	 * Whenever the Rating sprites should be shown or not.
	 *
	 * NOTE: This is just a default value for the final value, the final value can be changed through notes hit events.
	 */
	public var defaultDisplayRating:Bool = true;
	/**
	 * Whenever the Combo sprite should be shown or not (like old Week 7 patches).
	 *
	 * NOTE: This is just a default value for the final value, the final value can be changed through notes hit events.
	 */
	public var defaultDisplayCombo:Bool = false;
	/**
	 * Minimum Combo Count to display the combo digits. Anything less than 0 means it won't be shown.
	 */
	public var minDigitDisplay:Int = 10;
	/**
	 * Array containing all of the note types names.
	 */
	public var noteTypesArray:Array<String> = [null];

	/**
	 * Hit window, in milliseconds. A Legacy CNE Hit window configuration,
	 * Don't use this, it's for mods that still uses the old judgement timing, instead use ratingManager.
	 */
	public var hitWindow:Float = Options.hitWindow;
	@:noCompletion @:dox(hide) private var _legacyRating:Rating = {name: "", window: 0, accuracy: 0, score: 0};

	@:noCompletion @:dox(hide) private var _startCountdownCalled:Bool = false;
	@:noCompletion @:dox(hide) private var _endSongCalled:Bool = false;

	@:dox(hide)
	var __vocalSyncTimer:Float = 1;

	private function get_accuracy():Float {
		if (accuracyPressedNotes <= 0) return -1;
		return totalAccuracyAmount / accuracyPressedNotes;
	}
	private function set_accuracy(v:Float):Float {
		if (accuracyPressedNotes <= 0)
			accuracyPressedNotes = 1;
		return totalAccuracyAmount = v * accuracyPressedNotes;
	}
	/**
	 * All combo ratings.
	 */
	public var comboRatings:Array<ComboRating> = [
		new ComboRating(0, "F", 0xFFFF4444),
		new ComboRating(0.5, "E", 0xFFFF8844),
		new ComboRating(0.7, "D", 0xFFFFAA44),
		new ComboRating(0.8, "C", 0xFFFFFF44),
		new ComboRating(0.85, "B", 0xFFAAFF44),
		new ComboRating(0.9, "A", 0xFF88FF44),
		new ComboRating(0.95, "S", 0xFF44FFFF),
		new ComboRating(1, "S++", 0xFF44FFFF),
	];

	public var detailsText:String = "";
	public var detailsPausedText:String = "";

	@:unreflective
	private var __cachedGraphics:Array<FlxGraphic> = [];

	/**
	 * Updates the rating.
	 */
	public function updateRating() {
		var rating = null;
		var acc = accuracy;  // caching since it has a getter with an operation  - Nex

		if (comboRatings != null && comboRatings.length > 0) for (e in comboRatings)
			if ((e.percent <= acc && e.maxMisses >= misses) && (rating == null || (rating.percent < e.percent && e.maxMisses >= misses)))
				rating = e;

		var event = gameAndCharsEvent("onRatingUpdate", EventManager.get(RatingUpdateEvent).recycle(rating, curRating));
		if (!event.cancelled)
			curRating = event.rating;
	}

	private inline function set_health(v:Float)
		return health = FlxMath.bound(v, 0, maxHealth);
	private inline function set_maxHealth(v:Float) {
		if (healthBar != null && healthBar.max == maxHealth) healthBar.setRange(healthBar.min, v);
		maxHealth = v;
		health = health;  // running the setter  - Nex
		return maxHealth;
	}

	private inline function get_curStage()
		return stage == null ? "" : stage.stageName;

	private inline function set_curStage(name:String) {
		if (stage != null) stage.stageName = name;
		return name;
	}

	public inline function callOnCharacters(func:String, ?parameters:Array<Dynamic>) {
		if(strumLines != null) strumLines.forEachAlive(function (strLine:StrumLine) {
			if (strLine.characters != null) for (character in strLine.characters)
				if (character != null) character.scripts.call(func, parameters);
		});
	}

	public inline function gameAndCharsCall(func:String, ?parameters:Array<Dynamic>, ?charsFunc:String) {
		scripts.call(func, parameters);
		callOnCharacters(charsFunc != null ? charsFunc : func, parameters);
	}

	public inline function gameAndCharsEvent<T:CancellableEvent>(func:String, ?event:T, ?charsFunc:String):T {
		scripts.event(func, event);
		callOnCharacters(charsFunc != null ? charsFunc : func, [event]);
		return event;
	}

	@:dox(hide) override public function create()
	{
		Note.__customNoteTypeExists = [];

		// SCRIPTING & DATA INITIALIZATION
		#if REGION
		instance = this;
		if (FlxG.sound.music != null) FlxG.sound.music.stop();

		PauseSubState.script = Flags.DEFAULT_PAUSE_SCRIPT;
		GameOverSubstate.script = Flags.DEFAULT_GAMEOVER_SCRIPT;
		(scripts = new ScriptPack("PlayState")).setParent(this);

		camGame = camera;
		FlxG.cameras.add(camHUD = new HudCamera(), false);
		camHUD.bgColor.alpha = 0;

		downscroll = Options.downscroll;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Chart.parse('tutorial', difficulty = 'normal', variation = null);

		scrollSpeed = SONG.scrollSpeed;

		Conductor.setupSong(SONG);

		detailsText = isStoryMode ? ("Story Mode: " + storyWeek.name) : "Freeplay";

		for (rating in [for (i in ratingManager.ratingData) i.name]) hits.set(rating, 0); // Ensure all keys exist as to prevent null errors.

		// Checks if cutscene files exists
		var cutscenePath = Paths.script('songs/${SONG.meta.name}/cutscene');
		var endCutscenePath = Paths.script('songs/${SONG.meta.name}/cutscene-end');
		if (Assets.exists(cutscenePath)) cutscene = cutscenePath;
		if (Assets.exists(endCutscenePath)) endCutscene = endCutscenePath;

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		// CHARACTER INITIALIZATION
		#if REGION
		comboGroup = new RotatingSpriteGroup(FlxG.width * 0.55, (FlxG.height * 0.5) - 60);
		comboGroup.maxSize = Flags.DEFAULT_COMBO_GROUP_MAX_SIZE;
		#end

		// CAMERA FOLLOW, SCRIPTS & STAGE INITIALIZATION
		#if REGION
		camFollow = new FlxObject(0, 0, 2, 2);
		add(camFollow);

		if (SONG.stage == null || SONG.stage.trim() == "") SONG.stage = Flags.DEFAULT_STAGE;
		add(stage = new Stage(SONG.stage));

		if (!chartingMode || Options.charterEnablePlaytestScripts) {
			switch(SONG.meta.name) {
				// case "":
					// ADD YOUR HARDCODED SCRIPTS HERE!
				default:
					var normal = 'songs/${SONG.meta.name}/scripts';
					var scriptsFolders:Array<String> = [normal, normal + '/$difficulty/', 'data/charts/', 'songs/'];

					for (folder in scriptsFolders) {
						for (file in Paths.getFolderContent(folder, true, fromMods ? MODS : BOTH)) {
							if (folder == 'data/charts/')
								Logs.warn('data/charts/ is deprecated and will be removed in the future. Please move script $file to songs/', DARKYELLOW, "PlayState");

							addScript(file);
						}
					}

					var songEvents:Array<String> = [];
					for (event in SONG.events) songEvents.pushOnce(event.name);

					for (file in Paths.getFolderContent('data/events/', true, fromMods ? MODS : BOTH)) {
						var fileName:String = CoolUtil.getFilename(file);
						if (EventsData.eventsList.contains(fileName) && songEvents.contains(fileName)) {
							addScript(file);
						}
					}
			}
		}

		add(comboGroup);
		#end

		// PRECACHING
		#if REGION
		for(content in Paths.getFolderContent('images/game/score/', true, BOTH))
			graphicCache.cache(Paths.getPath(content));

		for(i in 1...4) {
			FlxG.sound.load(Paths.sound('missnote' + Std.string(i)));
		}
		#end

		// STRUMS & NOTES INITIALIZATION
		#if REGION
		strumLine = new FlxObject(0, 50, FlxG.width, 10);
		strumLine.scrollFactor.set();

		generateSong(SONG);

		for(noteType in SONG.noteTypes) {
			var scriptPath = Paths.script('data/notes/${noteType}');
			if (Assets.exists(scriptPath) && !scripts.contains(scriptPath)) {
				var script = Script.create(scriptPath);
				if (!(script is DummyScript)) {
					scripts.add(script);
					script.load();
				}
			}
		}

		for(i=>strumLine in SONG.strumLines) {
			if (strumLine == null) continue;

			var chars = [];
			var charPosName:String = strumLine.position == null ? (switch(strumLine.type) {
				case 0: "dad";
				case 1: "boyfriend";
				case 2: "girlfriend";
			}) : strumLine.position;
			if (strumLine.characters != null) for(k=>charName in strumLine.characters) {
				var char = new Character(0, 0, charName, stage.isCharFlipped(stage.characterPoses[charName] != null ? charName : charPosName, strumLine.type == 1));
				stage.applyCharStuff(char, charPosName, k);
				chars.push(char);
			}

			var strOffset:Float = strumLine.strumLinePos != null ? strumLine.strumLinePos : (strumLine.type == 1 ? 0.75 : 0.25);
			var strScale:Float = strumLine.strumScale != null ? strumLine.strumScale : 1;
			var strSpacing:Float = strumLine.strumSpacing == null ? 1 : strumLine.strumSpacing;
			var keyCount:Int = strumLine.keyCount == null ? 4 : strumLine.keyCount;
			var strXPos:Float = StrumLine.calculateStartingXPos(strOffset, strScale, strSpacing, keyCount);
			var startingPos:FlxPoint = strumLine.strumPos != null ?
				FlxPoint.get(strumLine.strumPos[0] == 0 ? strXPos : strumLine.strumPos[0], strumLine.strumPos[1]) :
				FlxPoint.get(strXPos, this.strumLine.y);
			var strLine = new StrumLine(chars,
				startingPos,
				strumLine.strumScale == null ? 1 : strumLine.strumScale,
				strumLine.type == 2 || (!coopMode && !((strumLine.type == 1 && !opponentMode) || (strumLine.type == 0 && opponentMode))),
				strumLine.type != 1, coopMode ? ((strumLine.type == 1) != opponentMode ? controlsP1 : controlsP2) : controls,
				strumLine.vocalsSuffix
			);
			strLine.cameras = [camHUD];
			strLine.data = strumLine;
			strLine.visible = (strumLine.visible != false);
			strLine.vocals.group = FlxG.sound.defaultMusicGroup;
			strLine.ID = i;
			strumLines.add(strLine);
		}

		add(strumLines);

		splashHandler = new SplashHandler();
		add(splashHandler);

		scripts.set("SONG", SONG);
		scripts.load();
		scripts.call("create");
		#end

		// HUD INITIALIZATION & CAMERA INITIALIZATION
		#if REGION
		var event = EventManager.get(AmountEvent).recycle(null);
		if (!gameAndCharsEvent("onPreGenerateStrums", event).cancelled) {
			generateStrums(event.amount);
			gameAndCharsEvent("onPostGenerateStrums", event);
		}

		for(str in strumLines)
			str.generate(str.data, (chartingMode && Charter.startHere) ? Charter.startTime : null);

		FlxG.camera.follow(camFollow, LOCKON, Flags.DEFAULT_CAMERA_FOLLOW_SPEED);
		FlxG.camera.zoom = defaultCamZoom;
		// camHUD.zoom = defaultHudZoom;

		if (smoothTransitionData != null && smoothTransitionData.stage == curStage) {
			FlxG.camera.scroll.set(smoothTransitionData.camX, smoothTransitionData.camY);
			FlxG.camera.zoom = smoothTransitionData.camZoom;
			MusicBeatState.skipTransIn = true;
			camFollow.setPosition(smoothTransitionData.camFollowX, smoothTransitionData.camFollowY);
		} else {
			FlxG.camera.focusOn(camFollow.getPosition(FlxPoint.weak()));
		}
		smoothTransitionData = null;

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadAnimatedGraphic(Paths.image('game/healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, maxHealth);
		healthBar.scrollFactor.set();
		var leftColor:Int = dad != null && dad.iconColor != null && Options.colorHealthBar ? dad.iconColor : (opponentMode ? 0xFF66FF33 : 0xFFFF0000);
		var rightColor:Int = boyfriend != null && boyfriend.iconColor != null && Options.colorHealthBar ? boyfriend.iconColor : (opponentMode ? 0xFFFF0000 : 0xFF66FF33); // switch the colors
		healthBar.createFilledBar(leftColor, rightColor);
		add(healthBar);

		if (Flags.DEFAULT_HEALTH != null) health = Flags.DEFAULT_HEALTH;
		else health = maxHealth / 2;

		iconArray.push(iconP1 = new HealthIcon(boyfriend != null ? boyfriend.getIcon() : Flags.DEFAULT_HEALTH_ICON, true));
		iconArray.push(iconP2 = new HealthIcon(dad != null ? dad.getIcon() : Flags.DEFAULT_HEALTH_ICON, false));
		for (icon in iconArray) {
			icon.y = healthBar.y - (icon.height / 2);
			add(icon);
		}

		scoreTxt = new FunkinText(healthBarBG.x + 50, healthBarBG.y + 30, Std.int(healthBarBG.width - 100), TEXT_GAME_SCORE.format([songScore]), 16);
		missesTxt = new FunkinText(healthBarBG.x + 50, healthBarBG.y + 30, Std.int(healthBarBG.width - 100), TEXT_GAME_MISSES.format([misses]), 16);
		accuracyTxt = new FunkinText(healthBarBG.x + 50, healthBarBG.y + 30, Std.int(healthBarBG.width - 100), TEXT_GAME_ACCURACY.format(["-%", "(N/A)"]), 16);
		accuracyTxt.addFormat(accFormat, 0, 1);

		for(text in [scoreTxt, missesTxt, accuracyTxt]) {
			text.scrollFactor.set();
			add(text);
		}
		scoreTxt.alignment = RIGHT;
		missesTxt.alignment = CENTER;
		accuracyTxt.alignment = LEFT;
		if (updateRatingStuff != null)
			updateRatingStuff();

		for(e in [healthBar, healthBarBG, iconP1, iconP2, scoreTxt, missesTxt, accuracyTxt])
			e.cameras = [camHUD];
		#end

		startingSong = true;

		super.create();

		for(s in introSprites)
			if (s != null)
				graphicCache.cache(Paths.image(s));

		for(s in introSounds)
			if (s != null)
				FlxG.sound.load(Paths.sound(s));

		if (chartingMode) {
			WindowUtils.prefix = Charter.undos.unsaved ? Flags.UNDO_PREFIX : "";
			WindowUtils.suffix = TU.translate("playtesting.chartPlaytesting");

			SaveWarning.showWarning = Charter.undos.unsaved;
			SaveWarning.selectionClass = CharterSelection;
			SaveWarning.warningFunc = saveWarn;
			SaveWarning.saveFunc = () -> Charter.saveEverything(false);
		}
	}

	@:dox(hide) public override function createPost() {
		startCutscene("", cutscene, null, true);
		super.createPost();

		updateDiscordPresence();

		// Make icons appear in the correct spot during cutscenes
		healthBar.update(0);
		if (updateIconPositions != null)
			updateIconPositions();

		__updateNote_event = EventManager.get(NoteUpdateEvent);

		gameAndCharsCall("postCreate", null, "gamePostCreate");
	}

	/**
	 * Function used to update Discord Presence.
	 *
	 * This function is dynamic, which means you can do `updateDiscordPresence = function() {}` in scripts.
	 */
	public dynamic function updateDiscordPresence()
		DiscordUtil.call("onPlayStateUpdate", []);

	/**
	 * Starts a cutscene.
	 * @param prefix Custom prefix. Using `midsong-` will require you to for example rename your video cutscene to `songs/song/midsong-cutscene.mp4` instead of `songs/song/cutscene.mp4`
	 * @param cutsceneScriptPath Optional: Custom script path.
	 * @param callback Callback called after the cutscene ended. If equals to `null`, `startCountdown` will be called.
	 * @param checkSeen Bool that by default is false, if true and `seenCutscene` is also true, it won't play the cutscene but directly call `callback` (PS: `seenCutscene` becomes true if the cutscene gets played and `checkSeen` was true)
	 * @param canSkipTransIn Bool that by default is true makes the in transition skip on certain types of cutscenes like dialogues.
	 */
	public function startCutscene(prefix:String = "", ?cutsceneScriptPath:String, ?callback:Void->Void, checkSeen:Bool = false, canSkipTransIn:Bool = true) {
		if (callback == null) callback = startCountdown;
		if ((checkSeen && seenCutscene) || !playCutscenes) {
			callback();
			return;
		}

		var songName = SONG.meta.name;

		if (cutsceneScriptPath == null)
			cutsceneScriptPath = Paths.script('songs/$songName/${prefix}cutscene');

		inCutscene = true;
		var videoCutscene = Paths.video('$songName-${prefix}cutscene');
		var videoCutsceneAlt = Paths.file('songs/$songName/${prefix}cutscene.${Flags.VIDEO_EXT}');
		var dialogue = Paths.file('songs/$songName/${prefix}dialogue.xml');
		persistentUpdate = true;
		var toCall:Void->Void = function() {
			if(checkSeen) seenCutscene = true;
			callback();
		}

		if (cutsceneScriptPath != null && Assets.exists(cutsceneScriptPath)) {
			openSubState(new ScriptedCutscene(cutsceneScriptPath, toCall));
		} else if (Assets.exists(dialogue)) {
			if (canSkipTransIn) MusicBeatState.skipTransIn = true;
			openSubState(new DialogueCutscene(dialogue, toCall));
		} else if (Assets.exists(videoCutsceneAlt)) {
			if (canSkipTransIn) MusicBeatState.skipTransIn = true;
			persistentUpdate = false;
			openSubState(new VideoCutscene(videoCutsceneAlt, toCall));
			persistentDraw = false;
		} else if (Assets.exists(videoCutscene)) {
			if (canSkipTransIn) MusicBeatState.skipTransIn = true;
			persistentUpdate = false;
			openSubState(new VideoCutscene(videoCutscene, toCall));
			persistentDraw = false;
		} else
			callback();
	}

	@:dox(hide) public function startCountdown():Void
	{
		if (!_startCountdownCalled) {
			_startCountdownCalled = true;
			inCutscene = false;

			if (gameAndCharsEvent("onStartCountdown", new CancellableEvent()).cancelled) return;
		}

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * introLength - Conductor.songOffset;

		if(introLength > 0) {
			var swagCounter:Int = 0;
			startTimer = new FlxTimer().start(Conductor.crochet / 1000, (tmr:FlxTimer) -> {
				countdown(swagCounter++);
			}, introLength);
		}
		gameAndCharsCall("onPostStartCountdown");
	}

	/**
	 * Creates a fake countdown.
	 */
	public function countdown(swagCounter:Int) {
		var event:CountdownEvent = gameAndCharsEvent("onCountdown", EventManager.get(CountdownEvent).recycle(
			swagCounter,
			1,
			introSounds[swagCounter],
			introSprites[swagCounter],
			0.6, true, null, null, null));

		var sprite:FlxSprite = null;
		var sound:FlxSound = null;
		var tween:FlxTween = null;

		if (!event.cancelled) {
			if (event.spritePath != null) {
				var spr = event.spritePath;
				if (!Assets.exists(spr)) spr = Paths.image('$spr');

				sprite = new FunkinSprite().loadAnimatedGraphic(spr);
				sprite.scrollFactor.set();
				sprite.scale.set(event.scale, event.scale);
				sprite.updateHitbox();
				sprite.screenCenter();
				sprite.antialiasing = event.antialiasing;
				add(sprite);
				tween = FlxTween.tween(sprite, {y: sprite.y + 100, alpha: 0}, Conductor.crochet / 1000, {
					ease: FlxEase.cubeInOut,
					onComplete: function(twn:FlxTween)
					{
						sprite.destroy();
						remove(sprite, true);
					}
				});
			}
			if (event.soundPath != null) {
				var sfx = event.soundPath;
				if (!Assets.exists(sfx)) sfx = Paths.sound(sfx);
				sound = FlxG.sound.play(sfx, event.volume);
			}
		}
		event.sprite = sprite;
		event.sound = sound;
		event.spriteTween = tween;
		event.cancelled = false;

		gameAndCharsEvent("onPostCountdown", event);
	}

	@:dox(hide) function startSong():Void
	{
		gameAndCharsCall("onSongStart");
		startingSong = false;

		inst.onComplete = endSong;

		var time = (chartingMode && Charter.startHere) ? Charter.startTime : 0;
		for (strumLine in strumLines.members) strumLine.vocals.play(true, time);
		vocals.play(true, time);
		inst.play(true, time);

		updateDiscordPresence();

		gameAndCharsCall("onStartSong");
	}

	public override function destroy() {
		var notNull = stage != null;
		if (notNull) PlayState.instance.gameAndCharsCall("onStageDestroy", [stage]);
		scripts.call("destroy");

		for (g in __cachedGraphics) g.useCount--;
		@:privateAccess {
			for (strumLine in strumLines.members) FlxG.sound.destroySound(strumLine.vocals);
			if (FlxG.sound.music != inst) FlxG.sound.destroySound(inst);
			FlxG.sound.destroySound(vocals);
		}

		if (notNull) {
			stage.destroySilently();
			remove(stage, true);
		}

		scripts = FlxDestroyUtil.destroy(scripts);

		super.destroy();

		WindowUtils.resetAffixes();
		SaveWarning.reset();

		instance = null;

		Note.__customNoteTypeExists = [];
	}

	@:dox(hide) @:deprecated("scrollSpeedTween is deprecated, use eventsTween['scrollSpeed'] instead")
	public var scrollSpeedTween(get, set):FlxTween;
	private inline function get_scrollSpeedTween() return eventsTween.get("scrollSpeed");
	private inline function set_scrollSpeedTween(val:FlxTween) {eventsTween.set("scrollSpeed", val); return val;}
	// End of backwards compat

	@:dox(hide) private function generateSong(?songData:ChartData):Void
	{
		if (songData == null) songData = SONG;

		var foundCam = false;
		var foundSigs = songData.meta.beatsPerMeasure.getDefault(4) != 4 || songData.meta.stepsPerBeat.getDefault(4) != 4;

		if (events == null) events = [];
		else events = [
			for (e in songData.events) {
				switch (e.name) {
					case "Camera Movement": if (!foundCam && e.time < 10) {
						foundCam = true;
						executeEvent(e);
					}
					case "Time Signature Change": if (!foundSigs && (e.params[0] != 4 || e.params[1] != 4)) {
						foundSigs = true;
					}
				}
				e;
			}
		];

		if (!foundSigs) {
			camZoomingInterval = 4;
			camZoomingEvery = BEAT;
		}

		events.sort(function(p1, p2) {
			return FlxSort.byValues(FlxSort.DESCENDING, p1.time, p2.time);
		});

		curSong = songData.meta.name.toLowerCase();
		curSongID = curSong.replace(" ", "-");

		FlxG.sound.setMusic(inst = FlxG.sound.load(Assets.getMusic(Paths.inst(SONG.meta.name, difficulty, SONG.meta.instSuffix))));

		var vocalsPath = Paths.voices(SONG.meta.name, difficulty, SONG.meta.vocalsSuffix);
		if (SONG.meta.needsVoices && Assets.exists(vocalsPath))
			vocals = FlxG.sound.load(Options.streamedVocals ? Assets.getMusic(vocalsPath) : vocalsPath);
		else
			vocals = new FlxSound();

		vocals.group = FlxG.sound.defaultMusicGroup;
		vocals.persist = false;

		generatedMusic = true;
	}

	@:dox(hide) function sortByShit(Obj1:Note, Obj2:Note):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	@:dox(hide)
	private inline function generateStrums(amount:Null<Int> = null):Void {
		for(p in strumLines) {
			var kc = amount != null ? amount : p.data.keyCount;
			p.generateStrums(kc);
		}
	}

	@:dox(hide)
	override function openSubState(SubState:FlxSubState)
	{
		var event = gameAndCharsEvent("onSubstateOpen", EventManager.get(StateEvent).recycle(SubState));

		if (!postCreated)
			MusicBeatState.skipTransIn = true;

		if (event.cancelled) return;

		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				for (strumLine in strumLines.members) strumLine.vocals.pause();
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(event.substate is FlxSubState ? cast event.substate : SubState);
	}

	@:dox(hide)
	override function closeSubState()
	{
		var event = gameAndCharsEvent("onSubstateClose", EventManager.get(StateEvent).recycle(subState));
		if (event.cancelled) return;

		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			paused = false;

			updateDiscordPresence();
		}

		super.closeSubState();
	}

	/**
	 * Returns the Discord RPC icon.
	 */
	public inline function getIconRPC():String
		return SONG.meta.icon;

	@:dox(hide)
	override public function onFocus():Void
	{
		if (!paused && FlxG.autoPause) {
			for (strumLine in strumLines.members) strumLine.vocals.resume();
			inst.resume();
			vocals.resume();
		}
		gameAndCharsCall("onFocus");
		updateDiscordPresence();
		super.onFocus();
	}

	@:dox(hide)
	override public function onFocusLost():Void
	{
		if (!paused && FlxG.autoPause) {
			for (strumLine in strumLines.members) strumLine.vocals.pause();
			inst.pause();
			vocals.pause();
		}
		gameAndCharsCall("onFocusLost");
		updateDiscordPresence();
		super.onFocusLost();
	}

	@:dox(hide)
	inline function resyncVocals():Void
	{
		final time = Conductor.songPosition + Conductor.songOffset;

		if (!inst.playing) inst.play(true, time);
		vocals.play(true, time);
		for (strumLine in strumLines.members) strumLine.vocals.play(true, time);

		gameAndCharsCall("onVocalsResync");
	}

	/**
	 * Pauses the game.
	 */
	public function pauseGame() {
		var e = gameAndCharsEvent("onGamePause", new CancellableEvent());
		if (e.cancelled) return;

		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		// 1 / 1000 chance for Gitaroo Man easter egg
		if (allowGitaroo && FlxG.random.bool(Flags.GITAROO_CHANCE))
		{
			// gitaroo man easter egg
			FlxG.switchState(new GitarooPause());
		}
		else {
			openSubState(new PauseSubState());
		}

		updateDiscordPresence();
	}

	public function saveWarn(closingWindow:Bool = true) {
		persistentUpdate = false;
		paused = true;

		var state:FlxState = FlxG.state;
		if (FlxG.state.subState != null)
			state = FlxG.state.subState;

		state.openSubState(new PlaytestingWarningSubstate(closingWindow, [
			{
				label: closingWindow ? TU.translate("playtesting.exitGame") : TU.translate("playtesting.exitToMenu"),
				color: 0xFF0000,
				onClick: function(_) {
					if (!closingWindow) {
						if (SaveWarning.selectionClass != null) FlxG.switchState(Type.createInstance(SaveWarning.selectionClass, []));
					} else {
						WindowUtils.preventClosing = false; WindowUtils.resetClosing();
						openfl.system.System.exit(0);
					}
				}
			},
			{
				label: closingWindow ? TU.translate("playtesting.saveAndExitGame") : TU.translate("playtesting.saveAndExitToMenu"),
				color: 0xFFFF00,
				onClick: function(_) {
					if (SaveWarning.saveFunc != null) SaveWarning.saveFunc();
					if (!closingWindow) {
						if (SaveWarning.selectionClass != null) FlxG.switchState(Type.createInstance(SaveWarning.selectionClass, []));
					} else {
						WindowUtils.preventClosing = false; WindowUtils.resetClosing();
						openfl.system.System.exit(0);
					}
				}
			},
			{
				label: TU.translate("playtesting.cancel"),
				color: 0xFFFFFF,
				onClick: function (_) {
					if (closingWindow) WindowUtils.resetClosing();
				}
			}
		]));
	}

	dynamic function updateIconPositions() {
		var iconOffset = Flags.ICON_OFFSET;
		var healthBarPercent = healthBar.percent;

		var center:Float = healthBar.x + healthBar.width * FlxMath.remapToRange(healthBarPercent, 0, 100, 1, 0);

		iconP1.x = center - iconOffset;
		iconP2.x = center - (iconP2.width - iconOffset);

		iconP1.health = healthBarPercent / 100;
		iconP2.health = 1 - (healthBarPercent / 100);
	}

	// bypass the caching in FormatUtil by doing it manually so its faster
	private var TEXT_GAME_SCORE = TU.getRaw("game.score");
	private var TEXT_GAME_MISSES = TU.getRaw("game.misses");
	private var TEXT_GAME_COMBOBREAKS = TU.getRaw("game.comboBreaks");
	private var TEXT_GAME_ACCURACY = TU.getRaw("game.accuracy");

	dynamic function updateRatingStuff() {
		scoreTxt.text = TEXT_GAME_SCORE.format([songScore]);
		missesTxt.text = (comboBreaks ? TEXT_GAME_COMBOBREAKS : TEXT_GAME_MISSES).format([misses]);

		if (curRating == null)
			curRating = new ComboRating(0, "[N/A]", 0xFF888888);

		@:privateAccess {
			accFormat.format.color = curRating.color;
			accuracyTxt.text = TEXT_GAME_ACCURACY.format([accuracy < 0 ? "-%" : '${CoolUtil.quantize(accuracy * 100, 100)}%', curRating.rating]);

			for (i => frmtRange in accuracyTxt._formatRanges) if (frmtRange.format == accFormat) {
				accuracyTxt._formatRanges[i].range.start = accuracyTxt.text.length - curRating.rating.length;
				accuracyTxt._formatRanges[i].range.end = accuracyTxt.text.length;
				break;
			}
		}
	}

	@:dox(hide)
	override public function update(elapsed:Float)
	{
		scripts.call("update", [elapsed]);

		if (inCutscene) {
			super.update(elapsed);
			scripts.call("postUpdate", [elapsed]);
			return;
		}

		if (updateRatingStuff != null)
			updateRatingStuff();

		if (canAccessDebugMenus && chartingMode && controls.DEV_ACCESS)
			FlxG.switchState(new funkin.editors.charter.Charter(SONG.meta.name, difficulty, variation, false));

		if (Options.camZoomOnBeat && camZooming) {
			var beat = Conductor.getBeats(camZoomingEvery, camZoomingInterval, camZoomingOffset);
			if (camZoomingLastBeat != beat) {
				camZoomingLastBeat = beat;
				if (useCamZoomMult) {
					if (camZoomingMult < maxCamZoomMult) camZoomingMult += camZoomingStrength;
				}
				else if (FlxG.camera.zoom < maxCamZoom) {
					FlxG.camera.zoom += camGameZoomMult * camZoomingStrength;
					camHUD.zoom += camHUDZoomMult * camZoomingStrength;
				}
			}
		}

		if (doIconBop)
			for (icon in iconArray)
				if (icon.updateBump != null)
					icon.updateBump();

		if (updateIconPositions != null)
			updateIconPositions();

		if (startingSong) {
			if (startedCountdown && (Conductor.songPosition += Conductor.songOffset + elapsed * 1000) >= 0) {
				Conductor.songPosition = Conductor.songOffset;
				startSong();
			}
		}
		else if (FlxG.sound.music != null && (__vocalSyncTimer -= elapsed) < 0) {
			__vocalSyncTimer = 1;

			final instTime = FlxG.sound.music.getActualTime();
			var isOffsync:Bool = vocals.loaded && Math.abs(instTime - vocals.getActualTime()) > 12;
			if (!isOffsync)
				for (strumLine in strumLines.members)
					if ((isOffsync = strumLine.vocals.loaded && Math.abs(instTime - strumLine.vocals.getActualTime()) > 12))
						break;

			if (isOffsync) resyncVocals();
		}

		while(events.length > 0 && events.last().time <= Conductor.songPosition)
			executeEvent(events.pop());

		if (controls.PAUSE && startedCountdown && canPause)
			pauseGame();

		if (generatedMusic)
			moveCamera();

		if (camZooming) {
			if (useCamZoomMult) {
				camZoomingMult = lerp(camZoomingMult, defaultZoom, camZoomLerp) - defaultZoom;
				FlxG.camera.zoomMultiplier = camZoomingMult * camGameZoomMult + defaultZoom;
				camHUD.zoomMultiplier = camZoomingMult * camHUDZoomMult + defaultZoom;
				camZoomingMult += defaultZoom;
			}
			FlxG.camera.zoom = lerp(FlxG.camera.zoom, defaultCamZoom, camGameZoomLerp);
			camHUD.zoom = lerp(camHUD.zoom, defaultHudZoom, camHUDZoomLerp);
		}

		// RESET = Quick Game Over Screen
		if (startedCountdown && controls.RESET)
			gameOver();

		if (health <= 0 && canDie)
			gameOver(boyfriend);
		else if (health >= maxHealth && canDadDie)
			gameOver(dad);

		if (!inCutscene)
			keyShit();

		#if debug
		if (generatedMusic && FlxG.keys.justPressed.ONE)
			endSong();
		#end

		super.update(elapsed);

		scripts.call("postUpdate", [elapsed]);
	}

	override function draw() {
		var e = scripts.event("draw", EventManager.get(DrawEvent).recycle());
		if (!e.cancelled)
			super.draw();
		scripts.event("postDraw", e);
	}

	public function moveCamera() if (strumLines.members[curCameraTarget] != null) {
		var data:CamPosData = getStrumlineCamPos(curCameraTarget);
		if (data.amount > 0) {
			var event = gameAndCharsEvent("onCameraMove", EventManager.get(CamMoveEvent).recycle(data.pos, strumLines.members[curCameraTarget], data.amount));
			if (!event.cancelled)
				camFollow.setPosition(event.position.x, event.position.y);
		}
		data.put();
	}

	/**
	 * Returns the camera position of the specified strumline.
	 * @param strumLine The strumline to get the camera position of.
	 * @param pos The position to put the camera position in. If `null`, a new FlxPoint will be created.
	 * @param ignoreInvisible Whenever invisible characters should be ignored.
	**/
	public inline function getStrumlineCamPos(strumLine:Int, ?pos:FlxPoint = null, ?ignoreInvisible:Bool = true):CamPosData {
		return getCharactersCamPos(strumLines.members[strumLine].characters, pos, ignoreInvisible);
	}

	/**
	 * Returns the camera position of the specified characters.
	 * @param chars The characters to get the camera position of.
	 * @param pos The position to put the camera position in. If `null`, a new FlxPoint will be created.
	 * @param ignoreInvisible Whenever invisible characters should be ignored.
	**/
	public dynamic function getCharactersCamPos(chars:Array<Character>, ?pos:FlxPoint = null, ?ignoreInvisible:Bool = true):CamPosData {
		if (pos == null) pos = FlxPoint.get();
		var amount = 0;
		for(c in chars) {
			if (c == null || (ignoreInvisible && !c.visible)) continue;
			var cpos = c.getCameraPosition();
			pos.x += cpos.x;
			pos.y += cpos.y;
			amount++;
			//cpos.put(); // not actually in the pool, so no need
		}
		if (amount > 0) {
			pos.x /= amount;
			pos.y /= amount;
		}
		return new CamPosData(pos, amount);
	}


	public var eventsTween:Map<String, FlxTween> = [];

	public function executeEvent(event:ChartEvent) @:privateAccess {
		if (event == null || event.params == null) return;

		var e = EventManager.get(EventGameEvent).recycle(event);
		gameAndCharsEvent("onEvent", e);
		if (e.cancelled) return;
		var event = e.event;

		switch(event.name) {
			case "HScript Call":
				var scriptPacks:Array<ScriptPack> = [scripts, stateScripts];
				for (strLine in strumLines.members) for (char in strLine.characters) scriptPacks.push(char.scripts);
				var args:Array<String> = event.params[1].split(',');

				for (pack in scriptPacks) {
					pack.call(event.params[0], args);
					//public functions
					if (pack.publicVariables.exists(event.params[0])) {
						var func = pack.publicVariables.get(event.params[0]);
						if (func != null && Reflect.isFunction(func))
							Reflect.callMethod(null, func, args);
					}
				}

				//static functions
				if (Script.staticVariables.exists(event.params[0])) {
					var func = Script.staticVariables.get(event.params[0]);
					if (func != null && Reflect.isFunction(func))
						Reflect.callMethod(null, func, args);
				}
			case "Camera Movement":
				var tween = eventsTween.get("cameraMovement");
				if (tween != null) {
					if (tween.onComplete != null) tween.onComplete(tween);
					tween.cancel();
				}

				curCameraTarget = event.params[0];
				moveCamera();

				if (strumLines.members[curCameraTarget] != null) {
					if (event.params[1] == false) FlxG.camera.snapToTarget();
					else if (event.params[3] != null && event.params[3] != "CLASSIC") {  // making more nullchecks in this event because of the default save value being false  - Nex
						var oldFollow = FlxG.camera.followEnabled;
						FlxG.camera.followEnabled = false;
						eventsTween.set("cameraMovement", FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x - FlxG.camera.width * 0.5, y: camFollow.y - FlxG.camera.height * 0.5},
							(Conductor.stepCrochet / 1000) * (event.params[2] == null ? 4 : event.params[2]), {
								ease: CoolUtil.flxeaseFromString(event.params[3], event.params[4]),
								onComplete: (_) -> FlxG.camera.followEnabled = oldFollow
							})
						);
					}
				}
			case "Camera Position":
				var tween = eventsTween.get("cameraMovement");
				if (tween != null) {
					if (tween.onComplete != null) tween.onComplete(tween);
					tween.cancel();
				}

				curCameraTarget = -1;
				var isOffset = event.params[6] == true;
				camFollow.setPosition(isOffset ? (camFollow.x + event.params[0]) : event.params[0], isOffset ? (camFollow.y + event.params[1]) : event.params[1]);

				if (event.params[2] == false) FlxG.camera.snapToTarget();
				else if (event.params[4] != null && event.params[4] != "CLASSIC") {
					var oldFollow = FlxG.camera.followEnabled;
					FlxG.camera.followEnabled = false;
					eventsTween.set("cameraMovement", FlxTween.tween(FlxG.camera.scroll, {x: camFollow.x - FlxG.camera.width * 0.5, y: camFollow.y - FlxG.camera.height * 0.5},
						(Conductor.stepCrochet / 1000) * (event.params[3] == null ? 4 : event.params[3]), {
							ease: CoolUtil.flxeaseFromString(event.params[4], event.params[5]),
							onComplete: (_) -> FlxG.camera.followEnabled = oldFollow
						})
					);
				}
			case "Add Camera Zoom":
				var camera:FlxCamera = event.params[1] == "camHUD" ? camHUD : camGame;
				camera.zoom += event.params[0];
			case "Camera Bop":
				if (Options.camZoomOnBeat) {
					if (useCamZoomMult) {
						camZoomingMult += event.params[0];
					} else {
						FlxG.camera.zoom += event.params[0] * camZoomingStrength;
						camHUD.zoom += event.params[0] * camZoomingStrength;
					}
				}
			case "Camera Zoom":
				var cam = event.params[2] == "camHUD" ? camHUD : camGame;
				var name = (event.params[2] == "camHUD" ? "camHUD" : "camGame") + ".zoom";  // avoiding having different values from these 2  - Nex
				var tween = eventsTween.get(name);
				if (tween != null) tween.cancel();

				var finalZoom:Float = event.params[1] * (event.params[6] == 'direct' ? FlxCamera.defaultZoom : stage.defaultZoom);
				if (event.params[7] == true) finalZoom *= cam.zoom;

				if (event.params[0] == false) {
					cam.zoom = finalZoom;
					if (cam == camHUD) defaultHudZoom = finalZoom;
					else defaultCamZoom = finalZoom;
				} else
					eventsTween.set(name, FlxTween.tween(cam, {zoom: finalZoom}, (Conductor.stepCrochet / 1000) * event.params[3], {ease: CoolUtil.flxeaseFromString(event.params[4], event.params[5]), onUpdate: function(_) {
						if (cam == camHUD) defaultHudZoom = cam.zoom;
						else defaultCamZoom = cam.zoom;
					}}));
			case "Camera Modulo Change":
				camZoomingInterval = event.params[0];
				camZoomingStrength = event.params[1];
				if (event.params[2] != null) camZoomingEvery = switch (event.params[2].toUpperCase()) {
					case "STEP": STEP;
					case "MEASURE": MEASURE;
					default: BEAT;
				}
				if (event.params[3] != null) camZoomingOffset = event.params[3];
			case "Camera Flash":
				var camera:FlxCamera = event.params[3] == "camHUD" ? camHUD : camGame;

				if (event.params[0]) // reversed
					camera.fade(event.params[1], (Conductor.stepCrochet / 1000) * event.params[2], false, () -> {camera._fxFadeAlpha = 0;}, true);
				else // Not Reversed
					camera.flash(event.params[1], (Conductor.stepCrochet / 1000) * event.params[2], null, true);
			case "BPM Change": // automatically handled by conductor
			case "Scroll Speed Change":
				var tween = eventsTween.get("scrollSpeedTween");
				if (tween != null) tween.cancel();

				var finalScroll:Float = event.params[1];
				if (event.params[5] == true) finalScroll *= scrollSpeed;

				if (event.params[0] == false)
					scrollSpeed = finalScroll;
				else
					eventsTween.set("scrollSpeedTween", FlxTween.tween(this, {scrollSpeed: finalScroll}, (Conductor.stepCrochet / 1000) * event.params[2], {ease: CoolUtil.flxeaseFromString(event.params[3], event.params[4])}));
			case "Alt Animation Toggle":
				var strLine = strumLines.members[event.params[2]];
				if (strLine != null) {
					strLine.altAnim = cast event.params[0];

					if (strLine.characters != null) // Alt anim Idle
						for (character in strLine.characters) {
							if (character == null) continue;
							character.idleSuffix = event.params[1] ? "-alt" : "";
						}
				}
			case "Play Animation":
				if (strumLines.members[event.params[0]] != null && strumLines.members[event.params[0]].characters != null)
					for (char in strumLines.members[event.params[0]].characters)
						if (char != null && char.hasAnim(event.params[1])) char.playAnim(event.params[1], event.params[2], event.params[3] == "NONE" ? null : event.params[3]);
			case "Unknown": // nothing
		}
	}

	@:dox(hide)
	public var __updateNote_event:NoteUpdateEvent = null;

	/**
	 * Forces a game over.
	 * @param character Character which died. Default to `boyfriend`.
	 * @param deathCharID Character ID (name) for game over. Default to whatever is specified in the character's XML.
	 * @param gameOverSong Song for the game over screen. Default to `this.gameOverSong` (`gameOver`)
	 * @param lossSFX SFX at the beginning of the game over (Mic drop). Default to `this.lossSFX` (`gameOverSFX`)
	 * @param retrySFX SFX played whenever the player retries. Defaults to `retrySFX` (`gameOverEnd`)
	 */
	public function gameOver(?character:Character, ?deathCharID:String, ?gameOverSong:String, ?lossSFX:String, ?retrySFX:String) {
		var charToUse:Character = character.getDefault(opponentMode ? dad : boyfriend);  // Imma still make it check null later just in case dad or bf are also null for some weird scripts  - Nex
		var event:GameOverEvent = gameAndCharsEvent("onGameOver", EventManager.get(GameOverEvent).recycle(
			charToUse == null ? 0 : charToUse.x,
			charToUse == null ? 0 : charToUse.y,
			charToUse,
			deathCharID.getDefault(charToUse != null ? charToUse.gameOverCharacter : Flags.DEFAULT_GAMEOVER_CHARACTER),
			charToUse != null ? charToUse.isPlayer : true,
			gameOverSong.getDefault(this.gameOverSong),
			lossSFX.getDefault(this.lossSFX),
			retrySFX.getDefault(this.retrySFX)
		));

		if (event.cancelled) return;

		if (character != null)
			character.stunned = true;

		persistentUpdate = false;
		persistentDraw = false;
		paused = true;

		vocals.stop();
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();
		for (strumLine in strumLines.members) strumLine.vocals.stop();

		deathCounter++;

		openSubState(new GameOverSubstate(event.x, event.y, event.deathCharID, event.isPlayer, event.gameOverSong, event.lossSFX, event.retrySFX));

		gameAndCharsEvent("onPostGameOver", event);
	}

	/**
	 * Ends the song.
	 */
	public function endSong():Void
	{
		if (gameAndCharsEvent("onSongEnd", new CancellableEvent()).cancelled) return;
		endingSong = true;
		canPause = false;

		for (strumLine in strumLines.members) strumLine.vocals.stop();
		inst.stop();
		vocals.stop();

		if (validScore) {
			#if !switch
			FunkinSave.setSongHighscore(SONG.meta.name, difficulty, variation, {
				score: songScore,
				misses: misses,
				accuracy: accuracy,
				hits: hits,
				date: Date.now().toString()
			}, getSongChanges());
			#end
		}

		startCutscene("end-", endCutscene, nextSong, false, false);
	}

	private static inline function getSongChanges():Array<HighscoreChange> {
		var a = [];
		if (opponentMode)
			a.push(COpponentMode);
		if (coopMode)
			a.push(CCoopMode);
		return a;
	}

	/**
	 * Immediately switches to the next song, or goes back to the Story/Freeplay menu.
	 */
	public function nextSong() {
		if (isStoryMode) {
			campaignScore += songScore;
			campaignMisses += misses;
			campaignAccuracyTotal += accuracy;
			campaignAccuracyCount++;
			for (k => v in hits) campaignHits[k] += v;
			storyPlaylist.shift();
			storyVariations.shift();

			if (storyPlaylist.length <= 0) {
				FlxG.switchState(new StoryMenuState());

				if (validScore) {
					#if !switch
					// TODO: more week info saving
					FunkinSave.setWeekHighscore(storyWeek.id, difficulty, {
						score: campaignScore,
						misses: campaignMisses,
						accuracy: campaignAccuracy,
						hits: campaignHits,
						date: Date.now().toString()
					});
					#end
				}
				FlxG.save.flush();
			}
			else {
				Logs.infos('Loading next song (${storyPlaylist[0].toLowerCase()}/$difficulty/${storyVariations[0]})', "PlayState");

				registerSmoothTransition();

				__loadSong(storyPlaylist[0], difficulty, storyVariations[0]);
				FlxG.switchState(new PlayState());
			}
		}
		else if (chartingMode)
			FlxG.switchState(new funkin.editors.charter.Charter(SONG.meta.name, difficulty, variation, false));
		else
			FlxG.switchState(new FreeplayState());
	}

	public function registerSmoothTransition() {
		smoothTransitionData = {
			stage: curStage,
			camX: FlxG.camera.scroll.x,
			camY: FlxG.camera.scroll.y,
			camFollowX: camFollow.x,
			camFollowY: camFollow.y,
			camZoom: FlxG.camera.zoom
		};
		MusicBeatState.skipTransIn = true;
		MusicBeatState.skipTransOut = true;
	}

	private inline function keyShit():Void
	{
		for(id=>p in strumLines.members)
			p.updateInput(id);
	}

	/**
	 * Misses a note
	 * @param strumLine The strumline the miss happened on.
	 * @param note Note to miss.
	 * @param direction Specify a custom direction in case note is null.
	 * @param player Specify a custom player in case note is null.
	 */
	public function noteMiss(strumLine:StrumLine, note:Note, ?direction:Int, ?player:Int):Void
	{
		var hasNote:Bool = note != null;
		var playerID:Null<Int> = hasNote ? strumLines.members.indexOf(strumLine) : player;
		var directionID:Null<Int> = hasNote ? note.strumID : direction;
		if (playerID == null || directionID == null || playerID == -1) return;

		if (hasNote) {
			if (Flags.SUSTAINS_AS_ONE_NOTE && note.isSustainNote) {
				strumLine.deleteNote(note);
				if (note.sustainParent.wasGoodHit) {
					note.sustainParent.wasGoodHit = false;
					note.sustainParent.tooLate = true;
					note = note.sustainParent;
				}
				else
					return;
			}
		}

		var event:NoteMissEvent = gameAndCharsEvent("onPlayerMiss", EventManager.get(NoteMissEvent).recycle(note, -10, 1, muteVocalsOnMiss, hasNote ? ((note.isSustainNote && Flags.SUSTAINS_AS_ONE_NOTE) ? -0.1425 : -0.0475) : -0.04, Paths.sound(FlxG.random.getObject(Flags.DEFAULT_MISS_SOUNDS)), FlxG.random.float(0.1, 0.2), !hasNote, combo > 5, "sad", true, true, "miss", strumLines.members[playerID].characters, playerID, hasNote ? note.noteType : null, directionID, 0));
		strumLine.onMiss.dispatch(event);
		if (event.cancelled) {
			gameAndCharsEvent("onPostPlayerMiss", event);
			return;
		}

		if (strumLine != null) strumLine.addHealth(event.healthGain);
		if (gf != null && event.gfSad && gf.hasAnimation(event.gfSadAnim))
			gf.playAnim(event.gfSadAnim, event.forceGfAnim, MISS);

		if (event.resetCombo) combo = 0;

		songScore += event.score;
		misses += event.misses;

		if (event.playMissSound) FlxG.sound.play(event.missSound, event.missVolume);

		if (event.muteVocals) {
			vocals.volume = 0;
			strumLine.vocals.volume = 0;
		}

		if (event.accuracy != null) {
			accuracyPressedNotes++;
			totalAccuracyAmount += event.accuracy;

			updateRating();
		}

		if (!event.animCancelled) {
			for(char in event.characters) {
				if (char == null) continue;

				if(event.stunned) char.stunned = true;
				char.playSingAnim(directionID, event.animSuffix, MISS, event.forceAnim);
			}
		}

		if (event.deleteNote && strumLine != null && hasNote)
			strumLine.deleteNote(note);

		gameAndCharsEvent("onPostPlayerMiss", event);
	}

	@:dox(hide)
	public function getNoteType(id:Int):String {
		return SONG.noteTypes[id-1];
	}

	/**
	 * Hits a note
	 * @param note Note to hit.
	 */
	public function goodNoteHit(strumLine:StrumLine, note:Note):Void
	{
		if(note == null || note.wasGoodHit) return;

		note.wasGoodHit = true;

		var noteDiff = Math.abs(Conductor.songPosition - note.strumTime), rating:Rating;
		if (!Flags.USE_LEGACY_TIMING) rating = ratingManager.judgeNote(noteDiff);
		else {
			(rating = _legacyRating).splash = false;
			if (noteDiff > hitWindow * 0.9) {
				rating.window = hitWindow;
				rating.name = "shit";
				rating.score = 50;
				rating.accuracy = 0.25;
			}
			else if (noteDiff > hitWindow * 0.75) {
				rating.window = hitWindow * 0.9;
				rating.name = "bad";
				rating.score = 100;
				rating.accuracy = 0.45;
			}
			else if (noteDiff > hitWindow * 0.2) {
				rating.window = hitWindow * 0.75;
				rating.name = "good";
				rating.score = 200;
				rating.accuracy = 0.75;
			}
			else {
				rating.window = hitWindow * 0.2;
				rating.name = "sick";
				rating.score = 300;
				rating.accuracy = 1;
				rating.splash = true;
			}
		}

		var event:NoteHitEvent;
		if (strumLine != null && !strumLine.cpu)
			event = EventManager.get(NoteHitEvent).recycle(false, !note.isSustainNote, !note.isSustainNote, null, defaultDisplayRating, defaultDisplayCombo, note, strumLine.characters, true, note.noteType, note.animSuffix.getDefault(note.strumID < strumLine.members.length ? strumLine.members[note.strumID].animSuffix : strumLine.animSuffix), "game/score/", "", note.strumID, rating.score, note.isSustainNote ? null : rating.accuracy, 0.023, rating.name, Options.splashesEnabled && !note.isSustainNote && rating.splash, 0.5, true, 0.7, true, true, iconP1);
		else
			event = EventManager.get(NoteHitEvent).recycle(false, false, false, null, defaultDisplayRating, defaultDisplayCombo, note, strumLine.characters, false, note.noteType, note.animSuffix.getDefault(note.strumID < strumLine.members.length ? strumLine.members[note.strumID].animSuffix : strumLine.animSuffix), "game/score/", "", note.strumID, 0, null, 0, rating.name, false, 0.5, true, 0.7, true, true, iconP2);
		event.deleteNote = !note.isSustainNote; // work around, to allow sustain notes to be deleted
		event = scripts.event(strumLine != null && !strumLine.cpu ? "onPlayerHit" : "onDadHit", event);
		strumLine.onHit.dispatch(event);
		gameAndCharsEvent("onNoteHit", event);

		note.noSustainClip = !event.clipSustain;
		
		if (!event.cancelled) {
			if (!note.isSustainNote) {
				if (event.countScore) songScore += event.score;
				if (event.accuracy != null) {
					accuracyPressedNotes++;
					totalAccuracyAmount += event.accuracy;
					updateRating();
				}
				if (event.countAsCombo) combo++;

				if (event.showRating || (event.showRating == null && event.player))
				{
					displayCombo(event);
					if (event.displayRating)
						displayRating(event.rating, event);
					ratingNum += 1;
				}
				if (event.player) hits[rating.name] += 1;
			}

			if (strumLine != null) strumLine.addHealth(event.healthGain);

			if (!event.animCancelled)
				for(char in event.characters)
					if (char != null)
						char.playSingAnim(event.direction, event.animSuffix, SING, event.forceAnim);

			if (event.note.__strum != null) {
				if (!event.strumGlowCancelled) event.note.__strum.press(event.note.strumTime);
				if (event.showSplash) splashHandler.showSplash(event.note.splash, event.note.__strum);
			}
		}

		if (event.unmuteVocals) {
			vocals.volume = 1;
			strumLine.vocals.volume = 1;
		}
		if (event.enableCamZooming) camZooming = true;
		if (event.autoHitLastSustain) {
			if (note.nextSustain != null && note.nextSustain.nextSustain == null) {
				// its a tail!!
				note.wasGoodHit = true;
			}
		}

		if (event.deleteNote) strumLine.deleteNote(note);
		else note.updateSustainClip();

		gameAndCharsEvent("onPostNoteHit", event);
	}

	public function displayRating(myRating:String, ?evt:NoteHitEvent = null):Void {
		var hasEvent = evt != null;
		var pre:String = hasEvent ? evt.ratingPrefix : "";
		var suf:String = hasEvent ? evt.ratingSuffix : "";

		var rating:FlxSprite = comboGroup.recycleLoop(FlxSprite);
		CoolUtil.resetSprite(rating, comboGroup.x + -40, comboGroup.y + -60);
		rating.loadAnimatedGraphic(Paths.image('${pre}${myRating}${suf}'));
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		if (hasEvent) {
			rating.scale.set(evt.ratingScale, evt.ratingScale);
			rating.antialiasing = evt.ratingAntialiasing;
		}
		rating.updateHitbox();

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001,
			onComplete: function(tween:FlxTween) {
				rating.kill();
			}
		});
	}

	public function displayCombo(?evt:NoteHitEvent = null):Void {
		if (minDigitDisplay >= 0 && (combo == 0 || combo >= minDigitDisplay)) {
			var hasEvent = evt != null;
			var pre:String = hasEvent ? evt.ratingPrefix : "";
			var suf:String = hasEvent ? evt.ratingSuffix : "";

			if (evt.displayCombo) {
				var comboSpr:FlxSprite = comboGroup.recycleLoop(FlxSprite).loadAnimatedGraphic(Paths.image('${pre}combo${suf}'));
				CoolUtil.resetSprite(comboSpr, comboGroup.x, comboGroup.y);
				comboSpr.acceleration.y = 600;
				comboSpr.velocity.y -= 150;
				comboSpr.velocity.x += FlxG.random.int(1, 10);

				if (hasEvent) {
					comboSpr.scale.set(evt.ratingScale, evt.ratingScale);
					comboSpr.antialiasing = evt.ratingAntialiasing;
				}
				comboSpr.updateHitbox();

				FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						comboSpr.kill();
					},
					startDelay: Conductor.crochet * 0.001
				});
			}

			var separatedScore:String = Std.string(combo).addZeros(3);
			for (i in 0...separatedScore.length)
			{
				var numScore:FlxSprite = comboGroup.recycleLoop(FlxSprite).loadAnimatedGraphic(Paths.image('${pre}num${separatedScore.charAt(i)}${suf}'));
				CoolUtil.resetSprite(numScore, comboGroup.x + (43 * i) - 90, comboGroup.y + 80);
				if (hasEvent) {
					numScore.antialiasing = evt.numAntialiasing;
					numScore.scale.set(evt.numScale, evt.numScale);
				}
				numScore.updateHitbox();

				numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);

				FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						numScore.kill();
					},
					startDelay: Conductor.crochet * 0.002
				});
			}
		}
	}

	public inline function deleteNote(note:Note)
		if (note.strumLine != null)
			note.strumLine.deleteNote(note);

	@:dox(hide)
	override function stepHit(curStep:Int)
	{
		super.stepHit(curStep);
		scripts.call("stepHit", [curStep]);
	}

	@:dox(hide)
	override function measureHit(curMeasure:Int)
	{
		super.measureHit(curMeasure);
		scripts.call("measureHit", [curMeasure]);
	}

	@:dox(hide)
	override function beatHit(curBeat:Int)
	{
		super.beatHit(curBeat);

		if (doIconBop)
			for (icon in iconArray)
				if (icon.bump != null)
					icon.bump();

		scripts.call("beatHit", [curBeat]);
	}

	public function addScript(file:String) {
		var ext = Path.extension(file).toLowerCase();
		if (Script.scriptExtensions.contains(ext))
			scripts.add(Script.create(file));
	}

	// GETTERS & SETTERS
	#if REGION
	private inline function get_player():StrumLine
		return playerStrums;
	private inline function set_player(s:StrumLine):StrumLine
		return playerStrums = s;

	private inline function get_cpu():StrumLine
		return cpuStrums;
	private inline function set_cpu(s:StrumLine):StrumLine
		return cpuStrums = s;

	private function get_boyfriend():Character {
		if (strumLines != null && strumLines.members[1] != null)
			return strumLines.members[1].characters[0];
		return null;
	}
	private function set_boyfriend(bf:Character):Character {
		if (strumLines != null && strumLines.members[1] != null)
			strumLines.members[1].characters = [bf];
		return bf;
	}
	private function set_bf(bf:Character):Character {
		if (strumLines != null && strumLines.members[1] != null)
			strumLines.members[1].characters = [bf];
		return bf;
	}
	private function get_bf():Character {
		if (strumLines != null && strumLines.members[1] != null)
			return strumLines.members[1].characters[0];
		return null;
	}
	private function get_dad():Character {
		if (strumLines != null && strumLines.members[0] != null)
			return strumLines.members[0].characters[0];
		return null;
	}
	private function set_dad(dad:Character):Character {
		if (strumLines != null && strumLines.members[0] != null)
			strumLines.members[0].characters = [dad];
		return dad;
	}
	private function get_gf():Character {
		if (strumLines != null && strumLines.members[2] != null)
			return strumLines.members[2].characters[0];
		return null;
	}
	private function set_gf(gf:Character):Character {
		if (strumLines != null && strumLines.members[2] != null)
			strumLines.members[2].characters = [gf];
		return gf;
	}
	private inline function get_cpuStrums():StrumLine
		return strumLines.members[0];
	private inline function set_cpuStrums(v:StrumLine):StrumLine
		return strumLines.members[0] = v;
	private inline function get_playerStrums():StrumLine
		return strumLines.members[1];
	private inline function set_playerStrums(v:StrumLine):StrumLine
		return strumLines.members[1] = v;
	private inline function get_gfSpeed():Int
		return (strumLines.members[2] != null && strumLines.members[2].characters[0] != null) ? strumLines.members[2].characters[0].beatInterval : 1;
	private inline function set_gfSpeed(v:Int):Int {
		if (strumLines.members[2] != null && strumLines.members[2].characters[0] != null)
			strumLines.members[2].characters[0].beatInterval = v;
		return v;
	}

	private inline static function get_campaignAccuracy()
		return campaignAccuracyCount == 0 ? 0 : campaignAccuracyTotal / campaignAccuracyCount;
	#end

	/**
	 * Load a week into PlayState.
	 * @param weekData Week Data
	 * @param difficulty Week Difficulty
	 */
	public static function loadWeek(weekData:WeekData, ?difficulty:String) {
		if (difficulty == null) difficulty = Flags.DEFAULT_DIFFICULTY;
		storyWeek = weekData;
		storyPlaylist = [for (e in weekData.songs) e.name];
		storyVariations = [for (e in weekData.songs) e.variation];
		isStoryMode = true;
		campaignScore = 0;
		campaignMisses = 0;
		campaignAccuracyTotal = 0;
		campaignAccuracyCount = 0;
		campaignHits = [];
		chartingMode = coopMode = opponentMode = false;
		__loadSong(storyPlaylist[0], difficulty, storyVariations[0]);
	}

	/**
	 * Loads a song into PlayState
	 * @param name Song name
	 * @param difficulty Chart difficulty (if invalid, will load an empty chart)
	 * @param variation Song Variation
	 * @param opponentMode Whenever opponent mode is on
	 * @param coopMode Whenever co-op mode is on.
	 */
	public static function loadSong(_name:String, ?_difficulty:String, ?_variation:Dynamic, _opponentMode:Bool = false, _coopMode:Bool = false) {
		if (_difficulty == null) difficulty = Flags.DEFAULT_DIFFICULTY;
		if (_variation is Bool) { // vackward cumpatibshit
			_coopMode = _opponentMode;
			_opponentMode = cast _variation;
			_variation = null;
		}
		else if (!(_variation is String)) _variation = null;
		opponentMode = _opponentMode;
		coopMode = _coopMode;
		isStoryMode = chartingMode = false;
		__loadSong(_name, _difficulty, cast _variation);
	}

	/**
	 * (INTERNAL) Loads a song without resetting story mode/opponent mode/coop mode values.
	 * @param name Song name
	 * @param difficulty Chart difficulty
	 * @param variation Song Variation
	 */
	public static function __loadSong(_name:String, _difficulty:String, _variation:String) {
		difficulty = _difficulty;
		variation = _variation;
		seenCutscene = false;
		deathCounter = 0;

		SONG = Chart.parse(_name, _difficulty, _variation);
		fromMods = SONG.fromMods;
	}
}

final class ComboRating {
	public var percent:Float;
	public var rating:String;
	public var color:FlxColor;
	public var maxMisses:Float;  // Float since it could be Math.POSITIVE_INFINITY  - Nex

	public function new(?percent:Float, ?rating:String, ?color:FlxColor, ?misses:Float) {
		maxMisses = misses == null || Math.isNaN(misses) ? Math.POSITIVE_INFINITY : misses;
		this.percent = percent;
		this.rating = TranslationUtil.get('game.rating.$rating', rating);
		this.color = color;
	}
}

typedef PlayStateTransitionData = {
	var stage:String;
	var camX:Float;
	var camY:Float;
	var camFollowX:Float;
	var camFollowY:Float;
	var camZoom:Float;
}

class CamPosData {
	/**
	 * The camera position.
	**/
	public var pos:FlxPoint;
	/**
	 * The amount of characters that was involved in the calculation.
	**/
	public var amount:Int;

	public function new(pos:FlxPoint, amount:Int) {
		this.pos = pos;
		this.amount = amount;
	}

	/**
	 * Puts the position back into the pool, making it reusable.
	**/
	public function put() {
		if(pos == null) return;
		pos.put();
		pos = null;
	}
}
