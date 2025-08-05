package funkin.backend.chart;

import funkin.backend.chart.ChartData;
import flixel.util.FlxColor;
import funkin.backend.chart.ChartData;
import haxe.Json;
import haxe.io.Path;

#if sys
import sys.FileSystem;
#end

using StringTools;

enum abstract ChartFormat(Int) {
	var CODENAME = 0;
	var LEGACY = 1;  // also used by many other engines (old Psych, Kade and more)  - Nex
	var VSLICE = 2;
	var PSYCH_NEW = 3;

	@:to public function toString():String {
		return switch(cast (this, ChartFormat)) {
			case CODENAME: "CODENAME";
			case LEGACY: "LEGACY";
			case VSLICE: "VSLICE";
			case PSYCH_NEW: "PSYCH_NEW";
		}
	}

	public static function fromString(str:String, def:ChartFormat = ChartFormat.LEGACY) {
		str = str.toLowerCase();
		str = StringTools.replace(str, " ", "");
		str = StringTools.replace(str, "_", "");
		str = StringTools.replace(str, ".", "");

		if(StringTools.startsWith(str, "psychv1") || StringTools.startsWith(str, "psych1"))
			return PSYCH_NEW;

		return switch(str) {
			case "codename" | "codenameengine": CODENAME;
			case "newpsych" | "psychnew": PSYCH_NEW;
			default: def;
		}
	}
}

class Chart {
	public static final version:String = "1.6.0";

	public static function cleanSongData(data:Dynamic):Dynamic {
		if (Reflect.hasField(data, "song")) {
			var field:Dynamic = Reflect.field(data, "song");
			if (field != null && Type.typeof(field) == TObject) // Cant use Reflect.isObject, because it detects strings for some reason
				return field;
		}
		return data;
	}

	public static function detectChartFormat(data:Dynamic):ChartFormat {
		var __temp:Dynamic;  // imma reuse this var so the program doesn't have to get values multiple times  - Nex

		if ((__temp = data.codenameChart) == true || __temp == "true")
			return CODENAME;

		if (Reflect.hasField(data, "version") && Reflect.hasField(data, "scrollSpeed"))
			return VSLICE;

		if ((__temp = cleanSongData(data).format) != null && __temp is String && StringTools.startsWith(__temp, "psych_v1"))
			return PSYCH_NEW;

		return LEGACY;
	}

	public static function loadEventsJson(songName:String) {
		var path = Paths.file('songs/${songName}/events.json');
		var data:Array<ChartEvent> = null;
		if (Assets.exists(path)) {
			try {
				data = Json.parse(Assets.getText(path)).events;
				for (event in data) event.global = true;
			} catch(e) Logs.trace('Failed to load song event data for ${songName} ($path): ${Std.string(e)}', ERROR);
		}
		return data;
	}

	public static function loadChartMeta(songName:String, ?difficulty:String, fromMods:Bool = true):ChartMetaData {
		if (difficulty == null) difficulty = Flags.DEFAULT_DIFFICULTY;

		var metaPath = Paths.file('songs/${songName}/meta.json');
		var metaDiffPath = Paths.file('songs/${songName}/meta-${difficulty}.json');

		var data:ChartMetaData = null;
		var fromMods:Bool = fromMods;
		for (path in [metaDiffPath, metaPath]) if (Assets.exists(path)) {
			fromMods = Paths.assetsTree.existsSpecific(path, "TEXT", MODS);
			try {
				var tempData = Json.parse(Assets.getText(path));
				tempData.color = CoolUtil.getColorFromDynamic(tempData.color).getDefault(Flags.DEFAULT_COLOR);
				data = tempData;
			} catch(e) Logs.trace('Failed to load song metadata for ${songName} ($path): ${Std.string(e)}', ERROR);
			if (data != null) break;
		}

		if (data == null) data = {
			name: songName,
			bpm: 100
		};

		data.name = songName;
		data.setFieldDefault("bpm", Flags.DEFAULT_BPM);
		data.setFieldDefault("beatsPerMeasure", Flags.DEFAULT_BEATS_PER_MEASURE);
		data.setFieldDefault("stepsPerBeat", Flags.DEFAULT_STEPS_PER_BEAT);
		data.setFieldDefault("needsVoices", true);
		data.setFieldDefault("icon", Flags.DEFAULT_HEALTH_ICON);
		data.setFieldDefault("difficulties", []);
		data.setFieldDefault("coopAllowed", Flags.DEFAULT_COOP_ALLOWED);
		data.setFieldDefault("opponentModeAllowed", Flags.DEFAULT_OPPONENT_MODE_ALLOWED);
		data.setFieldDefault("displayName", data.name);

		if (data.difficulties.length <= 0) {
			data.difficulties = [for(f in Paths.getFolderContent('songs/${songName}/charts/', false, fromMods ? MODS : SOURCE)) if (Path.extension(f.toUpperCase()) == "JSON") Path.withoutExtension(f)];
			var tempDiffs = [];
			if (data.difficulties.length == 3) {
				for(d in data.difficulties) {
					switch(d.toLowerCase()) {
						case "easy":	tempDiffs.insert(0, d);
						case "normal":	tempDiffs.insert(1, d);
						case "hard":	tempDiffs.insert(2, d);
					}
				}
				data.difficulties = tempDiffs;
			}
		}

		return data;
	}

	public static function parse(songName:String, ?difficulty:String):ChartData {
		if (difficulty == null) difficulty = Flags.DEFAULT_DIFFICULTY;

		var chartPath = Paths.chart(songName, difficulty);
		var base:ChartData = {
			strumLines: [],
			noteTypes: [],
			events: [],
			meta: {
				name: null
			},
			scrollSpeed: Flags.DEFAULT_SCROLL_SPEED,
			stage: Flags.DEFAULT_STAGE,
			codenameChart: true,
			fromMods: Paths.assetsTree.existsSpecific(chartPath, "TEXT", MODS)
		};

		var valid:Bool = true;
		if (!Assets.exists(chartPath)) {
			Logs.error('Chart for song ${songName} ($difficulty) at "$chartPath" was not found.');
			valid = false;
		}
		var data:Dynamic = null;
		if (valid) {
			try data = Json.parse(Assets.getText(chartPath))
			catch(e) Logs.trace('Could not parse chart for song ${songName} ($difficulty): ${Std.string(e)}', ERROR, RED);
		}

		/**
		 * CHART CONVERSION
		 */
		#if REGION
		if (data != null) switch (detectChartFormat(data)) {
			case CODENAME:
				// backward compat on events since it caused problems
				var eventTypesToString:Map<Int, String> = [
					-1 => "HScript Call",
					0 => "Unknown",
					1 => "Camera Movement",
					2 => "BPM Change",
					3 => "Alt Animation Toggle",
				];

				if (data.events == null) data.events = [];
				for (event in cast(data.events, Array<Dynamic>)) if (Reflect.hasField(event, "type")) {
					if (event.type != null)
						event.name = eventTypesToString[event.type];
					Reflect.deleteField(event, "type");
				}

				base = data;
			case PSYCH_NEW: PsychParser.parse(data, base);
			case VSLICE: Logs.trace("Couldn't parse V-Slice chart because it's not supported on runtime, it MUST be imported and converted in the new song editor window.", ERROR, RED);
			case LEGACY: FNFLegacyParser.parse(data, base);
		}
		#end

		var loadedMeta = loadChartMeta(songName, difficulty, base.fromMods);
		if (base.meta == null) base.meta = loadedMeta;
		else {
			for (field in Reflect.fields(base.meta)) {
				var f = Reflect.field(base.meta, field);
				if (f != null)
					Reflect.setField(loadedMeta, field, f);
			}
			base.meta = loadedMeta;
		}

		/**
		 * events.json LOADING
		 */
		#if REGION
		var extraEvents:Array<ChartEvent> = loadEventsJson(songName);
		if (extraEvents != null)
			base.events = base.events.concat(extraEvents);
		#end

		/**
		 * Set defaults on strum lines
		*/
		for(strumLine in base.strumLines) {
			if(strumLine.keyCount == null)
				strumLine.keyCount = 4;
		}

		return base;
	}

	public static function addNoteType(chart:ChartData, noteTypeName:String):Int {
		switch(noteTypeName.trim()) {
			case "Default Note" | null | "":
				return 0;
			default:
				var index = chart.noteTypes.indexOf(noteTypeName);
				if (index > -1) return index + 1;
				chart.noteTypes.push(noteTypeName);
				return chart.noteTypes.length;
		}
	}

	/**
	 * Saves the chart to the specific song folder path.
	 * @param songFolderPath Path to the song folder (ex: `mods/your mod/songs/song/`)
	 * @param chart Chart to save
	 * @param difficulty Name of the difficulty
	 * @param saveSettings
	 * @return Filtered chart used for saving.
	 */
	public static function save(songFolderPath:String, chart:ChartData, ?difficulty:String, ?saveSettings:ChartSaveSettings):ChartData {
		if (difficulty == null) difficulty = Flags.DEFAULT_DIFFICULTY;
		if (saveSettings == null) saveSettings = {};

		if (saveSettings.saveMetaInChart == null) saveSettings.saveMetaInChart = true;
		if (saveSettings.saveLocalEvents == null) saveSettings.saveLocalEvents = true;
		if (saveSettings.saveGlobalEvents == null) saveSettings.saveGlobalEvents = false;

		var filteredChart = filterChartForSaving(chart, saveSettings.saveMetaInChart, saveSettings.saveLocalEvents, saveSettings.saveGlobalEvents);
		var meta = filteredChart.meta;

		#if sys
		var saveFolder:String = saveSettings.folder == null ? "charts" : saveSettings.folder;

		if (!FileSystem.exists('${songFolderPath}/$saveFolder/'))
			FileSystem.createDirectory('${songFolderPath}/$saveFolder/');

		var chartPath = '${songFolderPath}/$saveFolder/${difficulty.trim()}.json';
		var metaPath = '${songFolderPath}/meta.json';

		CoolUtil.safeSaveFile(chartPath, Json.stringify(filteredChart, null, saveSettings.prettyPrint == true ? Flags.JSON_PRETTY_PRINT : null));

		if (saveSettings.overrideExistingMeta == true || !FileSystem.exists(metaPath))
			CoolUtil.safeSaveFile(metaPath, makeMetaSaveable(meta));
		#end
		return filteredChart;
	}

	public static function filterChartForSaving(chart:ChartData, ?saveMetaInChart:Bool, ?saveLocalEvents:Bool, ?saveGlobalEvents:Bool):ChartData {
		var data = Reflect.copy(chart); // make a copy of the chart to leave the OG intact
		if (saveMetaInChart != true) {
			data.meta = null;
		} else {
			data.meta = Reflect.copy(chart.meta); // also make a copy of the metadata to leave the OG intact.
			if (data.meta != null && Reflect.hasField(data.meta, "parsedColor")) Reflect.deleteField(data.meta, "parsedColor");
		}

		// in this part abt the events, i gotta account that these booleans can be null  - Nex
		if (saveLocalEvents != true && saveGlobalEvents != true) data.events = null;
		else {
			data.events = [];
			for (event in chart.events) if ((saveLocalEvents == true && event.global != true) || (saveGlobalEvents == true && event.global == true)) {
				var copy = Reflect.copy(event);
				if (saveLocalEvents == true ? event.global != true : event.global == true) Reflect.deleteField(copy, "global");  // should NOT delete the field when saving with the local events and the event should have been global  - Nex
				data.events.push(copy);
			}
			if (data.events.length == 0) data.events = null;
		}

		data.fromMods = null;

		var sortedData:Dynamic = {};
		for (f in Reflect.fields(data)) {
			var v = Reflect.field(data, f);
			if (v != null)
				Reflect.setField(sortedData, f, v);
		}
		return sortedData;
	}

	public static inline function makeMetaSaveable(meta:ChartMetaData, prettyPrint:Bool = true):String {
		var data:Dynamic = Reflect.copy(meta);
		if (data.color != null) data.color = new FlxColor(data.color).toWebString();  // dont even ask me  - Nex
		return Json.stringify(data, null, prettyPrint ? Flags.JSON_PRETTY_PRINT : null);
	}
}

typedef ChartSaveSettings = {
	var ?overrideExistingMeta:Bool;
	var ?saveMetaInChart:Bool;
	var ?saveLocalEvents:Bool;
	var ?saveGlobalEvents:Bool;
	var ?prettyPrint:Bool;
	var ?folder:String;
}