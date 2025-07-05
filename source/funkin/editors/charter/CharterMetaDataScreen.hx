package funkin.editors.charter;

import flixel.math.FlxPoint;
import funkin.backend.chart.ChartData.ChartMetaData;
import funkin.editors.extra.PropertyButton;
import funkin.game.HealthIcon;

using StringTools;

class CharterMetaDataScreen extends UISubstateWindow {
	public var metadata:ChartMetaData;
	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public var songNameTextBox:UITextBox;
	public var bpmStepper:UINumericStepper;
	public var beatsPerMeasureStepper:UINumericStepper;
	public var stepsPerBeatStepper :UINumericStepper;
	public var needsVoicesCheckbox:UICheckbox;
	public var customPropertiesButtonList:UIButtonList<PropertyButton>;

	public var displayNameTextBox:UITextBox;
	public var iconTextBox:UITextBox;
	public var iconSprite:HealthIcon;
	public var opponentModeCheckbox:UICheckbox;
	public var coopAllowedCheckbox:UICheckbox;
	public var colorWheel:UIColorwheel;
	public var difficulitesTextBox:UITextBox;

	public function new(metadata:ChartMetaData) {
		super();
		this.metadata = metadata;
	}

	public override function create() {
		winTitle = "Edit Metadata";
		winWidth = 1056;
		winHeight = 520;

		super.create();

		FlxG.sound.music.pause();
		Charter.instance.vocals.pause();
		for (strumLine in Charter.instance.strumLines.members) strumLine.vocals.pause();

		function addLabelOn(ui:UISprite, text:String)
			add(new UIText(ui.x, ui.y - 24, 0, text));

		var title:UIText;
		add(title = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, "Song Data", 28));

		songNameTextBox = new UITextBox(title.x, title.y + title.height + 36, metadata.name);
		add(songNameTextBox);
		addLabelOn(songNameTextBox, "Song Name");

		bpmStepper = new UINumericStepper(songNameTextBox.x + 320 + 26, songNameTextBox.y, metadata.bpm, 1, 2, 1, null, 90);
		add(bpmStepper);
		addLabelOn(bpmStepper, "BPM");

		beatsPerMeasureStepper = new UINumericStepper(bpmStepper.x + 60 + 26, bpmStepper.y, metadata.beatsPerMeasure, 1, 0, 1, null, 54);
		add(beatsPerMeasureStepper);
		addLabelOn(beatsPerMeasureStepper, "Time Signature");

		add(new UIText(beatsPerMeasureStepper.x + 30, beatsPerMeasureStepper.y + 3, 0, "/", 22));

		stepsPerBeatStepper = new UINumericStepper(beatsPerMeasureStepper.x + 30 + 24, beatsPerMeasureStepper.y, metadata.stepsPerBeat, 1, 0, 1, null, 54);
		add(stepsPerBeatStepper);

		needsVoicesCheckbox = new UICheckbox(stepsPerBeatStepper.x + 80 + 26, stepsPerBeatStepper.y, "Voices", metadata.needsVoices);
		add(needsVoicesCheckbox);
		addLabelOn(needsVoicesCheckbox, "Needs Voices");
		needsVoicesCheckbox.y += 6; needsVoicesCheckbox.x += 4;

		add(title = new UIText(songNameTextBox.x, songNameTextBox.y + 10 + 46, 0, "Menus Data (Freeplay/Story)", 28));

		displayNameTextBox = new UITextBox(title.x, title.y + title.height + 36, metadata.displayName);
		add(displayNameTextBox);
		addLabelOn(displayNameTextBox, "Display Name");

		iconTextBox = new UITextBox(displayNameTextBox.x + 320 + 26, displayNameTextBox.y, metadata.icon, 150);
		iconTextBox.onChange = (newIcon:String) -> {updateIcon(newIcon);}
		add(iconTextBox);
		addLabelOn(iconTextBox, "Icon");

		updateIcon(metadata.icon);

		opponentModeCheckbox = new UICheckbox(displayNameTextBox.x, iconTextBox.y + 10 + 32 + 26, "Opponent Mode", metadata.opponentModeAllowed);
		add(opponentModeCheckbox);
		addLabelOn(opponentModeCheckbox, "Modes Allowed");

		coopAllowedCheckbox = new UICheckbox(opponentModeCheckbox.x + 150 + 26, opponentModeCheckbox.y, "Co-op Mode", metadata.coopAllowed);
		add(coopAllowedCheckbox);

		colorWheel = new UIColorwheel(iconTextBox.x, coopAllowedCheckbox.y, metadata.color);
		add(colorWheel);
		addLabelOn(colorWheel, "Color");

		difficulitesTextBox = new UITextBox(opponentModeCheckbox.x, opponentModeCheckbox.y + 6 + 32 + 26, metadata.difficulties.join(", "));
		add(difficulitesTextBox);
		addLabelOn(difficulitesTextBox, "Difficulties");

		customPropertiesButtonList = new UIButtonList<PropertyButton>(needsVoicesCheckbox.x + needsVoicesCheckbox.width + 105, songNameTextBox.y, 290, 316, '', FlxPoint.get(280, 35), null, 5);
		customPropertiesButtonList.frames = Paths.getFrames('editors/ui/inputbox');
		customPropertiesButtonList.cameraSpacing = 0;
		customPropertiesButtonList.addButton.callback = function() {
			customPropertiesButtonList.add(new PropertyButton("newProperty", "valueHere", customPropertiesButtonList));
		}
		for (val in Reflect.fields(metadata.customValues))
			customPropertiesButtonList.add(new PropertyButton(val, Reflect.field(metadata.customValues, val), customPropertiesButtonList));
		add(customPropertiesButtonList);
		addLabelOn(customPropertiesButtonList, "Custom Values (Advanced)");

		for (checkbox in [opponentModeCheckbox, coopAllowedCheckbox])
			{checkbox.y += 6; checkbox.x += 4;}

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight - 20, "Save & Close", function() {
			saveMeta();
			close();
		}, 125);
		saveButton.x -= saveButton.bWidth;
		saveButton.y -= saveButton.bHeight;

		closeButton = new UIButton(saveButton.x - 20, saveButton.y, "Close", function() {
			close();
		}, 125);
		closeButton.color = 0xFFFF0000;
		closeButton.x -= closeButton.bWidth;
		//closeButton.y -= closeButton.bHeight;
		add(closeButton);
		add(saveButton);
	}

	function updateIcon(icon:String) {
		if (iconSprite == null) add(iconSprite = new HealthIcon());

		iconSprite.setIcon(icon);
		var size = Std.int(150 * 0.5);
		iconSprite.setUnstretchedGraphicSize(size, size, true);
		iconSprite.updateHitbox();
		iconSprite.setPosition(iconTextBox.x + iconTextBox.bWidth + 8, iconTextBox.y + (iconTextBox.bHeight / 2) - (iconSprite.height / 2));
		iconSprite.scrollFactor.set(1, 1);
	}

	public function saveMeta() {
		for (stepper in [bpmStepper, beatsPerMeasureStepper, stepsPerBeatStepper])
			@:privateAccess stepper.__onChange(stepper.label.text);

		var customVals = {};
		for (vals in customPropertiesButtonList.buttons.members) {
			Reflect.setProperty(customVals, vals.propertyText.label.text, vals.valueText.label.text);
		}

		PlayState.SONG.meta = {
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
			customValues: customVals,
		};

		Charter.instance.updateBPMEvents();
	}
}