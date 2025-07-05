package funkin.backend.chart;

import funkin.backend.chart.ChartData.ChartEvent;
import funkin.backend.system.Conductor;

class FNFLegacyParser {
	public static function parse(data:Dynamic, result:ChartData) {
		// base fnf chart parsing
		var data:SwagSong = Chart.cleanSongData(data);

		result.scrollSpeed = data.speed;
		result.stage = data.stage;

		var p2isGF:Bool = false;
		result.strumLines.push({
			characters: [data.player2],
			type: 0,
			position: (p2isGF = data.player2.startsWith("gf")) ? "girlfriend" : "dad",
			notes: []
		});
		result.strumLines.push({
			characters: [data.player1],
			type: 1,
			position: "boyfriend",
			notes: []
		});
		var gfName = data.gf != null ? data.gf : (data.gfVersion != null ? data.gfVersion : (data.player3 != null ? data.player3 : "gf"));
		if (!p2isGF && gfName != "none") {
			result.strumLines.push({
				characters: [gfName],
				type: 2,
				position: "girlfriend",
				notes: [],
				visible: false,
			});
		}

		result.meta.bpm = data.bpm;
		result.meta.needsVoices = data.needsVoices.getDefault(true);

		var camFocusedBF:Bool = false;
		var altAnims:Bool = false;
		var beatsPerMeasure:Float = data.beatsPerMeasure.getDefault(4);
		var curBPM:Float = data.bpm;
		var curTime:Float = 0;
		var curCrochet:Float = ((60 / curBPM) * 1000);

		if (data.notes != null) for(section in data.notes) {
			if (section == null) {
				curTime += curCrochet * beatsPerMeasure;
				continue; // Yoshi Engine charts crash fix
			}

			if (camFocusedBF != (camFocusedBF = section.mustHitSection)) {
				result.events.push({
					time: curTime,
					name: "Camera Movement",
					params: [camFocusedBF ? 1 : 0]
				});
			}

			if (section.altAnim == null) section.altAnim = false;
			if (altAnims != (altAnims = section.altAnim)) {
				result.events.push({
					time: curTime,
					name: "Alt Animation Toggle",
					params: [altAnims, false, 0]
				});
			}

			if (section.sectionNotes != null) for(note in section.sectionNotes) {
				if (note[1] < 0) continue;

				var daStrumTime:Float = note[0];
				var daNoteData:Int = Std.int(note[1] % 8);
				var daNoteType:Int = Std.int(note[1] / 8);
				var gottaHitNote:Bool = daNoteData >= 4 ? !section.mustHitSection : section.mustHitSection;

				if (note.length > 2) {
					if (note[3] is Int && data.noteTypes != null)
						daNoteType = Chart.addNoteType(result, data.noteTypes[Std.int(note[3])-1]);
					else if (note[3] is String)
						daNoteType = Chart.addNoteType(result, note[3]);
				} else {
					if(data.noteTypes != null)
						daNoteType = Chart.addNoteType(result, data.noteTypes[daNoteType-1]);
				}

				result.strumLines[gottaHitNote ? 1 : 0].notes.push({
					time: daStrumTime,
					id: daNoteData % 4,
					type: daNoteType,
					sLen: note[2]
				});
			}

			if (section.changeBPM && section.bpm != curBPM) {
				curCrochet = ((60 / (curBPM = section.bpm)) * 1000);

				result.events.push({
					time: curTime,
					name: "BPM Change",
					params: [section.bpm]
				});
			}

			curTime += curCrochet * beatsPerMeasure;
		}
	}

	// have conductor set up BEFORE you run this :D -lunar
	public static function encode(chart:ChartData):Dynamic {
		var base:SwagSong = __convertToSwagSong(chart);
		base.notes = __convertToSwagSections(chart);

		for (strumLine in chart.strumLines)
			for (note in strumLine.notes) {
				var section:Int = Math.floor(Conductor.getStepForTime(note.time) / Conductor.getMeasureLength());
				var swagSection:SwagSection = base.notes[section];
				if (section > 0 && section < base.notes.length) {
					var sectionNote:Array<Dynamic> = [
						note.time, // TIME
						note.id, // DATA
						note.sLen // SUSTAIN LENGTH
					];

					if ((swagSection.mustHitSection && strumLine.type == OPPONENT) ||
						(!swagSection.mustHitSection && strumLine.type == PLAYER))
					   sectionNote[1] += 4;
					swagSection.sectionNotes.push(sectionNote);
				}
			}

		return {song: base};
	}

	// To make it easier to write the psych parser... -lunar
	@:noCompletion public static function __convertToSwagSong(chart:ChartData):SwagSong {
		var base:SwagSong = {
			song: chart.meta.name,
			notes: null,
			bpm: chart.meta.bpm,
			needsVoices: chart.meta.needsVoices,
			speed: chart.scrollSpeed,

			player1: null,
			player2: null,
			validScore: true
		};

		for (strumLine in chart.strumLines)
			switch (strumLine.type) {
				case OPPONENT:
					if (base.player2 == null) base.player2 = strumLine.characters.getDefault(["dad"])[0];
				case PLAYER:
					if (base.player1 == null) base.player1 = strumLine.characters.getDefault(["bf"])[0];
				case ADDITIONAL: // do nothing
			}

		return base;
	}

	@:noCompletion public static function __convertToSwagSections(chart:ChartData):Array<SwagSection> {
		var events:Array<ChartEvent> = [for (event in chart.events) Reflect.copy(event)];

		var measures:Float = Conductor.getMeasuresLength();
		var sections:Int = Math.floor(measures) + (measures % 1 > 0 ? 1 : 0);

		var notes:Array<SwagSection> = cast new haxe.ds.Vector<SwagSection>(sections);
		for (section in 0...sections) {
			var baseSection:SwagSection = {
				sectionNotes: [],
				lengthInSteps: Std.int(Conductor.getMeasureLength()),
				mustHitSection: notes[section-1] != null ? notes[section-1].mustHitSection : false,
				bpm: notes[section-1] != null ? notes[section-1].bpm : chart.meta.bpm,
				changeBPM: false,
				altAnim: notes[section-1] != null ? notes[section-1].altAnim : false
			};

			var sectionEndTime:Float = Conductor.getTimeForStep(Conductor.getMeasureLength() * (section+1));
			while(events.length > 0 && events[0].time < sectionEndTime) {
				var event:ChartEvent = events.shift();
				switch (event.name) {
					case "Camera Movement":
						baseSection.mustHitSection = chart.strumLines[event.params[0]].type == PLAYER;
					case "Alt Animation Toggle":
						baseSection.altAnim = event.params[0] || event.params[1];
					case "BPM Change":
						baseSection.changeBPM = true;
						baseSection.bpm = event.params[0];
				}
			}
			notes[section] = baseSection;
		}
		return notes;
	}
}

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var ?stage:String;
	var ?noteTypes:Array<String>;
	var ?events:Array<Dynamic>;

	var player1:String;
	var player2:String;
	var ?player3:String;  // alt for gf but idr if it was just used in psych or what but eh whatever maybe its better here anyways  - Nex
	var ?gf:String;
	var ?gfVersion:String;
	var validScore:Bool;

	// ADDITIONAL STUFF THAT MAY NOT BE PRESENT IN CHART
	var ?maxHealth:Float;
	var ?beatsPerMeasure:Float;
	var ?stepsPerBeat:Float;
}

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var ?sectionBeats:Float;
	var ?typeOfSection:Int;
	var mustHitSection:Bool;
	var ?gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Null<Bool>;
	var ?camTarget:Null<Float>;
}
