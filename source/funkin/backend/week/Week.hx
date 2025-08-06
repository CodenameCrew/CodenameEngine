package funkin.backend.week;

import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import funkin.backend.week.WeekData.WeekCharacter;
import funkin.backend.week.WeekData;
import haxe.xml.Access;

class Week {
	public static function loadWeek(weekName:String, loadCharactersData:Bool = true):WeekData {
		var week:Access = null;
		try week = new Access(Xml.parse(Assets.getText(Paths.xml('weeks/weeks/$weekName'))).firstElement())
		catch(e) Logs.trace('Cannot parse week "$weekName.xml": ${Std.string(e)}', ERROR);

		if (week == null) return null;
		if (!week.has.name) {
			Logs.trace('Week "${weekName}" has no name attribute', WARNING);
			return null;
		}

		var weekObj:WeekData = {
			xml: week,
			name: week.att.name,
			id: weekName,
			sprite: week.getAtt('sprite').getDefault(weekName),
			chars: [null, null, null],
			songs: [],
			difficulties: ['easy', 'normal', 'hard'],
			bgColor: week.has.bgColor ? FlxColor.fromString(week.getAtt("bgColor")) : Flags.DEFAULT_WEEK_COLOR
		};

		var weekName = weekObj.name;
		for (k => song in week.nodes.song) {
			if (song == null) continue;
			try {
				var name = song.innerData.trim();
				if (name == "") {
					Logs.trace('Song at index ${k} in week $weekName has no name. Skipping...', WARNING);
					continue;
				}
				weekObj.songs.push({
					name: name,
					hide: song.getAtt('hide').getDefault('false') == "true",
					displayName: song.getAtt('displayName')
				});
			} catch(e) {
				Logs.trace('Song at index ${k} in week $weekName cannot contain any other XML nodes in its name.', WARNING);
				continue;
			}
		}

		if (weekObj.songs.length <= 0) {
			Logs.trace('Week $weekName has no songs.', WARNING);
			return null;
		}

		var diffNodes = week.nodes.difficulty;
		if (diffNodes.length > 0) {
			var diffs:Array<String> = [for (e in diffNodes) if (e.has.name) e.att.name];
			if (diffs.length > 0) weekObj.difficulties = diffs;
		}

		if (week.has.chars) for (k => e in week.att.chars.split(",")) {
			var trim = e.trim();
			weekObj.chars[k] = (trim == "" || e == "none" || e == "null") ? null : (loadCharactersData ? loadWeekCharacter(trim) : {name: trim});
		}

		return weekObj;
	}

	public static function loadWeekCharacter(charName:String):WeekCharacter {
		var char:Access = null;
		try char = new Access(Xml.parse(Assets.getText(Paths.xml('weeks/characters/$charName'))).firstElement())
		catch(e) Logs.trace('Cannot parse character "$charName.xml": ${Std.string(e)}', ERROR);
		if (char == null) return null;

		if (!char.has.name) char.x.set("name", charName);
		if (!char.has.sprite) char.x.set("sprite", 'menus/storymenu/characters/${char.att.name}');
		if (!char.has.updateHitbox) char.x.set("updateHitbox", "true");

		return {
			xml: char,
			name: char.att.name,
			spritePath: char.att.sprite,
			scale: Std.parseFloat(char.getAtt('scale')).getDefault(1),
			offset: FlxPoint.get(
				Std.parseFloat(char.getAtt('x')).getDefault(0),
				Std.parseFloat(char.getAtt('y')).getDefault(0)
			)
		};
	}
}