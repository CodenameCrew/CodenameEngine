package funkin.editors.alphabet;

import haxe.io.Path;
import haxe.xml.Access;
import funkin.game.Character;
import funkin.editors.EditorTreeMenu;
import funkin.options.type.NewOption;
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

		var modsList:Array<String> = [];
		for (file in Paths.getFolderContent('data/alphabet/', true, BOTH)) // mods ? MODS : BOTH
			if (Path.extension(file) == "xml") modsList.push(CoolUtil.getFilename(file));

		for (typeface in modsList)
			add(new AlphabetIconOption(typeface, getID('acceptTypeface'), typeface, () -> FlxG.switchState(new AlphabetEditor(typeface))));
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
				spritesheet = node.firstChild().nodeValue;
				break;
			}
		}

		var useColorOffsets = xml.get("useColorOffsets").getDefault("false") == "true";


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
		if (useColorOffsets) {
			iconSpr.colorTransform.color = -1;
		}
		iconSpr.setPosition(90 - iconSpr.width - 20, (__text.height - iconSpr.height) / 2);
		add(iconSpr);

		__text.x = 100;
	}
}