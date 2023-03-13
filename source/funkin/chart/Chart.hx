package funkin.chart;

import funkin.chart.ChartData;
import flixel.util.FlxColor;
import haxe.io.Path;
import funkin.system.Song.SwagSong;
import haxe.Json;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

class Chart {
    public static function loadChartMeta(songName:String, difficulty:String = "normal") {
        var metaPath = Paths.file('songs/${songName.toLowerCase()}/meta.json');
        var metaDiffPath = Paths.file('songs/${songName.toLowerCase()}/meta-${difficulty.toLowerCase()}.json');

        var data:ChartMetaData = null;
        var fromMods:Bool = false;
        for(path in [metaDiffPath, metaPath]) {
            if (Assets.exists(path)) {
                fromMods = Paths.assetsTree.existsSpecific(path, "TEXT", MODS);
                try {
                    data = Json.parse(Assets.getText(path));
                } catch(e) {
                    Logs.trace('Failed to load song metadata for ${songName} ($path): ${Std.string(e)}', ERROR);
                }
                if (data != null) break;
            }
        }

        if (data == null)
            data = {
                name: songName,
                bpm: 100
            };
        data.setFieldDefault("name", songName);
        data.setFieldDefault("beatsPerMesure", 4);
        data.setFieldDefault("stepsPerBeat", 4);
        data.setFieldDefault("needsVoices", true);
        data.setFieldDefault("icon", "face");
        data.setFieldDefault("difficulties", []);
        data.setFieldDefault("coopAllowed", false);
        data.setFieldDefault("opponentModeAllowed", false);
        data.setFieldDefault("displayName", data.name);
        data.setFieldDefault("parsedColor", data.color.getColorFromDynamic());

        if (data.difficulties.length <= 0) {
            data.difficulties = [for(f in Paths.getFolderContent('songs/${songName.toLowerCase()}/charts/', false, !fromMods)) if (Path.extension(f = f.toUpperCase()) == "JSON") Path.withoutExtension(f)];
			if (data.difficulties.length == 3) {
				var hasHard = false, hasNormal = false, hasEasy = false;
				for(d in data.difficulties) {
					switch(d) {
						case "EASY":	hasEasy = true;
						case "NORMAL":	hasNormal = true;
						case "HARD":	hasHard = true;
					}
				}
				if (hasHard && hasNormal && hasEasy) {
					data.difficulties[0] = "EASY";
					data.difficulties[1] = "NORMAL";
					data.difficulties[2] = "HARD";
				}
			}
        }
        if (data.difficulties.length <= 0)
            data.difficulties.push("CHART MISSING");

        return data;
    }

    public static function parse(songName:String, difficulty:String = "normal"):ChartData {
        var chartPath = Paths.chart(songName, difficulty);
        var base:ChartData = {
            strumLines: [],
            noteTypes: [],
            events: [],
            meta: null,
            scrollSpeed: 2,
            stage: "stage",
            codenameChart: true,
            fromMods: Paths.assetsTree.existsSpecific(chartPath, "TEXT", MODS)
        };

        if (!Assets.exists(chartPath)) {
            Logs.trace('Chart for song ${songName} ($difficulty) at "$chartPath" was not found.', ERROR, RED);
            return base;
        }
        var data:Dynamic = null;
        try {
            data = Json.parse(Assets.getText(chartPath));
        } catch(e) {
            Logs.trace('Could not parse chart for song ${songName} ($difficulty): ${Std.string(e)}', ERROR, RED);
        }

        if (Reflect.hasField(data, "codenameChart") && Reflect.field(data, "codenameChart") == true) {
            base = data;
        } else {
            // base fnf chart parsing
            var data:SwagSong = data;
            if (Reflect.hasField(data, "song")) {
                var field:Dynamic = Reflect.field(data, "song");
                if (!(field is String))
                    data = field;
            }

            base.scrollSpeed = data.speed;
            base.stage = data.stage;

            base.strumLines.push({
                characters: [data.player2],
                opponent: true,
                position: "dad",
                notes: []
            });
            base.strumLines.push({
                characters: [data.player1],
                opponent: false,
                position: "boyfriend",
                notes: []
            });
            if (data.gf != "none") {
                base.strumLines.push({
                    characters: [data.gf != null ? data.gf : "gf"],
                    opponent: true,
                    position: "girlfriend",
                    notes: [],
                    visible: false,
                    strumLinePos: 0.5
                });
            }

            var camFocusedBF:Bool = false;
            var beatsPerMesure:Float = data.beatsPerMesure.getDefault(4);
            var curBPM:Float = data.bpm;
            var curTime:Float = 0;
            var curCrochet:Float = ((60 / curBPM) * 1000);

            if (data.notes != null) for(section in data.notes) {
                if (section == null) {
                    curTime += curCrochet * beatsPerMesure;
                    continue; // Yoshi Engine charts crash fix
                }

                if (camFocusedBF != (camFocusedBF = section.mustHitSection)) {
                    base.events.push({
                        time: curTime,
                        type: CAM_MOVEMENT,
                        params: [camFocusedBF ? 1 : 0]
                    });
                }

                if (section.sectionNotes != null) for(note in section.sectionNotes) {
                    if (note[1] < 0) continue;

                    var daStrumTime:Float = note[0];
				    var daNoteData:Int = Std.int(note[1] % 8);
                    var daNoteType:Int = Std.int(note[1] / 8);
                    var gottaHitNote:Bool = daNoteData >= 4 ? !section.mustHitSection : section.mustHitSection;

                    if (note.length > 2) {
                        if (note[3] is Int)
                            daNoteType = addNoteType(base, data.noteTypes[Std.int(note[3])-1]);
                        else if (note[3] is String)
                            daNoteType = addNoteType(base, note[3]);
                    } else {
                        daNoteType = addNoteType(base, data.noteTypes[daNoteType-1]);
                    }

                    
                    base.strumLines[gottaHitNote ? 1 : 0].notes.push({
                        time: daStrumTime,
                        id: daNoteData % 4,
                        type: daNoteType,
                        sLen: note[2]
                    });
                }

                if (section.changeBPM && section.bpm != curBPM) {
                    // TODO: BPM CHANGE EVENT
                    curCrochet = ((60 / (curBPM = section.bpm)) * 1000);
                }

                curTime += curCrochet * beatsPerMesure;
            }
        }

        if (base.meta == null)
            base.meta = loadChartMeta(songName, difficulty);
        return base;
    }

    private static function addNoteType(chart:ChartData, noteTypeName:String):Int {
        switch(noteTypeName.trim()) {
            case "Default Note" | null | "":
                return 0;
            default:
                var index = chart.noteTypes.indexOf(noteTypeName);
                if (index > -1)
                    return index+1;
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
    public static function save(songFolderPath:String, chart:ChartData, difficulty:String = "normal", ?saveSettings:ChartSaveSettings):ChartData {
        if (saveSettings == null) saveSettings = {};

        var filteredChart = filterChartForSaving(chart, saveSettings.saveMetaInChart);
        var meta = filteredChart.meta;
        
        // idk how null reacts to it so better be sure

        #if sys
        if (!FileSystem.exists('${songFolderPath}\\charts\\'))
            FileSystem.createDirectory('${songFolderPath}\\charts\\');

        var chartPath = '${songFolderPath}\\charts\\${difficulty.trim()}.json';
        var metaPath = '${songFolderPath}\\meta.json';

        File.saveContent(chartPath, Json.stringify(filteredChart, null, saveSettings.prettyPrint == true ? "\t" : null));

        if (saveSettings.overrideExistingMeta == true || !FileSystem.exists(metaPath))
            File.saveContent(metaPath, Json.stringify(meta, null, saveSettings.prettyPrint == true ? "\t" : null));
        #end
        return filteredChart;
    }

    public static function filterChartForSaving(chart:ChartData, ?saveMetaInChart:Null<Bool>):ChartData {
        var data = Reflect.copy(chart); // make a copy of the chart to leave the OG intact
        if (saveMetaInChart != true) {
            data.meta = null;
        } else {
            data.meta = Reflect.copy(chart.meta); // also make a copy of the metadata to leave the OG intact.
            if (data.meta != null) data.meta.parsedColor = null;
        }

        data.fromMods = null;

        var sortedData:Dynamic = {};
        for(f in Reflect.fields(data)) {
            var v = Reflect.field(data, f);
            if (v != null)
                Reflect.setField(sortedData, f, v);
        }
        return sortedData;
    }
}

typedef ChartSaveSettings = {
    var ?overrideExistingMeta:Bool;
    var ?saveMetaInChart:Bool;
    var ?prettyPrint:Bool;
}