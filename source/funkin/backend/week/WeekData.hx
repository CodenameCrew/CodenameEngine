package funkin.backend.week;

import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import haxe.xml.Access;

typedef WeekData = {
	var ?xml:Access;
	var name:String;  // name SHOULD NOT be used for loading week highscores, its just the name on the right side of the week, remember that next time!!  - Nex
	var id:String;  // id IS instead for saving and loading!!  - Nex
	var sprite:String;
	var chars:Array<WeekCharacter>;
	var songs:Array<WeekSong>;
	var difficulties:Array<String>;
	var bgColor:FlxColor;
}

typedef WeekCharacter = {
	var ?xml:Access;
	var name:String;
	var ?spritePath:String;
	var ?scale:Float;
	var ?offset:FlxPoint;
	// var frames:FlxFramesCollection;
}

typedef WeekSong = {
	var name:String;
	var hide:Bool;
	var ?displayName:String;
}