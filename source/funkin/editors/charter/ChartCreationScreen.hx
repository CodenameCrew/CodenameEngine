package funkin.editors.charter;

import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import funkin.backend.chart.ChartData;
import funkin.backend.shaders.CustomShader;
import funkin.game.Character;
import funkin.game.HealthIcon;
import funkin.game.Stage;

class ChartCreationScreen extends UISubstateWindow {
	private var onSave:(String, ChartData) -> Void = null;
	public var charFileList:Array<String> = [];

	public var difficultyNameTextBox:UITextBox;
	public var scrollSpeedTextBox:UINumericStepper;
	public var stageTextBox:UIAutoCompleteTextBox;
	public var strumLineList:UIButtonList<StrumLineButton>;

	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public function new(?onSave:(String, ChartData)->Void) {
		super();
		if (onSave != null) this.onSave = onSave;
	}

	public override function create() {
		winTitle = TU.translate("chartCreation.title");

		winWidth = 652;
		winHeight = 600;

		super.create();

		function addLabelOn(ui:UISprite, text:String):UIText {
			var text:UIText = new UIText(ui.x, ui.y - 24, 0, text);
			ui.members.push(text);
			return text;
		}

		charFileList = Character.getList(true);
		if (charFileList.length == 0) charFileList = Character.getList(false);

		var chartTitle:UIText;
		add(chartTitle = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, TU.translate("chartCreation.info"), 28));

		difficultyNameTextBox = new UITextBox(chartTitle.x, chartTitle.y + chartTitle.height + 36, "difficulty", 200);
		add(difficultyNameTextBox);
		addLabelOn(difficultyNameTextBox, TU.translate("chartCreation.diffName"));

		var stageFileList = Stage.getList(true);
		if (stageFileList.length == 0) stageFileList = Stage.getList(false);

		stageTextBox = new UIAutoCompleteTextBox(difficultyNameTextBox.x + 200 + 26, difficultyNameTextBox.y, "stage", 180);
		stageTextBox.suggestItems = stageFileList;
		add(stageTextBox);
		addLabelOn(stageTextBox, TU.translate("chartCreation.stage"));

		scrollSpeedTextBox = new UINumericStepper(stageTextBox.x + 180 + 26, difficultyNameTextBox.y, 1.0, 0.1, 2, null, null, 90);
		scrollSpeedTextBox.onChange = function (text:String) {
			@:privateAccess scrollSpeedTextBox.__onChange(text);
			for (button in strumLineList.buttons.members)
				if (button.usesChartScrollSpeed.checked)
					button.scrollSpeedStepper.value = scrollSpeedTextBox.value;
		}
		add(scrollSpeedTextBox);
		addLabelOn(scrollSpeedTextBox, TU.translate("chartCreation.scrollSpeed"));

		strumLineList = new UIButtonList<StrumLineButton>(difficultyNameTextBox.x, difficultyNameTextBox.y+difficultyNameTextBox.bHeight+36, 620, (552-179)-16, null, FlxPoint.get(620, 246), null, 6);
		strumLineList.frames = Paths.getFrames('editors/ui/inputbox');
		strumLineList.cameraSpacing = 0;

		strumLineList.addButton.callback = function() {
			strumLineList.add(new StrumLineButton(strumLineList.buttons.length, {
				characters: [Flags.DEFAULT_OPPONENT],
				type: 0,
				notes: null,
				position: "DAD",
				strumPos: [0, 50],
				strumLinePos: 0.25,
			}, strumLineList));
		}

		// DEFAULTS
		strumLineList.add(new StrumLineButton(0, {
			characters: [Flags.DEFAULT_OPPONENT],
			type: 0,
			notes: null,
			position: "DAD",
			strumPos: [0, 50],
			strumLinePos: 0.25,
			scrollSpeed: 1,
		}, strumLineList));
		strumLineList.add(new StrumLineButton(1, {
			characters: [Flags.DEFAULT_CHARACTER],
			type: 1,
			notes: null,
			position: "BOYFRIEND",
			strumPos: [0, 50],
			strumLinePos: 0.75,
			scrollSpeed: 1,
		}, strumLineList));
		strumLineList.add(new StrumLineButton(2, {
			characters: [Flags.DEFAULT_GIRLFRIEND],
			type: 2,
			notes: null,
			position: "GIRLFRIEND",
			strumPos: [0, 50],
			strumLinePos: 0.50,
			scrollSpeed: 1,
			visible: false,
		}, strumLineList));

		add(strumLineList);
		addLabelOn(strumLineList, "").applyMarkup(
			TU.translate("chartCreation.strumLineList"),
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);

		var strumlineFormat = TU.getRaw("chartCreation.strumLine.format");
		strumLineList.dragCallback = (object:StrumLineButton, oldIndex:Int, newIndex:Int) -> {object.idText.text = strumlineFormat.format([newIndex]);};
		scrollSpeedTextBox.onChange(scrollSpeedTextBox.label.text);

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, TU.translate("editor.saveClose"), function() {
			createChart();
			close();
		}, 125);
		add(saveButton);

		closeButton = new UIButton(saveButton.x - 20 - saveButton.bWidth, saveButton.y, TU.translate("editor.close"), function() {
			close();
		}, 125);
		add(closeButton);
		closeButton.color = 0xFFFF0000;
	}

	public override function update(elapsed:Float) {
		saveButton.selectable = strumLineList.buttons.members.length != 0;
		saveButton.alpha = saveButton.field.alpha = saveButton.selectable ? 1 : 0.4;
		super.update(elapsed);
	}

	public function createChart() {
		scrollSpeedTextBox.onChange(scrollSpeedTextBox.label.text);

		var strumLines:Array<ChartStrumLine> = [];
		for (strline in strumLineList.buttons.members) {
			UIUtil.confirmUISelections(strline);

			strumLines.push({
				characters: [for (char in strline.charactersList.buttons.members) char.textBox.label.text],
				type: strline.typeDropdown.index,
				notes: [],
				position: strline.stagePositionDropdown.label.text.toLowerCase(),
				visible: strline.visibleCheckbox.checked,
				strumPos: [0, strline.hudYStepper.value],
				strumLinePos: strline.hudXStepper.value,
				strumScale: strline.hudScaleStepper.value,
				scrollSpeed: strline.usesChartScrollSpeed.checked ? strline.scrollSpeedStepper.value : null
			});
		}

		var chartData:ChartData = {
			codenameChart: true,
			strumLines: strumLines,
			stage: stageTextBox.label.text,
			scrollSpeed: scrollSpeedTextBox.value,
			events: [],
			noteTypes: [],
			meta: null
		}

		if (onSave != null) onSave(difficultyNameTextBox.label.text, chartData);
	}
}

class StrumLineButton extends UIButton {
	public var idText:UIText;

	public var charactersList:UIButtonList<CompactCharacterButton>;
	public var typeDropdown:UIDropDown;
	public var stagePositionDropdown:UIDropDown;
	public var hudScaleStepper:UINumericStepper;
	public var hudXStepper:UINumericStepper;
	public var hudYStepper:UINumericStepper;
	public var visibleCheckbox:UICheckbox;
	public var scrollSpeedStepper:UINumericStepper;
	public var usesChartScrollSpeed:UICheckbox;

	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public var labels:Map<UISprite, UIText> = [];
	public var XYComma:UIText;

	public var cameraClipShader:CustomShader;

	public function new(id:Int, strumLine:ChartStrumLine, parent:UIButtonList<StrumLineButton>) {
		super(0, 0, '', function () {}, 620, 246);

		var subState:ChartCreationScreen = cast FlxG.state.subState;
		autoAlpha = false; frames = Paths.getFrames('editors/ui/inputbox');

		function addLabelOn(ui:UISprite, text:String, ?size:Int):UIText {
			var uiText:UIText = new UIText(ui.x, ui.y - 24, 0, text, size);
			members.push(uiText); labels.set(ui, uiText);
			return uiText;
		}

		charactersList = new UIButtonList<CompactCharacterButton>(16, 8+26, 210, 160, null, FlxPoint.get(200, 40), null, 5);
		charactersList.frames = Paths.getFrames('editors/ui/inputbox');
		charactersList.cameraSpacing = 0;

		charactersList.addButton.callback = function()
			charactersList.add(new CompactCharacterButton(TU.translate("charterStrumLine.newChar"), subState.charFileList, charactersList));
		for (character in strumLine.characters)
			charactersList.add(new CompactCharacterButton(character, subState.charFileList, charactersList));

		members.push(charactersList);
		idText = addLabelOn(charactersList, TU.translate("chartCreation.strumLine.format", [id]));

		cameraClipShader = new CustomShader("engine/cameraClip");
		cameraClipShader.hset("clipRect", [0, 0, 100, 100]);
		charactersList.buttonCameras.addShader(cameraClipShader);

		typeDropdown = new UIDropDown(charactersList.x + charactersList.bWidth + 16, 8+26, 200, 32, ["OPPONENT", "PLAYER", "ADDITIONAL"], strumLine.type);
		members.push(typeDropdown);
		addLabelOn(typeDropdown, TU.translate("charterStrumLine.type"));

		var stagePositionI = strumLine.position == null ? strumLine.type : ["DAD", "BOYFRIEND", "GIRLFRIEND"].indexOf(strumLine.position.toUpperCase());

		stagePositionDropdown = new UIDropDown(typeDropdown.x + 200 - 32 + 26, typeDropdown.y, 200, 32, ["DAD", "BOYFRIEND", "GIRLFRIEND"], stagePositionI);
		members.push(stagePositionDropdown);
		addLabelOn(stagePositionDropdown, TU.translate("charterStrumLine.stagePos"));

		hudScaleStepper = new UINumericStepper(typeDropdown.x, typeDropdown.y + 64, strumLine.strumScale == null ? 1 : strumLine.strumScale, 0.001, 2, null, null, 74);
		members.push(hudScaleStepper);
		addLabelOn(hudScaleStepper, TU.translate("charterStrumLine.scale"));

		var strOffset:Float = strumLine.strumLinePos == null ? (strumLine.type == 1 ? 0.75 : 0.25) : strumLine.strumLinePos;

		var startingPos:FlxPoint = strumLine.strumLinePos == null ?
			FlxPoint.get(strOffset, 50) :
			FlxPoint.get(strOffset, strumLine.strumPos[1]);

		hudXStepper = new UINumericStepper(hudScaleStepper.x + 80 - 32 + 26, hudScaleStepper.y, startingPos.x, 0.01, 2, 0, 2, 84);
		members.push(hudXStepper);
		addLabelOn(hudXStepper, TU.translate("charterStrumLine.hudPos"));

		members.push(XYComma = new UIText(hudXStepper.x + 84 - 32 + 0, hudXStepper.y + 9, 0, ",", 22));

		hudYStepper = new UINumericStepper(hudXStepper.x + 84 - 32 + 26, hudXStepper.y, startingPos.y, 0.001, 2, null, null, 84);
		members.push(hudYStepper);

		visibleCheckbox = new UICheckbox(hudYStepper.x + hudYStepper.bWidth + 42, hudYStepper.y + 9, TU.translate("charterStrumLine.visible"), strumLine.visible == null ? true : strumLine.visible);
		members.push(visibleCheckbox);

		scrollSpeedStepper = new UINumericStepper(typeDropdown.x, typeDropdown.y + 128, strumLine.scrollSpeed, 0.1, 2, 0, 10, 82);
		scrollSpeedStepper.selectable = strumLine.scrollSpeed != null;
		members.push(scrollSpeedStepper);
		addLabelOn(scrollSpeedStepper, TU.translate("charterStrumLine.scrollSpeed"));

		usesChartScrollSpeed = new UICheckbox(scrollSpeedStepper.x + 104, typeDropdown.y + 135, TU.translate("charterStrumLine.useChartScrollSpeed"), strumLine.scrollSpeed == null);
		usesChartScrollSpeed.onChecked = function(b) {
			if(b) {
				scrollSpeedStepper.value = subState.scrollSpeedTextBox.value;
				scrollSpeedStepper.selectable = false;
			} else
				scrollSpeedStepper.selectable = true;
		}
		members.push(usesChartScrollSpeed);

		deleteButton = new UIButton(16, 246-32-11, null, function () {
			parent.remove(this);
		}, 620-32);
		deleteButton.color = 0xFFFF0000;
		deleteButton.autoAlpha = false;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(deleteButton.x + ((deleteButton.bWidth/2)-(15/2)), deleteButton.y + ((deleteButton.bHeight/2)-(16/2))).loadGraphic(Paths.image('editors/delete-button'));
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		charactersList.follow(this, 16, 8+26);
		typeDropdown.follow(this, charactersList.x + charactersList.bWidth + 16, 8+26);
		stagePositionDropdown.follow(this, typeDropdown.x + 200 - 32 + 26, 8+26);
		hudScaleStepper.follow(this, typeDropdown.x, 8+26 + 64);
		hudXStepper.follow(this, hudScaleStepper.x + 80 - 32 + 26, 8+26 + 64);
		hudYStepper.follow(this, hudXStepper.x + 84 - 32 + 26, 8+26 + 64);
		visibleCheckbox.follow(this, hudYStepper.x + hudYStepper.bWidth + 42, 8+26 + 64 + 9);
		scrollSpeedStepper.follow(this, typeDropdown.x, 8+26 + 128);
		usesChartScrollSpeed.follow(this, scrollSpeedStepper.x + 104, 8+26 + 135);

		deleteButton.follow(this, 16, 246-32-11);
		deleteIcon.follow(this, 16 + ((deleteButton.bWidth/2)-(15/2)), (246-32-11) + ((deleteButton.bHeight/2)-(16/2)));

		XYComma.follow(hudXStepper, 84 - 32, 9);
		for (ui => text in labels)
			text.follow(ui, 0, -24);

		var subState:ChartCreationScreen = cast FlxG.state.subState;
		var strumLineList:UIButtonList<StrumLineButton> = subState.strumLineList;
		cameraClipShader.hset("clipRect", [0, (-y-(8+26))+cameras[0].scroll.y, strumLineList.bWidth, strumLineList.bHeight]);
	}
}

class CompactCharacterButton extends UIButton {
	public var charIcon:HealthIcon;
	public var textBox:UIAutoCompleteTextBox;
	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public function new(char:String, charsList:Array<String>, parent:UIButtonList<CompactCharacterButton>) {
		super(0, 0, null, null, 200, 40);
		autoAlpha = false;

		charIcon = new HealthIcon(funkin.game.Character.getIconFromCharName(char));
		var size = Std.int(150 * 0.2);
		charIcon.setUnstretchedGraphicSize(size, size, true);
		charIcon.updateHitbox();
		charIcon.setPosition(10, bHeight/2 - charIcon.height / 2);
		charIcon.scrollFactor.set(1,1);

		members.push(charIcon);

		members.push(textBox = new UIAutoCompleteTextBox(charIcon.x + charIcon.width + 16, bHeight/2 - (32/2), char, 115));
		textBox.suggestItems = charsList;
		textBox.antialiasing = true;
		textBox.onChange = function(char:String) {
			char = funkin.game.Character.getIconFromCharName(char);
			charIcon.setIcon(char);
			charIcon.setUnstretchedGraphicSize(size, size, true);
			charIcon.updateHitbox();
			charIcon.setPosition(10, bHeight/2 - charIcon.height / 2);
		}

		deleteButton = new UIButton(textBox.x + 115 + 16, bHeight/2 - (32/2), null, function () {
			parent.remove(this);
		}, 32);
		deleteButton.color = 0xFFFF0000;
		deleteButton.autoAlpha = false;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(deleteButton.x + (15/2), deleteButton.y + 8).loadGraphic(Paths.image('editors/delete-button'));
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);
	}

	override function update(elapsed) {
		charIcon.follow(this, 6, bHeight / 2 - charIcon.height / 2);
		textBox.follow(charIcon, charIcon.width + 6, 0);
		deleteButton.follow(textBox, 115 + 6, 0);
		deleteIcon.follow(deleteButton, 15 / 2, 8);

		deleteButton.selectable = selectable;
		deleteButton.shouldPress = shouldPress;

		super.update(elapsed);
	}
}