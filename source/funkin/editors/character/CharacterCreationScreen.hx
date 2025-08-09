package funkin.editors.character;

import haxe.xml.Printer;
import funkin.game.Character;
import funkin.editors.ui.UIImageExplorer.ImageSaveData;
import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;

class CharacterCreationScreen extends UISubstateWindow {
	private var onSave:(String, ImageSaveData, Xml)-> Void = null;

	public var characterNameTextBox:UITextBox;
	public var imageExplorer:UIImageExplorer;

	public var saveButton:UIButton;
	public var closeButton:UIButton;

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("characterCreationScreen." + id, args);

	public function new(?onSave:(String, ImageSaveData, Xml)->Void) {
		super();
		if (onSave != null) this.onSave = onSave;
	}

	public override function create() {
		winTitle = translate("win-title");

		winWidth = 360;
		winHeight = 520;

		super.create();

		function addLabelOn(ui:UISprite, text:String):UIText {
			var text:UIText = new UIText(ui.x, ui.y - 24, 0, text);
			ui.members.push(text);
			return text;
		}

		characterNameTextBox = new UITextBox(windowSpr.x + 20, windowSpr.y + 30 + 16 + 20, "character", 320);
		characterNameTextBox.onChange = (_) -> {checkRequired();};
		add(characterNameTextBox);
		addLabelOn(characterNameTextBox, "").applyMarkup(
			translate("charName"),
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);

		imageExplorer = new UIImageExplorer(characterNameTextBox.x, characterNameTextBox.y + 30 + 16 + 20, null, 320, 58, (_, _) -> {onLoadImage();}, "images/characters");
		add(imageExplorer);
		addLabelOn(imageExplorer, "").applyMarkup(
			translate("charImgName"),
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);
		imageExplorer.maxSize.y -= 100;

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, TU.translate("editor.saveClose"), function() {
			close();
			createCharacter();
		}, 125);
		add(saveButton);

		closeButton = new UIButton(saveButton.x - 20 - saveButton.bWidth, saveButton.y, TU.translate("editor.cancel"), function() {
			close();
		}, 125);
		add(closeButton);
		closeButton.color = 0xFFFF0000;

		onLoadImage();
	}

	public function onLoadImage() {
		refreshWindowSize();
		checkRequired();
	}

	public function refreshWindowSize() {
		if (imageExplorer == null) return;
		windowSpr.bWidth = 20 + imageExplorer.bWidth + 20;
		windowSpr.bHeight = 30 + 16 + 20 + 32 + 30 + 10 + imageExplorer.bHeight + 14 + saveButton.bHeight + 14;

		saveButton.x = windowSpr.x + windowSpr.bWidth - 20 - saveButton.bWidth;
		closeButton.x = saveButton.x - 20 - closeButton.bWidth; 
		closeButton.y = saveButton.y = imageExplorer.y + imageExplorer.bHeight + 14;
	}

	public function checkRequired() {
		saveButton.selectable = characterNameTextBox.label.text.length > 0 && !CoolUtil.isMapEmpty(imageExplorer.imageFiles) && (imageExplorer.animationList.length > 0);
	}

	public function createCharacter() {
		var imageSaveData:ImageSaveData = imageExplorer.getSaveData();

		var xml:Xml = Xml.createElement("character");
		xml.attributeOrder = Character.characterProperties.copy();

		xml.set("sprite", '${imageSaveData.directory.length > 0 ? '${imageSaveData.directory}/' : ""}' + imageSaveData.imageName);

		// Look for animations >:D
		var animationList:Array<String> = imageExplorer.animationList.copy();
		animationList.sort((a, b) -> {
			var lengthCompare = a.length - b.length;
			if (lengthCompare != 0) return lengthCompare;

			// Miss animations don't show up as regular if they are the same length as regular >:D
			var aIsMiss = a.toLowerCase().contains("miss");
			var bIsMiss = b.toLowerCase().contains("miss");
			return aIsMiss == bIsMiss ? 0 : (aIsMiss ? 1 : -1);
		});

		var animationsFound:Map<String, String> = [
			"singLEFT" => null,
			"singRIGHT" => null,
			"singUP" => null,
			"singDOWN" => null,
			"idle" => null
		];

		for (anim => found in animationsFound) {
			var animToLookFor:String = StringTools.replace(anim, "sing", "").toLowerCase();
			for (imageAnim in animationList)
				if (imageAnim.toLowerCase().contains(animToLookFor)) {
					animationsFound.set(anim, imageAnim);
					animationList.remove(imageAnim);
					break;
				}
		}
		
		// Add said animations >:D
		for (anim => found in animationsFound) {
			var animXml:Xml = Xml.createElement('anim');
			animXml.attributeOrder = Character.characterAnimProperties;

			animXml.set("name", anim);
			animXml.set("anim", found.getDefault(animationList[0]));

			xml.addChild(animXml);
		}

		// Do the rest only if not atlas (until we make it animations and not symbols >:D)
		if (!imageSaveData.isAtlas) {
			for (imageAnim in animationList) {
				var animXml:Xml = Xml.createElement('anim');
				animXml.attributeOrder = Character.characterAnimProperties;
	
				animXml.set("name", imageAnim);
				animXml.set("anim", imageAnim);
	
				xml.addChild(animXml);
			}
		}

		if (onSave != null) onSave(characterNameTextBox.label.text, imageSaveData, xml);
	}
}