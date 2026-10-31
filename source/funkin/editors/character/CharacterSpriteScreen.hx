package funkin.editors.character;

import flixel.text.FlxText.FlxTextFormat;
import funkin.editors.ui.UIImageExplorer.ImageSaveData;
import flixel.text.FlxText.FlxTextFormatMarkerPair;

class CharacterSpriteScreen extends UISubstateWindow {
	private var imagePaths:Array<String> = null;
	private var onSave:(Array<ImageSaveData>) -> Void = null;

	public var ogImageSaveDatas:Array<ImageSaveData>;
	public var imageList:UIImageList;

	public var saveButton:UIButton;
	public var closeButton:UIButton;

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("characterEditor.characterSpriteScreen." + id, args);

	public function new(imagePaths:Array<String>, ?onSave:(saveDatas:Array<ImageSaveData>)->Void) {
		super();
		this.imagePaths = imagePaths;
		if (onSave != null) this.onSave = onSave;
	}

	public override function create() {
		winTitle = translate("win-title");
		winWidth = 660; winHeight = 520;

		function addLabelOn(ui:UISprite, text:String):UIText {
			var text:UIText = new UIText(ui.x, ui.y - 24, 0, text);
			ui.members.push(text);
			return text;
		}

		super.create();

		imageList = new UIImageList(10, Std.int(windowSpr.y + 30 + 16 + 20), null, () -> {onLoadImage();}, imagePaths);
		add(imageList);
		addLabelOn(imageList, "").applyMarkup(
			translate('charImageFile'),
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);
		imageList.bHeight += 100;
	
		ogImageSaveDatas = imageList.getSaveDatas();

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight - 20, TU.translate("editor.saveClose"), function() {
			addToUndo(); // should be async?? -lunar
			var saveDatas:Array<ImageSaveData> = imageList.getSaveDatas();
			
			for(data in saveDatas)
				UIImageExplorer.saveFilesGlobal(data, '${Paths.getAssetsRoot()}/images/characters');

			onSave(saveDatas);
			close();
		}, 125);
		saveButton.x -= saveButton.bWidth;
		saveButton.y -= saveButton.bHeight;
		saveButton.selectable = false;

		closeButton = new UIButton(saveButton.x - 20, saveButton.y, TU.translate("editor.cancel"), function() {
			close();
		}, 125);
		closeButton.color = 0xFFFF0000;
		closeButton.x -= closeButton.bWidth;
		//closeButton.y -= closeButton.bHeight;
		add(closeButton);
		add(saveButton);
	}

	public function onLoadImage() {
		saveButton.selectable = imageList.getSaveDatas() != imageList.getSaveDatas() && (imageList.getAnimList().length > 0);
	}

	public static var idCounter:Int = -1;
	public inline function addToUndo() {
		idCounter = FlxMath.wrap(idCounter + FlxG.random.int(1, 57349), 0, 9999);
		CharacterEditor.undos.addToUndo(CCharEditSprite(idCounter));
	
		for(i in 0...ogImageSaveDatas.length)
			CoolUtil.safeSaveFile('./.temp/${idCounter}__undo__/${Type.getClassName(Type.getClass(FlxG.state))}__$i.cneisd', UIImageExplorer.serializeSaveDataGlobal(ogImageSaveDatas[i]));
		
		for(i in 0...imageList.getSaveDatas().length)
			CoolUtil.safeSaveFile('./.temp/${idCounter}__redo__/${Type.getClassName(Type.getClass(FlxG.state))}__$i.cneisd', UIImageExplorer.serializeSaveDataGlobal(imageList.getSaveDatas()[i]));
	}
}