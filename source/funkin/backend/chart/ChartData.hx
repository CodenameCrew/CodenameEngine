package funkin.backend.chart;

import flixel.util.FlxColor;

typedef ChartData = {
	public var strumLines:Array<ChartStrumLine>;
	public var events:Array<ChartEvent>;
	public var meta:ChartMetaData;
	public var codenameChart:Bool;
	public var stage:String;
	public var scrollSpeed:Float;
	public var noteTypes:Array<String>;

	public var ?fromMods:Bool;
}

typedef ChartMetaData = {
	public var name:String;
	public var ?bpm:Float;
	public var ?displayName:String;
	public var ?beatsPerMeasure:Float;
	public var ?stepsPerBeat:Float;
	public var ?needsVoices:Bool;
	public var ?icon:String;
	public var ?color:FlxColor;
	public var ?difficulties:Array<String>;
	public var ?coopAllowed:Bool;
	public var ?opponentModeAllowed:Bool;
	public var ?customValues:Dynamic;
}

typedef ChartStrumLine = {
	var characters:Array<String>;
	var type:ChartStrumLineType;
	var notes:Array<ChartNote>;
	var position:String;
	var ?visible:Null<Bool>;
	var ?strumPos:Array<Float>;
	var ?strumScale:Float;
	var ?scrollSpeed:Float;
	var ?vocalsSuffix:String;

	var ?strumLinePos:Float; // Backwards compatability
}

typedef ChartNote = {
	var time:Float; // time at which the note will be hit (ms)
	var id:Int; // strum id of the note
	var type:Int; // type (int) of the note
	var sLen:Float; // sustain length of the note (ms)
}

typedef ChartEvent = {
	var name:String;
	var time:Float;
	var params:Array<Dynamic>;
}

enum abstract ChartStrumLineType(Int) from Int to Int {
	/**
	 * STRUMLINE IS MARKED AS OPPONENT - WILL BE PLAYED BY CPU, OR PLAYED BY PLAYER IF OPPONENT MODE IS ON
	 */
	var OPPONENT = 0;
	/**
	 * STRUMLINE IS MARKED AS PLAYER - WILL BE PLAYED AS PLAYER, OR PLAYED AS CPU IF OPPONENT MODE IS ON
	 */
	var PLAYER = 1;
	/**
	 * STRUMLINE IS MARKED AS ADDITIONAL - WILL BE PLAYED AS CPU EVEN IF OPPONENT MODE IS ENABLED
	 */
	var ADDITIONAL = 2;
}