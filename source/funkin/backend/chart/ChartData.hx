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
	public var ?bookmarks:Array<ChartBookmark>;

	public var ?chartVersion:String;
	public var ?fromMods:Bool;
}

typedef ChartMetaData = {
	public var name:String;
	public var ?variant:String;
	public var ?displayName:String;

	public var ?bpm:Float;
	public var ?beatsPerMeasure:Float;
	public var ?stepsPerBeat:Int;

	public var ?difficulties:Array<String>;
	public var ?variants:Array<String>;
	public var ?customValues:Dynamic;

	public var ?icon:String;
	public var ?color:FlxColor;

	public var ?coopAllowed:Bool;
	public var ?opponentModeAllowed:Bool;

	public var ?metas:Map<String, ChartMetaData>;
	public var ?instSuffix:String;
	public var ?vocalsSuffix:String;
	public var ?needsVoices:Bool;

	public var ?musicExt:String;
}

typedef ChartStrumLine = {
	var characters:Array<String>;
	var type:ChartStrumLineType;
	var notes:Array<ChartNote>;
	var position:String;
	var ?visible:Null<Bool>;
	var ?strumPos:Array<Float>;
	var ?strumScale:Float;
	var ?strumSpacing:Float;
	var ?scrollSpeed:Float;
	var ?vocalsSuffix:String;
	var ?keyCount:Int; // default=4

	var ?strumLinePos:Float; // Backwards compatibility
}

typedef ChartNote = {
	var time:Float; // time at which the note will be hit (ms)
	var id:Int; // strum id of the note
	var type:Int; // type (int) of the note
	var sLen:Float; // sustain length of the note (ms)
}

typedef ChartBookmark = {
	var time:Float;
	var name:String;
	var color:String;
}

typedef ChartEvent = {
	var name:String;
	var time:Float;
	var params:Array<Dynamic>;
	var ?global:Bool;  // If its from a global event file like events.json; this field might be saved rarely in the chart json directly but modders can mess with this for messing with the saving funcs too  - Nex
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