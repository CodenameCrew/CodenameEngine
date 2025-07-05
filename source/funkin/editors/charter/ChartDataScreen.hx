package funkin.editors.charter;

import funkin.game.Stage;
import funkin.backend.chart.ChartData;
import flixel.math.FlxPoint;
import funkin.backend.chart.ChartData.ChartMetaData;

using StringTools;

class ChartDataScreen extends UISubstateWindow {
	public var data:ChartData;
	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public var scrollSpeedStepper:UINumericStepper;
	public var stageTextBox:UIAutoCompleteTextBox;

	public function new(data:ChartData) {
		super();
		this.data = data;
	}

	public override function create() {
		FlxG.sound.music.pause();
		Charter.instance.vocals.pause();
		for (strumLine in Charter.instance.strumLines.members) strumLine.vocals.pause();

		winTitle = 'Chart Properties';
		winWidth = 420; winHeight = 230; // guys look, the funny numbers!

		super.create();

		function addLabelOn(ui:UISprite, text:String)
			add(new UIText(ui.x, ui.y - 24, 0, text));

		var title:UIText;
		add(title = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, "Edit Chart Data", 28));

		var stageFileList = Stage.getList(true);
		if (stageFileList.length == 0) stageFileList = Stage.getList(false);

		stageTextBox = new UIAutoCompleteTextBox(title.x, title.y + title.height + 38, PlayState.SONG.stage, 200);
		stageTextBox.suggestItems = stageFileList;
		add(stageTextBox);
		addLabelOn(stageTextBox, "Stage");

		scrollSpeedStepper = new UINumericStepper(stageTextBox.x + 200 + 26, stageTextBox.y, data.scrollSpeed, 0.1, 2, 0, 10, 82);
		add(scrollSpeedStepper);
		addLabelOn(scrollSpeedStepper, "Scroll Speed");

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, "Save & Close", function() {
			saveInfo();
			close();
		}, 125);
		add(saveButton);

		closeButton = new UIButton(saveButton.x - 20, saveButton.y, "Close", function() {
			close();
		}, 125);
		add(closeButton);
		closeButton.color = 0xFFFF0000;
		closeButton.x -= closeButton.bWidth;
	}

	public function saveInfo()
	{
		@:privateAccess scrollSpeedStepper.__onChange(scrollSpeedStepper.label.text);

		var oldData:{stage:String, speed:Float} = {stage: PlayState.SONG.stage, speed: PlayState.SONG.scrollSpeed};

		PlayState.SONG.stage = stageTextBox.label.text;
		PlayState.SONG.scrollSpeed = scrollSpeedStepper.value;

		Charter.undos.addToUndo(CEditChartData(oldData, {stage: stageTextBox.label.text, speed: scrollSpeedStepper.value}));
	}
}