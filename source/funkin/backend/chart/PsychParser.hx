package funkin.backend.chart;

import funkin.backend.chart.FNFLegacyParser.SwagSection;
import funkin.backend.chart.ChartData.ChartEvent;
import funkin.backend.chart.FNFLegacyParser.SwagSong;
import funkin.backend.system.Conductor;

class PsychParser {
	// Already parsed in sections
	public static var ignoreEvents:Array<String> = [
		"Camera Movement",
		"Alt Animation Toggle",
		"BPM Change"
	];

	/**
	 * Converts 1.0 Psych charts to older ones
	 */
	public static function standardize(data:Dynamic, result:ChartData) {
		var sectionsData:Array<Dynamic> = Chart.cleanSongData(data).notes;
		if (sectionsData == null) return;

		for (section in sectionsData) for (note in cast(section.sectionNotes, Array<Dynamic>)) {
			var gottaHitNote:Bool = section.mustHitSection == (note[1] >= 4);
			note[1] = (note[1] % 4) + (gottaHitNote ? 4 : 0);

			if (note[3] != null && Std.isOfType(note[3], String))
				note[3] = Chart.addNoteType(result, note[3]);
		}
	}

	public static function parse(data:Dynamic, result:ChartData) {
		if (Chart.detectChartFormat(data) == PSYCH_NEW) standardize(data, result);
		FNFLegacyParser.parse(data, result);
	}

	public static function encode(chart:ChartData):Dynamic {
		var base:SwagSong = FNFLegacyParser.__convertToSwagSong(chart);
		base.notes = FNFLegacyParser.__convertToSwagSections(chart);
		base.stage = chart.stage;

		for (section in base.notes)
			section.sectionBeats = Conductor.beatsPerMeasure;

		for (strumLine in chart.strumLines)
			if (strumLine.type == ADDITIONAL && base.gfVersion == null)
				base.gfVersion = strumLine.characters.getDefault(["gf"])[0];

		for (strumLine in chart.strumLines)
			for (note in strumLine.notes) {
				var section:Int = Math.floor(Conductor.getStepForTime(note.time) / Conductor.getMeasureLength());
				var swagSection:SwagSection = base.notes[section];

				if (section >= 0 && section < base.notes.length) {
					var sectionNote:Array<Dynamic> = [
						note.time, // TIME
						note.id, // DATA
						note.sLen, // SUSTAIN LENGTH
						chart.noteTypes.getDefault([""])[note.type] // NOTE TYPE
					];

					if ((swagSection.mustHitSection && strumLine.type == OPPONENT) ||
						 (!swagSection.mustHitSection && strumLine.type == PLAYER))
						sectionNote[1] += 4;
					swagSection.sectionNotes.push(sectionNote);
				}
			}

		var groupedEvents:Array<Array<ChartEvent>> = [];
		var __last:Array<ChartEvent> = null;
		var __lastTime:Float = Math.NaN;
		for (e in [for (event in chart.events) Reflect.copy(event)]) {
			if (e == null || ignoreEvents.contains(e.name)) continue;

			if (__last != null && __lastTime == e.time)
				__last.push(e);
			else {
				__last = [e];
				__lastTime = e.time;
				groupedEvents.push(__last);
			}
		}

		base.events = [];
		for (events in groupedEvents) {
			var psychEvents:Array<Dynamic> = [];
			for (event in events)
				switch (event.name) {
					case "Add Camera Zoom":
						psychEvents.push([
							event.name,
							event.params[1] == "camGame" ? event.params[0] : 0, // CAMERA ZOOM
							event.params[1] == "camHUD" ? event.params[0] : 0, // UI ZOOM
						]);
					case "Play Animation":
						psychEvents.push([
							event.name,
							event.params[1], // ANIMATION TO PLAY
							switch (chart.strumLines[event.params[0]].type) { // CHARACTER
								case PLAYER: "bf";
								case OPPONENT: "dad";
								case ADDITIONAL: "gf";
							}
						]);
					case "Scroll Speed Change":
						var eventStep:Float = Conductor.getStepForTime(event.time);
						psychEvents.push([
							"Change Scroll Speed",
							FlxMath.roundDecimal(event.params[1]/chart.scrollSpeed, 2), // SCROLL SPEED MULTIPLER
							FlxMath.roundDecimal( // TIME
								event.params[0] ? // IS TWEENED?
								(Conductor.getTimeForStep(eventStep+event.params[2]) - Conductor.getTimeForStep(eventStep))/1000
								: 0, 2)
						]);
					default:
						// TODO: allow custom formats in event.json
						var split:Float = event.params.length / 2;

						var val1:String = [for (arg in 0...Math.ceil(split)) event.params[arg]].join(",");
						var val2:String = [for (arg in Math.ceil(split)...event.params.length) event.params[arg]].join(",");

						psychEvents.push([event.name, val1, val2]);
				}

			for (psychEvent in psychEvents)
				for (i in 1...3) // Turn both vals into strings
					if (!(psychEvent[i] is String))
						psychEvent[i] = Std.string(psychEvent[i]);

			base.events.push([events[0].time, psychEvents]);
		}
		return {song: base};
	}
}
