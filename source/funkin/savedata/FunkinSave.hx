package funkin.savedata;

import flixel.util.FlxSave;
import lime.app.Application;
import openfl.Lib;
import haxe.Serializer;
import haxe.Unserializer;

/**
 * Class used for saves WITHOUT going through the struggle of type checks
 * Just add your save variables the way you would do in the Options.hx file.
 * The macro will automatically generate the `flush` and `load` functions.
 */
@:build(funkin.backend.system.macros.FunkinSaveMacro.build("save", "__flush", "__load"))
class FunkinSave {
	@:doNotSave public static var highscores:Map<HighscoreEntry, SongScore> = [];

	/**
	 * ONLY OPEN IF YOU WANT TO EDIT FUNCTIONS RELATED TO SAVING, LOADING OR HIGHSCORES.
	 */
	#if REGION
	@:dox(hide) @:doNotSave private static var __eventAdded = false;
	@:doNotSave public static var save:FlxSave;

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

	public static function load() {
		__load();
		if (save.data.highscores != null) {
			var temp;
			for (entryData in Reflect.fields(save.data.highscores))
				if ((temp = __getHighscoreEntry(entryData)) != null && Reflect.field(save.data.highscores, entryData) != null)
					highscores.set(temp, Reflect.field(save.data.highscores, entryData));
		}
	}

	public static function flush() {
		if (save.data.highscores == null) save.data.highscores = {};
		for (entry => score in highscores) Reflect.setField(save.data.highscores, __formatHighscoreEntry(entry), score);
		__flush();
	}

	static function __getHighscoreEntry(data:String):HighscoreEntry {
		try {
			var d = Unserializer.run(data);
			if (d.song is String)
				return HSongEntry(d.song, d.diff, d.variation, d.changes);
			else if (d.week is String)
				return HWeekEntry(d.week, d.diff);
		}
		catch (e) {}
		return null;
	}

	static function __formatHighscoreEntry(entry:HighscoreEntry):String {
		switch (entry) {
			case HWeekEntry(weekName, difficulty):
				return Serializer.run({week: weekName, diff: difficulty});
			case HSongEntry(songName, difficulty, variation, changes):
				var d:Dynamic = {
					song: songName,
					diff: difficulty,
					changes: changes
				};
				if (variation != null && variation != '') d.variation = variation;
				return Serializer.run(d);
		}
		return '';
	}

	/**
	 * Returns the high-score for a song.
	 * @param name Song name
	 * @param diff Song difficulty
	 * @param changes Changes made to that song in freeplay.
	 */
	public static inline function getSongHighscore(name:String, diff:String, ?variation:String, ?changes:Array<HighscoreChange>) {
		if (changes == null) changes = [];
		return safeGetHighscore(HSongEntry(name.toLowerCase(), diff.toLowerCase(), variation, changes));
	}

	public static inline function setSongHighscore(name:String, diff:String, ?variation:String, highscore:SongScore, ?changes:Array<HighscoreChange>) {
		if (changes == null) changes = [];
		if (safeRegisterHighscore(HSongEntry(name.toLowerCase(), diff.toLowerCase(), variation, changes), highscore)) {
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
	HSongEntry(songName:String, difficulty:String, variation:Null<String>, changes:Array<HighscoreChange>);
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