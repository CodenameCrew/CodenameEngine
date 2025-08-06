package funkin.editors.character;

import haxe.xml.Printer;
import funkin.game.Character;
import funkin.editors.ui.UIImageExplorer.ImageSaveData;
import funkin.editors.EditorTreeMenu;
import funkin.options.type.IconOption;
import funkin.options.type.NewOption;
import funkin.options.type.TextOption;
import funkin.options.type.OptionType;

class CharacterSelection extends EditorTreeMenu {
	override function create() {
		super.create();
		DiscordUtil.call("onEditorTreeLoaded", ["Character Editor"]);
		addMenu(new CharacterSelectionScreen());
	}
}

class CharacterSelectionScreen extends EditorTreeMenuScreen {
	public var modsList:Array<String> = [];

	public function new() {
		super('editor.character.name', 'characterSelection.desc', 'characterSelection.', 'newCharacter', 'newCharacterDesc', () -> {
			parent.openSubState(new CharacterCreationScreen(createCharacter));
		});

		var isMods:Bool = true;
		modsList = Character.getList(true, true);

		if (modsList.length == 0) {
			modsList = Character.getList(false, true);
			isMods = false;
		}

		function generateList(modsList:Array<String>, isMods:Bool, folderPath:String = ""):Array<FlxSprite> {
			var list:Array<FlxSprite> = [];

			for (char in modsList) {
				if (char.endsWith("/")) {
					var folderName = CoolUtil.getFilename(char.substr(0, char.length-1));

					list.push(new TextOption(folderName, getID('acceptFolder'), ' >', () -> {
						var newModsList = Character.getList(isMods, true, char);
						var newList:Array<FlxSprite> = generateList(newModsList, isMods, folderPath + folderName + "/");
						parent.addMenu(new EditorTreeMenuScreen(folderPath + folderName, translate('desc-folder', [folderPath + folderName + "/"]), newList));
					}));
				}
				else {
					list.push(new IconOption(char, getID('acceptCharacter'), Character.getIconFromCharName(folderPath + char, char), () -> {
						FlxG.switchState(new CharacterEditor(folderPath + char));
					}));
				}
			}

			return list;
		}

		for (o in generateList(modsList, isMods)) add(o);
	}

	public function createCharacter(name:String, imageSaveData:ImageSaveData, xml:Xml) {
		var characterAlreadyExists:Bool = modsList.contains(name);
		if (characterAlreadyExists) {
			parent.openSubState(new UIWarningSubstate(TU.translate('characterCreationScreen.warning.char-exists-title'), TU.translate('characterCreationScreen.warning.char-exists-body'), [
				{label: TU.translate('editor.ok'), color: 0xFFFF0000, onClick: (t) -> {}}
			]));
			return;
		}

		// Save Data file
		var characterPath:String = '${Paths.getAssetsRoot()}/data/characters/${name}.xml';
		CoolUtil.safeSaveFile(characterPath, "<!DOCTYPE codename-engine-character>\n" + Printer.print(xml, true));

		// Save Image files 
		UIImageExplorer.saveFilesGlobal(imageSaveData, '${Paths.getAssetsRoot()}/images/characters');

		// Add to Menu >:D
		var option:IconOption = new IconOption(name, getID('acceptCharacter'), Character.getIconFromCharName(name), () -> {
			FlxG.switchState(new CharacterEditor(name));
		});

		insert(1, option);
	}
}