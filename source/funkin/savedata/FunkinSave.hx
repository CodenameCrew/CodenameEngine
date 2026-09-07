package funkin.savedata;

import funkin.backend.chart.ChartData.ChartMetaData;
import funkin.menus.FreeplayState.FreeplaySonglist;
import funkin.backend.system.gamejolt.GameJoltData.GJTrophyData;
import flixel.util.FlxSave;
import funkin.backend.system.gamejolt.*;
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
		return safeGetHighscore(getSongEntry(name, diff, variation, changes));
	}

	public static inline function setSongHighscore(name:String, diff:String, ?variation:String, highscore:SongScore, ?changes:Array<HighscoreChange>, ?force:Bool) {
		if (changes == null) changes = [];
		if (safeRegisterHighscore(getSongEntry(name, diff, variation, changes), highscore, force)) {
			flush();
			return true;
		}
		return false;
	}

	public static inline function getSongEntry(name:String, diff:String, ?variation:String, ?changes:Array<HighscoreChange>):HighscoreEntry
		return HSongEntry(name.toLowerCase(), diff.toLowerCase(), variation, changes);

	public static inline function getWeekHighscore(name:String, diff:String)
		return safeGetHighscore(getWeekEntry(name, diff));

	public static inline function setWeekHighscore(name:String, diff:String, highscore:SongScore, ?force:Bool) {
		if (safeRegisterHighscore(getWeekEntry(name, diff), highscore, force)) {
			flush();
			return true;
		}
		return false;
	}


	public static inline function getWeekEntry(name, diff:String):HighscoreEntry
		return HWeekEntry(name.toLowerCase(), diff.toLowerCase());

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

	private static function safeRegisterHighscore(entry:HighscoreEntry, highscore:SongScore, force = false) {
		var oldHigh = safeGetHighscore(entry);
		if (force || oldHigh.date == null || oldHigh.score < highscore.score) {
			highscores.set(entry, highscore);

			// GameJolt is only logged in if GAMEJOLT_API is on, otherwise it's always false.
			if (GJUtil.loggedIn) {
				switch(entry) {
					case HSongEntry(songName, difficulty, variation, changes):
						if (changes.length == 0) {
							if (GameJoltData.leaderboards.exists('song-$songName--D:$difficulty (V:${variation != null ? variation : 'Default'})'))
								GameJoltSecurity.sendTrusted(SCORES_ADD('${highscore.score}', highscore.score, 'accuracy=${highscore.accuracy};date=${highscore.date}', GameJoltData.leaderboards.get('song-$songName--D:$difficulty (V:${variation != null ? variation : 'Default'})')), true, function(err) {
									Logs.error('Could not post score to leaderboard: $err', RED, 'GameJolt');
								}, function(resp) {
									Logs.trace('Successfully posted score to leaderboard associated with song $songName.', SUCCESS, LIGHTGRAY, 'GameJolt');
								})
							else if (GameJoltData.leaderboards.exists('song-$songName (V:${variation != null ? variation : 'Default'})'))
								GameJoltSecurity.sendTrusted(SCORES_ADD('${highscore.score}', highscore.score, 'accuracy=${highscore.accuracy};date=${highscore.date}', GameJoltData.leaderboards.get('song-$songName (V:${variation != null ? variation : 'Default'})')), true, function(err) {
									Logs.error('Could not post score to leaderboard: $err', RED, 'GameJolt');
								}, function(resp) {
									Logs.trace('Successfully posted score to leaderboard associated with song $songName.', SUCCESS, LIGHTGRAY, 'GameJolt');
								});

							// song trophy and exception check
							if (GameJoltData.definedTrophies.exists('song-$songName')) {
								var tropData:GJTrophyData = GameJoltData.definedTrophies.get('song-$songName');
								var hasException:Bool = false;
								if (tropData.except != null) {
									for (itms in tropData.except) {
										var indic:String = itms.substr(0, 3);
										var dat:Array<String> = itms.substr(3).split(',');
										for (d in dat) d.trim();
										switch (indic) {
											case "=D:": //difficulty exception
												if (dat.contains(difficulty)) hasException = true;

											case "=V:": //variation exception
												if (dat.contains(variation)) hasException = true;

											case _:
												// nothing lol
										}
									}
								}
								if (!hasException) GameJoltSecurity.unlockDefinedTrophy('song-$songName');
							}

							// first fc check
							if (highscore.misses == 0 && GameJoltData.definedTrophies.exists('fc-first')) {
								if (!GameJoltData.definedTrophies.get('fc-first').except.contains(songName))
									GameJoltSecurity.unlockDefinedTrophy('fc-first');
							}
							
							// complete all & fc all achievement check
							if (GameJoltData.definedTrophies.exists('complete-all') || GameJoltData.definedTrophies.exists('fc-all')) {
								var songList:Array<ChartMetaData> = FreeplaySonglist.get().songs;
								var completedSongs:Array<String> = [];
								var fcData:Array<SongScore> = [];
								for (s in highscores.keys()) {
									if (highscores.get(s).score == 0)
										continue
									else switch (s) {
										case HSongEntry(songName, difficulty, variation, changes):
											completedSongs.push(songName);
											fcData.push(highscores.get(s));
										default:
											// oop
									}
								}
								
								if (GameJoltData.definedTrophies.exists('complete-all'))
								{
									var daTrophy:GJTrophyData = GameJoltData.definedTrophies.get('complete-all');
									var songAmount:Int = completedSongs.length;
									for (sng in completedSongs) {
										if (daTrophy.except.contains(sng))
											songAmount--;
									}
									if (songAmount == (completedSongs.length - daTrophy.except.length))
										GameJoltSecurity.unlockDefinedTrophy('complete-all');
								}

								if (GameJoltData.definedTrophies.exists('fc-all'))
								{
									var daTrophy:GJTrophyData = GameJoltData.definedTrophies.get('fc-all');
									var songAmount:Int = 0;
									for (sng in completedSongs) {
										if (daTrophy.except.contains(sng))
											continue;

										if (fcData[completedSongs.indexOf(sng)].misses == 0)
											songAmount++;
									}
									if (songAmount == (completedSongs.length - daTrophy.except.length))
										GameJoltSecurity.unlockDefinedTrophy('fc-all');
								}
							}

						}
					case HWeekEntry(weekName, difficulty):
						if (GameJoltData.leaderboards.exists('week-$weekName--D:$difficulty'))
							GameJoltSecurity.sendTrusted(SCORES_ADD('${highscore.score}', highscore.score, 'accuracy=${highscore.accuracy};date=${highscore.date}', GameJoltData.leaderboards.get('week-$weekName--D:$difficulty')), true, function(err) {
								Logs.error('Could not post score to leaderboard: $err', RED, 'GameJolt');
							}, function(resp) {
								Logs.trace('Successfully posted score to leaderboard associated with week $weekName.', SUCCESS, LIGHTGRAY, 'GameJolt');
							})
						else if (GameJoltData.leaderboards.exists('week-$weekName'))
							GameJoltSecurity.sendTrusted(SCORES_ADD('${highscore.score}', highscore.score, 'accuracy=${highscore.accuracy};date=${highscore.date}', GameJoltData.leaderboards.get('week-$weekName')), true, function(err) {
								Logs.error('Could not post score to leaderboard: $err', RED, 'GameJolt');
							}, function(resp) {
								Logs.trace('Successfully posted score to leaderboard associated with week $weekName.', SUCCESS, LIGHTGRAY, 'GameJolt');
							});

						// week trophy and exception check
						if (GameJoltData.definedTrophies.exists('week-$weekName')) {
							var tropData:GJTrophyData = GameJoltData.definedTrophies.get('week-$weekName');
							var hasException:Bool = false;
							if (tropData.except != null) {
								for (itms in tropData.except) {
									var indic:String = itms.substr(0, 3);
									var dat:Array<String> = itms.substr(3).split(',');
									for (d in dat) d.trim();
									switch (indic) {
										case "=D:": //difficulty exception
											if (dat.contains(difficulty)) hasException = true;

										case _:
											// nothing lol
									}
								}
							}
							if (!hasException) GameJoltSecurity.unlockDefinedTrophy('week-$weekName');
						}
				}
			}
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