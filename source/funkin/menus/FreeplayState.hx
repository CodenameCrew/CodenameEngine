package funkin.menus;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.chart.Chart;
import funkin.backend.chart.ChartData.ChartMetaData;
import funkin.backend.scripting.events.menu.MenuChangeEvent;
import funkin.backend.scripting.events.menu.freeplay.*;
import funkin.backend.system.Conductor;
import funkin.game.HealthIcon;
import funkin.savedata.FunkinSave;
import haxe.io.Path;

using StringTools;

class FreeplayState extends MusicBeatState
{
	/**
	 * Array containing all of the songs' metadata.
	 */
	public var songs:Array<ChartMetaData> = [];

	/**
	 * Current song metadata
	 */
	public var curSong:Null<ChartMetaData>;

	/**
	 * Current song difficulties
	 */
	public var curDifficulties:Array<String>;

	/**
	 * songs[curSelected].metas.get(curDiffMetaIndices[curDifficulty])
	 */
	public var curDiffMetaKeys:Array<String> = [];

	/*
	 * Array containing all labels for game modes.
	 */
	public var gameModeLabels:Array<FreeplayGameMode> = [];

	/**
	 * Currently selected song
	 */
	public var curSelected:Int = 0;
	/**
	 * Currently selected difficulty
	 */
	public var curDifficulty:Int = 1;
	/**
	 * Currently selected game mode
	 */
	public var curGameMode:Int = 0;

	/**
	 * Text containing the score info (PERSONAL BEST: 0)
	 */
	public var scoreText:FlxText;

	/**
	 * Text containing the current difficulty (< HARD >)
	 */
	public var diffText:FlxText;

	/**
	 * Text containing the current game mode, for example: ([KEYBINDS] Co-Op mode)
	 */
	public var gameModeText:FlxText;

	/**
	 * Currently lerped score. Is updated to go towards `intendedScore`.
	 */
	public var lerpScore:Float = 0;
	/**
	 * Destination for the currently lerped score.
	 */
	public var intendedScore:Int = 0;

	/**
	 * Assigned FreeplaySonglist item.
	 */
	public var songList:FreeplaySonglist;
	/**
	 * Black background around the score, the difficulty text and the co-op text.
	 */
	public var scoreBG:FlxSprite;

	/**
	 * Background.
	 */
	public var bg:FlxSprite;

	/**
	 * Whenever the player can navigate and select
	 */
	public var canSelect:Bool = true;

	/**
	 * Group containing all of the alphabets
	 */
	public var grpSongs:FlxTypedGroup<Alphabet>;

	/**
	 * Whenever the currently selected song is playing.
	 */
	public var curPlaying:Bool = false;

	/**
	 * Array containing all of the icons.
	 */
	public var iconArray:Array<HealthIcon> = [];

	/**
	 * FlxInterpolateColor object for smooth transition between Freeplay colors.
	 */
	public var interpColor:FlxInterpolateColor;


	override function create()
	{
		CoolUtil.playMenuSong();
		songList = FreeplaySonglist.get();
		songs = songList.songs;

		for(k=>s in songs) {
			if (s.name == Options.freeplayLastSong) {
				curSelected = k;
			}
		}

		updateCurDifficulties();
		for(i=>diff in curDifficulties) {
			if (curDiffMetaKeys[i] == Options.freeplayLastVariation && diff == Options.freeplayLastDifficulty)
				curDifficulty = i;
		}

		updateCurSong();
		gameModeLabels = FreeplayGameMode.get();

		DiscordUtil.call("onMenuLoaded", ["Freeplay"]);

		super.create();

		// LOAD CHARACTERS

		bg = new FlxSprite(0, 0).loadAnimatedGraphic(Paths.image('menus/menuDesat'));
		if (songs.length > 0)
			bg.color = songs[0].color;
		bg.antialiasing = true;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].displayName, "bold");
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].icon);
			icon.sprTracker = songText;
			if (Math.max(icon.width, icon.height) > 150) icon.setUnstretchedGraphicSize(150, 150);

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DON'T PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 1, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		gameModeText = new FlxText(diffText.x, diffText.y + diffText.height + 2, 0, "", 24);
		gameModeText.font = scoreText.font;
		add(gameModeText);

		add(scoreText);

		changeSelection(0, true);
		changeDiff(0, true);
		changeGameMode(0, true);

		interpColor = new FlxInterpolateColor(bg.color);
	}

	#if PRELOAD_ALL
	/**
	 * How much time a song stays selected until it autoplays.
	 */
	public var timeUntilAutoplay:Float = 1;
	/**
	 * Whenever the song autoplays when hovered over.
	 */
	public var disableAutoPlay:Bool = false;
	/**
	 * Whenever the autoplayed song gets async loaded.
	 */
	public var disableAsyncLoading:Bool = #if desktop false #else true #end;
	/**
	 * Time elapsed since last autoplay. If this time exceeds `timeUntilAutoplay`, the currently selected song will play.
	 */
	public var autoplayElapsed:Float = 0;
	/**
	 * Whenever the currently selected song instrumental is playing.
	 */
	public var songInstPlaying:Bool = true;
	/**
	 * Path to the currently playing song instrumental.
	 */
	public var curPlayingInst:String = null;
	/**
	 * If it should play the song automatically.
	 */
	public var autoplayShouldPlay:Bool = true;
	#end

	private var TEXT_FREEPLAY_SCORE = TU.getRaw("freeplay.score");

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
		}

		lerpScore = lerp(lerpScore, intendedScore, 0.4);

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		if (canSelect) {
			changeSelection((controls.UP_P ? -1 : 0) + (controls.DOWN_P ? 1 : 0) - FlxG.mouse.wheel);
			changeDiff((controls.LEFT_P ? -1 : 0) + (controls.RIGHT_P ? 1 : 0));
			changeGameMode((controls.CHANGE_MODE ? 1 : 0));
			// putting it before so that its actually smooth
			updateOptionsAlpha();
		}

		scoreText.text = TEXT_FREEPLAY_SCORE.format([Math.round(lerpScore)]);
		scoreBG.scale.set(MathUtil.maxSmart(diffText.width, scoreText.width, gameModeText.width) + 8, (gameModeText.visible ? gameModeText.y + gameModeText.height : 66));
		scoreBG.updateHitbox();
		scoreBG.x = FlxG.width - scoreBG.width;

		scoreText.x = gameModeText.x = scoreBG.x + 4;
		diffText.x = Std.int(scoreBG.x + ((scoreBG.width - diffText.width) / 2));

		interpColor.fpsLerpTo(curSong.color, 0.0625);
		bg.color = interpColor.color;

		#if PRELOAD_ALL
		var dontPlaySongThisFrame = false;
		autoplayElapsed += elapsed;
		if (!disableAutoPlay && !songInstPlaying && (autoplayElapsed > timeUntilAutoplay)) {
			if (curPlayingInst != (curPlayingInst = Paths.inst(curSong.name, curDifficulties[curDifficulty], curSong.instSuffix))) {
				var streamed = false;
				if (Options.streamedMusic) {
					var sound = Assets.getMusic(curPlayingInst, true, false);
					streamed = sound != null;

					if (streamed && autoplayShouldPlay) {
						FlxG.sound.playMusic(sound, 0);
						Conductor.changeBPM(curSong.bpm, curSong.beatsPerMeasure, curSong.stepsPerBeat);
					}
				}

				if (!streamed) {
					var huh:Void->Void = function() {
						var soundPath = curPlayingInst;
						var sound = null;
						if (Assets.exists(soundPath, SOUND) || Assets.exists(soundPath, MUSIC))
							sound = Assets.getSound(soundPath);
						else
							FlxG.log.error('Could not find a Sound asset with an ID of \'$soundPath\'.');

						if (sound != null && autoplayShouldPlay) {
							FlxG.sound.playMusic(sound, 0);
							Conductor.changeBPM(curSong.bpm, curSong.beatsPerMeasure, curSong.stepsPerBeat);
						}
					}
					if (!disableAsyncLoading) Main.execAsync(huh);
					else huh();
				}
			}
			songInstPlaying = true;
			if (disableAsyncLoading && !Options.streamedMusic) dontPlaySongThisFrame = true;
		}
		#end


		if (controls.BACK)
		{
			CoolUtil.playMenuSFX(CANCEL, 0.7);
			FlxG.switchState(new MainMenuState());
		}

		#if sys
		if (FlxG.keys.justPressed.EIGHT && Sys.args().contains("-livereload"))
			convertChart();
		#end

		if (controls.ACCEPT #if PRELOAD_ALL && !dontPlaySongThisFrame #end)
			select();
	}

	/**
	 * Selects the current song.
	 */
	public function select() {
		if (curDifficulties.length == 0) return;

		var event = event("onSelect", EventManager.get(FreeplaySongSelectEvent).recycle(curSong.name, curDifficulties[curDifficulty], curSong.variant, gameModeLabels[curGameMode]));

		if (event.cancelled) return;

		#if PRELOAD_ALL
		autoplayShouldPlay = false;
		#end

		Options.freeplayLastSong = curSong.name;
		Options.freeplayLastDifficulty = curDifficulties[curDifficulty];
		Options.freeplayLastVariation = curSong.variant;

		PlayState.loadSong(event.song, event.difficulty, event.variant, event.opponentMode, event.coopMode);
		FlxG.switchState(new PlayState());
	}

	public function convertChart() {
		trace('Converting ${curSong.name} ${curDifficulties[curDifficulty]} ${curSong.variant} to Codename format...');
		var chart = Chart.parse(curSong.name, curDifficulties[curDifficulty], curSong.variant);
		Chart.save(chart, curDifficulties[curDifficulty], curSong.variant);
	}

	/**
	 * Changes the current difficulty
	 * @param change How much to change.
	 * @param force Force the change if `change` is equal to 0
	 */
	public function changeDiff(change:Int = 0, force:Bool = false) {
		if (change == 0 && !force) return;

		var validDifficulties = curDifficulties.length > 0;
		var event = event("onChangeDiff", EventManager.get(MenuChangeEvent).recycle(curDifficulty, validDifficulties ? FlxMath.wrap(curDifficulty + change, 0, curDifficulties.length-1) : 0, change));

		if (event.cancelled) {
			if (force) updateCurSong();
			return;
		}

		var prevSong = curSong;
		curDifficulty = event.value;
		updateCurSong();
		updateScore();

		#if PRELOAD_ALL
		if (curSong != prevSong) {
			autoplayElapsed = 0;
			songInstPlaying = false;
		}
		#end

		var text = validDifficulties ? curDifficulties[curDifficulty].toUpperCase() + (curSong != songs[curSelected] ? ' (${curSong.variant.toUpperCase()})' : '') : '-';
		diffText.text = curDifficulties.length > 1 ? '< $text >' : text;
	}

	function updateScore() {
		if (curDifficulties.length == 0) {
			intendedScore = 0;
			return;
		}

		var changes:Array<HighscoreChange> = [];
		if (__coopMode) changes.push(CCoopMode);
		if (__opponentMode) changes.push(COpponentMode);
		var saveData = FunkinSave.getSongHighscore(curSong.name, curDifficulties[curDifficulty], curSong.variant, changes);
		intendedScore = saveData.score;
	}

	/**
	 * Change the current coop mode context.
	 * @param change How much to change
	 * @param force Force the change, even if `change` is equal to 0.
	 */
	public function changeGameMode(change:Int = 0, force:Bool = false) {
		if (change == 0 && !force) return;

		var i = 0;
		var allowed = getAllowedGameModesID();
		var wrapped = FlxMath.wrap(curGameMode + change, 0, gameModeLabels.length - 1);
		while (!allowed.contains(gameModeLabels[wrapped].modeID)) {  // Skipping the blacklisted ones  - Nex
			wrapped = FlxMath.wrap(wrapped + change, 0, gameModeLabels.length - 1);
			if (i++ > allowed.length) {
				curGameMode = 0;  // Idk honestly if I should modify the other event's variables  - Nex
				break;
			}
		}

		var e = EventManager.get(MenuChangeEvent).recycle(curGameMode, wrapped, change);
		event("onChangeCoopMode", e);  // Backwards compat  - Nex
		if (event("onChangeGameMode", e).cancelled) return;

		// Getting from scratch the allowed game modes just in case they changed when the event got called  - Nex
		if (gameModeText.visible = getAllowedGameModesID().length > 0) gameModeText.text = "[TAB] " + gameModeLabels[curGameMode = e.value].modeName;
		updateScore();
	}

	public inline function getAllowedGameModesID() {
		var excluded = songs[curSelected].excludedGameModes;
		return [for (mode in gameModeLabels) if (!excluded.contains(mode.modeID)) mode.modeID];
	}

	/**
	 * Change the current selection.
	 * @param change How much to change
	 * @param force Force the change, even if `change` is equal to 0.
	 */
	public function changeSelection(change:Int = 0, force:Bool = false) {
		if (change == 0 && !force) return;

		var event = event("onChangeSelection", EventManager.get(MenuChangeEvent).recycle(curSelected, FlxMath.wrap(curSelected + change, 0, songs.length-1), change));
		if (event.cancelled) return;

		curSelected = event.value;
		if (event.playMenuSFX) CoolUtil.playMenuSFX(SCROLL, 0.7);

		var prevDiff = curDifficulties[curDifficulty], prevVariant = curDiffMetaKeys[curDifficulty];
		updateCurDifficulties();

		for (i => diff in curDifficulties) if (diff == prevDiff && curDiffMetaKeys[i] == prevVariant) {
			curDifficulty = i;
			break;
		}

		changeDiff(0, true);
		changeGameMode(0, true);

		#if PRELOAD_ALL
		autoplayElapsed = 0;
		songInstPlaying = false;
		#end
	}

	function updateOptionsAlpha() {
		var event = event("onUpdateOptionsAlpha", EventManager.get(FreeplayAlphaUpdateEvent).recycle(0.6, 0.45, 1, 1, 0.25));
		if (event.cancelled) return;

		final idleAlpha = #if PRELOAD_ALL songInstPlaying ? event.idlePlayingAlpha : #end event.idleAlpha;
		final selectedAlpha = #if PRELOAD_ALL songInstPlaying ? event.selectedPlayingAlpha : #end event.selectedAlpha;

		for (i in 0...iconArray.length)
			iconArray[i].alpha = lerp(iconArray[i].alpha, idleAlpha, event.lerp);

		iconArray[curSelected].alpha = selectedAlpha;

		for (i => item in grpSongs.members)
		{
			item.targetY = i - curSelected;

			item.alpha = lerp(item.alpha, idleAlpha, event.lerp);

			if (item.targetY == 0)
				item.alpha = selectedAlpha;
		}
	}

	function updateCurDifficulties() {
		curDiffMetaKeys.resize(0);
		curDifficulties = songs[curSelected].difficulties.copy();
		for (i in 0...curDifficulties.length) curDiffMetaKeys.push(null);
		
		if (songs[curSelected].variants != null) {
			var meta:ChartMetaData;
			for (variant in songs[curSelected].variants) if ((meta = songs[curSelected].metas.get(variant)) != null) {
				curDifficulties = curDifficulties.concat(meta.difficulties);
				for (i in 0...meta.difficulties.length) curDiffMetaKeys.push(variant);
			}
		}
	}

	function updateCurSong() {
		var song = songs[curSelected];
		if (song == null) curSong = null;
		else if ((curSong = song.metas.get(curDiffMetaKeys[curDifficulty])) == null)
			curSong = song;
	}

	// Backwards compat
	@:noCompletion public function changeCoopMode(change:Int = 0, force:Bool = false) return changeGameMode(change, force);

	@:noCompletion public var coopText(get, set):FlxText;
	@:noCompletion private function get_coopText() return gameModeText;
	@:noCompletion private function set_coopText(val:FlxText) return gameModeText = val;

	@:noCompletion function updateCoopModes() {}
	@:noCompletion var __opponentMode(get, default):Bool = false;  // God this is so cursed  - Nex
	@:noCompletion private function get___opponentMode() return getAllowedGameModesID().contains("codename.opponent");
	@:noCompletion var __coopMode(get, default):Bool = false;
	@:noCompletion private function get___coopMode() return getAllowedGameModesID().contains("codename.coop");

	@:noCompletion var curCoopMode(get, set):Int;
	@:noCompletion private function get_curCoopMode() return curGameMode;
	@:noCompletion private function set_curCoopMode(val:Int) return curGameMode = val;

	@:noCompletion var coopLabels(get, set):Array<String>;
	@:noCompletion private function get_coopLabels() return [for(mode in gameModeLabels) mode.modeName];
	@:noCompletion private function set_coopLabels(names:Array<String>) {
		gameModeLabels = [for(name in names) {
			if (name.startsWith("[TAB] ")) name = name.substr("[TAB] ".length);
			new FreeplayGameMode(name, switch(name) {
				case "Solo": "codename.solo";
				case "Opponent Mode": "codename.opponent";
				case "Co-Op Mode": "codename.coop";
				case "Co-Op Mode (Switched)": "codename.coop-opponent";
				default: name.toLowerCase().replace(" ", "-");
			}, switch(name) {
				case "Solo": ["solo"];
				case "Opponent Mode": ["opponent"];
				case "Co-Op Mode": ["coop"];
				case "Co-Op Mode (Switched)": ["coop-switched", "opponent", "coop"];
				default: null;
			});
		}];
		return names;
	}
}

/**
 * Class used for the Freeplay menu game modes.
 *
 * **NOTE**: `fields` is useable not just for boolean values!!
 */
class FreeplayGameMode {
	public var modeName:String;
	public var modeID:String;
	public var scripts(default, set):Array<String>;
	public var fields(default, set):Dynamic;

	@:noCompletion function set_scripts(val:Array<String>) return scripts = (val == null ? [] : val);
	@:noCompletion function set_fields(val:Dynamic) return fields = (val == null ? {} : val);

	public function new(modeName:String, modeID:String, ?scripts:Array<String>, ?fields:Dynamic) {
		this.modeName = modeName;
		this.modeID = modeID;
		this.scripts = scripts;
		this.fields = fields;
	}

	public function toModifiers():Array<Dynamic> {
		var fields = this.fields;
		var modifiers:Array<Dynamic> = [];
		for (field in {var _ = Reflect.fields(fields); _.sort(Reflect.compare); _;}) {
			var val:Dynamic = Reflect.field(fields, field);
			if (val != null && val != false) { // allow true, and floats/ints
				modifiers.push(field);
				modifiers.push(val);
			}
		}
		return modifiers;
	}

	public static inline function generateDefault() return new FreeplayGameMode("Solo Mode", "solo");

	public static inline function getGameModesFromSource(source:AssetSource = BOTH, useTxt:Bool = true):Array<FreeplayGameMode> {
		var path = 'data/gamemodes';
		var txt = Paths.txt('gamemodes/list');
		var list = useTxt && Paths.assetsTree.existsSpecific(txt, "TEXT", source) ? CoolUtil.coolTextFile(txt) : Paths.getFolderContent(path, false, source);

		return [for (file in list) {
			if (useTxt) file += ".json";
			else if (Path.extension(file) != "json") continue;

			var meta:FreeplayGameMode = null;
			try {
				var data = CoolUtil.parseJson(Paths.file(path + "/" + file)); var id = data.modeID;
				meta = new FreeplayGameMode(CoolUtil.getDefault(data.displayName, id), id, [Path.withoutExtension(file)].concat(CoolUtil.getDefault(data.scripts, [])), data.fields);
			} catch(e) Logs.trace('Failed to load game mode metadata for $file ($path): ${Std.string(e)}', ERROR);
			if (meta != null) meta;
		}];
	}

	public static function get(useTxt:Bool = true):Array<FreeplayGameMode> {
		var list:Array<FreeplayGameMode>;

		switch(Flags.GAME_MODES_LIST_MOD_MODE) {
			case 'prepend':
				list = getGameModesFromSource(MODS, useTxt).concat(getGameModesFromSource(SOURCE, useTxt));
			case 'append':
				list = getGameModesFromSource(SOURCE, useTxt).concat(getGameModesFromSource(MODS, useTxt));
			case 'override':
				list = getGameModesFromSource(BOTH, useTxt);
			default /*case 'oneOFtwo'*/:
				if ((list = getGameModesFromSource(MODS, useTxt)).length == 0)
					list = getGameModesFromSource(SOURCE, useTxt);
		}

		return list;
	}
}

class FreeplaySonglist {
	public var songs:Array<ChartMetaData> = [];

	public function new() {}

	public function getSongsFromSource(source:funkin.backend.assets.AssetSource, useTxt:Bool = true) {
		var songsFound:Array<String> = null;
		if (useTxt) {
			var oldPath = Paths.txt('freeplaySonglist');
			var newPath = Paths.txt('config/freeplaySonglist');
			if (Paths.assetsTree.existsSpecific(newPath, "TEXT", source)) songsFound = CoolUtil.coolTextFile(newPath);
			else if (Paths.assetsTree.existsSpecific(oldPath, "TEXT", source)) {
				Logs.warn("data/freeplaySonglist.txt is deprecated and will be removed in the future. Please move the file to data/config/", DARKYELLOW, "FreeplaySonglist");
				songsFound = CoolUtil.coolTextFile(oldPath);
			}
		}
		if (songsFound == null) songsFound = Paths.getFolderDirectories("songs", false, source);
		if (songsFound.length > 0) {
			for (s in songsFound) songs.push(Chart.loadChartMeta(s, source == MODS));
			return false;
		}
		return true;
	}

	public static function get(useTxt:Bool = true) {
		var songList = new FreeplaySonglist();

		switch(Flags.SONGS_LIST_MOD_MODE) {
			case 'prepend':
				songList.getSongsFromSource(MODS, useTxt);
				songList.getSongsFromSource(SOURCE, useTxt);
			case 'append':
				songList.getSongsFromSource(SOURCE, useTxt);
				songList.getSongsFromSource(MODS, useTxt);
			case 'override':
				songList.getSongsFromSource(BOTH, useTxt);
			default /*case 'oneOFtwo'*/:
				if (songList.getSongsFromSource(MODS, useTxt))
					songList.getSongsFromSource(SOURCE, useTxt);
		}

		return songList;
	}
}
