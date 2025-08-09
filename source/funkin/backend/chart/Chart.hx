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

	public static function loadEventsJson(songName:String, ?variant:String) {
		var variantSuffix = variant != null && variant != "" ? '-$variant' : "";
		var path = Paths.file('songs/${songName}/events$variantSuffix.json');
		var data:Array<ChartEvent> = null;
		if (Assets.exists(path)) {
			try {
				data = Json.parse(Assets.getText(path)).events;
				for (event in data) event.global = true;
			} catch(e) Logs.trace('Failed to load song event data for ${songName} ($path): ${Std.string(e)}', ERROR);
		}
		return data;
	}

	inline public static function defaultChartMetaFields(data:ChartMetaData):ChartMetaData {
		data.setFieldDefault("displayName", data.name);

		data.setFieldDefault("bpm", Flags.DEFAULT_BPM);
		data.setFieldDefault("beatsPerMeasure", Flags.DEFAULT_BEATS_PER_MEASURE);
		data.setFieldDefault("stepsPerBeat", Flags.DEFAULT_STEPS_PER_BEAT);
		data.setFieldDefault("icon", Flags.DEFAULT_HEALTH_ICON);
		data.setFieldDefault("coopAllowed", Flags.DEFAULT_COOP_ALLOWED);
		data.setFieldDefault("opponentModeAllowed", Flags.DEFAULT_OPPONENT_MODE_ALLOWED);
		data.setFieldDefault("instSuffix", "");
		data.setFieldDefault("vocalsSuffix", "");
		data.setFieldDefault("needsVoices", true);
		data.setFieldDefault("difficulties", []);
		data.setFieldDefault("variants", []);

		return data;
	}

	public static function loadChartMeta(songName:String, ?variant:String, fromMods:Bool = true, includeMetaVariations = true):ChartMetaData {
		var defaultPath = Paths.file('songs/$songName/meta.json'), isVariant = false;
		var data:ChartMetaData = null, paths = (variant == null || variant == '') ? [defaultPath] : [Paths.file('songs/$songName/meta-$variant.json'), defaultPath];
		for (path in paths) if (Assets.exists(path)) {
			fromMods = Paths.assetsTree.existsSpecific(path, "TEXT", MODS);
			try {
				var tempData = Json.parse(Assets.getText(path));
				tempData.color = CoolUtil.getColorFromDynamic(tempData.color).getDefault(Flags.DEFAULT_COLOR);
				data = tempData;
			} catch(e) Logs.trace('Failed to load song metadata for $songName ($path): ${Std.string(e)}', ERROR);

			if (data != null) {
				isVariant = path != defaultPath;
				break;
			}
		}

		if (data != null) data.name = songName;
		else data = {
			name: songName,
			color: Flags.DEFAULT_COLOR
		};

		if (isVariant) data.variant = variant;
		else data.variant = null;

		defaultChartMetaFields(data);

		if (data.difficulties.length <= 0) {
			var path = 'songs/$songName/charts/';
			if (isVariant) path += '$variant/';

			data.difficulties = [for(f in Paths.getFolderContent(path, false, fromMods ? MODS : SOURCE)) if (Path.extension(f.toUpperCase()) == "JSON") Path.withoutExtension(f)];
			if (data.difficulties.length == 3) {
				var tempDiffs = [];
				for (d in data.difficulties) switch(d.toLowerCase()) {
					case "easy":   tempDiffs.insert(0, d);
					case "normal": tempDiffs.insert(1, d);
					case "hard":   tempDiffs.insert(2, d);
				}
				if (tempDiffs.length == 3) data.difficulties = tempDiffs;
			}
		}

		data.metas = [];
		if (includeMetaVariations && data.variants.length > 0) for (variant in data.variants) {
			if (!data.metas.exists(variant) && Assets.exists(Paths.file('songs/$songName/meta-$variant.json')))
				data.metas.set(variant, loadChartMeta(songName, variant, fromMods));
		}

		return data;
	}

	public static function parse(songName:String, ?difficulty:String, ?variant:String):ChartData {
		if (difficulty == null) difficulty = Flags.DEFAULT_DIFFICULTY;

		var chartPath = Paths.chart(songName, difficulty, variant);
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

		var valid:Bool = true, namePrint = '$songName $difficulty' + ((variant != null && variant != '') ? ' ($variant)' : '');
		if (!Assets.exists(chartPath)) {
			Logs.error('Chart for song $namePrint at "$chartPath" was not found.');
			valid = false;
		}
		var data:Dynamic = null;
		if (valid) {
			try data = Json.parse(Assets.getText(chartPath))
			catch(e) Logs.trace('Could not parse chart for song $namePrint: ${Std.string(e)}', ERROR, RED);
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

		var loadedMeta = loadChartMeta(songName, variant != null && variant != "" ? variant : difficulty, base.fromMods, false);
		if (base.meta == null) base.meta = loadedMeta;
		else {
			for (field in Reflect.fields(base.meta)) {
				var f = Reflect.field(base.meta, field);
				if (f != null) Reflect.setField(loadedMeta, field, f);
			}
			base.meta = loadedMeta;
		}

		/**
		 * events.json LOADING
		 */
		#if REGION
		var extraEvents:Array<ChartEvent> = loadEventsJson(songName, variant);
		if (extraEvents != null) base.events = base.events.concat(extraEvents);
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
	 * @param chart Chart to save.
	 * @param difficulty Name of the difficulty (Optional).
	 * @param variant Name of the Variant (Optional).
	 * @param saveSettings (Optional).
	 * @return Filtered chart used for saving.
	 */
	public static function save(chart:ChartData, ?difficulty:String, ?variant:String, ?saveSettings:ChartSaveSettings):ChartData {
		if (difficulty == null) difficulty = Flags.DEFAULT_DIFFICULTY;
		if (saveSettings == null) saveSettings = {};

		var filteredChart = filterChartForSaving(chart, saveSettings.saveMetaInChart, saveSettings.saveLocalEvents, saveSettings.saveGlobalEvents && saveSettings.seperateGlobalEvents != true);

		#if sys
		var songPath = saveSettings.songFolder == null ? 'assets/songs/${chart.meta.name}' : saveSettings.songFolder, variantSuffix = variant != null && variant != "" ? '-$variant' : "";
		var metaPath = 'meta$variantSuffix.json', prettyPrint = saveSettings.prettyPrint == true ? Flags.JSON_PRETTY_PRINT : null, temp:String;
		if ((temp = Paths.assetsTree.getPath('$songPath/$metaPath')) != null) {
			songPath = temp.substr(0, temp.length - metaPath.length - 1);
			metaPath = temp;
		}
		else if (saveSettings.songFolder == null)
			metaPath = (songPath = '${Paths.getAssetsRoot()}/$songPath') + '/$metaPath';

		var chartFolder = saveSettings.folder == null ? ((variant == null || variant == '') ? 'charts' : 'charts/$variant') : saveSettings.folder;
		var chartPath = '$songPath/$chartFolder/${difficulty.trim()}.json';

		if (saveSettings.saveChart == null || saveSettings.saveChart == true)
			CoolUtil.safeSaveFile(chartPath, Json.stringify(filteredChart, null, prettyPrint));

		if (saveSettings.overrideExistingMeta || !FileSystem.exists(metaPath))
			CoolUtil.safeSaveFile(metaPath, Json.stringify(filterMetaForSaving(chart.meta), null, prettyPrint));

		if (saveSettings.seperateGlobalEvents == true) {
			var eventsPath = '$songPath/events$variantSuffix.json', events = filterEventsForSaving(chart.events, false, true);

			if (events.length != 0) CoolUtil.safeSaveFile(eventsPath, Json.stringify({events: events}, null, prettyPrint));
		}
		#end

		return filteredChart;
	}

	public static function filterChartForSaving(chart:ChartData, saveMetaInChart = true, ?saveLocalEvents:Bool, ?saveGlobalEvents:Bool):ChartData {
		var meta = chart.meta, events = chart.events;
		chart.meta = null;
		chart.events = null;

		var data = Reflect.copy(chart); // make a copy of the chart to leave the OG intact

		chart.meta = meta;
		chart.events = events;

		data.meta = saveMetaInChart ? filterMetaForSaving(meta) : null;
		data.events = filterEventsForSaving(events, saveLocalEvents, saveGlobalEvents);
		data.fromMods = null;

		var sortedData:Dynamic = {};
		for (f in Reflect.fields(data)) {
			var v = Reflect.field(data, f);
			if (v != null)
				Reflect.setField(sortedData, f, v);
		}
		return sortedData;
	}

	public static function filterEventsForSaving(events:Array<ChartEvent>, saveLocalEvents = true, saveGlobalEvents = false):Array<ChartEvent> {
		var data = [];
		if (!saveLocalEvents && !saveGlobalEvents) return data;

		for (event in events) if ((saveLocalEvents && event.global != true) || (saveGlobalEvents && event.global == true)) {
			var copy = Reflect.copy(event);
			if (saveLocalEvents ? event.global != true : event.global == true) Reflect.deleteField(copy, "global"); // should NOT delete the field when saving with the local events and the event should have been global  - Nex
			data.push(copy);
		}

		return data;
	}

	public static inline function makeMetaSaveable(meta:ChartMetaData, prettyPrint:Bool = true):String
		return Json.stringify(filterMetaForSaving(meta), null, prettyPrint ? Flags.JSON_PRETTY_PRINT : null);

	public static inline function filterMetaForSaving(meta:ChartMetaData):ChartMetaData {
		var data:Dynamic = Reflect.copy(meta);
		if (data.color != null) data.color = FlxColor.fromInt(data.color).toWebString(); // dont even ask me  - Nex
		Reflect.deleteField(data, "name");
		Reflect.deleteField(data, 'parsedColor');
		Reflect.deleteField(data, 'metas');
		Reflect.deleteField(data, "variant");
		if (data.instSuffix != null && data.instSuffix == "") Reflect.deleteField(data, "instSuffix");
		if (data.vocalsSuffix != null && data.vocalsSuffix == "") Reflect.deleteField(data, "vocalsSuffix");
		if (data.variants != null && data.variants.length == 0) Reflect.deleteField(data, "variants");
		return data;
	}
}

typedef ChartSaveSettings = {
	var ?prettyPrint:Bool;

	var ?saveMetaInChart:Bool;
	var ?saveLocalEvents:Bool;
	var ?saveGlobalEvents:Bool;

	var ?saveChart:Bool;
	var ?overrideExistingMeta:Bool;
	var ?seperateGlobalEvents:Bool;

	var ?folder:String;
	var ?songFolder:String;
}
