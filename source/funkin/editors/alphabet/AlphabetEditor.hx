package funkin.editors.alphabet;

import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import funkin.backend.system.framerate.Framerate;
import funkin.backend.utils.XMLUtil.AnimData;
import funkin.editors.ui.UIContextMenu.UIContextMenuOption;
import funkin.game.Character;
import haxe.xml.Access;
import haxe.xml.Printer;

@:access(funkin.menus.ui.Alphabet)
class AlphabetEditor extends UIState {
	static var __typeface:String;

	public static var instance(get, null):AlphabetEditor;

	private static inline function get_instance()
		return FlxG.state is AlphabetEditor ? cast FlxG.state : null;

	public var topMenu:Array<UIContextMenuOption>;
	public var topMenuSpr:UITopMenu;

	public var uiGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	var editorCamera:FlxCamera;
	var uiCamera:FlxCamera;

	public function new(typeface:String) {
		super();
		if (typeface != null) __typeface = typeface;
	}

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("editor.alphabet." + id, args);

	public var brokenWarning:UIText;
	public var tape:Alphabet;
	public var bigLetter:Alphabet;
	public var curLetter:Int = 0;
	public var targetX:Float = 0;

	public var queueReorder:Bool = false;
	public var componentList:UIButtonList<ComponentButton>;

	public var glyphCreateWindow:UISliceSprite;
	public var glyphChar:UITextBox;
	public var confirmGlyph:UIButton;
	public var deleteGlyph:UIButton;

	public var infoWindow:GlyphInfoWindow;
	public var curSelectedComponent:AlphabetComponent = null;
	public var curSelectedData:AlphabetLetterData = null;
	public var outlineIdx:Int = -1;

	public var defaultTmr:Float = 0.0;
	public var charsForDefault:Array<Array<String>> = [];

	public override function create() {
		super.create();

		WindowUtils.suffix = " (" + TU.translate("editor.alphabet.name", true) + ")";
		SaveWarning.selectionClass = AlphabetSelection;
		SaveWarning.saveFunc = () -> {_file_save(null);};

		topMenu = [
			{
				label: translate("topBar.file"),
				childs: [
					{
						label: translate("file.save"),
						keybind: [CONTROL, S],
						onSelect: _file_save
					},
					{
						label: translate("file.saveAs"),
						keybind: [CONTROL, SHIFT, S],
						onSelect: _file_saveas
					},
					null,
					{
						label: translate("file.exit"),
						onSelect: _file_exit
					}
				]
				// TODO: add more options
			},
			{
				label: translate("topBar.edit"),
				childs: [
					// TODO: add redo and undo
					/*{
						label: translate("edit.undo"),
						onSelect: null
					},
					{
						label: translate("edit.redo"),
						onSelect: null
					},*/
					{
						label: translate("glyph.deleteCurGlyph"),
						
					},
					{
						label: translate("edit.editMainData"),
						onSelect: _edit_main
					}
				]
			},
			{
				label: translate("topBar.view"),
				childs: [
					{
						label: translate("view.zoomIn"),
						keybind: [CONTROL, NUMPADPLUS],
						//onSelect: _view_zoomin
					},
					{
						label: translate("view.zoomOut"),
						keybind: [CONTROL, NUMPADMINUS],
						//onSelect: _view_zoomout
					},
					{
						label: translate("view.resetZoom"),
						keybind: [CONTROL, NUMPADZERO],
						//onSelect: _view_zoomreset
					},
				]
			},
			{
				label: translate("topBar.tape"),
				childs: [
					{
						label: translate("tape.MoveTapeLeft"),
						keybind: [LEFT],
						onSelect: _tape_left
					},
					{
						label: translate("tape.MoveTapeRight"),
						keybind: [RIGHT],
						onSelect: _tape_right
					}
				]
			}
		];

		editorCamera = FlxG.camera;

		uiCamera = new FlxCamera();
		uiCamera.bgColor = 0;

		FlxG.cameras.add(uiCamera, false);

		var bg = new FlxSprite(0, 0).makeSolid(Std.int(FlxG.width + 100), Std.int(FlxG.height + 100), 0xFF7f7f7f);
		bg.cameras = [editorCamera];
		bg.scrollFactor.set();
		bg.screenCenter();
		add(bg);

		topMenuSpr = new UITopMenu(topMenu);
		topMenuSpr.cameras = uiGroup.cameras = [uiCamera];
		
		tape = new Alphabet(0, 70, "", __typeface);
		tape.alignment = CENTER;
		tape.renderMode = MONOSPACE;
		add(tape);
		
		bigLetter = new Alphabet(0, 0, "", "<SKIP>");
		bigLetter.copyData(tape);
		bigLetter.alignment = CENTER;
		bigLetter.scale.set(4, 4);
		// TODO: fix the offset issues, when not using updateHitbox
		bigLetter.updateHitbox();
		bigLetter.screenCenter();
		add(bigLetter);

		tape.x = targetX;

		brokenWarning = new UIText(0, 550, FlxG.width, "", 32);
		brokenWarning.alignment = CENTER;
		brokenWarning.color = 0xFFFF6969;
		add(brokenWarning);

		glyphCreateWindow = new UISliceSprite(FlxG.width - 15, topMenuSpr.bHeight + 15, 200, 150, "editors/ui/context-bg");
		glyphCreateWindow.x -= glyphCreateWindow.bWidth;
		uiGroup.add(glyphCreateWindow);

		glyphChar = new UITextBox(glyphCreateWindow.x + 15, glyphCreateWindow.y + 15, "", glyphCreateWindow.bWidth - 30);
		glyphCreateWindow.members.push(glyphChar);

		confirmGlyph = new UIButton(glyphChar.x, glyphChar.y + glyphChar.bHeight + 15, translate("glyph.newGlyph"), function() {
			if (deleteGlyph.selectable) {
				curLetter = tape.manualLetters.indexOf(lastChar) + charsForDefault.length;
				changeLetter(0);
			} else {
				tape.manualLetters.push(lastChar);
				tape.text = "";
				for (def in charsForDefault)
					tape.text += def[Std.int(Math.floor(defaultTmr) % def.length)] + " ";
				tape.text += tape.manualLetters.join(" ");

				for (i in 0...tape.fastGetData(lastChar).components.length) {
					var anim = bigLetter.text + i;
					bigLetter.animation.remove(anim);
					tape.animation.remove(anim);
				}

				tape.letterData.set(lastChar, {
					isDefault: false,
					advance: Math.NaN,
					advanceEmpty: true,
					components: [],
					startIndex: 0
				});

				curLetter = tape.manualLetters.length - 1 + charsForDefault.length;
				changeLetter(0);
			}
		}, glyphChar.bWidth);
		confirmGlyph.selectable = false;
		glyphCreateWindow.members.push(confirmGlyph);

		deleteGlyph = new UIButton(glyphChar.x, confirmGlyph.y + confirmGlyph.bHeight + 5, translate("glyph.deleteGlyph"), function() {
			final charIdx = tape.manualLetters.indexOf(lastChar);

			tape.manualLetters.splice(charIdx, 1);
			tape.text = "";
			for (def in charsForDefault)
				tape.text += def[Std.int(Math.floor(defaultTmr) % def.length)] + " ";
			tape.text += tape.manualLetters.join(" ");

			for (i in 0...tape.fastGetData(lastChar).components.length) {
				var anim = bigLetter.text + i;
				bigLetter.animation.remove(anim);
				tape.animation.remove(anim);
			}
			tape.letterData.remove(lastChar);

			changeLetter((curLetter >= charIdx + charsForDefault.length) ? -1 : 0);
		}, glyphChar.bWidth);
		deleteGlyph.color = FlxColor.RED;
		deleteGlyph.selectable = false;
		glyphCreateWindow.members.push(deleteGlyph);

		infoWindow = new GlyphInfoWindow();
		uiGroup.add(infoWindow);

		componentList = new UIButtonList<ComponentButton>(0, 720 - 170 - 30, 230, 170, "Components:", FlxPoint.get(230, 50), FlxPoint.get(0, 0), 0);
		componentList.dragCallback = (button, oldID, newID) -> {
			queueReorder = true; // not do it for every button reordered
		}
		componentList.addButton.callback = () -> {
			curSelectedComponent = {
				anim: "",
				x: 0,
				y: 0,

				shouldRotate: false,
				angle: 0,
				sin: 0,
				cos: 1,

				scaleX: 1,
				scaleY: 1,
				
				flipX: false,
				flipY: false,

				hasColorMode: false,
				colorMode: bigLetter.colorMode
			};
			curSelectedData.components.push(curSelectedComponent);
			var newButton = new ComponentButton(curSelectedComponent);
			componentList.add(newButton);
			newButton.ID = componentList.buttons.members.length - 1; // readjust it because UIButtonList doesnt generate the id properly
			findOutline();
			infoWindow.updateInfo();
		}

		updateTape();
		uiGroup.add(componentList);

		add(topMenuSpr);
		add(uiGroup);

		if(Framerate.isLoaded) {
			Framerate.fpsCounter.alpha = 0.4;
			Framerate.memoryCounter.alpha = 0.4;
			Framerate.codenameBuildField.alpha = 0.4;
		}

		DiscordUtil.call("onEditorLoaded", ["Alphabet Editor", __typeface]);
	}

	override function destroy() {
		super.destroy();
		if(Framerate.isLoaded) {
			Framerate.fpsCounter.alpha = 1;
			Framerate.memoryCounter.alpha = 1;
			Framerate.codenameBuildField.alpha = 1;
		}
	}

	var lastChar:String = "";
	public override function update(elapsed:Float) {
		super.update(elapsed);

		if (glyphChar.label.text != lastChar) {
			if (glyphChar.label.text == "") {
				lastChar = "";
				confirmGlyph.selectable = false;
				deleteGlyph.selectable = false;
				confirmGlyph.field.text = translate("glyph.newGlyph");
			} else {
				glyphChar.label.text = lastChar = switch (tape.forceCase) {
					case UPPER: glyphChar.label.text.charAt(glyphChar.label.text.length - 1).toUpperCase();
					case LOWER: glyphChar.label.text.charAt(glyphChar.label.text.length - 1).toLowerCase();
					case NONE: glyphChar.label.text.charAt(glyphChar.label.text.length - 1);
				};
				
				confirmGlyph.selectable = true;
				deleteGlyph.selectable = tape.manualLetters.contains(lastChar);
				confirmGlyph.field.text = translate(deleteGlyph.selectable ? "glyph.editGlyph" : "glyph.newGlyph");
			}
		}

		if (queueReorder) {
			queueReorder = false;
			var outlines = [];
			var newList = [];
			for (button in componentList.buttons.members) {
				var com = button.component;
				if (com.outIndex != null) {
					var out = curSelectedData.components[com.outIndex];
					out.refIndex = newList.length;
					com.outIndex = outlines.length;
					outlines.push(out);
				}
				newList.push(com);
			}
			curSelectedData.components = outlines.concat(newList);

			findOutline();
			for (i in 0...curSelectedData.components.length) {
				var anim = bigLetter.text + i;
				bigLetter.animation.remove(anim);
				tape.animation.remove(anim);
			}
		}

		if (currentFocus == null) {
			if(FlxG.keys.justPressed.ANY)
				UIUtil.processShortcuts(topMenu);
			
			if(curSelectedComponent != null) {
				if(FlxG.keys.pressed.K) {
					curSelectedComponent.y -= 100 * elapsed;
				}
				if(FlxG.keys.pressed.I) {
					curSelectedComponent.y += 100 * elapsed;
				}
				if(FlxG.keys.pressed.L) {
					curSelectedComponent.x -= 100 * elapsed;
				}
				if(FlxG.keys.pressed.J) {
					curSelectedComponent.x += 100 * elapsed;
				}
			}
		}


		var lastIdx = Math.floor(defaultTmr);
		defaultTmr += elapsed * 0.5;
		if (lastIdx != (lastIdx = Math.floor(defaultTmr))) {
			tape.text = "";
			for (def in charsForDefault)
				tape.text += def[Std.int(lastIdx % def.length)] + " ";
			tape.text += tape.manualLetters.join(" ");
		}
		tape.x = lerp(tape.x, targetX, 0.25);
	}

	function updateTape() {
		charsForDefault = [[], [], []];

		for (i in 33...127) {
			var letter = String.fromCharCode(i);
			if (tape.manualLetters.contains(letter)) continue;

			var data = tape.fastGetData(letter);
			for (i => com in data.components) {
				if (tape.fastGetLetterAnim(letter, data, com, i) == null)
					continue;
			}

			if (i >= 'A'.code && i <= 'Z'.code && tape.defaults[CaseMode.UPPER] != null)
				charsForDefault[CaseMode.UPPER].push(letter);
			else if (i >= 'a'.code && i <= 'z'.code && tape.defaults[CaseMode.LOWER] != null)
				charsForDefault[CaseMode.LOWER].push(letter);
			else if (tape.defaults[CaseMode.NONE] != null)
				charsForDefault[CaseMode.NONE].push(letter);
		}

		var i = charsForDefault.length - 1;
		while (i >= 0) {
			if (charsForDefault[i].length <= 0)
				charsForDefault.splice(i, 1);
			--i;
		}

		tape.text = "";
		for (def in charsForDefault)
			tape.text += def[Math.floor(defaultTmr % def.length)] + " ";
		tape.text += tape.manualLetters.join(" ");
		changeLetter(0);
	}

	function changeLetter(inc:Int) {
		curLetter = CoolUtil.positiveModuloInt(curLetter + inc, tape.manualLetters.length + charsForDefault.length);
		targetX = FlxG.width * 0.5 - tape.defaultAdvance * (0.5 + curLetter * 2);
		bigLetter.text = (curLetter < charsForDefault.length) ? charsForDefault[curLetter][0] : tape.manualLetters[curLetter - charsForDefault.length];
		glyphChar.label.text = bigLetter.text;
		bigLetter.updateHitbox();
		bigLetter.screenCenter();

		checkForFailed();
		
		while (componentList.buttons.members.length > 0)
			componentList.remove(componentList.buttons.members[0]);
		for (i in curSelectedData.startIndex...curSelectedData.components.length) {
			var newButton = new ComponentButton(curSelectedData.components[i]);
			componentList.add(newButton);
			newButton.ID = componentList.buttons.members.length - 1; // readjust it because UIButtonList doesnt generate the id properly
		}
		curSelectedComponent = (curSelectedData.components.length > 0) ? curSelectedData.components[curSelectedData.startIndex] : null;
		findOutline();
		infoWindow.updateInfo();
	}

	public function findOutline() {
		outlineIdx = -1;
		for (i in curSelectedData.startIndex...curSelectedData.components.length) {
			var com = curSelectedData.components[i];
			if (com.outIndex != null)
				outlineIdx = com.outIndex;
			if (com == curSelectedComponent)
				break;
		}
		++outlineIdx;
	}

	public function checkForFailed() {
		bigLetter.failedLetters.remove(bigLetter.text);
		curSelectedData = bigLetter.fastGetData(bigLetter.text);
		brokenWarning.text = "";
		bigLetter.draw();
		if (!bigLetter.failedLetters.contains(bigLetter.text))
			return false;

		for (i in 0...curSelectedData.components.length) {
			var com = curSelectedData.components[i];
			if (!bigLetter.animation.exists(bigLetter.text + Std.string(i)))
				brokenWarning.text += " Unable to find: " + com.anim + "\n";
		}
		return true;
	}

	function _tape_left(_) {
		changeLetter(-1);
	}
	function _tape_right(_) {
		changeLetter(1);
	}

	function buildAlphabet() {
		var tempPrettyPrint = true;
		var xmlThingYea:String = "<!DOCTYPE codename-engine-alphabet-font>\n" + Printer.print(tape.buildXML(), tempPrettyPrint);
		return tempPrettyPrint ? xmlThingYea : xmlThingYea.replace("\n", "");
	}

	function _file_save(_) {
		#if sys
		CoolUtil.safeSaveFile(
			'${Paths.getAssetsRoot()}/data/alphabet/${__typeface}.xml',
			buildAlphabet()
		);
		#else
		_file_saveas(_);
		#end
	}

	function _file_saveas(_) {
		openSubState(new SaveSubstate(buildAlphabet(), {
			defaultSaveFile: '${__typeface}.xml'
		}));
	}

	function _file_exit(_) {
		/*if (undos.unsaved) SaveWarning.triggerWarning();
		else */FlxG.switchState(new AlphabetSelection());
	}

	function _edit_main(_) {
		FlxG.state.openSubState(new AlphabetMainDataScreen());
	}
}

/*

/===============\
| Components    |
|===============|
|[ Component 1 ]|
|[ Component 2 ]|
|[ Component 3 ]|
|[ Component 4 ]|
|[ Component 5 ]|
|[ Add component]|
\===============/

*/

class ComponentButton extends UIButton {
	public var component:AlphabetComponent;

	public var selected:Bool = false;

	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public function new(component:AlphabetComponent) {
		super(0, 0, component.anim, function() {
			AlphabetEditor.instance.curSelectedComponent = component;
			AlphabetEditor.instance.findOutline();
			AlphabetEditor.instance.infoWindow.updateInfo();
		}, 230, 50);
		this.component = component;

		deleteButton = new UIButton(bWidth - 32 - 10, 0, "", function() {
			var data = AlphabetEditor.instance.curSelectedData;

			var outlineDrop = (component.outIndex != null) ? 1 : 0;
			var componentIndex = data.components.indexOf(component);
			for (i in 0...data.components.length) {
				var nextCompon = data.components[i];
				var anim = AlphabetEditor.instance.bigLetter.text + i;
				AlphabetEditor.instance.bigLetter.animation.remove(anim);
				AlphabetEditor.instance.tape.animation.remove(anim);

				if (i > componentIndex && nextCompon.outIndex != null) {
					--data.components[nextCompon.outIndex].refIndex;
					nextCompon.outIndex -= outlineDrop;
				}
			}

			if (component.outIndex != null) {
				data.components.splice(component.outIndex, 1);
				--data.startIndex;
			}

			data.components.remove(component);
			AlphabetEditor.instance.curSelectedComponent = (AlphabetEditor.instance.curSelectedComponent == component) ? null : AlphabetEditor.instance.curSelectedComponent;
			AlphabetEditor.instance.findOutline();
			AlphabetEditor.instance.infoWindow.updateInfo();

			AlphabetEditor.instance.componentList.remove(this);
		}, 32);
		deleteButton.color = FlxColor.RED;
		deleteButton.autoAlpha = false;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(deleteButton.x + (15/2), deleteButton.y + 8).loadGraphic(Paths.image('editors/delete-button'));
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		deleteButton.y = y + 10;
		deleteIcon.x = deleteButton.x + (15/2);
		deleteIcon.y = deleteButton.y + 8;
	}
}