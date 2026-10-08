package funkin.editors.ui;

import funkin.editors.ui.UIImageExplorer.ImageSaveData;
import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;

class UIImageList extends UIButtonList<UIImageButton> {
	public var onImage:()-> Void;
	public var dirPath:String;

	public function new(x:Int, y:Int, path:String = "images/characters", ?onImage:()-> Void, ?baseImages:Array<String>){
		this.dirPath = path;
		this.onImage = onImage;

		super(x, y, 640, 270, null, FlxPoint.get(Std.int(500-16-32-20), 100), null, FlxPoint.get(-100, 0));

		cameraSpacing = 0;
		frames = Paths.getFrames('editors/ui/inputbox');
		alpha = 0.7;

		addImages(baseImages);

		this.addButton.callback = function() {
			add(makeNewButton());
		}
	}

	function addImages(imgs:Array<String>){
		if (imgs == null)
			return;

		for(img in imgs)
			add(makeNewButton(img));
	}

	public function makeNewButton(?img:String):UIImageButton {
		var butt = new UIImageButton(10, 10, 650 - 20, 60 - 10, dirPath, img);
			
		if(onImage != null)
			butt.onImage = onImage;
			
		return butt;
	}

	public function getSaveDatas() {
		var data:Array<ImageSaveData> = [];

		for(b in buttons){
			var file = b.imageExplorer.getSaveData();

			if(b.imageExplorer.uiElement != null && b.imageExplorer.uiElement.exists)
				data.push(file);
		}
		
		return data;
	}

	public function getAnimList():Array<String> {
		var anims:Array<String> = [];

		for(b in buttons)
			if (b.imageExplorer.animationList != null)
				anims = anims.concat(b.imageExplorer.animationList);
		
		return anims;
	}
}

class UIImageButton extends UIButton {
	public var onImage:()-> Void = null;

	public var imageExplorer:UIImageExplorer;

	public var labels:Map<UISprite, UIText> = [];

	public function new(x:Int, y:Int, w:Int, h:Int, ?path:String, ?imgPath:String) {
		super(x,y,"",null,w,h);

		function addLabelOn(ui:UISprite, text:String, ?size:Int):UIText {
			var uiText:UIText = new UIText(ui.x, ui.y-18, 0, text, size);
			members.push(uiText); labels.set(ui, uiText);
			return uiText;
		}

		alpha = 0.2;

		autoAlpha = autoFrames = autoFollow = false;

		frames = Paths.getFrames('editors/ui/inputbox');
		field.fieldWidth = 0; framesOffset = 9;
		field.size = 14;

		imageExplorer = new UIImageExplorer(10, 10, imgPath, this.bWidth - 10, this.bHeight - 10, (_,_) -> {if(onImage != null) onImage();}, path, FlxPoint.get(w - 40, 500));
		members.push(imageExplorer);
	}

	inline function updateButtonsPos(){
		imageExplorer.follow(this, bWidth / 2 - imageExplorer.bWidth / 2, 5);

		bHeight = imageExplorer.bHeight + 10;
	}

	public override function draw() {
		updateButtonsPos();
		super.draw();
	}
}