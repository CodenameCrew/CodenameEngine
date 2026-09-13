package funkin.editors.alphabet;

import haxe.io.Path;
import haxe.xml.Access;
import funkin.game.Character;
import funkin.editors.EditorTreeMenu;
import funkin.options.type.NewOption;
import funkin.options.type.FolderOption;
import funkin.options.type.TextOption;
import funkin.options.type.OptionType;

class AlphabetSelection extends EditorTreeMenu {
	override function create() {
		super.create();
		DiscordUtil.call("onEditorTreeLoaded", ["Alphabet Editor"]);
		addMenu(new AlphabetSelectionScreen());
	}
}

class AlphabetSelectionScreen extends EditorTreeMenuScreen {
	public function new() {
		super('editor.alphabet.name', 'editor.alphabet.selection.desc', 'editor.alphabet.selection.', 'newTypeface', 'newTypefaceDesc', () -> {
			parent.openSubState(new UIWarningSubstate(translate('warnings.notImplemented-title'), translate('warnings.notImplemented-body'), [
				{label: TU.translate("editor.ok"), color: 0xFFFF0000, onClick: (t) -> {}}
			]));
		});

		var modsList:Array<String> = getAlphabetList();

		function generateList(modsList:Array<String>, folderPath:String = ""):Array<FlxSprite> {
			var list:Array<FlxSprite> = [];

			for (char in modsList) {
				if (char.endsWith("/")) {
					var folderName = CoolUtil.getFilename(char.substr(0, char.length-1));

					list.push(new FolderOption(folderName + ' >', getID('acceptFolder'), () -> {
						var newModsList = getAlphabetList(char);
						var newList:Array<FlxSprite> = generateList(newModsList, folderPath + folderName + "/");
						parent.addMenu(new EditorTreeMenuScreen(folderPath + folderName, translate('desc-folder', [folderPath + folderName + "/"]), newList));
					}));
				}
				else {
					list.push(new AlphabetIconOption(char, getID('acceptTypeface'), folderPath + char, () -> FlxG.switchState(new AlphabetEditor(folderPath + char))));
				}
			}

			return list;
		}

		for (o in generateList(modsList)) add(o);
	}

	// this is a duplicate of Character.getList, but using that would cause confusion and yea
	public function getAlphabetList(folder:String = 'data/alphabet/'):Array<String> {
		var list:Array<String> = [];
		for (path in Paths.getFolderDirectories(folder, true, BOTH)) {
			if(!path.endsWith("/")) path += "/";
			list.push(path);
		}
		for (path in Paths.getFolderContent(folder, true, BOTH))
			if (Path.extension(path) == "xml")
				list.push(CoolUtil.getFilename(path));
		return list;
	}
}

class AlphabetIconOption extends TextOption {
	public var iconSpr:FlxSprite;

	public function new(name:String, desc:String, typeface:String, callback:Void->Void) {
		super(name, desc, callback);

		var xml = Xml.parse(Assets.getText(Paths.xml('alphabet/$typeface'))).firstElement();
		var spritesheet = null;
		for (node in xml.elements()) {
			if (node.nodeName == "spritesheet") {
				spritesheet = node.firstChild().nodeValue.trim();
				break;
			}
		}

		// todo fix crash if invalid spritesheet;

		iconSpr = new FlxSprite();
		iconSpr.frames = Paths.getFrames(spritesheet);
		iconSpr.antialiasing = true;
		var frameToUse = iconSpr.frames.frames[0];
		for (frame in iconSpr.frames.frames) {
			if (frame.name.toUpperCase().startsWith("A")) {
				frameToUse = frame;
				break;
			}
		}
		iconSpr.frame = frameToUse;
		if (xml.get("colorMode") == "offsets") {
			iconSpr.colorTransform.color = -1;
		}
		iconSpr.setPosition(90 - iconSpr.width - 20, (__text.height - iconSpr.height) / 2);
		add(iconSpr);

		__text.x = 100;
	}
}