package funkin.savedata;

import flixel.util.FlxSave;
import lime.app.Application;
import openfl.Lib;

/**
 * Class used for saves WITHOUT going through the struggle of type checks
 * Just add your save variables the way you would do in the Options.hx file.
 * The macro will automatically generate the `flush` and `load` functions.
 */
@:build(funkin.backend.system.macros.FunkinSaveMacro.build("save", "flush", "load"))
class FunkinSave {
	public static var highscores:Map<HighscoreEntry, SongScore> = [];


	/**
	 * ONLY OPEN IF YOU WANT TO EDIT FUNCTIONS RELATED TO SAVING, LOADING OR HIGHSCORES.
	 */
	#if REGION
	@:dox(hide) @:doNotSave
	private static var __eventAdded = false;
	@:doNotSave
	public static var save:FlxSave;

	public static function init() {
		var path = Flags.SAVE_PATH, name = Flags.SAVE_NAME;
		if (path == null) path = 'CodenameEngine';
		if (name == null) name = 'save-default';

		if (save == null) save = new FlxSave();
		save.bind(name, path);
		load();

		if (!__eventAdded) {
			Lib.application.onExit.add(function(i:Int) {
				Logs.traceColored([
					Logs.getPrefix("FunkinSave"),
					Logs.logText("Saving "),
					Logs.logText("save data", GREEN),
					Logs.logText("...")
				], VERBOSE);
				flush();
			});
			__eventAdded = true;
		}
	}

	/**
	 * Returns the high-score for a song.
	 * @param name Song name
	 * @param diff Song difficulty
	 * @param changes Changes made to that song in freeplay.
	 */
	public static inline function getSongHighscore(name:String, diff:String, ?changes:Array<HighscoreChange>) {
		if (changes == null) changes = [];
		return safeGetHighscore(HSongEntry(name.toLowerCase(), diff.toLowerCase(), changes));
	}

	public static inline function setSongHighscore(name:String, diff:String, highscore:SongScore, ?changes:Array<HighscoreChange>) {
		if (changes == null) changes = [];
		if (safeRegisterHighscore(HSongEntry(name.toLowerCase(), diff.toLowerCase(), changes), highscore)) {
			flush();
			return true;
		}
		return false;
	}

	public static inline function getWeekHighscore(name:String, diff:String)
		return safeGetHighscore(HWeekEntry(name.toLowerCase(), diff.toLowerCase()));

	public static inline function setWeekHighscore(name:String, diff:String, highscore:SongScore) {
		if (safeRegisterHighscore(HWeekEntry(name.toLowerCase(), diff.toLowerCase()), highscore)) {
			flush();
			return true;
		}
		return false;
	}

	private static function safeGetHighscore(entry:HighscoreEntry):SongScore {
		if (!highscores.exists(entry)) {
			return {
				score: 0,
				accuracy: 0,
				misses: 0,
				hits: [],
				date: null
			};
		}
		return highscores.get(entry);
	}

	private static function safeRegisterHighscore(entry:HighscoreEntry, highscore:SongScore) {
		var oldHigh = safeGetHighscore(entry);
		if (oldHigh.date == null || oldHigh.score < highscore.score) {
			highscores.set(entry, highscore);
			return true;
		}
		return false;
	}
	#end
}

enum HighscoreEntry {
	HWeekEntry(weekName:String, difficulty:String);
	HSongEntry(songName:String, difficulty:String, changes:Array<HighscoreChange>);
}

enum HighscoreChange {
	CCoopMode;
	COpponentMode;
}

typedef SongScore = {
	var score:Int;
	var accuracy:Float;
	var misses:Int;
	var hits:Map<String, Int>;
	var date:String;
}