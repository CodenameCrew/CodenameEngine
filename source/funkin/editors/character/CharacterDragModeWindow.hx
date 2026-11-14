package funkin.editors.character;

class CharacterDragModeWindow extends UISliceSprite {

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("characterEditor.dragMode." + id, args);

	inline function getDragTranslate(drag:CharacterDragMode){
		return switch(drag){
			case NONE:
				translate('none');
			case OFFSET:
				translate('offset');
			case POSITION:
				translate('position');
			// case CAMERA:
			// 	translate('camera');
		}
	}

	var dragModeText:UIText;

	var cameraButton:UIButton;
	var cameraIcon:FlxSprite;

	var positionButton:UIButton;
	var positionIcon:FlxSprite;

	var offsetButton:UIButton;
	var offsetIcon:FlxSprite;

	var noneButton:UIButton;
	var noneIcon:FlxSprite;

	public function new(x:Float, y:Float) {
		super(x, y, 300, 32, "editors/ui/inputbox");

		dragModeText = new UIText(x, y+this.bHeight/2-7, 300, '');
		dragModeText.alignment = CENTER;
		members.push(dragModeText);

		// cameraButton = new UIButton(0, 0, null, () -> {CharacterEditor.instance.changeOffsetDragType(CAMERA);}, Std.int(300/4-40),32);
		// cameraButton.frames = Paths.getFrames("editors/ui/grayscale-button");
		// cameraButton.color = 0xFF444444;
		// members.push(cameraButton);

		// cameraIcon = new FlxSprite(0,0).loadGraphic(Paths.image("editors/character/dragmode-icons"), true, 16, 12);
		// cameraIcon.scale.set(1.5,1.5);
		// cameraIcon.antialiasing = false;
		// members.push(cameraIcon);

		positionButton = new UIButton(0, 0, null, () -> {CharacterEditor.instance.changeOffsetDragType(POSITION);}, Std.int(300/4-40),32);
		positionButton.frames = Paths.getFrames("editors/ui/grayscale-button");
		positionButton.color = 0xFFFA9357;
		members.push(positionButton);

		positionIcon = new FlxSprite(0,0).loadGraphic(Paths.image("editors/character/dragmode-icons"), true, 16, 12);
		positionIcon.animation.add("pos", [1]);
		positionIcon.animation.play("pos", true);
		positionIcon.scale.set(1.5,1.5);
		positionIcon.antialiasing = false;
		members.push(positionIcon);

		offsetButton = new UIButton(0, 0, null, () -> {CharacterEditor.instance.changeOffsetDragType(OFFSET);}, Std.int(300/4-40),32);
		offsetButton.frames = Paths.getFrames("editors/ui/grayscale-button");
		offsetButton.color = 0xFF00A0B9;
		members.push(offsetButton);

		offsetIcon = new FlxSprite(0,0).loadGraphic(Paths.image("editors/character/dragmode-icons"), true, 16, 12);
		offsetIcon.animation.add("off", [2]);
		offsetIcon.animation.play("off", true);
		offsetIcon.scale.set(1.5,1.5);
		offsetIcon.antialiasing = false;
		members.push(offsetIcon);

		noneButton = new UIButton(0, 0, null, () -> {CharacterEditor.instance.changeOffsetDragType(NONE);}, Std.int(300/4-40),32);
		noneButton.frames = Paths.getFrames("editors/ui/grayscale-button");
		noneButton.color = 0xFFAC3D3D;
		members.push(noneButton);

		noneIcon = new FlxSprite(0,0).loadGraphic(Paths.image("editors/character/dragmode-icons"), true, 16, 12);
		noneIcon.animation.add("none", [3]);
		noneIcon.animation.play("none", true);
		noneIcon.scale.set(1.5,1.5);
		noneIcon.antialiasing = false;
		members.push(noneIcon);

		alpha = 0.7;

		refreshText();
	}

	public function refreshText(){
		dragModeText.text = '${translate('currentDrag')}: ${getDragTranslate(Options.characterDragging)}';

		positionIcon.alpha = Options.characterDragging == POSITION ? 1 : 0.5;
		offsetIcon.alpha = Options.characterDragging == OFFSET ? 1 : 0.5;
		noneIcon.alpha = Options.characterDragging == NONE ? 1 : 0.5;
	}

	public function updateButtonsPos() {
		dragModeText.follow(this, 0, this.bHeight/2-8);

		// cameraButton.follow(this, this.bWidth / 2 - ((cameraButton.bWidth + 5) * 4) / 2, -32 - 4);
		// cameraIcon.follow(cameraButton, cameraButton.bWidth / 2 - cameraIcon.width / 2, 
		// 	cameraButton.bHeight / 2 - cameraIcon.height / 2);

		positionButton.follow(this, this.bWidth / 2 - ((positionButton.bWidth + 5) * 3) / 2, -32 - 4);
		positionIcon.follow(positionButton, positionButton.bWidth / 2 - positionIcon.width / 2 - 1, 
			positionButton.bHeight / 2 - positionIcon.height / 2);

		offsetButton.follow(positionButton, offsetButton.bWidth + 5, 0);
		offsetIcon.follow(offsetButton, offsetButton.bWidth / 2 - offsetIcon.width / 2 - 1, 
			offsetButton.bHeight / 2 - offsetIcon.height / 2);

		noneButton.follow(offsetButton, noneButton.bWidth + 5, 0);
		noneIcon.follow(noneButton, noneButton.bWidth / 2 - noneIcon.width / 2 - 1, 
			noneButton.bHeight / 2 - noneIcon.height / 2);
	}

	public override function draw() {
		updateButtonsPos();
		super.draw();
	}
}