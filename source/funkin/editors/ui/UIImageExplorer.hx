package funkin.editors.ui;

import flixel.util.typeLimit.OneOfTwo;
import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import flxanimate.data.SpriteMapData.AnimateAtlas;
import flixel.graphics.frames.FlxFramesCollection;
import haxe.Json;
import haxe.io.Bytes;
import haxe.io.Path;
import openfl.display.BitmapData;
import sys.FileSystem;
import sys.io.File;

using StringTools;
using funkin.backend.utils.BitmapUtil;
using flixel.util.FlxSpriteUtil;

typedef ImageSaveData = {
	var imageName:String;
	var directory:String;
	var isAtlas:Bool;
	var imageFiles:Map<String, OneOfTwo<String, Bytes>>;
}

// TODO: make this limited if on web
class UIImageExplorer extends UIFileExplorer {
	private var allowAtlases:Bool = true;
	private var allowDirectories:Bool = true;

	public var directoryButton:UIButton;
	public var directoryIcon:UIText;

	public var directoryBG:UISliceSprite;
	public var directoryTextBoxLabel:UIText;
	public var directoryTextBox:UITextBox;

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("uiImageExplorer." + id, args);

	public function new(x:Float, y:Float, image:String, ?w:Int, ?h:Int, ?onFile:(String, Bytes)->Void, ?directory:String = "images") {
		super(x, y, w, h, "png, jpg", function (filePath, file) {
			if (filePath != null && file != null) uploadImage(filePath, file);
			if (onFile != null) onFile(filePath, file);
		});
		
		deleteButton.bWidth = 26;
		deleteButton.bHeight = 26;

		directoryButton = new UIButton(x + bWidth - (bHeight - 16) - 8, y + 8, null, () -> {directoryBG.visible = !directoryBG.visible;}, 26, 26);
		members.push(directoryButton);

	 	directoryIcon = new UIText(directoryButton.x, directoryButton.y, 0, "/", 14);
		members.push(directoryIcon);

		directoryBG = new UISliceSprite(0, 0, 210+16, 8+12+4+22+8, 'editors/ui/inputbox');
		directoryBG.alpha = 0.9; directoryBG.members.push(directoryTextBoxLabel = new UIText(8, 6, 0, TU.getRaw('uiImageExplorer.directory').format([directory]), 12));
		
		directoryTextBox = new UITextBox(8, 8+12+4, "", 210, 22, false, true);
		directoryBG.members.push(directoryTextBox);

		if (image != null) {
			var fullImagePath:String = '${Path.normalize(Sys.getCwd())}/${Paths.image(image)}'.replace('/', '\\');
			var noExt = Path.withoutExtension(fullImagePath);
			if (FileSystem.exists('$noExt\\spritemap1.png'))
				fullImagePath = '$noExt\\spritemap1.png';
	
			if (FileSystem.exists(fullImagePath))
				loadFile(fullImagePath);
		}

		allowDirectories = CoolUtil.isMapEmpty(imageFiles); __firstLoad = false;
		directoryButton.visible = directoryButton.selectable = directoryIcon.visible = directoryBG.visible = false;
	}

	public var isAtlas:Bool = false;

	static var ANIMATE_ATLAS_REGEX = ~/^(?:Animation\.json|spritemap(?:\d+)?\.json)$/i; // no .zip atlases tho
	static var SPRITEMAP_JSON_REGEX = ~/^(?:spritemap(?:\d+)?\.json)$/i;
	static var SPRITEMAP_PNG_REGEX = ~/^(?:spritemap(?:\d+)?\.png)$/i;

	public var imageName:String = null;
	public var imageFiles:Map<String, OneOfTwo<String, Bytes>> = [];
	public var animationList:Array<String> = [];

	public var fileText:UIText;

	public var maxSize:FlxPoint = FlxPoint.get(700, 500);

	@:noCompletion var __firstLoad:Bool = true;
	public function uploadImage(filePath:String, file:Bytes) {
		__resetData();

		var imagePath:Dynamic = Path.normalize(filePath);

		var directoryPath:String = Path.directory(imagePath);
		var fileName:String = Path.withoutDirectory(imagePath).toLowerCase();
		var files:Array<String> = [];

		// CHECK ATLAS
		if(allowAtlases && ANIMATE_ATLAS_REGEX.match(fileName)) {
			// check if directory has the other files
			files = FileSystem.readDirectory(directoryPath);
			var hasAnimationJson:Bool = false;
			var hasSpritemapJson:Bool = false;
			for(file in files) {
				if(file == "Animation.json")
					hasAnimationJson = true;
				else if(SPRITEMAP_JSON_REGEX.match(file.toLowerCase()))
					hasSpritemapJson = true;

				if(hasAnimationJson && hasSpritemapJson) {
					isAtlas = true;
					break;
				}
			}
		} else if(allowAtlases && Path.extension(fileName) == "png") {
			// check if the spritemap json files point to the image
			files = FileSystem.readDirectory(directoryPath);
			var hasAnimationJson:Bool = false;
			var foundSpritemapJson:Bool = false;
			for(file in files) {
				if(SPRITEMAP_JSON_REGEX.match(file)) {
					var content:String = CoolUtil.removeBOM(File.getContent(Path.join([directoryPath, file])));
					var json:AnimateAtlas = Json.parse(content);
					if(json.meta.image.toLowerCase() == fileName.toLowerCase())
						foundSpritemapJson = true;
				} else if(file == "Animation.json")
					hasAnimationJson = true;

				if(hasAnimationJson && foundSpritemapJson) {
					isAtlas = true;
					break;
				}
			}
		}

		// IF ATLAS FIND SPRITMAPS
		var spritemaps:Array<String> = [];
		var spritemapImages:Array<String> = [];
		if(isAtlas) {
			// this doesn't check for gaps in the numbering
			for(file in files)
				if(SPRITEMAP_JSON_REGEX.match(file))
					spritemaps.push(file);

			spritemaps.sort(Reflect.compare);
			for(spritemap in spritemaps) {
				var content:String = CoolUtil.removeBOM(File.getContent(Path.join([directoryPath, spritemap])));
				var json:AnimateAtlas = Json.parse(content);
				var imageToFind:String = json.meta.image.toLowerCase();
				for(file in files) {
					// lowercase since windows does case insensitive stuff, so we use lowercase to match behavior on mac and linux
					// and we also store the data from the filesystem instead of the json.meta.image
					if(file.toLowerCase() == imageToFind) {
						spritemapImages.push(file);
						break;
					}
				}
			}

			if(spritemapImages.length == 0)
				isAtlas = false;
		}

		// GATHER ANIMATIONS/DATA FILES!!!
		var frames:FlxFramesCollection = null;
		if (isAtlas) {
			var dataPath:String = '$directoryPath/Animation.json'.replace('/', '\\');

			if (FileSystem.exists(dataPath)) {
				var dataPathFile:String = File.getContent(dataPath);
				animationList = CoolUtil.getAnimsListFromAtlas(cast haxe.Json.parse(dataPathFile));

				imageFiles.set(Path.withoutDirectory(dataPath), dataPathFile);
			}
		} else {
			var dataPathExt:String = CoolUtil.imageHasFrameData(imagePath);
			var dataPath:String = Path.withExtension(imagePath, dataPathExt);
			var dataPathFile:String = !isAtlas && dataPathExt != null ? File.getContent(dataPath) : null;
	
			if (dataPathExt != null) {
				frames = CoolUtil.loadFramesFromData(dataPathFile, dataPathExt);
				animationList = CoolUtil.getAnimsListFromFrames(frames, dataPathExt);

				imageFiles.set(Path.withoutDirectory(dataPath), dataPathFile);
			}
		}

		// GATHER INFO!!!
		var size:Float = 0;
		var image:BitmapData = null;
		if (isAtlas && spritemapImages.length > 0) {
			var spritemapPath:String = Path.join([directoryPath, spritemapImages[0]]);

			imagePath = Path.normalize(spritemapPath);
			directoryPath = Path.directory(imagePath);
			fileName = Path.withoutDirectory(imagePath).toLowerCase();

			for(spritemap in spritemapImages) {
				var spritemapPath:String = Path.join([directoryPath, spritemap]);

				var info = FileSystem.stat(spritemapPath);
				size += info.size;

				spritemapPath = spritemapPath.replace('/', '\\');
				imageFiles.set(Path.withoutDirectory(spritemapPath), sys.io.File.getBytes(spritemapPath));
			}

			file = cast sys.io.File.getBytes(filePath = spritemapPath);
			image = BitmapData.fromBytes(file).crop();

		} else {
			size = file.length;
			image = BitmapData.fromBytes(file).crop();

			imageFiles.set(Path.withoutDirectory(imagePath), file);
		}

		// DISPLAY IMAGE!!
		uiElement = new FlxSprite().loadGraphic(image);
		var imageScale:Float = 1;
		if (uiElement.width < Math.min(300, maxSize.x) || uiElement.height < Math.min(200, maxSize.y))
			imageScale = Math.max(Math.min(300, maxSize.x) / uiElement.width, Math.min(200, maxSize.y) / uiElement.height);
		else if (uiElement.width > maxSize.x || uiElement.height > maxSize.y)
			imageScale = Math.min(maxSize.x/uiElement.width, maxSize.y/uiElement.height);
		uiElement.scale.set(imageScale, imageScale);
		uiElement.updateHitbox();

		bWidth = Std.int(uiElement.width)+32; bHeight = Std.int(uiElement.height)+32+deleteButton.bHeight+4;
		uiElement.x = x+16; uiElement.y = y+16+deleteButton.bHeight+4;

		uiElement.antialiasing = true;
		members.push(uiElement);

		//if (!isAtlas && frames != null) {
		//	for (frame in frames.frames) {
		//		var rect = frame.frame;
		//		uiElement.drawRect(rect.x, rect.y, rect.width, rect.height, 0x00161E87, {thickness: Std.int(1.75/imageScale), color: 0xFF11178C});
		//	}
		//}
		// GENERATE TEXT!!!
		imagePath = new Path(imagePath);
		imageName = isAtlas ? Path.withoutDirectory(directoryPath) : imagePath.file;

		var message = new StringBuf();
		if (isAtlas) message.add('${imageName}/');
		message.add('${imagePath.file}.${imagePath.ext}');
		message.add(' (${CoolUtil.getSizeString(size)}');

		var typeOfFrame = isAtlas ? translate("symbol") : translate("animation");
		var shouldUsePlural = animationList.length != 1;
		if (animationList.length > 0) {
			message.add(', ${TU.getRaw("uiImageExplorer." + (shouldUsePlural ? "foundplural" : "found")).format([animationList.length, typeOfFrame])}');
		} else message.add(', ${TU.getRaw("uiImageExplorer.notFound").format([typeOfFrame])}');

		if (isAtlas) {
			shouldUsePlural = spritemaps.length != 1;
			message.add(', ${TU.getRaw("uiImageExplorer.foundAtlas" + (shouldUsePlural ? "plural" : "")).format([spritemaps.length])}');
		}
		message.add(')');
		message.add(isAtlas ? ' - ${translate("atlas")}' : ' - ${translate("spritemap")}');

		fileText = new UIText(x+20, y+16, bWidth-20-deleteButton.bWidth-16, "");
		fileText.applyMarkup(message.toString(), [new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "#")]);
		members.push(fileText);

		deleteButton.x = x + bWidth - deleteButton.bWidth - 16;
		deleteButton.y = y + 12;

		deleteIcon.x = deleteButton.x + deleteButton.bWidth/2 - 8;
		deleteIcon.y = deleteButton.y + deleteButton.bHeight/2 - 8;

		directoryButton.x = deleteButton.x - deleteButton.bWidth - 12;
		directoryButton.y = y + 12;

		directoryIcon.x = directoryButton.x + directoryButton.bWidth/2 - (directoryIcon.width/2);
		directoryIcon.y = directoryButton.y + directoryButton.bHeight/2 - (directoryIcon.height/2);
		
		directoryBG.x = x + bWidth - directoryBG.bWidth - 16;
		directoryBG.y = directoryButton.y + directoryButton.bHeight + 8;

		directoryTextBoxLabel.x = directoryBG.x + 8;
		directoryTextBoxLabel.y = directoryBG.y + 6;

		directoryTextBox.x = directoryBG.x + 8;
		directoryTextBox.y = directoryBG.y + 8+12+4;

		if (!__firstLoad) allowDirectories = true;

		directoryButton.visible = directoryButton.selectable = directoryIcon.visible = allowDirectories;
		directoryBG.visible = false;
		if (directoryButton.visible) fileText.fieldWidth -= directoryButton.bWidth + 12;

		members.push(directoryBG); __firstLoad = false;
	}

	public var saveData:ImageSaveData = null;
	public inline function getSaveData():ImageSaveData {
		return saveData = {
			imageName: this.imageName, 
			directory: Path.removeTrailingSlashes(directoryTextBox.label.text),
			isAtlas: this.isAtlas, 
			imageFiles: this.imageFiles.copy()
		};
	}

	public inline function saveFiles(directory:String, ?onFinishSaving:Void->Void, ?checkExisting:Bool = true) {
		UIImageExplorer.saveFilesGlobal(getSaveData(), directory, onFinishSaving, checkExisting);
	}

	public static function serializeSaveDataGlobal(data:ImageSaveData):String
		return haxe.Serializer.run(data);

	public static function deserializeSaveDataGlobal(data:String):ImageSaveData
		return cast haxe.Unserializer.run(data);

	public static function saveFilesGlobal(imageData:ImageSaveData, directory:String, ?onFinishSaving:Void->Void, ?checkExisting:Bool = true) {
		directory += '${directory.length > 0 ? '/${imageData.directory}' : ""}';
		if (imageData.isAtlas) directory += '/${imageData.imageName}';

		var alreadlyExistingFiles:Array<String> = [];
		for (name => file in imageData.imageFiles)
			if (FileSystem.exists('$directory/$name'))
				alreadlyExistingFiles.push('$directory/$name');

		function deleteExistingFiles() {
			for (file in alreadlyExistingFiles)
				FileSystem.deleteFile(file);
			alreadlyExistingFiles = [];
		}

		function acuttalySaveFiles() {
			for (name => file in imageData.imageFiles)
				if (!alreadlyExistingFiles.contains('$directory/$name')) {
					CoolUtil.safeSaveFile('$directory/$name', file);
					trace('SAVED: $directory/$name');
				}

			if (onFinishSaving != null) onFinishSaving();
		}

		if (alreadlyExistingFiles.length > 0 && checkExisting) @:privateAccess {
			var buttons = [
				{
					label: TU.translate("uiImageExplorer.override"),
					color: 0xFFFF0000,
					onClick: (_) -> {
						deleteExistingFiles();
						acuttalySaveFiles();
					}
				}, 
				{
					label: TU.translate("uiImageExplorer.useExisting"),
					onClick: (_) -> {if (onFinishSaving != null) onFinishSaving();}
				}
			];
			(FlxG.state.subState != null && !FlxG.state._requestSubStateReset ? FlxG.state.subState : FlxG.state).openSubState(new UIWarningSubstate("Alreadly Existing Files!!!", 
				TU.getRaw("uiImageExplorer.fileAlreadyExists").format([alreadlyExistingFiles.join('\n')]), buttons, false));
		} else acuttalySaveFiles();
	}

	public override function removeFile() {
		__resetData();
		bWidth = 320; bHeight = 58;

		members.remove(fileText);
		fileText.destroy();

		members.remove(directoryBG);
		directoryButton.visible = directoryButton.selectable = directoryIcon.visible = directoryBG.visible = false;

		super.removeFile();
	}

	@:noCompletion inline function __resetData() {
		imageFiles.clear(); isAtlas = false; animationList = [];
	}

	public override function destroy() {
		maxSize.put();
		super.destroy();
	}
}