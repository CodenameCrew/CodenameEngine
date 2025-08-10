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
	public var denominatorStepper:UINumericStepper;
	public var customPropertiesButtonList:UIButtonList<PropertyButton>;

	public var displayNameTextBox:UITextBox;
	public var iconTextBox:UITextBox;
	public var iconSprite:HealthIcon;
	public var opponentModeCheckbox:UICheckbox;
	public var coopAllowedCheckbox:UICheckbox;
	public var needsVoicesCheckbox:UICheckbox;
	public var colorWheel:UIColorwheel;
	public var difficultiesTextBox:UITextBox;

	public function new(metadata:ChartMetaData) {
		super();
		this.metadata = metadata;
	}

	inline function translate(id:String):String
		return TU.translate("charterMetaDataScreen." + id);

	public override function create() {
		winTitle = translate("title");
		winWidth = 1056;
		winHeight = 520;

		super.create();

		FlxG.sound.music.pause();
		Charter.instance.vocals.pause();
		for (strumLine in Charter.instance.strumLines.members) strumLine.vocals.pause();

		function addLabelOn(ui:UISprite, text:String)
			add(new UIText(ui.x, ui.y - 24, 0, text));

		var title:UIText;
		add(title = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, translate("songData"), 28));

		songNameTextBox = new UITextBox(title.x, title.y + title.height + 36, metadata.name);
		add(songNameTextBox);
		addLabelOn(songNameTextBox, translate("songName"));

		bpmStepper = new UINumericStepper(songNameTextBox.x + 320 + 26, songNameTextBox.y, metadata.bpm, 1, 2, 1, null, 90);
		add(bpmStepper);
		addLabelOn(bpmStepper, translate("bpm"));

		beatsPerMeasureStepper = new UINumericStepper(bpmStepper.x + 60 + 26, bpmStepper.y, metadata.beatsPerMeasure, 1, 0, 1, null, 54);
		add(beatsPerMeasureStepper);
		addLabelOn(beatsPerMeasureStepper, translate("timeSignature"));

		add(new UIText(beatsPerMeasureStepper.x + 30, beatsPerMeasureStepper.y + 3, 0, "/", 22));

		denominatorStepper = new UINumericStepper(beatsPerMeasureStepper.x + 30 + 24, beatsPerMeasureStepper.y, Math.floor(16 / metadata.stepsPerBeat), 1, 0, 1, null, 54);
		add(denominatorStepper);

		needsVoicesCheckbox = new UICheckbox(beatsPerMeasureStepper.x + 100, beatsPerMeasureStepper.y + 6, translate("needsVoices"), metadata.needsVoices);
		add(needsVoicesCheckbox);

		add(title = new UIText(songNameTextBox.x, songNameTextBox.y + 10 + 46, 0, translate("menusData"), 28));

		displayNameTextBox = new UITextBox(title.x, title.y + title.height + 36, metadata.displayName);
		add(displayNameTextBox);
		addLabelOn(displayNameTextBox, translate("displayName"));

		iconTextBox = new UITextBox(displayNameTextBox.x + 320 + 26, displayNameTextBox.y, metadata.icon, 150);
		iconTextBox.onChange = (newIcon:String) -> {updateIcon(newIcon);}
		add(iconTextBox);
		addLabelOn(iconTextBox, translate("icon"));

		updateIcon(metadata.icon);

		opponentModeCheckbox = new UICheckbox(displayNameTextBox.x, iconTextBox.y + 10 + 32 + 26, translate("opponentMode"), metadata.opponentModeAllowed);
		add(opponentModeCheckbox);
		addLabelOn(opponentModeCheckbox, translate("modesAllowed"));

		coopAllowedCheckbox = new UICheckbox(opponentModeCheckbox.x + 150 + 26, opponentModeCheckbox.y, translate("coopAllowed"), metadata.coopAllowed);
		add(coopAllowedCheckbox);

		colorWheel = new UIColorwheel(iconTextBox.x, coopAllowedCheckbox.y, metadata.color);
		add(colorWheel);
		addLabelOn(colorWheel, translate("color"));

		difficultiesTextBox = new UITextBox(opponentModeCheckbox.x, opponentModeCheckbox.y + 6 + 32 + 26, metadata.difficulties.join(", "));
		add(difficultiesTextBox);
		addLabelOn(difficultiesTextBox, translate("difficulties"));

		customPropertiesButtonList = new UIButtonList<PropertyButton>(denominatorStepper.x + 80 + 26 + 105, songNameTextBox.y, 290, 316, '', FlxPoint.get(280, 35), null, 5);
		customPropertiesButtonList.frames = Paths.getFrames('editors/ui/inputbox');
		customPropertiesButtonList.cameraSpacing = 0;
		customPropertiesButtonList.addButton.callback = function() {
			customPropertiesButtonList.add(new PropertyButton("newProperty", "valueHere", customPropertiesButtonList));
		}
		for (val in Reflect.fields(metadata.customValues))
			customPropertiesButtonList.add(new PropertyButton(val, Reflect.field(metadata.customValues, val), customPropertiesButtonList));
		add(customPropertiesButtonList);
		addLabelOn(customPropertiesButtonList, translate("customValues"));

		for (checkbox in [opponentModeCheckbox, coopAllowedCheckbox])
			{checkbox.y += 6; checkbox.x += 4;}

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight - 20, TU.translate("editor.saveClose"), function() {
			saveMeta();
			close();
		}, 125);
		saveButton.x -= saveButton.bWidth;
		saveButton.y -= saveButton.bHeight;

		closeButton = new UIButton(saveButton.x - 20, saveButton.y, TU.translate("editor.close"), function() {
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
		UIUtil.confirmUISelections(this);

		var customVals = {};
		for (vals in customPropertiesButtonList.buttons.members) {
			Reflect.setProperty(customVals, vals.propertyText.label.text, vals.valueText.label.text);
		}

		var meta = PlayState.SONG.meta;
		if (meta == null) meta = {name: songNameTextBox.label.text};
		else meta.name = songNameTextBox.label.text;

		meta.bpm = bpmStepper.value;
		meta.needsVoices = needsVoicesCheckbox.checked;
		meta.beatsPerMeasure = Std.int(beatsPerMeasureStepper.value);
		meta.stepsPerBeat = Std.int(16 / denominatorStepper.value);
		meta.displayName = displayNameTextBox.label.text;
		meta.icon = iconTextBox.label.text;
		meta.color = colorWheel.curColor;
		meta.opponentModeAllowed = opponentModeCheckbox.checked;
		meta.coopAllowed = coopAllowedCheckbox.checked;
		meta.difficulties = [for (diff in difficultiesTextBox.label.text.split(",")) diff.trim()];
		meta.customValues = customVals;

		Charter.instance.updateBPMEvents();
		Charter.instance.vocals.muted = !needsVoicesCheckbox.checked;
	}
}