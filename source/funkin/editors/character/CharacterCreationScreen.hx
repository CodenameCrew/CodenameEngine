package funkin.editors.character;

import haxe.xml.Printer;
import funkin.game.Character;
import funkin.editors.ui.UIImageExplorer.ImageSaveData;
import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;

class CharacterCreationScreen extends UISubstateWindow {
	private var onSave:(String, Array<ImageSaveData>, Xml)-> Void = null;

	public var characterNameTextBox:UITextBox;
	public var imageExplorer:UIImageExplorer;

	public var imageList:UIImageList;

	public var saveButton:UIButton;
	public var closeButton:UIButton;

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("characterCreationScreen." + id, args);

	public function new(?onSave:(String, Array<ImageSaveData>, Xml)->Void) {
		super();
		if (onSave != null)
			this.onSave = onSave;
	}

	public override function create()
	{
		winTitle = translate("win-title");

		winWidth = 660;
		winHeight = 520;

		super.create();

		function addLabelOn(ui:UISprite, text:String):UIText
		{
			var text:UIText = new UIText(ui.x, ui.y - 24, 0, text);
			ui.members.push(text);
			return text;
		}

		characterNameTextBox = new UITextBox(windowSpr.x + 20, windowSpr.y + 30 + 16 + 20, "character", 320);
		characterNameTextBox.onChange = (_) ->
		{
			checkRequired();
		};
		add(characterNameTextBox);
		addLabelOn(characterNameTextBox, "").applyMarkup(translate("charName"), [new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]);

		imageList = new UIImageList(10, 190, null, () -> {checkRequired();});
		var listTxt = addLabelOn(imageList, "");
		listTxt.applyMarkup(
			"Character Image Files $* At Least One Required$",
			[new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFAD1212), "$")]
		);
		listTxt.x += 30;
		add(imageList);

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, TU.translate("editor.saveClose"), function() {
			close();
			createCharacter();
		}, 125);
		saveButton.selectable = false;
		add(saveButton);

		closeButton = new UIButton(saveButton.x - 20 - saveButton.bWidth, saveButton.y, TU.translate("editor.cancel"), function()
		{
			close();
		}, 125);
		add(closeButton);
		closeButton.color = 0xFFFF0000;
	}

	public function checkRequired() {
		saveButton.selectable = characterNameTextBox.label.text.length > 0 && imageList.getSaveDatas().length > 0 && !CoolUtil.isMapEmpty(imageList.getSaveDatas()[0].imageFiles);
	}

	public function createCharacter() {
		var imageSaveData = imageList.getSaveDatas();

		var xml:Xml = Xml.createElement("character");
		xml.attributeOrder = Character.characterProperties.copy();

		if(imageSaveData.length == 1){
			var imgData = imageSaveData[0];
			xml.set("sprite", '${imgData.directory.length > 0 ? '${imgData.directory}/' : ""}' + imgData.imageName);
		} else {
			for(data in imageSaveData){
				var sheetElement = Xml.createElement("spritesheet");
				sheetElement.set("path", 'characters/${data.directory.length > 0 ? '${data.directory}/' : ""}' + data.imageName);
				xml.addChild(sheetElement);
			}
		}

		// Look for animations >:D
		var animationList:Array<String> = imageList.getAnimList();
		animationList.sort((a, b) -> {
			var lengthCompare = a.length - b.length;
			if (lengthCompare != 0)
				return lengthCompare;

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

		for (anim => found in animationsFound)
		{
			var animToLookFor:String = StringTools.replace(anim, "sing", "").toLowerCase();
			for (imageAnim in animationList)
				if (imageAnim.toLowerCase().contains(animToLookFor))
				{
					animationsFound.set(anim, imageAnim);
					animationList.remove(imageAnim);
					break;
				}
		}

		// Add said animations >:D
		for (anim => found in animationsFound)
		{
			var animXml:Xml = Xml.createElement('anim');
			animXml.attributeOrder = Character.characterAnimProperties;

			animXml.set("name", anim);
			animXml.set("anim", found.getDefault(animationList[0]));

			xml.addChild(animXml);
		}

		if (onSave != null)
			onSave(characterNameTextBox.label.text, imageSaveData, xml);
	}
}
