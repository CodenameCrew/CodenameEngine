package funkin.backend.chart;

import funkin.backend.chart.ChartData.ChartMetaData;

typedef ChartDataWithInfo = {
	var diffName:String;
	var chart:ChartData;
}

// These new structures are kinda a mess to port, i love and hate them at the same time; why the hell are every difficulty in the same file???  - Nex
class VSliceParser {
	public static function parse(metaData:Dynamic, chartData:Dynamic, resultMeta:ChartMetaData, resultCharts:Array<ChartDataWithInfo>, ?songID:String) {
		var metaData:SwagMetadata = metaData;
		var chartData:NewSwagSong = chartData;

		parseMeta(metaData, resultMeta, songID);

		for (diff in Reflect.fields(chartData.notes))
		{
			var base:ChartData = {
				strumLines: [],
				noteTypes: [],
				events: [],
				meta: {name: null},
				scrollSpeed: Reflect.field(chartData.scrollSpeed, diff),
				stage: Flags.DEFAULT_STAGE,
				codenameChart: true
			};
			parseChart(Reflect.field(chartData.notes, diff), metaData, chartData.events, base);
			resultCharts.push({diffName: diff, chart: base});
		}
	}

	public static function parseChart(data:Dynamic, metaData:Dynamic, events:Dynamic, result:ChartData) {
		// vslice chart parsing
		var data:Array<SwagNote> = data;
		var metadata:SwagMetadata = metaData;
		var events:Array<SwagEvent> = events;

		result.stage = metadata.playData.stage;

		var p2isGF:Bool = false;
		result.strumLines.push({
			characters: [metadata.playData.characters.opponent],
			type: 0,
			position: (p2isGF = metadata.playData.characters.opponent.startsWith("gf")) ? "girlfriend" : "dad",
			notes: [],
			vocalsSuffix: "-Opponent"
		});
		result.strumLines.push({
			characters: [metadata.playData.characters.player],
			type: 1,
			position: "boyfriend",
			notes: [],
			vocalsSuffix: "-Player"
		});
		var gfName = metadata.playData.characters.girlfriend;
		if (!p2isGF && gfName != "none") {
			result.strumLines.push({
				characters: [gfName],
				type: 2,
				position: "girlfriend",
				notes: [],
				visible: false,
			});
		}

		var timeChanges = metadata.timeChanges;
		result.meta.bpm = timeChanges[0].bpm;
		result.meta.needsVoices = false;

		for (note in data)
		{
			var daNoteType:Null<Int> = null;
			if (note.k != null)
				daNoteType = Chart.addNoteType(result, note.k == "alt" ? "Alt Anim Note" : note.k);  // they hardcoded "alt" for converting old charts BUT THEN WHY THE HELL WOULD YOU CALL "MOM" THE NOTE KIND IN WEEK5 GRAHHH  - Nex

			var daNoteData:Int = Std.int(note.d % 8);
			var isMustHit:Bool = Math.floor(daNoteData / 4) == 0;

			result.strumLines[isMustHit ? 1 : 0].notes.push({
				time: note.t,
				id: daNoteData % 4,
				type: daNoteType,
				sLen: note.l
			});
		}

		var curBPM = result.meta.bpm;
		for (i in 1...timeChanges.length)  // starting from 1 on purpose  - Nex
		{
			var curChange = timeChanges[i];
			if (curBPM != curChange.bpm)
			{
				curBPM = curChange.bpm;
				result.events.push({
					time: curChange.t,
					name: "BPM Change",
					params: [curBPM]
				});
			}
		}

		for (event in events)
		{
			var values = event.v;
			switch (event.e)
			{
				case "FocusCamera":
					var isPosOnly = false;
					var arr:Array<Dynamic> = [switch(values.char) {
						// more cases here in the future if they add em? (i hope not)  - Nex
						case 0: 1;
						case 1: 0;
						case -1:
							isPosOnly = true;
							-1;
						default: 2;
					}];
					if (values.ease != "CLASSIC" && values.ease != null) {
						if (values.ease == "INSTANT") arr = arr.concat([false]);
						else {
							var cneEase = parseEase(values.ease);
							arr = arr.concat([true, values.duration == null ? 4 : values.duration, cneEase[0], cneEase[1]]);
						}
					}
					if (isPosOnly || ((values.x != null && values.x != 0) || (values.y != null && values.y != 0))) {
						var useNull = arr.length <= 2;
						result.events.push({
							time: event.t,
							name: "Camera Position",
							params: [values.x, values.y, useNull ? null : arr[1], useNull ? null : arr[2], useNull ? null : arr[3], useNull ? null : arr[4], true]
						});
					}
					if (!isPosOnly) result.events.push({
						time: event.t,
						name: "Camera Movement",
						params: arr
					});
				case "PlayAnimation":
					result.events.push({
						time: event.t,
						name: "Play Animation",
						params: [switch(values.target) {
							case 'boyfriend' | 'bf' | 'player': 1;
							case 'dad' | 'opponent': 0;
							default /*case 'girlfriend' | 'gf'*/: 2;  // usually the default should be the stage prop but we dont have that sooo  - Nex
						}, values.anim, values.force == null ? false : values.force]
					});
				case "ScrollSpeed":
					var cneEase = values.ease == null || values.ease == "INSTANT" ? ["linear", null] : parseEase(values.ease);
					result.events.push({
						time: event.t,
						name: "Scroll Speed Change",  // we dont support the strumline value and also i will put the whole ease name into a single parameter since it works anyways  - Nex
						params: [values.ease != "INSTANT", values.scroll == null ? 1 : values.scroll, values.duration == null ? 4 : values.duration, cneEase[0], cneEase[1], values.absolute != true]
					});
				case "SetCameraBop":
					result.events.push({
						time: event.t,
						name: "Camera Modulo Change",
						params: [values.rate == null ? 4 : values.rate, values.intensity == null ? 1 : values.intensity]
					});
				case "ZoomCamera":
					var cneEase = values.ease == null || values.ease == "INSTANT" ? ["linear", null] : parseEase(values.ease);
					result.events.push({
						time: event.t,
						name: "Camera Zoom",  // we dont support the direct mode since welp, its kind of useless here  - Nex
						params: [values.ease != "INSTANT", values.zoom == null ? 1 : values.zoom, "camGame", values.duration == null ? 4 : values.duration, cneEase[0], cneEase[1], values.mode, false]
					});
			}
		}
	}

	public static function parseMeta(data:Dynamic, result:ChartMetaData, ?songID:String) {
		var data:SwagMetadata = data;
		var songName = data.songName;
		var songID:String = songID == null ? songName.toLowerCase().replace(" ", "-") : songID;
		var firstTimeChange:SwagTimeChange = data.timeChanges[0];

		result.name = songID;
		result.bpm = firstTimeChange.bpm.getDefault(Flags.DEFAULT_BPM);
		result.beatsPerMeasure = firstTimeChange.n.getDefault(Flags.DEFAULT_BEATS_PER_MEASURE);
		result.stepsPerBeat = firstTimeChange.d.getDefault(Flags.DEFAULT_STEPS_PER_BEAT);
		result.displayName = songName;
		result.icon = Flags.DEFAULT_HEALTH_ICON;
		result.color = 0xFFFFFF;
		result.opponentModeAllowed = true;
		result.coopAllowed = true;
		result.difficulties = data.playData.difficulties.concat(data.playData.songVariations.getDefault([]));

		if (result.customValues == null) result.customValues = {};
		result.customValues.artist = data.artist;
		if (data.charter != null) result.customValues.charter = data.charter;
		for (field in Reflect.fields(data.playData)) if (field != "difficulties" && field != "songVariations" && field != "characters" && field != "stage")
			Reflect.setProperty(result.customValues, field, Reflect.getProperty(data.playData, field));
	}

	public static function encodeMeta(meta:ChartMetaData, ?chart:ChartData):SwagMetadata {
		var addVars:Dynamic = meta.customValues;
		var defStage:String = addVars.stage != null ? addVars.stage : Flags.DEFAULT_STAGE;
		var defChars:SwagCharactersList = addVars.characters != null ? addVars.characters : {player: Flags.DEFAULT_CHARACTER, girlfriend: Flags.DEFAULT_GIRLFRIEND, opponent: Flags.DEFAULT_OPPONENT, playerVocals: [], opponentVocals: [], instrumental: '', altInstrumentals: []};
		var defTimeCh:Array<SwagTimeChange>;

		if (addVars.timeChanges != null && addVars.timeChanges.length > 0) {
			defTimeCh = addVars.timeChanges;
			defTimeCh[0].bpm = meta.bpm;
		}
		else defTimeCh = [{bpm: meta.bpm, t: -1}];

		if (chart != null) {
			defStage = chart.stage;

			var done:Array<Bool> = [false, false, false];
			for (strumLine in chart.strumLines) switch (strumLine.type) {
				case OPPONENT:
					if (!done[0]) {
						done[0] = true;
						defChars.opponent = strumLine.characters.getDefault([defChars.opponent])[0];
					}
				case PLAYER:
					if (!done[1]) {
						done[1] = true;
						defChars.player = strumLine.characters.getDefault([defChars.player])[0];
					}
				case ADDITIONAL:
					if (!done[3]) {
						done[3] = true;
						defChars.girlfriend = strumLine.characters.getDefault([defChars.girlfriend])[0];
					}
			}
		}

		var result:SwagMetadata = {
			songName: meta.name,
			timeFormat: MILLISECONDS,
			artist: "",
			timeChanges: defTimeCh,
			looped: false,
			generatedBy: 'V-Slice Chart Importer (Codename Engine)',
			version: Flags.VSLICE_SONG_METADATA_VERSION,
			playData: {
				stage: defStage,
				characters: defChars,
				songVariations: addVars.songVariations != null ? [for (i in 0...addVars.songVariations.length) {meta.difficulties.remove(addVars.songVariations[i]); addVars.songVariations[i];}] : [],
				difficulties: meta.difficulties,
				noteStyle: addVars.noteStyle != null ? addVars.noteStyle : Flags.VSLICE_DEFAULT_NOTE_STYLE,
				album: addVars.album != null ? addVars.album : Flags.VSLICE_DEFAULT_ALBUM_ID,
				previewStart: addVars.previewStart != null ? addVars.previewStart : Flags.VSLICE_DEFAULT_PREVIEW_START,
    			previewEnd: addVars.previewEnd != null ? addVars.previewEnd : Flags.VSLICE_DEFAULT_PREVIEW_END
			},
		};

		return result;
	}

	public static function encodeChart(chart:ChartData):NewSwagSong {
		// TO DO
		return null;
	}

	public static function parseEase(vsliceEase:String):Array<String> {
		for (key in ['InOut', 'In', 'Out']) if (vsliceEase.endsWith(key)) return [vsliceEase.substr(0, vsliceEase.length - key.length), key];
		return [vsliceEase];
	}
}

// METADATA STRUCTURES
typedef SwagMetadata =
{
	var version:String;
	var songName:String;
	var artist:String;
	var ?charter:String;
	var ?divisions:Int;
	var ?looped:Bool;
	var ?offsets:SwagSongOffsets;
	var playData:SwagPlayData;
	var generatedBy:String;
	var ?timeFormat:SwagTimeFormat;
	var timeChanges:Array<SwagTimeChange>;
}

enum abstract SwagTimeFormat(String) from String to String
{
	var TICKS = 'ticks';
	var FLOAT = 'float';
	var MILLISECONDS = 'ms';
}

typedef SwagTimeChange =
{
	var t:Int;  // Time Stamp
	var ?b:Int;  // Beat Time
	var bpm:Float;
	var ?n:Int;  // Time Signature Num
	var ?d:Int;  // Time Signature Den
	var ?bt:Array<Int>;  // Beat Tuplets
}

typedef SwagSongOffsets =
{
	var ?instrumental:Float;
	var ?altInstrumentals:Dynamic;
	var ?vocals:Dynamic;
	var ?altVocals:Dynamic;
}

typedef SwagPlayData =
{
	var ?songVariations:Array<String>;
	var difficulties:Array<String>;
	var characters:SwagCharactersList;
	var stage:String;
	var noteStyle:String;
	var ?ratings:Dynamic;
	var ?album:String;
	var ?previewStart:Int;
	var ?previewEnd:Int;
}

typedef SwagCharactersList =
{
	var ?player:String;
	var ?girlfriend:String;
	var ?opponent:String;
	var ?instrumental:String;
	var ?altInstrumentals:Array<String>;
	var ?opponentVocals:Array<String>;
	var ?playerVocals:Array<String>;
}

// CHART STRUCTURE
typedef NewSwagSong =
{
	var version:String;
	var scrollSpeed:Dynamic;  // Map<String, Float>
	var events:Array<SwagEvent>;
	var notes:Dynamic;  // Map<String, Array<SwagNote>>
	var generatedBy:String;
}

typedef SwagEvent =
{
	var t:Float;  // Time
	var e:String;  // Event Kind
	var ?v:Dynamic;  // Value (Map<String, Dynamic>)
}

typedef SwagNote =
{
	var t:Float;  // Time
	var d:Int;  // Data
	var ?l:Float;  // Length
	var ?k:String;  // Kind
	var ?p:Array<SwagNoteParamsData>; // Params
}

typedef SwagNoteParamsData =
{
	var n:String;  // Name
	var v:Dynamic;  // Value
}