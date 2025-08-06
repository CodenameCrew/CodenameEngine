package funkin.editors.character;

import haxe.io.Bytes;
import flixel.util.typeLimit.OneOfTwo;
import flixel.text.FlxText.FlxTextFormat;
import funkin.editors.ui.UIImageExplorer.ImageSaveData;
import flixel.text.FlxText.FlxTextFormatMarkerPair;

class CharacterSpriteScreen extends UISubstateWindow {
	private var imagePath:String = null;
	private var onSave:(String, Bool) -> Void = null;

	public var ogImageSaveData:ImageSaveData;
	public var imageExplorer:UIImageExplorer;

	public var saveButton:UIButton;
	public var closeButton:UIButton;

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("characterEditor.characterSpriteScreen." + id, args);

	public function new(imagePath:String, ?onSave:(String, Bool)->Void) {
		super();
		this.imagePath = imagePath;
		if (onSave != null) this.onSave = onSave;
	}

	public override function create() {
		winTitle = translate("win-title");
		winWidth = 360; winHeight = 183;

		function addLabelOn(ui:UISprite, text:String):UIText {
			var text:UIText = new UIText(ui.x, ui.y - 24, 0, text);
			ui.members.push(text);
			return text;
		}

		super.create();

		imageExplorer = new UIImageExplorer(20, windowSpr.y + 30 + 16 + 20, imagePath, 320, 58, (_, _) -> {onLoadImage();}, "images/characters");
		add(imageExplorer);
		addLabelOn(imageExplorer, "").applyMarkup(
			translate('charImageFile'),
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);

		ogImageSaveData = imageExplorer.getSaveData();

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight - 20, TU.translate("editor.saveClose"), function() {
			addToUndo(); // should be async?? -lunar
			imageExplorer.saveFiles('${Paths.getAssetsRoot()}/images/characters', () -> {
				onSave('${imageExplorer.saveData.directory.length > 0 ? '${imageExplorer.saveData.directory}/' : ""}' + imageExplorer.imageName, imageExplorer.isAtlas);
				close();
			});
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

		refreshWindowSize();
	}

	public function onLoadImage() {
		refreshWindowSize();

		if (imageExplorer == null || imageExplorer.imageFiles == null) return;
		var filesSame = CoolUtil.deepEqual(ogImageSaveData.imageFiles, imageExplorer.imageFiles);
		saveButton.selectable = !filesSame && !CoolUtil.isMapEmpty(imageExplorer.imageFiles) && (imageExplorer.animationList.length > 0);
	}

	public function refreshWindowSize() {
		if (imageExplorer == null) return;
		windowSpr.bWidth = 20 + imageExplorer.bWidth + 20;
		windowSpr.bHeight = 30 + 16 + 20 + imageExplorer.bHeight + 14 + saveButton.bHeight + 14;

		saveButton.x = windowSpr.x + windowSpr.bWidth - 20 - saveButton.bWidth;
		closeButton.x = saveButton.x - 20 - closeButton.bWidth; 
		closeButton.y = saveButton.y = imageExplorer.y + imageExplorer.bHeight + 14;
	}

	public static var idCounter:Int = -1;
	public inline function addToUndo() {
		idCounter = FlxMath.wrap(idCounter + FlxG.random.int(1, 57349), 0, 9999);
		CharacterEditor.undos.addToUndo(CCharEditSprite(idCounter));
	
		CoolUtil.safeSaveFile('./.temp/__undo__${Type.getClassName(Type.getClass(FlxG.state))}__${idCounter}.cneisd', UIImageExplorer.serializeSaveDataGlobal(ogImageSaveData));
		CoolUtil.safeSaveFile('./.temp/__redo__${Type.getClassName(Type.getClass(FlxG.state))}__${idCounter}.cneisd', UIImageExplorer.serializeSaveDataGlobal(imageExplorer.getSaveData()));
	}
}