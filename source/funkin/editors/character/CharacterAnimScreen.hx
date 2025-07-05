package funkin.editors.character;

import flixel.math.FlxPoint;
import flixel.animation.FlxAnimation;
import funkin.backend.utils.XMLUtil.AnimData;

class CharacterAnimScreen extends UISubstateWindow {
	public var animData:AnimData;

	public var nameTextBox:UITextBox;
	public var animTextBox:UITextBox;
	public var fpsStepper:UINumericStepper;
	public var loopedCheckbox:UICheckbox;
	public var indicesTextBox:UITextBox;
	public var offsetXStepper:UINumericStepper;
	public var offsetYStepper:UINumericStepper;

	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public var onSave:(animData:AnimData) -> Void = null;

	public function new(animData:AnimData, ?onSave:(animData:AnimData) -> Void) {
		this.animData = animData;
		this.onSave = onSave;
		super();
	}

	public override function create() {
		var creatingAnim:Bool = animData == null;

		if (creatingAnim)
			animData = {
				name: "name",
				anim: "anim",
				fps: 24,
				loop: false,
				animType: NONE,
				x: 0,
				y: 0,
				indices: []
			};

		winTitle = creatingAnim ? 'Creating Animation' : 'Animation ${animData.name} properties';
		winWidth = 690; winHeight = 314;

		super.create();

		function addLabelOn(ui:UISprite, text:String)
			add(new UIText(ui.x, ui.y - 24, 0, text));

		var title:UIText;
		add(title = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, creatingAnim ? "Create New Animation" : "Edit Animation Properties", 28));

		nameTextBox = new UITextBox(title.x, title.y + title.height + 38, animData.name, 160);
		add(nameTextBox);
		addLabelOn(nameTextBox, "Name");

		animTextBox = new UITextBox(nameTextBox.x + 160 + 26, nameTextBox.y, animData.anim, 200);
		add(animTextBox);
		addLabelOn(animTextBox, "Animation");

		fpsStepper = new UINumericStepper(animTextBox.x + 200 + 26, animTextBox.y, animData.fps, 0.1, 2, 1, 100, 82);
		add(fpsStepper);
		addLabelOn(fpsStepper, "FPS");

		loopedCheckbox = new UICheckbox(fpsStepper.x + 82 - 32 + 26, fpsStepper.y, "Looped", animData.loop);
		add(loopedCheckbox);
		addLabelOn(loopedCheckbox, "Looping");
		loopedCheckbox.x += 8; loopedCheckbox.y += 6;

		indicesTextBox = new UITextBox(nameTextBox.x, nameTextBox.y + 32 + 40, CoolUtil.formatNumberRange(animData.indices, ", "), 270);
		add(indicesTextBox);
		addLabelOn(indicesTextBox, "Indices");

		offsetXStepper = new UINumericStepper(indicesTextBox.x + 270 + 26, indicesTextBox.y, animData.x, 0.001, 2, null, null, 84);
		add(offsetXStepper);
		addLabelOn(offsetXStepper, "Offset (X,Y)");

		add(new UIText(offsetXStepper.x + 84 - 32 + 0, offsetXStepper.y + 9, 0, ",", 22));

		offsetYStepper = new UINumericStepper(offsetXStepper.x + 84 - 32 + 26, offsetXStepper.y, animData.y, 0.001, 2, null, null, 84);
		add(offsetYStepper);

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, "Save & Close", function() {
			saveAnimData();
			close();
		}, 125);
		add(saveButton);

		closeButton = new UIButton(saveButton.x - 20, saveButton.y, creatingAnim ? "Cancel" : "Close", function() {
			if (creatingAnim && onSave != null) onSave(null);
			close();
		}, 125);
		add(closeButton);
		closeButton.color = 0xFFFF0000;
		closeButton.x -= closeButton.bWidth;
	}

	public function saveAnimData() {
		for (stepper in [offsetXStepper, offsetYStepper, fpsStepper])
			@:privateAccess stepper.__onChange(stepper.label.text);

		animData = {
			name: nameTextBox.label.text,
			anim: animTextBox.label.text,
			fps: fpsStepper.value,
			loop: loopedCheckbox.checked,
			animType: NONE,
			x: offsetXStepper.value,
			y: offsetYStepper.value,
			indices: CoolUtil.parseNumberRange(indicesTextBox.label.text)
		};

		if (onSave != null) onSave(animData);
	}
}