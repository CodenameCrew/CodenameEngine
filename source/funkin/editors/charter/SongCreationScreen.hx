package funkin.editors.charter;

import flixel.group.FlxGroup;
import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import funkin.backend.chart.ChartData;
import funkin.backend.chart.FNFLegacyParser.SwagSong;
import funkin.backend.chart.PsychParser;
import funkin.backend.chart.VSliceParser;
import funkin.backend.utils.ZipUtil;
import funkin.backend.utils.ZipUtil.ZipReader;
import funkin.game.HealthIcon;
import haxe.Json;
import haxe.io.Bytes;
import haxe.io.BytesInput;

typedef SongCreationData = {
	var meta:ChartMetaData;
	var instBytes:Bytes;
	var voicesBytes:Bytes;
	@:optional var playerVocals:Bytes;
	@:optional var oppVocals:Bytes;
}

class SongCreationScreen extends UISubstateWindow {
	private var onSave:Null<SongCreationData> -> Null<String -> SongCreationData -> Void> -> Void = null;

	public var songNameTextBox:UITextBox;
	public var bpmStepper:UINumericStepper;
	public var beatsPerMeasureStepper:UINumericStepper;
	public var denominatorStepper:UINumericStepper;
	public var instExplorer:UIFileExplorer;
	public var voicesExplorer:UIFileExplorer;
	public var importFrom:UIButton;

	public var displayNameTextBox:UITextBox;
	public var iconTextBox:UITextBox;
	public var iconSprite:HealthIcon;
	public var opponentModeCheckbox:UICheckbox;
	public var coopAllowedCheckbox:UICheckbox;
	public var colorWheel:UIColorwheel;
	public var difficultiesTextBox:UITextBox;

	public var engineDropdown:UIDropDown;
	public var createSong:UIButton;

	public var importInstExplorer:UIFileExplorer;
	public var importVoicesExplorer:UIFileExplorer;

	public var importIdTextBox:UITextBox;
	public var importChartFile:UIFileExplorer;
	public var importMetaFile:UIFileExplorer;

	public var backButton:UIButton;
	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public var songDataGroup:FlxGroup = new FlxGroup();
	public var menuDataGroup:FlxGroup = new FlxGroup();

	public var selectFormatGroup:FlxGroup = new FlxGroup();
	public var importAudioGroup:FlxGroup = new FlxGroup();
	public var importDataGroup:FlxGroup = new FlxGroup();

	public var pages:Array<FlxGroup> = [];
	public var pageSizes:Array<FlxPoint> = [];

	public var importPages:Array<FlxGroup> = [];
	public var importPageSizes:Array<FlxPoint> = [];

	public var isImporting = false;

	public var curPage:Int = 0;

	public function new(?onSave:SongCreationData -> Null<String -> SongCreationData -> Void> -> Void) {
		super();
		if (onSave != null) this.onSave = onSave;
	}

	inline function translate(id:String):String
		return TU.translate("songCreationScreen." + id);

	inline function translateMeta(id:String):String
		return TU.translate("charterMetaDataScreen." + id);

	public override function create() {
		winTitle = translate("win-title");

		winWidth = 748 - 32 + 40;
		winHeight = 520;

		super.create();

		function addLabelOn(ui:UISprite, text:String):UIText {
			var label:UIText = new UIText(ui.x, ui.y - 24, 0, text);
			ui.members.push(label);
			return label;
		}

		var songTitle:UIText;
		songDataGroup.add(songTitle = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, translate("title"), 28));

		songNameTextBox = new UITextBox(songTitle.x, songTitle.y + songTitle.height + 36, translateMeta("songName"));
		songDataGroup.add(songNameTextBox);
		addLabelOn(songNameTextBox, translateMeta("songName"));

		bpmStepper = new UINumericStepper(songNameTextBox.x + 320 + 26, songNameTextBox.y, 100, 1, 2, 1, null, 90);
		songDataGroup.add(bpmStepper);
		addLabelOn(bpmStepper, translateMeta("bpm"));

		beatsPerMeasureStepper = new UINumericStepper(bpmStepper.x + 60 + 26, bpmStepper.y, 4, 1, 0, 1, null, 54);
		songDataGroup.add(beatsPerMeasureStepper);
		addLabelOn(beatsPerMeasureStepper, translateMeta("timeSignature"));

		songDataGroup.add(new UIText(beatsPerMeasureStepper.x + 30, beatsPerMeasureStepper.y + 3, 0, "/", 22));

		denominatorStepper = new UINumericStepper(beatsPerMeasureStepper.x + 30 + 24, beatsPerMeasureStepper.y, 4, 1, 0, 1, null, 54);
		songDataGroup.add(denominatorStepper);

		instExplorer = new UIFileExplorer(songNameTextBox.x, songNameTextBox.y + 32 + 36, null, null, Flags.SOUND_EXT, function (path, res) {
			if (path == null || res == null) return;
			var audioPlayer:UIAudioPlayer = new UIAudioPlayer(instExplorer.x + 8, instExplorer.y + 8, res);
			instExplorer.members.push(audioPlayer);
			instExplorer.uiElement = audioPlayer;
		});
		songDataGroup.add(instExplorer);
		addLabelOn(instExplorer, "").applyMarkup(
			translate("instAudio"),
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);

		voicesExplorer = new UIFileExplorer(instExplorer.x + 320 + 26, instExplorer.y, null, null, Flags.SOUND_EXT, function (path, res) {
			if (path == null || res == null) return;
			var audioPlayer:UIAudioPlayer = new UIAudioPlayer(voicesExplorer.x + 8, voicesExplorer.y + 8, res);
			voicesExplorer.members.push(audioPlayer);
			voicesExplorer.uiElement = audioPlayer;
		});
		songDataGroup.add(voicesExplorer);

		/*voicesUIText = addLabelOn(voicesExplorer, "");
		voicesUIText.applyMarkup(
			translate("voicesAudio"),
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);*/

		addLabelOn(voicesExplorer, translate("voicesAudio"));

		importFrom = new UIButton(windowSpr.x + 20, windowSpr.y + windowSpr.bHeight - 16 - 32, translate("importFrom"), function() {
			winTitle = translate("win-title-importing");
			isImporting = true;
			updatePagesTexts();
			refreshPages();
		}, 150);
		songDataGroup.add(importFrom);

		var menuTitle:UIText;
		menuDataGroup.add(menuTitle = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, translateMeta("menusData"), 28));

		displayNameTextBox = new UITextBox(menuTitle.x, menuTitle.y + menuTitle.height + 36, translateMeta("displayName"));
		menuDataGroup.add(displayNameTextBox);
		addLabelOn(displayNameTextBox, translateMeta("displayName"));

		iconTextBox = new UITextBox(displayNameTextBox.x + 320 + 26, displayNameTextBox.y, "face", 150);
		iconTextBox.onChange = (newIcon:String) -> {updateIcon(newIcon);}
		menuDataGroup.add(iconTextBox);
		addLabelOn(iconTextBox, translateMeta("icon"));

		updateIcon("face");

		opponentModeCheckbox = new UICheckbox(displayNameTextBox.x, iconTextBox.y + 10 + 32 + 26, translateMeta("opponentMode"), true);
		menuDataGroup.add(opponentModeCheckbox);
		addLabelOn(opponentModeCheckbox, translateMeta("modesAllowed"));

		coopAllowedCheckbox = new UICheckbox(opponentModeCheckbox.x + 150 + 26, opponentModeCheckbox.y, translateMeta("coopAllowed"), true);
		menuDataGroup.add(coopAllowedCheckbox);

		colorWheel = new UIColorwheel(iconTextBox.x, coopAllowedCheckbox.y, 0xFFFFFF);
		menuDataGroup.add(colorWheel);
		addLabelOn(colorWheel, translateMeta("color"));

		difficultiesTextBox = new UITextBox(opponentModeCheckbox.x, opponentModeCheckbox.y + 6 + 32 + 26, "");
		menuDataGroup.add(difficultiesTextBox);
		addLabelOn(difficultiesTextBox, translateMeta("difficulties"));

		for (checkbox in [opponentModeCheckbox, coopAllowedCheckbox])
			{checkbox.y += 6; checkbox.x += 4;}

		var menuTitle:UIText;
		selectFormatGroup.add(menuTitle = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, translate("importSource"), 28));

		engineDropdown = new UIDropDown(menuTitle.x, menuTitle.y + menuTitle.height + 36, 480, 32, [translate("legacyOrPsych"), translate("vslice"), translate("vsliceProject")]);
		selectFormatGroup.add(engineDropdown);
		addLabelOn(engineDropdown, translate("importChartFormat"));

		createSong = new UIButton(windowSpr.x + 20, windowSpr.y + windowSpr.bHeight - 16 - 32, "< " + translate("back"), function() {
			winTitle = translate("win-title");
			isImporting = false;
			updatePagesTexts();
			refreshPages();
		}, 120);
		selectFormatGroup.add(createSong);

		var menuTitle:UIText;
		importAudioGroup.add(menuTitle = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, translate("importAudios"), 28));

		importInstExplorer = new UIFileExplorer(menuTitle.x, menuTitle.y + menuTitle.height + 36, null, null, Flags.SOUND_EXT, function (path, res) {
			if (path == null || res == null) return;
			var audioPlayer:UIAudioPlayer = new UIAudioPlayer(importInstExplorer.x + 8, importInstExplorer.y + 8, res);
			importInstExplorer.members.push(audioPlayer);
			importInstExplorer.uiElement = audioPlayer;
		});
		importAudioGroup.add(importInstExplorer);
		addLabelOn(importInstExplorer, "").applyMarkup(
			translate("instAudio"),
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);

		importVoicesExplorer = new UIFileExplorer(importInstExplorer.x + 320 + 26, importInstExplorer.y, null, null, Flags.SOUND_EXT, function (path, res) {
			if (path == null || res == null) return;
			var audioPlayer:UIAudioPlayer = new UIAudioPlayer(importVoicesExplorer.x + 8, importVoicesExplorer.y + 8, res);
			importVoicesExplorer.members.push(audioPlayer);
			importVoicesExplorer.uiElement = audioPlayer;
		});
		importAudioGroup.add(importVoicesExplorer);
		addLabelOn(importVoicesExplorer, translate("voicesAudio"));

		var menuTitle:UIText;
		importDataGroup.add(menuTitle = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, "Add Data", 28));

		importDataGroup.add(importIdTextBox = new UITextBox(menuTitle.x, menuTitle.y + menuTitle.height + 36));
		addLabelOn(importIdTextBox, "").applyMarkup(
			translate("songFileName"),
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);

		importChartFile = new UIFileExplorer(importIdTextBox.x, importIdTextBox.y + importIdTextBox.height + 56, null, null, "fnfc", function (_, _) importIdTextBox.label.text = new haxe.io.Path(importChartFile.filePath).file);
		importDataGroup.add(importChartFile);
		addLabelOn(importChartFile, "").applyMarkup(
			translate("songDataFile"),
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);

		importMetaFile = new UIFileExplorer(importChartFile.x + 320 + 26, importChartFile.y, null, null, "json");
		importDataGroup.add(importMetaFile);
		addLabelOn(importMetaFile, "").applyMarkup(
			translate("songMetaFile"),
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, TU.translate("editor.saveClose"), function() {
			var pages = isImporting ? importPages : pages;
			if (curPage == pages.length-1) {
				saveSongInfo();
				close();
			} else {
				curPage++;
				refreshPages();
			}

			updatePagesTexts();
		}, 125);
		add(saveButton);

		backButton = new UIButton(saveButton.x - 20 - saveButton.bWidth, saveButton.y, "< " + translate("back"), function() {
			curPage--;
			refreshPages();

			updatePagesTexts();
		}, 125);
		add(backButton);

		closeButton = new UIButton(backButton.x - 20 - saveButton.bWidth, saveButton.y, TU.translate("editor.close"), function() {
			close();
		}, 125);
		add(closeButton);
		closeButton.color = 0xFFFF0000;

		pages.push(cast add(songDataGroup));
		pageSizes.push(FlxPoint.get(748 - 32 + 40, 340));

		pages.push(cast add(menuDataGroup));
		pageSizes.push(FlxPoint.get(748 - 32 + 40, 400));

		importPages.push(cast add(selectFormatGroup));
		importPageSizes.push(FlxPoint.get(500, 250));

		importPages.push(cast add(importAudioGroup));
		importPageSizes.push(FlxPoint.get(705, 250));

		importPages.push(cast add(importDataGroup));
		importPageSizes.push(FlxPoint.get(705, 300));

		refreshPages();
		updatePagesTexts();
	}

	public override function update(elapsed:Float) {
		if (isImporting)
		{
			var name = engineDropdown.options[engineDropdown.index];
			var project = name == translate("vsliceProject");

			if (curPage == 1) {
				importInstExplorer.selectable = importVoicesExplorer.selectable = !project;
				saveButton.selectable = project ? true : (importInstExplorer.file != null);
			} else if (curPage == 2) {
				importIdTextBox.selectable = !project;
				importChartFile.fileType = project ? "fnfc" : "json";
				importMetaFile.selectable = name == translate("vslice");
				saveButton.selectable = importChartFile.file != null && (!importMetaFile.selectable || importMetaFile.file != null) && (!importIdTextBox.selectable || importIdTextBox.label.text.trim().length > 0);
			} else
				saveButton.selectable = true;
		} else {
			if (curPage == 0)
				saveButton.selectable = (instExplorer.file != null);
			else
				saveButton.selectable = true;
		}

		saveButton.alpha = saveButton.field.alpha = saveButton.selectable ? 1 : 0.4;
		super.update(elapsed);
	}

	function refreshPages() {
		for (i=>page in pages)
			page.visible = page.exists = i == curPage && !isImporting;

		for (i=>page in importPages)
			page.visible = page.exists = i == curPage && isImporting;
	}

	function updatePagesTexts() {
		var pageSizes = isImporting ? importPageSizes : pageSizes;
		var pages = isImporting ? importPages : pages;
		windowSpr.bWidth = Std.int(pageSizes[curPage].x);
		windowSpr.bHeight = Std.int(pageSizes[curPage].y);

		titleSpr.x = windowSpr.x + 25;
		titleSpr.y = windowSpr.y + ((30 - titleSpr.height) / 2);

		saveButton.field.text = curPage == pages.length-1 ? TU.translate("editor.saveClose") : translate("next") + ' >';
		titleSpr.text = '$winTitle (${curPage+1}/${pages.length})';

		backButton.field.text = '< ' + translate("back");
		backButton.visible = backButton.exists = curPage > 0;

		backButton.x = (saveButton.x = windowSpr.x + windowSpr.bWidth - 20 - 125) - 20 - saveButton.bWidth;
		closeButton.x = (curPage > 0 ? backButton : saveButton).x - 20 - saveButton.bWidth;

		for (button in [saveButton, backButton, closeButton, importFrom, createSong])
			button.y = windowSpr.y + windowSpr.bHeight - 16 - 32;
	}

	function updateIcon(icon:String) {
		if (iconSprite == null) menuDataGroup.add(iconSprite = new HealthIcon());

		iconSprite.setIcon(icon);
		var size = Std.int(150 * 0.5);
		iconSprite.setUnstretchedGraphicSize(size, size, true);
		iconSprite.updateHitbox();
		iconSprite.setPosition(iconTextBox.x + iconTextBox.bWidth + 8, iconTextBox.y + (iconTextBox.bHeight / 2) - (iconSprite.height / 2));
		iconSprite.scrollFactor.set(1, 1);
	}

	function saveSongInfo() {
		if (isImporting)
		{
			try switch(engineDropdown.index)
			{
				case 2 /*"V-Slice Project (.fnfc)"*/:
					var files:Map<String, Any> = [];
					for (field in new ZipReader(new BytesInput(importChartFile.file)).read()) {
						var fileName = field.fileName;
						var fileContent = ZipUtil.unzip(field);
						files.set(fileName, fileContent);
					}
					saveFromVSlice(files);
				case 1 /*"V-Slice"*/:
					var songId = importIdTextBox.label.text;
					var files:Map<String, Any> = [];
					files.set('${songId}-metadata.json', importMetaFile.file);
					files.set('${songId}-chart.json', importChartFile.file);
					files.set('Inst.${Flags.SOUND_EXT}', importInstExplorer.file);
					files.set('Voices.${Flags.SOUND_EXT}', importVoicesExplorer.file);
					saveFromVSlice(files, songId);
				default /*"Psych/Legacy FNF"*/:
					var songId = importIdTextBox.label.text;
					var oldChart:SwagSong = Json.parse(cast importChartFile.file);
					var base:ChartData = {
						strumLines: [],
						noteTypes: [],
						events: [],
						meta: {name: null},
						scrollSpeed: Flags.DEFAULT_SCROLL_SPEED,
						stage: Flags.DEFAULT_STAGE,
						codenameChart: true
					};
					PsychParser.parse(oldChart, base);
					if (onSave != null) onSave({
						meta: {
							name: songId,
							difficulties: [songId],
							bpm: oldChart.bpm,
							beatsPerMeasure: oldChart.beatsPerMeasure,
							stepsPerBeat: oldChart.stepsPerBeat,
							displayName: oldChart.song
						},
						instBytes: importInstExplorer.file,
						voicesBytes: importVoicesExplorer.file,
					}, (songFolder:String, creation:SongCreationData) -> {
						#if sys
						CoolUtil.safeSaveFile('$songFolder/charts/${songId}.json', Json.stringify(base, Flags.JSON_PRETTY_PRINT));
						#end
					});
			} catch (e:haxe.Exception) {
				openSubState(new UIWarningSubstate("Importing Song/Charts: Error!", e.details(), [
					{label: "Ok", color: 0xFFFF0000, onClick: function(t) {}}
				]));
			}
		} else {
			for (stepper in [bpmStepper, beatsPerMeasureStepper, denominatorStepper])
				@:privateAccess stepper.__onChange(stepper.label.text);

			var meta:ChartMetaData = {
				name: songNameTextBox.label.text,
				bpm: bpmStepper.value,
				beatsPerMeasure: Std.int(beatsPerMeasureStepper.value),
				stepsPerBeat: Std.int(16 / denominatorStepper.value),
				displayName: displayNameTextBox.label.text,
				icon: iconTextBox.label.text,
				color: colorWheel.curColor,
				opponentModeAllowed: opponentModeCheckbox.checked,
				coopAllowed: coopAllowedCheckbox.checked,
				difficulties: [for (diff in difficultiesTextBox.label.text.split(",")) diff.trim()],
			};

			if (onSave != null) onSave({
				meta: meta,
				instBytes: instExplorer.file,
				voicesBytes: voicesExplorer.file
			}, null);
		}
	}

	function saveFromVSlice(files:Map<String, Any>, ?name:String) {
		var songId = name == null && files.exists("manifest.json") ? Json.parse(files.get("manifest.json")).songId : name;
		var vslicemeta:SwagMetadata = Json.parse(files.get('${songId}-metadata.json'));
		var vslicechart:NewSwagSong = Json.parse(files.get('${songId}-chart.json'));
		var playData = vslicemeta.playData;

		var meta:ChartMetaData = {name: songId};
		var diffCharts:Array<ChartDataWithInfo> = [];
		VSliceParser.parse(vslicemeta, vslicechart, meta, diffCharts, songId);

		if (onSave != null) onSave({
			meta: meta,
			instBytes: files.get('Inst.${Flags.SOUND_EXT}'),
			voicesBytes: files.get('Voices.${Flags.SOUND_EXT}'), //it may exist
			playerVocals: files.get('Voices-${playData.characters.playerVocals != null ? playData.characters.playerVocals[0] : playData.characters.player}.${Flags.SOUND_EXT}'),
			oppVocals: files.get('Voices-${playData.characters.opponentVocals != null ? playData.characters.opponentVocals[0] : playData.characters.opponent}.${Flags.SOUND_EXT}'),
		}, (songFolder:String, creation:SongCreationData) -> {
			#if sys
			for (diff in diffCharts) CoolUtil.safeSaveFile('$songFolder/charts/${diff.diffName}.json', Json.stringify(diff.chart, Flags.JSON_PRETTY_PRINT));
			#end
		});
	}
}