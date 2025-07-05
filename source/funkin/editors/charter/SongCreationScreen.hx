package funkin.editors.charter;

import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import flixel.group.FlxGroup;
import funkin.backend.chart.ChartData.ChartMetaData;
import haxe.io.Bytes;
import funkin.game.HealthIcon;

typedef SongCreationData = {
	var meta:ChartMetaData;
	var instBytes:Bytes;
	var voicesBytes:Bytes;
}

class SongCreationScreen extends UISubstateWindow {
	private var onSave:Null<SongCreationData> -> Void = null;

	public var songNameTextBox:UITextBox;
	public var bpmStepper:UINumericStepper;
	public var beatsPerMeasureStepper:UINumericStepper;
	public var stepsPerBeatStepper :UINumericStepper;
	public var needsVoicesCheckbox:UICheckbox;
	public var instExplorer:UIFileExplorer;
	public var voicesExplorer:UIFileExplorer;

	public var displayNameTextBox:UITextBox;
	public var iconTextBox:UITextBox;
	public var iconSprite:HealthIcon;
	public var opponentModeCheckbox:UICheckbox;
	public var coopAllowedCheckbox:UICheckbox;
	public var colorWheel:UIColorwheel;
	public var difficulitesTextBox:UITextBox;

	public var backButton:UIButton;
	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public var songDataGroup:FlxGroup = new FlxGroup();
	public var menuDataGroup:FlxGroup = new FlxGroup();

	public var pages:Array<FlxGroup> = [];
	public var pageSizes:Array<FlxPoint> = [];
	public var curPage:Int = 0;

	public function new(?onSave:SongCreationData->Void) {
		super();
		if (onSave != null) this.onSave = onSave;
	}

	public override function create() {
		winTitle = "Creating New Song";

		winWidth = 748 - 32 + 40;
		winHeight = 520;

		super.create();

		function addLabelOn(ui:UISprite, text:String):UIText {
			var text:UIText = new UIText(ui.x, ui.y - 24, 0, text);
			ui.members.push(text);
			return text;
		}

		var songTitle:UIText;
		songDataGroup.add(songTitle = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, "Song Info", 28));

		songNameTextBox = new UITextBox(songTitle.x, songTitle.y + songTitle.height + 36, "Song Name");
		songDataGroup.add(songNameTextBox);
		addLabelOn(songNameTextBox, "Song Name");

		bpmStepper = new UINumericStepper(songNameTextBox.x + 320 + 26, songNameTextBox.y, 100, 1, 2, 1, null, 90);
		songDataGroup.add(bpmStepper);
		addLabelOn(bpmStepper, "BPM");

		beatsPerMeasureStepper = new UINumericStepper(bpmStepper.x + 60 + 26, bpmStepper.y, 4, 1, 0, 1, null, 54);
		songDataGroup.add(beatsPerMeasureStepper);
		addLabelOn(beatsPerMeasureStepper, "Time Signature");

		songDataGroup.add(new UIText(beatsPerMeasureStepper.x + 30, beatsPerMeasureStepper.y + 3, 0, "/", 22));

		stepsPerBeatStepper = new UINumericStepper(beatsPerMeasureStepper.x + 30 + 24, beatsPerMeasureStepper.y, 4, 1, 0, 1, null, 54);
		songDataGroup.add(stepsPerBeatStepper);

		var voicesUIText:UIText = null;

		needsVoicesCheckbox = new UICheckbox(stepsPerBeatStepper.x + 80 + 26, stepsPerBeatStepper.y, "Voices", true);
		needsVoicesCheckbox.onChecked = function(checked) {
			if (voicesExplorer == null) return;

			if(!checked) {
				voicesExplorer.removeFile();
				voicesExplorer.selectable = voicesExplorer.uploadButton.selectable = false;
				voicesUIText.text = "Vocal Audio File";
			} else {
				voicesExplorer.selectable = voicesExplorer.uploadButton.selectable = true;
				voicesUIText.applyMarkup(
					"Vocal Audio File $* Required$",
					[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);
			}
		}
		songDataGroup.add(needsVoicesCheckbox);
		addLabelOn(needsVoicesCheckbox, "Needs Voices");
		needsVoicesCheckbox.y += 6; needsVoicesCheckbox.x += 4;

		instExplorer = new UIFileExplorer(songNameTextBox.x, songNameTextBox.y + 32 + 36, null, null, Paths.SOUND_EXT, function (res) {
			var audioPlayer:UIAudioPlayer = new UIAudioPlayer(instExplorer.x + 8, instExplorer.y + 8, res);
			instExplorer.members.push(audioPlayer);
			instExplorer.uiElement = audioPlayer;
		});
		songDataGroup.add(instExplorer);
		addLabelOn(instExplorer, "Inst Audio File").applyMarkup(
			"Inst Audio File $* Required$",
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);

		voicesExplorer = new UIFileExplorer(instExplorer.x + 320 + 26, instExplorer.y, null, null, Paths.SOUND_EXT, function (res) {
			var audioPlayer:UIAudioPlayer = new UIAudioPlayer(voicesExplorer.x + 8, voicesExplorer.y + 8, res);
			voicesExplorer.members.push(audioPlayer);
			voicesExplorer.uiElement = audioPlayer;
		});
		songDataGroup.add(voicesExplorer);

		voicesUIText = addLabelOn(voicesExplorer, "Vocal Audio File");
		voicesUIText.applyMarkup(
			"Vocal Audio File $* Required$",
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);

		var menuTitle:UIText;
		menuDataGroup.add(menuTitle = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, "Menus Data (Freeplay/Story)", 28));

		displayNameTextBox = new UITextBox(menuTitle.x, menuTitle.y + menuTitle.height + 36, "Display Name");
		menuDataGroup.add(displayNameTextBox);
		addLabelOn(displayNameTextBox, "Display Name");

		iconTextBox = new UITextBox(displayNameTextBox.x + 320 + 26, displayNameTextBox.y, "Icon", 150);
		iconTextBox.onChange = (newIcon:String) -> {updateIcon(newIcon);}
		menuDataGroup.add(iconTextBox);
		addLabelOn(iconTextBox, "Icon");

		updateIcon("Icon");

		opponentModeCheckbox = new UICheckbox(displayNameTextBox.x, iconTextBox.y + 10 + 32 + 26, "Opponent Mode", true);
		menuDataGroup.add(opponentModeCheckbox);
		addLabelOn(opponentModeCheckbox, "Modes Allowed");

		coopAllowedCheckbox = new UICheckbox(opponentModeCheckbox.x + 150 + 26, opponentModeCheckbox.y, "Co-op Mode", true);
		menuDataGroup.add(coopAllowedCheckbox);

		colorWheel = new UIColorwheel(iconTextBox.x, coopAllowedCheckbox.y, 0xFFFFFF);
		menuDataGroup.add(colorWheel);
		addLabelOn(colorWheel, "Color");

		difficulitesTextBox = new UITextBox(opponentModeCheckbox.x, opponentModeCheckbox.y + 6 + 32 + 26, "");
		menuDataGroup.add(difficulitesTextBox);
		addLabelOn(difficulitesTextBox, "Difficulties");

		for (checkbox in [opponentModeCheckbox, coopAllowedCheckbox])
			{checkbox.y += 6; checkbox.x += 4;}

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, "Save & Close", function() {
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

		backButton = new UIButton(saveButton.x - 20 - saveButton.bWidth, saveButton.y, "< Back", function() {
			curPage--;
			refreshPages();

			updatePagesTexts();
		}, 125);
		add(backButton);

		closeButton = new UIButton(backButton.x - 20 - saveButton.bWidth, saveButton.y, "Cancel", function() {
			close();
		}, 125);
		add(closeButton);
		closeButton.color = 0xFFFF0000;

		pages.push(cast add(songDataGroup));
		pageSizes.push(FlxPoint.get(748 - 32 + 40, 340));

		pages.push(cast add(menuDataGroup));
		pageSizes.push(FlxPoint.get(748 - 32 + 40, 400));

		refreshPages();
		updatePagesTexts();
	}

	public override function update(elapsed:Float) {
		if (curPage == 0) {
			if (instExplorer.file != null && (needsVoicesCheckbox.checked ? voicesExplorer.file != null : true))
				saveButton.selectable = true;
			else saveButton.selectable = false;
		} else
			saveButton.selectable = true;

		saveButton.alpha = saveButton.field.alpha = saveButton.selectable ? 1 : 0.4;
		super.update(elapsed);
	}

	function refreshPages() {
		for (i=>page in pages)
			page.visible = page.exists = i == curPage;
	}

	function updatePagesTexts() {
		windowSpr.bWidth = Std.int(pageSizes[curPage].x);
		windowSpr.bHeight = Std.int(pageSizes[curPage].y);

		titleSpr.x = windowSpr.x + 25;
		titleSpr.y = windowSpr.y + ((30 - titleSpr.height) / 2);

		saveButton.field.text = curPage == pages.length-1 ? "Save & Close" : 'Next >';
		titleSpr.text = 'Creating New Song (${curPage+1}/${pages.length})';

		backButton.field.text = '< Back';
		backButton.visible = backButton.exists = curPage > 0;

		backButton.x = (saveButton.x = windowSpr.x + windowSpr.bWidth - 20 - 125) - 20 - saveButton.bWidth;
		closeButton.x = (curPage > 0 ? backButton : saveButton).x - 20 - saveButton.bWidth;

		for (button in [saveButton, backButton, closeButton])
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
		for (stepper in [bpmStepper, beatsPerMeasureStepper, stepsPerBeatStepper])
			@:privateAccess stepper.__onChange(stepper.label.text);

		var meta:ChartMetaData = {
			name: songNameTextBox.label.text,
			bpm: bpmStepper.value,
			beatsPerMeasure: Std.int(beatsPerMeasureStepper.value),
			stepsPerBeat: Std.int(stepsPerBeatStepper.value),
			needsVoices: needsVoicesCheckbox.checked,
			displayName: displayNameTextBox.label.text,
			icon: iconTextBox.label.text,
			color: colorWheel.curColor,
			opponentModeAllowed: opponentModeCheckbox.checked,
			coopAllowed: coopAllowedCheckbox.checked,
			difficulties: [for (diff in difficulitesTextBox.label.text.split(",")) diff.trim()],
		};

		if (onSave != null) onSave({
			meta: meta,
			instBytes: instExplorer.file,
			voicesBytes: voicesExplorer.file
		});
	}

}