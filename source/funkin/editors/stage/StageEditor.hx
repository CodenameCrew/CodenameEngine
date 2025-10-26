package funkin.editors.stage;

import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import funkin.backend.system.framerate.Framerate;
import funkin.backend.utils.XMLUtil.AnimData;
import funkin.editors.stage.elements.*;
import funkin.editors.stage.elements.StageSpriteButton.StageSpriteEditScreen;
import funkin.editors.ui.UIContextMenu.UIContextMenuOption;
import funkin.editors.extra.AxisGizmo;
import funkin.game.Character;
import funkin.game.Stage;
import haxe.xml.Access;
import haxe.xml.Printer;
import lime.ui.MouseCursor;
import openfl.ui.Mouse;

using funkin.backend.utils.MatrixUtil;

@:access(flixel.FlxSprite)
class StageEditor extends UIState {
	static var __stage:String;
	public var stage:Stage;

	private var _point:FlxPoint = new FlxPoint();

	public static var instance(get, null):StageEditor;

	private static inline function get_instance()
		return FlxG.state is StageEditor ? cast FlxG.state : null;

	public var topMenu:Array<UIContextMenuOption>;
	public var topMenuSpr:UITopMenu;

	public var uiGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	public var stageSpritesWindow:StageSpritesWindow;

	public var xmlMap:Map<FlxObject, Access> = new Map<FlxObject, Access>();

	public var chars:Array<Character> = [];
	public var charMap:Map<String, Character> = [];

	public var stageCamera:FlxCamera;
	//public var guideCamera:FlxCamera;
	public var uiCamera:FlxCamera;

	public var gizmosCamera:FlxCamera;
	public var axisGizmo:AxisGizmo;

	public var selection:Selection = new Selection();
	public var mouseMode:StageEditorMouseMode = NONE;
	public var mousePoint:FlxPoint = new FlxPoint();
	public var clickPoint:FlxPoint = new FlxPoint();
	public var storedPos:FlxPoint = new FlxPoint();
	public var storedScale:FlxPoint = new FlxPoint();
	public var storedSkew:FlxPoint = new FlxPoint();
	public var storedAngle:Float = 0;
	public var angleOffset:Float = 0;

	public var showCharacters:Bool = true;

	public static inline var SPRITE_WINDOW_WIDTH:Int = 400;
	public static inline var SPRITE_WINDOW_BUTTON_HEIGHT:Int = 64;

	public var undos:UndoList<StageChange> = new UndoList<StageChange>();

	public inline static function exID(id:String) {
		return "stageEditor." + id;
	}

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("stageEditor." + id, args);

	public function new(stage:String) {
		super();
		if (stage != null) __stage = stage;
	}

	public override function create() {
		super.create();

		WindowUtils.suffix = " (" + TU.translate("editor.stage.name") + ")";
		SaveWarning.selectionClass = StageSelection;
		SaveWarning.saveFunc = () -> {_file_save(null);};

		topMenu = [
			{
				label: translate("topBar.file"),
				childs: [
					{
						label: translate("file.save"),
						keybind: [CONTROL, S],
						onSelect: _file_save,
					},
					{
						label: translate("file.saveAs"),
						keybind: [CONTROL, SHIFT, S],
						onSelect: _file_saveas,
					},
					null,
					{
						label: translate("file.exit"),
						onSelect: _file_exit
					}
				]
			},
			{
				label: translate("topBar.edit"),
				childs: [
					{
						label: translate("edit.undo"),
						keybind: [CONTROL, Z],
						onSelect: _edit_undo,
					},
					{
						label: translate("edit.redo"),
						keybind: [CONTROL, SHIFT, Z],
						onSelect: _edit_redo,
					},
					null,
					{
						label: translate("edit.editStageInfo"),
						onSelect: (_) -> {
							openSubState(new UISoftcodedWindow(
								"layouts/stage/stageInfoScreen",
								[
									"winTitle" => "Editing Stage Info",
									"hasSaveButton" => true,
									"hasCloseButton" => true,
									"stage" => stage,
									"Stage" => Stage,
									"exID" => exID,
									"CEditInfo" => StageChange.CEditInfo,
									"translate" => function (id:String, ?args:Array<Dynamic>) {
										return TU.translate("stageInfoScreen." + id, args);
									}
								]
							));
						},
					}
				]
			},
			{
				label: translate("topBar.select"),
				childs: [
					{
						label: translate("select.all"),
						keybind: [CONTROL, A],
						onSelect: (_) -> _select_all(_),
					},
					{
						label: translate("select.deselect"),
						keybind: [CONTROL, D],
						onSelect: (_) -> _select_deselect(_),
					},
					{
						label: translate("select.inverse"),
						keybind: [CONTROL, SHIFT, I],
						onSelect: (_) -> _select_inverse(_),
					},
				]
			},
			{
				label: translate("topBar.view"),
				childs: [
					{
						label: translate("view.zoomIn"),
						keybind: [CONTROL, NUMPADPLUS],
						onSelect: _view_zoomin
					},
					{
						label: translate("view.zoomOut"),
						keybind: [CONTROL, NUMPADMINUS],
						onSelect: _view_zoomout
					},
					{
						label: translate("view.zoomReset"),
						keybind: [CONTROL, NUMPADZERO],
						onSelect: _view_zoomreset
					},
					null,
					{
						label: translate("view.focusDad"),
						//keybind: [CONTROL, NUMPADZERO],
						onSelect: _view_focusdad
					},
					{
						label: translate("view.focusGF"),
						//keybind: [CONTROL, NUMPADZERO],
						onSelect: _view_focusgf
					},
					{
						label: translate("view.focusBF"),
						//keybind: [CONTROL, NUMPADZERO],
						onSelect: _view_focusbf
					},
					// TODO: add support for custom character focus
				]
			},
			{
				label: translate("topBar.editor"),
				childs: [
					{
						label: translate("editor.showCharacters"),
						//keybind: [CONTROL, NUMPADMINUS],
						onSelect: _editor_showCharacters,
						icon: showCharacters ? 1 : 0
					}
				]
			},
		];

		stageCamera = FlxG.camera;

		gizmosCamera = new FlxCamera();
		gizmosCamera.bgColor = 0;
		FlxG.cameras.add(gizmosCamera, false);

		axisGizmo = new AxisGizmo();
		axisGizmo.cameras = [gizmosCamera];
		add(axisGizmo);

		uiCamera = new FlxCamera();
		uiCamera.bgColor = 0;

		uiCameras = [uiCamera];

		//FlxG.cameras.add(guideCamera, false);
		FlxG.cameras.add(uiCamera, false);

		// Load from xml
		var order:Array<Dynamic> = [];
		var orderNodes:Array<Access> = [];

		loadStage(order, orderNodes);

		// for (sprite => node in xmlMap)
		// 	sprite.cameras = [stageCamera];

		topMenuSpr = new UITopMenu(topMenu);
		topMenuSpr.cameras = uiGroup.cameras = [uiCamera];

		stageSpritesWindow = new StageSpritesWindow(Std.int(FlxG.width - 400), 25);
		for (i=>sprite in order) {
			var xml = (sprite != null) ? xmlMap.get(sprite) : orderNodes[i];
			if (xml != null) {
				if (sprite is Character) {
					var char:Character = cast sprite;
					var button = new StageCharacterButton(0,0, char, xml);
					char.extra.set(exID("button"), button);
					stageSpritesWindow.add(button);
				} else if (sprite is FunkinSprite) {
					var sprite:FunkinSprite = cast sprite;
					var type = sprite.extra.get(exID("type"));
					var button:StageElementButton = (type == "box" || type == "solid") ? new StageSolidButton(0,0, sprite, xml) : new StageSpriteButton(0,0, sprite, xml);
					sprite.extra.set(exID("button"), button);
					stageSpritesWindow.add(button);
				} else if(sprite == null) {
					var basic = new FlxBasic(); // prevent awkward layering
					insert(i, basic);
					var button = new StageUnknownButton(0,0, basic, xml);
					stageSpritesWindow.add(button);
				}
			}
		}
		uiGroup.add(stageSpritesWindow);

		add(topMenuSpr);
		add(uiGroup);

		if(Framerate.isLoaded) {
			Framerate.fpsCounter.alpha = 0.4;
			Framerate.memoryCounter.alpha = 0.4;
			Framerate.codenameBuildField.alpha = 0.4;
		}

		// DiscordUtil.call("onEditorLoaded", ["Stage Editor", __stage]);
	}

	function loadStage(order:Array<Dynamic>, orderNodes:Array<Access>) {
		stage = new Stage(__stage, this, false);
		stage.onXMLLoaded = function(xml:Access, elems:Array<Access>) {
			return elems;
		}
		stage.onNodeFinished = function(node:Access, sprite:Dynamic) {
			if(sprite is FlxSprite) {
				sprite.moves = false;
			}
			if (sprite is FunkinSprite) {
				sprite.animEnabled = false;
				//sprite.zoomFactorEnabled = false;
			}
		}
		stage.onNodeLoaded = function(node:Access, sprite:Dynamic):Dynamic {
			var parent = new Access(node.x.parent);
			//var name = "";
			//trace(node, sprite);
			if(sprite is FlxSprite) {
				//sprite.forceIsOnScreen = true; // hack
			}
			if(sprite is FunkinSprite) {
				var sprite:FunkinSprite = cast sprite;
				//name = sprite.name;
				sprite.extra.set(exID("node"), node);
				sprite.extra.set(exID("type"), node.name);
				sprite.extra.set(exID("imageFile"), '${node.getAtt("sprite").getDefault(sprite.name)}');
				sprite.extra.set(exID("parentNode"), parent);
				sprite.extra.set(exID("highMemory"), parent.name == "highMemory");
				sprite.extra.set(exID("lowMemory"), parent.name == "lowMemory");
				//sprite.active = false;
			}
			if(sprite is StageCharPos)
				sprite = prepareCharacter(cast sprite, node);
			order.push(sprite);
			orderNodes.push(node);
			xmlMap.set(sprite, node);

			return sprite;
		}
		stage.loadXml(stage.stageXML, true);

		if (!charMap.exists("NO_DELETE_girlfriend")) {
			var xml = Xml.createElement("girlfriend");
			stage.stageXML.x.addChild(xml);
			var node = new Access(xml);
			var sprite = prepareCharacter(stage.characterPoses["girlfriend"], node);
			order.push(sprite);
			orderNodes.push(node);
			xmlMap.set(sprite, node);
		}
		if (!charMap.exists("NO_DELETE_dad")) {
			var xml = Xml.createElement("dad");
			stage.stageXML.x.addChild(xml);
			var node = new Access(xml);
			var sprite = prepareCharacter(stage.characterPoses["dad"], node);
			order.push(sprite);
			orderNodes.push(node);
			xmlMap.set(sprite, node);
		}
		if (!charMap.exists("NO_DELETE_boyfriend")) {
			var xml = Xml.createElement("boyfriend");
			stage.stageXML.x.addChild(xml);
			var node = new Access(xml);
			var sprite = prepareCharacter(stage.characterPoses["boyfriend"], node);
			order.push(sprite);
			orderNodes.push(node);
			xmlMap.set(sprite, node);
		}

		add(stage);

		setZoom(stage.defaultZoom);
	}

	function prepareCharacter(charPos:StageCharPos, node:Access):Character {
		var parent = new Access(node.x.parent);

		var charName = switch(node.name) {
			case "dad" | "opponent": Flags.DEFAULT_OPPONENT;
			case "gf" | "girlfriend": Flags.DEFAULT_GIRLFRIEND;
			case "bf" | "boyfriend" | "player": Flags.DEFAULT_CHARACTER;
			default: (charPos.flipX) ? Flags.DEFAULT_CHARACTER : Flags.DEFAULT_OPPONENT;
		}

		var char = new Character(0,0, charName, charPos.flipX, true);
		charName = switch(node.name) {
			case "dad" | "opponent": "NO_DELETE_dad";
			case "gf" | "girlfriend": "NO_DELETE_girlfriend";
			case "bf" | "boyfriend" | "player": "NO_DELETE_boyfriend";
			default: node.att.name;
		}
		char.name = charName;
		char.debugMode = true;
		// Play first anim, and make it the last frame
		var animToPlay = char.getAnimOrder()[0];
		char.playAnim(animToPlay, true, NONE);
		var lastIndx = (char.animateAtlas != null) ?
			char.animateAtlas.anim.length - 1 :
			char.animation.curAnim.numFrames - 1;
		char.playAnim(animToPlay, true, NONE, false, lastIndx);
		char.stopAnimation();

		// Add it to the stage
		char.visible = true;
		char.alpha = 0.75;

		char.extra.set(exID("node"), node);
		char.extra.set(exID("spacingX"), charPos.charSpacingX);
		char.extra.set(exID("spacingY"), charPos.charSpacingY);
		char.extra.set(exID("camX"), charPos.camxoffset);
		char.extra.set(exID("camY"), charPos.camyoffset);

		char.extra.set(exID("parentNode"), parent);
		char.extra.set(exID("highMemory"), parent.name == "highMemory");
		char.extra.set(exID("lowMemory"), parent.name == "lowMemory");

		chars.push(char);
		stage.applyCharStuff(char, charPos.name, 0);
		charMap[charName] = char;

		remove(charPos, true);
		charPos.destroy();
		
		return char;
	}

	override function destroy() {
		super.destroy();
		nextScroll = FlxDestroyUtil.destroy(nextScroll);
		if(Framerate.isLoaded) {
			Framerate.fpsCounter.alpha = 1;
			Framerate.memoryCounter.alpha = 1;
			Framerate.codenameBuildField.alpha = 1;
		}
	}

	//private var movingCam:Bool = false;
	//private var camDragSpeed:Float = 1.2;

	private var movedTillRel:FlxPoint = FlxPoint.get(0,0);
	private var nextScroll:FlxPoint = FlxPoint.get(0,0);

	public override function update(elapsed:Float) {
		super.update(elapsed);

		if (true) {
			if(FlxG.keys.justPressed.ANY)
				UIUtil.processShortcuts(topMenu);
		}

		//if (character != null)
		//	characterPropertiresWindow.characterInfo.text = '${character.getNameList().length} Animations\nFlipped: ${character.flipX}\nSprite: ${character.sprite}\nAnim: ${character.getAnimName()}\nOffset: (${character.frameOffset.x}, ${character.frameOffset.y})';

		currentCursor = ARROW;

		FlxG.mouse.getWorldPosition(stageCamera, mousePoint);
		if ((!stageSpritesWindow.hovered && !stageSpritesWindow.dragging) && !topMenuSpr.hovered) {
			if (FlxG.mouse.wheel != 0) {
				zoom += 0.25 * FlxG.mouse.wheel;
				updateZoom();
			}

			var prevMode = mouseMode;

			// TODO: make this work with multiple selections
			if(selection.length == 1) {
				for(sprite in selection) {
					if(sprite is FunkinSprite) {
						handleSelection(cast sprite);
					}
				}
			}

			//if (FlxG.mouse.justReleasedRight) {
			//	closeCurrentContextMenu();
			//	openContextMenu(topMenu[2].childs);
			//}

			if (mouseMode == NONE && prevMode == NONE) {
				if (FlxG.mouse.pressed) {
					var x = FlxG.mouse.deltaScreenX;
					var y = FlxG.mouse.deltaScreenY;
					movedTillRel.x += x; movedTillRel.y += y;
					nextScroll.set(nextScroll.x - x, nextScroll.y - y);
					currentCursor = HAND;
				}

				if (FlxG.mouse.justReleased) {
					if (Math.abs(movedTillRel.x) < 16 && Math.abs(movedTillRel.y) < 16) {
						var point = FlxG.mouse.getWorldPosition(stageCamera, _point);
						var sprites = getRealSprites();
						for (i in 0...sprites.length) {
							var sprite = sprites[sprites.length - i - 1];
							//if(sprite.animateAtlas != null) continue;

							calcSpriteBounds(sprite);
							//trace("Sprite: " + sprite);
							//trace("Sprite bounds: " + sprite.extra.get(exID("bounds")));
							if (cast(sprite.extra.get(exID("bounds")), FlxRect).containsPoint(point)) {
								selectSprite(sprite); break;
							}
						}
					}
					movedTillRel.set();
				}
			}
		}/* else if (!FlxG.mouse.pressed)
			currentCursor = ARROW;*/

		stageCamera.scroll.set(
			lerp(stageCamera.scroll.x, nextScroll.x, 0.35),
			lerp(stageCamera.scroll.y, nextScroll.y, 0.35)
		);

		stageCamera.zoom = lerp(stageCamera.zoom, __camZoom, 0.125);

		WindowUtils.prefix = undos.unsaved ? "* " : "";
		SaveWarning.showWarning = undos.unsaved;
	}

	// TOP MENU OPTIONS
	#if REGION
	function _file_exit(_) {
		if (undos.unsaved) SaveWarning.triggerWarning();
		else FlxG.switchState(new StageSelection());
	}

	function _file_save(_) {
		#if sys
		UIState.playEditorSound(Flags.DEFAULT_EDITOR_SAVE_SOUND);
		CoolUtil.safeSaveFile(
			'${Paths.getAssetsRoot()}/data/stages/${__stage}.xml',
			buildStage()
		);
		undos.save();
		#else
		_file_saveas(_);
		#end
	}

	function _file_saveas(_) {
		UIState.playEditorSound(Flags.DEFAULT_EDITOR_SAVE_SOUND);
		openSubState(new SaveSubstate(buildStage(), {
			defaultSaveFile: '${__stage}.xml'
		}));
		undos.save();
	}

	function _sprite_new(_) {
		var node:Access = new Access(Xml.createElement("sprite"));
		stage.stageXML.x.addChild(node.x);
		node.att.name = "sprite_" + stageSpritesWindow.buttons.members.length;

		var sprite:FunkinSprite = new FunkinSprite();
		insert(members.indexOf(stage), sprite);
		sprite.extra.set(exID("node"), node);
		sprite.extra.set(exID("type"), node.name);
		sprite.extra.set(exID("imageFile"), '');
		sprite.extra.set(exID("parentNode"), stage.stageXML.x);
		sprite.extra.set(exID("highMemory"), false);
		sprite.extra.set(exID("lowMemory"), false);
		sprite.antialiasing = true;
		xmlMap.set(sprite, node);

		var button:StageSpriteButton = new StageSpriteButton(0, 0, sprite, node);
		sprite.extra.set(exID("button"), button);
		stageSpritesWindow.add(button);

		var substate = new StageSpriteEditScreen(button);
		substate.newSprite = true;
		openSubState(substate);
	}

	function _character_new(_) {
		var node:Access = new Access(Xml.createElement("char"));
		stage.stageXML.x.addChild(node.x);
		node.att.name = "character_" + stageSpritesWindow.buttons.members.length;

		var char = new Character(0,0, "bf", false, true);
		char.name = node.att.name;
		char.debugMode = true;
		// Play first anim, and make it the last frame
		var animToPlay = char.getAnimOrder()[0];
		char.playAnim(animToPlay, true, NONE);
		var lastIndx = (char.animateAtlas != null) ?
			char.animateAtlas.anim.length - 1 :
			char.animation.curAnim.numFrames - 1;
		char.playAnim(animToPlay, true, NONE, false, lastIndx);
		char.stopAnimation();

		// Add it to the stage
		char.visible = true;
		char.alpha = 0.75;

		char.extra.set(exID("node"), node);
		char.extra.set(exID("spacingX"), 20);
		char.extra.set(exID("spacingY"), 0);
		char.extra.set(exID("camX"), 0);
		char.extra.set(exID("camY"), 0);

		char.extra.set(exID("parentNode"), stage.stageXML);
		char.extra.set(exID("highMemory"), false);
		char.extra.set(exID("lowMemory"), false);
		xmlMap.set(char, node);
		chars.push(char);

		insert(members.indexOf(stage), char);
		charMap[node.att.name] = char;

		var button = new StageCharacterButton(0,0, char, node);
		char.extra.set(exID("button"), button);
		stageSpritesWindow.add(button);
	}

	function saveToXml(xml:Xml, name:String, value:Dynamic, ?defaultValue:Dynamic) {
		if(value == null || value == defaultValue) return xml;
		xml.set(name, Std.string(value));
		return xml;
	}
	function savePointToXml(xml:Xml, name:String, point:FlxPoint, ?defaultValueX:Float, ?defaultValueY:Float) {
		if (point == null) return xml;
		if(defaultValueY == null) defaultValueY = defaultValueX;
		if(point.x == point.y) {
			saveToXml(xml, name, point.x, defaultValueX);
		} else {
			saveToXml(xml, name + "x", point.x, defaultValueX);
			saveToXml(xml, name + "y", point.y, defaultValueY);
		}
		return xml;
	}

	function getBoolOfNode(node:Access, name:String) {
		var xml:Xml = cast node;

		return xml.exists(name) && xml.get(name) == "true";
	}

	function buildStage():String {
		var xml = Xml.createElement("stage");
		saveToXml(xml, "zoom", stage.defaultZoom, 1.05);
		saveToXml(xml, "name", stage.stageName);
		saveToXml(xml, "folder", stage.spritesParentFolder);
		saveToXml(xml, "startCamPosX", stage.startCam.x, 0);
		saveToXml(xml, "startCamPosY", stage.startCam.y, 0);

		for(prop in stage.extra.keys())
			if(!Stage.DEFAULT_ATTRIBUTES.contains(prop) && !prop.startsWith("stageEditor."))
				saveToXml(xml, prop, stage.extra.get(prop));

		var group:Xml = null;
		var curGroup:String = null;

		for(sprite in getSprites()) {
			var button:StageElementButton = sprite.extra.get(exID("button"));
			var newNode:Xml = null;
			var sprite:FunkinSprite = button.getSprite();
			if(button is StageSolidButton) {
				var button:StageSolidButton = cast button;
				var node:Access = cast sprite.extra.get(exID("node"));
				Logs.trace("SOLID / BOX isnt implemented yet!");
			} else if(button is StageSpriteButton) {
				var button:StageSpriteButton = cast button;
				var node:Access = cast sprite.extra.get(exID("node"));
				var spriteXML = Xml.createElement("sprite");
				saveToXml(spriteXML, "name", sprite.name);
				saveToXml(spriteXML, "x", sprite.x, 0);
				saveToXml(spriteXML, "y", sprite.y, 0);
				saveToXml(spriteXML, "sprite", sprite.extra.get(exID("imageFile")));
				savePointToXml(spriteXML, "scale", sprite.scale, 1);
				savePointToXml(spriteXML, "scroll", sprite.scrollFactor, 1);
				saveToXml(spriteXML, "skewx", sprite.skew.x, 0);
				saveToXml(spriteXML, "skewy", sprite.skew.y, 0);
				saveToXml(spriteXML, "alpha", sprite.alpha, 1);
				saveToXml(spriteXML, "angle", sprite.angle, 0);
				//saveToXml(spriteXML, "graphicSize", sprite.width, sprite.width);
				//saveToXml(spriteXML, "graphicSizex", sprite.height, sprite.height);
				//saveToXml(spriteXML, "graphicSizey", sprite.height, sprite.height);
				saveToXml(spriteXML, "zoomfactor", sprite.zoomFactor, 1);
				saveToXml(spriteXML, "updateHitbox", getBoolOfNode(node, "updateHitbox"), false);
				saveToXml(spriteXML, "antialiasing", sprite.antialiasing, true);
				//saveToXml(spriteXML, "width", sprite.width);
				//saveToXml(spriteXML, "height", sprite.height);
				saveToXml(spriteXML, "playOnCountdown", getBoolOfNode(node, "playOnCountdown"), false);
				saveToXml(spriteXML, "interval", node.getAtt("beatInterval"), 2);
				saveToXml(spriteXML, "interval", node.getAtt("interval"), 2);
				saveToXml(spriteXML, "beatOffset", node.getAtt("beatOffset"), 0);
				if(sprite.spriteAnimType != LOOP)
					spriteXML.set("type", sprite.spriteAnimType.toString());
				saveToXml(spriteXML, "color", sprite.color.toWebString(), "#FFFFFF");
				// TODO: save custom parameters
				//saveToXml(spriteXML, "flipX", sprite.flipX, false);
				newNode = spriteXML;
			} else if(button is StageCharacterButton) {
				var button:StageCharacterButton = cast button;
				var char:Character = button.char;
				var node:Access = cast char.extra.get(exID("node"));
				var defaultPos = Stage.getDefaultPos(char.name.replace("NO_DELETE_", ""));
				var charXML:Xml = Xml.createElement(node.name);
				if(!char.name.startsWith("NO_DELETE_"))
					saveToXml(charXML, "name", char.name);
				saveToXml(charXML, "x", char.x, defaultPos.x);
				saveToXml(charXML, "y", char.y, defaultPos.y);
				saveToXml(charXML, "camxoffset", char.extra.get(exID("camX")), 0);
				saveToXml(charXML, "camyoffset", char.extra.get(exID("camY")), 0);
				saveToXml(charXML, "skewx", char.skew.x, 0);
				saveToXml(charXML, "skewy", char.skew.y, 0);
				saveToXml(charXML, "spacingx", char.extra.get(exID("spacingX")), 20);
				saveToXml(charXML, "spacingy", char.extra.get(exID("spacingY")), 0);
				saveToXml(charXML, "alpha", char.alpha / 0.75, 1);
				saveToXml(charXML, "angle", char.angle, 0);
				saveToXml(charXML, "zoomfactor", char.zoomFactor, 1);
				saveToXml(charXML, "flipX", char.isPlayer, defaultPos.flip);
				savePointToXml(charXML, "scroll", char.scrollFactor, defaultPos.scroll);
				savePointToXml(charXML, "scale", char.scale.scaleNew(button.charScale), 1);
				// TODO: save custom parameters
				newNode = charXML;
			} else if(button is StageUnknownButton) {
				var button:StageUnknownButton = cast button;
				newNode = button.xml.x;
			}
			else {
				Logs.trace("Unknown Stage Type : " + Type.getClassName(Type.getClass(button)));
				Logs.trace("> Sprite : " + Type.getClassName(Type.getClass(sprite)));
			}

			if(newNode != null && sprite != null) {
				var isLowMemory = sprite.extra.get(exID("lowMemory")) == true;
				var isHighMemory = sprite.extra.get(exID("highMemory")) == true;
				/* // Only if this compiled :sob:
				var groupName:String = null;
				if ((groupName = isLowMemory ? "low-memory" : isHighMemory ? "high-memory" : null) != null) {
					var a = group != null && groupName != curGroup && ((group = cast xml.addChild(group)) != null);
					(group = (group == null ? Xml.createElement(curGroup = groupName) : group)).addChild(newNode);
				}else xml.addChild(newNode);
				*/

				var groupName = isLowMemory ? "low-memory" : isHighMemory ? "high-memory" : null;
				if(group != null && groupName != curGroup) {
					xml.addChild(group);
					group = null;
				}
				if(groupName != null)
					(group = (group == null ? Xml.createElement(curGroup = groupName) : group)).addChild(newNode);
				else
					xml.addChild(newNode);
			}
		}

		var xmlThingYea:String = "<!DOCTYPE codename-engine-stage>\n" + Printer.print(xml, Options.editorStagePrettyPrint);
		return Options.editorStagePrettyPrint ? xmlThingYea : xmlThingYea.replace("\n", "");
	}

	function _edit_undo(_) {
		UIState.playEditorSound(Flags.DEFAULT_EDITOR_UNDO_SOUND);
		var undo = undos.undo();
		switch(undo) {
			case null:
				// do nothing
			case CEditInfo(oldInfo, newInfo):
				stage.startCam.x = oldInfo.startCamX;
				stage.startCam.y = oldInfo.startCamY;
				stage.defaultZoom = oldInfo.zoom;
				stage.stageName = oldInfo.name;
				stage.spritesParentFolder = oldInfo.folder;

				for (attrib in newInfo.attrib.keys())
					stage.extra.remove(attrib);
				for (attrib => val in oldInfo.attrib)
					stage.extra.set(attrib, val);
			case CTransform(sprite, oldInfo, newInfo):
				sprite.setPosition(oldInfo.x, oldInfo.y);
				sprite.scale.set(oldInfo.scaleX, oldInfo.scaleY);
				sprite.skew.set(oldInfo.skewX, oldInfo.skewY);
				sprite.angle = oldInfo.angle;
				cast(sprite.extra.get(exID("button")), StageElementButton).updateInfo();
		}
	}

	function _edit_redo(_) {
		UIState.playEditorSound(Flags.DEFAULT_EDITOR_REDO_SOUND);
		var redo = undos.redo();
		switch(redo) {
			case null:
				// do nothing
			case CEditInfo(oldInfo, newInfo):
				stage.startCam.x = newInfo.startCamX;
				stage.startCam.y = newInfo.startCamY;
				stage.defaultZoom = newInfo.zoom;
				stage.stageName = newInfo.name;
				stage.spritesParentFolder = newInfo.folder;

				for (attrib in oldInfo.attrib.keys())
					stage.extra.remove(attrib);
				for (attrib => val in newInfo.attrib)
					stage.extra.set(attrib, val);
			case CTransform(sprite, oldInfo, newInfo):
				sprite.setPosition(newInfo.x, newInfo.y);
				sprite.scale.set(newInfo.scaleX, newInfo.scaleY);
				sprite.skew.set(newInfo.skewX, newInfo.skewY);
				sprite.angle = newInfo.angle;
				cast(sprite.extra.get(exID("button")), StageElementButton).updateInfo();
		}
	}

	public function selectSprite(_sprite:FunkinSprite) {
		if(!UIUtil.getKeyState(CONTROL, PRESSED))
			_select_deselect(null, false);

		if(_sprite is FunkinSprite) {
			if(selection.contains(_sprite))
				selection.remove(_sprite);
			else
				selection.push(_sprite);
		}
		updateSelection();
	}

	function getSprites() {
		return stageSpritesWindow.buttons.members.map((o) -> o.getSprite()).filter((o) -> o != null);
	}
	function getRealSprites() {
		return stageSpritesWindow.buttons.members.filter(o -> o.canRender()).map((o) -> o.getSprite()).filter((o) -> o != null);
	}

	function updateSelection() {
		var sprites = getRealSprites();
		// Unselect all
		for(sprite in sprites) {
			if(sprite is FunkinSprite) {
				var sprite:FunkinSprite = cast sprite;
				sprite.extra.set(exID("selected"), false);
				sprite.extra.get(exID("button")).selected = false;
			}
		}
		// Mark selected as selected
		for(sprite in selection) {
			if(sprite is FunkinSprite) {
				var sprite:FunkinSprite = cast sprite;
				sprite.extra.set(exID("selected"), true);
				sprite.extra.get(exID("button")).selected = true;
				//Logs.trace("Selected " + sprite.name);
			}
		}
	}

	function _select_all(_, checkSelection:Bool = true) {
		_select_deselect(null, false);
		var sprites = getRealSprites();
		selection = new Selection(sprites);
		if(checkSelection) updateSelection();
	}

	function _select_deselect(_, checkSelection:Bool = true) {
		selection = new Selection();
		if(checkSelection) updateSelection();
	}

	function _select_inverse(_, checkSelection:Bool = true) {
		var oldSelection = selection;
		_select_all(null, false);
		for(sprite in oldSelection) {
			selection.remove(sprite);
		}
		if(checkSelection) updateSelection();
	}

	var zoom(default, set):Float = 0;
	var __camZoom(default, set):Float = 1;
	function set_zoom(val:Float) {
		return zoom = CoolUtil.bound(val, -3.5, 1.75); // makes zooming not lag behind when continuing scrolling
	}
	function set___camZoom(val:Float) {
		return __camZoom = CoolUtil.bound(val, 0.1, 3);
	}

	function _view_zoomin(_) {
		zoom += 0.25;
		updateZoom();
	}
	function _view_zoomout(_) {
		zoom -= 0.25;
		updateZoom();
	}
	function _view_zoomreset(_) {
		setZoom(stage.defaultZoom);
	}

	inline function updateZoom() {
		__camZoom = Math.pow(2, zoom);
	}

	inline function calculateZoom(zoom:Float) {
		return Math.log(zoom) / Math.log(2);
	}

	inline function setZoom(_zoom:Float) {
		zoom = calculateZoom(__camZoom = _zoom);
	}

	function _view_focusdad(_) {
		focusCharacter(charMap["NO_DELETE_dad"]);
	}
	function _view_focusgf(_) {
		focusCharacter(charMap["NO_DELETE_girlfriend"]);
	}
	function _view_focusbf(_) {
		focusCharacter(charMap["NO_DELETE_boyfriend"]);
	}

	function focusCharacter(char:Character) {
		var point = char.getCameraPosition();
		nextScroll.set(point.x - stageCamera.width / 2, point.y - stageCamera.height / 2);

		setZoom(stage.defaultZoom);
	}

	function _editor_showCharacters(t) {
		showCharacters = !showCharacters;
		t.icon = showCharacters ? 1 : 0;
		for(char in chars) {
			var button:StageCharacterButton = char.extra.get(exID("button"));
			button.isHidden = !showCharacters;
			button.updateInfo();
		}
	}
	#end

	override function draw() {
		super.draw();

		for(sprite in selection)
			if(sprite is FunkinSprite) drawGuides(cast sprite);
	}

	function drawGuides(sprite:FunkinSprite) {
		if(sprite == null || sprite.offset == null) return; // destroyed

		var corners:Array<FlxPoint> = calcSpriteBounds(sprite);
		var transformedCorners:Array<FlxPoint> = [for (corner in corners) corner.clone()];
		for (corner in transformedCorners) {
			corner.x -= sprite.cameras[0].viewX;
			corner.y -= sprite.cameras[0].viewY;
	
			corner.x *= sprite.cameras[0].zoom;
			corner.y *= sprite.cameras[0].zoom;
		}

		if (DrawUtil.line == null) DrawUtil.createDrawers();
		DrawUtil.line.cameras = [gizmosCamera]; DrawUtil.line.alpha = 0.85;
		DrawUtil.dot.cameras = [gizmosCamera]; DrawUtil.dot.alpha = 1; 

		DrawUtil.drawLine(transformedCorners[0], transformedCorners[1], 1, 0xFF007B8F); // tl - tr
		DrawUtil.drawLine(transformedCorners[0], transformedCorners[2], 1, 0xFF007B8F); // tl - bl
		DrawUtil.drawLine(transformedCorners[1], transformedCorners[3], 1, 0xFF007B8F); // tr - br
		DrawUtil.drawLine(transformedCorners[2], transformedCorners[3], 1, 0xFF007B8F); // bl - br

		DrawUtil.drawLine(transformedCorners[7], transformedCorners[9], 1, 0xFF007B8F); // tc - ac // top center to angle center

		// cross
		// DrawUtil.drawLine(transformedCorners[0], transformedCorners[3], 1, 0xFF007B8F); // tl - br
		// DrawUtil.drawLine(transformedCorners[1], transformedCorners[2], 1, 0xFF007B8F); // tr - bl

		final ANGLE_INDEX = StageEditorEdge.ROTATE_CIRCLE.toInt();
		final CENTER_INDEX = StageEditorEdge.CENTER_CIRCLE.toInt();

		if(sprite.extra.exists(exID("buttonBoxes"))) {
			var oldButtonBoxes:Array<FlxPoint> = cast sprite.extra.get(exID("buttonBoxes"));
			if(oldButtonBoxes != null)
				for(point in oldButtonBoxes) point.put();
		}

		var buttonBoxes:Array<FlxPoint> = [];
		if(sprite != null) sprite.extra.set(exID("buttonBoxes"), buttonBoxes);

		DrawUtil.dot.color = 0xFFBBE4EA; DrawUtil.dot.animation.play("default");
		for(i in 0...transformedCorners.length) {
			var transformedCorner:FlxPoint = transformedCorners[i];

			if (i != CENTER_INDEX) {
				if (i == ANGLE_INDEX)  {
					DrawUtil.dot.animation.play("hollow"); DrawUtil.dot.color = 0xFFBBE4EA;
					DrawUtil.drawDot(transformedCorner.x, transformedCorner.y, 0.5);
				} else {
					DrawUtil.dot.animation.play("default"); DrawUtil.dot.color = 0xFFF7A7A7;
					DrawUtil.drawDot(transformedCorner.x, transformedCorner.y, 0.3);

					DrawUtil.dot.animation.play("hollow"); DrawUtil.dot.color = 0xFFBBE4EA;
					DrawUtil.drawDot(transformedCorner.x, transformedCorner.y, 0.5);
				}
			} else if (sprite.visible) {
				DrawUtil.dot.color = 0xFFBBE4EA;
				DrawUtil.drawDot(transformedCorner.x, transformedCorner.y, 0.7*0.5);
				DrawUtil.dot.animation.play("hollow");
			}

			buttonBoxes.push(corners[i]);
		}
	}

	public static function calcSpriteBounds(sprite:FunkinSprite) {
		var oldWidth = sprite.width;
		var oldHeight = sprite.height;

		/*
		if (sprite.animateAtlas != null) {
			var rect:FlxRect = MatrixUtil.getBounds(sprite);
			oldWidth = rect.width;
			oldHeight = rect.height;
		}
		*/

		var oldOffset = sprite.offset.clone(FlxPoint.weak());
		var oldOrigin = sprite.origin.clone(FlxPoint.weak());
		sprite.updateHitbox();
		sprite.offset.copyFrom(oldOffset);
		sprite.origin.copyFrom(oldOrigin);
		@:privateAccess sprite.updateTrig();

		var corners = sprite.getMatrixPosition([
			// corners
			FlxPoint.get(0, 0),
			FlxPoint.get(1, 0),
			FlxPoint.get(0, 1),
			FlxPoint.get(1, 1),
			// edges
			FlxPoint.get(0, 0.5),
			FlxPoint.get(1, 0.5),
			FlxPoint.get(0.5, 1),
			FlxPoint.get(0.5, 0),
			// center
			FlxPoint.get(0.5, 0.5),
			//FlxPoint.get(0.5, -100/sprite.frameHeight) // angle
			FlxPoint.get(0.5, -0.5), // angle
			FlxPoint.get(1, 0) // rotate corner
		], sprite.camera, sprite.frameWidth, sprite.frameHeight);
		//if(sprite.animateAtlas != null) {
		//	trace("Corners: " + corners);
		//}
		@:privateAccess corners[corners.length - 1].add(
			dotCheckSize * 0.35 * sprite._cosAngle + dotCheckSize * 0.35 * sprite._sinAngle,
			-dotCheckSize * 0.35 * sprite._cosAngle + dotCheckSize * 0.35 * sprite._sinAngle
		);

		//Logs.trace("Guide at " + corners[0].x + ", " + corners[0].y + " sprite at " + sprite.x + ", " + sprite.y);

		if(sprite is FunkinSprite) {
			var sprite:FunkinSprite = cast sprite;
			var corner0 = corners[0];
			var corner1 = corners[1];
			var corner2 = corners[2];
			var corner3 = corners[3];
			var maxX = MathUtil.maxSmart(corner0.x, corner1.x, corner2.x, corner3.x);
			var maxY = MathUtil.maxSmart(corner0.y, corner1.y, corner2.y, corner3.y);
			var minX = MathUtil.minSmart(corner0.x, corner1.x, corner2.x, corner3.x);
			var minY = MathUtil.minSmart(corner0.y, corner1.y, corner2.y, corner3.y);

			if(!sprite.extra.exists(exID("bounds"))) {
				sprite.extra.set(exID("bounds"), new FlxRect());
			}
			cast(sprite.extra.get(exID("bounds")), FlxRect).set(minX, minY, maxX - minX, maxY - minY);
		}

		// reset hitbox to old values
		sprite.width = oldWidth;
		sprite.height = oldHeight;

		return corners;
	}

	var edges:Array<StageEditorEdge> = [
		//// corners
		TOP_LEFT, //FlxPoint.get(0, 0),
		TOP_RIGHT, //FlxPoint.get(1, 0),
		BOTTOM_LEFT, //FlxPoint.get(0, 1),
		BOTTOM_RIGHT, //FlxPoint.get(1, 1),
		//// edges
		MIDDLE_LEFT, //FlxPoint.get(0, 0.5),
		MIDDLE_RIGHT, //FlxPoint.get(1, 0.5),
		BOTTOM_MIDDLE, //FlxPoint.get(0.5, 1),
		TOP_MIDDLE, //FlxPoint.get(0.5, 0),

		CENTER_CIRCLE, //FlxPoint.get(0.5, -0.5)

		ROTATE_CIRCLE, //FlxPoint.get(0.5, -0.5)
		ROTATE_CORNER
	];

	function tryUpdateHitbox(sprite:FunkinSprite) {
		call("tryUpdateHitbox", [sprite]);
	}

	function handleSelection(sprite:FunkinSprite) {
		if(!sprite.extra.exists(exID("buttonBoxes"))) return;
		var buttonBoxes:Array<FlxPoint> = cast sprite.extra.get(exID("buttonBoxes"));

		dotCheckSize = DrawUtil.dot.frameWidth / 0.7/stageCamera.zoom; // basically adjust it to the zoom.

		var prevMode = mouseMode;
		if(FlxG.mouse.justPressed) {
			for (i in StageEditorMouseMode.SKEW_TOP...(StageEditorMouseMode.SKEW_BOTTOM + 1)) {
				var cappedI1 = CoolUtil.maxInt(i - StageEditorMouseMode.SKEW_TOP - 1, 0);
				var cappedI2 = CoolUtil.minInt(i - StageEditorMouseMode.SKEW_TOP + 1, 3);
				var point1 = buttonBoxes[cappedI1];
				var point2 = buttonBoxes[cappedI2];
				if (checkLine(point1, point2, point2.x - point1.x, point2.y - point1.y)) {
					mousePoint.copyTo(clickPoint);
					storedPos.set(sprite.x, sprite.y);
					storedSkew.copyFrom(sprite.skew);
					storedScale.copyFrom(sprite.scale);
					storedAngle = sprite.angle;
					mouseMode = i;
				}
			}

			for(i=>edge in edges) {
				if(checkDot(buttonBoxes[i])) {
					mouseMode = switch(edge) {
						case TOP_LEFT: SCALE_TOP_LEFT;
						case TOP_MIDDLE: SCALE_TOP;
						case TOP_RIGHT: SCALE_TOP_RIGHT;
						case MIDDLE_LEFT: SCALE_LEFT;
						case MIDDLE_RIGHT: SCALE_RIGHT;
						case BOTTOM_LEFT: SCALE_BOTTOM_LEFT;
						case BOTTOM_MIDDLE: SCALE_BOTTOM;
						case BOTTOM_RIGHT: SCALE_BOTTOM_RIGHT;
						case CENTER_CIRCLE: MOVE_CENTER;
						case ROTATE_CIRCLE:
							angleOffset = 90;
							ROTATE;
						case ROTATE_CORNER:
							angleOffset = Math.atan(sprite.height / sprite.width) * FlxAngle.TO_DEG;
							ROTATE;
						default: NONE;
					}
					Logs.trace("Clicked Dot: " + mouseMode.toString());
					mousePoint.copyTo(clickPoint);
					storedPos.set(sprite.x, sprite.y);
					storedSkew.set(sprite.skew.x, sprite.skew.y);
					storedScale.copyFrom(sprite.scale);
					storedAngle = sprite.angle;
				}
				
				if(mouseMode == MOVE_CENTER){
					trace(mouseMode);
					storedPos.set(sprite.x, sprite.y);
				}
			}
		}
		for(i=>edge in edges) {
			if(checkDot(buttonBoxes[i])) {
				// TODO: make it show both sided arrows when resizing, unless its at minimum size then show only one
				// TODO: make this rotate with the sprite
				currentCursor = switch(edge) {
					// RESIZE_NESW; //RESIZE_NS; //RESIZE_NWSE; //RESIZE_WE;
					case TOP_LEFT: RESIZE_TL;
					case TOP_MIDDLE: RESIZE_T;
					case TOP_RIGHT: RESIZE_TR;
					case MIDDLE_LEFT: RESIZE_L;
					case CENTER_CIRCLE: 
						#if (mac) FlxG.mouse.pressed ? DRAG : DRAG_OPEN 
						#elseif (linux) FlxG.mouse.pressed ? DRAG : CLICK 
						#else MOVE #end;
					case MIDDLE_RIGHT: RESIZE_R;
					case BOTTOM_LEFT: RESIZE_BL;
					case BOTTOM_MIDDLE: RESIZE_B;
					case BOTTOM_RIGHT: RESIZE_BR;
					//case TOP_LEFT | BOTTOM_RIGHT: MouseCursor.RESIZE_NWSE;
					//case TOP_MIDDLE | BOTTOM_MIDDLE: MouseCursor.RESIZE_NS;
					//case TOP_RIGHT | BOTTOM_LEFT: MouseCursor.RESIZE_NESW;
					//case MIDDLE_LEFT | MIDDLE_RIGHT: MouseCursor.RESIZE_WE;

					case ROTATE_CIRCLE | ROTATE_CORNER: FlxG.mouse.pressed ? DRAG : #if mac DRAG_OPEN #else CLICK #end;
					default: ARROW;
				}
				break;
			}
		}

		mouseMode = (FlxG.mouse.justReleased) ? NONE : mouseMode;

		if (prevMode == NONE && mouseMode == NONE) return;

		if (prevMode != NONE && mouseMode == NONE) {
			undos.addToUndo(CTransform(sprite, {
				x: storedPos.x,
				y: storedPos.y,
				scaleX: storedScale.x,
				scaleY: storedScale.y,
				skewX: storedSkew.x,
				skewY: storedSkew.y,
				angle: storedAngle
			}, {
				x: sprite.x,
				y: sprite.y,
				scaleX: sprite.scale.x,
				scaleY: sprite.scale.y,
				skewX: sprite.skew.x,
				skewY: sprite.skew.y,
				angle: sprite.angle
			}));
		}

		if(mouseMode == NONE) return;

		var relative = clickPoint.subtractNew(mousePoint);
		call(mouseMode.toString(), [sprite, relative]);
		cast(sprite.extra.get(exID("button")), StageElementButton).updateInfo();
		relative.put();
	}

	public static var dotCheckSize:Float = 53;

	function checkDot(point:FlxPoint):Bool {
		if(point!=null){
			var rect = new FlxRect(point.x - dotCheckSize/2, point.y - dotCheckSize/2, dotCheckSize, dotCheckSize);
			return rect.containsPoint(mousePoint);
		}
		return false;
	}

	function checkLine(point1:FlxPoint, point2:FlxPoint, dx:Float, dy:Float) {
		var leftRegion = Math.min(point1.x, point2.x) - dotCheckSize * 0.2;
		var rightRegion = Math.max(point1.x, point2.x) + dotCheckSize * 0.2;
		var topRegion = Math.min(point1.y, point2.y) - dotCheckSize * 0.2;
		var bottomRegion = Math.max(point1.y, point2.y) + dotCheckSize * 0.2;

		if (dx == 0.0 || dy == 0.0)
			return (mousePoint.x >= leftRegion && mousePoint.x <= rightRegion)
				&& (mousePoint.y >= topRegion && mousePoint.y <= bottomRegion);

		var inc = dx * ((mousePoint.y - point1.y) / dy);
		leftRegion += inc;
		rightRegion += inc;

		inc = dy * ((mousePoint.x - point1.x) / dx);
		topRegion += inc;
		bottomRegion += inc;
			
		return (mousePoint.x >= leftRegion && mousePoint.x <= rightRegion)
			&& (mousePoint.y >= topRegion && mousePoint.y <= bottomRegion);
	}
}

typedef StageInfo = {
	name:String,
	folder:String,
	startCamX:Float,
	startCamY:Float,
	zoom:Float,
	attrib:Map<String, String>
};

typedef StageSprInfo = {
	x:Float,
	y:Float,
	scaleX:Float,
	scaleY:Float,
	skewX:Float,
	skewY:Float, // i dont wanna be cloning a bunch of FlxPoints. Theres a pool for a reason.
	angle:Float
}

enum StageChange {
	CEditInfo(oldInfo:StageInfo, newInfo:StageInfo);
	CTransform(sprite:FunkinSprite, oldInfo:StageSprInfo, newInfo:StageSprInfo);
}

@:forward abstract Selection(Array<FunkinSprite>) from Array<FunkinSprite> to Array<FunkinSprite> {
	public inline function new(?array:Array<FunkinSprite>)
		this = array == null ? [] : array;

	// too lazy to put this in every for loop so i made it a abstract
	//public inline function loop(onNote:CharterNote->Void, ?onEvent:CharterEvent->Void, ?draggableOnly:Bool = true) {
	//	for (s in this) {
	//		if (s is CharterNote && onNote != null && (draggableOnly ? s.draggable: true))
	//			onNote(cast(s, CharterNote));
	//		else if (s is CharterEvent && onEvent != null && (draggableOnly ? s.draggable: true))
	//			onEvent(cast(s, CharterEvent));
	//	}
	//}
}

enum abstract StageEditorMouseMode(Int) from Int to Int {
	var NONE;

	var SCALE_LEFT;
	var SCALE_BOTTOM;
	var SCALE_TOP;
	var SCALE_RIGHT;
	var SCALE_TOP_LEFT;
	var SCALE_TOP_RIGHT;
	var SCALE_BOTTOM_LEFT;
	var SCALE_BOTTOM_RIGHT;

	var MOVE_CENTER;

	var SKEW_TOP;
	var SKEW_LEFT;
	var SKEW_RIGHT;
	var SKEW_BOTTOM;

	var ROTATE;

	public function toString():String {
		return switch(cast this) {
			case NONE: "NONE";
			case SCALE_LEFT: "SCALE_LEFT";
			case SCALE_BOTTOM: "SCALE_BOTTOM";
			case SCALE_TOP: "SCALE_TOP";
			case SCALE_RIGHT: "SCALE_RIGHT";
			case SCALE_TOP_LEFT: "SCALE_TOP_LEFT";
			case SCALE_TOP_RIGHT: "SCALE_TOP_RIGHT";
			case SCALE_BOTTOM_LEFT: "SCALE_BOTTOM_LEFT";
			case SCALE_BOTTOM_RIGHT: "SCALE_BOTTOM_RIGHT";
			case MOVE_CENTER: "MOVE_CENTER";
			case SKEW_LEFT: "SKEW_LEFT";
			case SKEW_BOTTOM: "SKEW_BOTTOM";
			case SKEW_TOP: "SKEW_TOP";
			case SKEW_RIGHT: "SKEW_RIGHT";
			case ROTATE: "ROTATE";
		}
	}
}

enum abstract StageEditorEdge(Int) {
	var NONE = -1;

	var TOP_LEFT = 0;
	var TOP_MIDDLE;
	var TOP_RIGHT;
	var MIDDLE_LEFT;
	//var MIDDLE_MIDDLE;
	var MIDDLE_RIGHT;
	var BOTTOM_LEFT;
	var BOTTOM_MIDDLE;
	var BOTTOM_RIGHT;
	var CENTER_CIRCLE;

	var ROTATE_CIRCLE;
	var ROTATE_CORNER;

	public function toString():String {
		return switch(cast this) {
			case NONE: "NONE";
			case TOP_LEFT: "TOP_LEFT";
			case TOP_MIDDLE: "TOP_MIDDLE";
			case TOP_RIGHT: "TOP_RIGHT";
			case MIDDLE_LEFT: "MIDDLE_LEFT";
			//case MIDDLE_MIDDLE: "MIDDLE_MIDDLE";
			case MIDDLE_RIGHT: "MIDDLE_RIGHT";
			case BOTTOM_LEFT: "BOTTOM_LEFT";
			case BOTTOM_MIDDLE: "BOTTOM_MIDDLE";
			case BOTTOM_RIGHT: "BOTTOM_RIGHT";
			case CENTER_CIRCLE: "CENTER_CIRCLE";
			case ROTATE_CIRCLE: "ROTATE_CIRCLE";
			case ROTATE_CORNER: "ROTATE_CORNER";
		}
	}

	public function toInt():Int {
		return switch(cast this) {
			case NONE: -1;
			case TOP_LEFT: 0;
			case TOP_MIDDLE: 1;
			case TOP_RIGHT: 2;
			case MIDDLE_LEFT: 3;

			case MIDDLE_RIGHT: 4;
			case BOTTOM_LEFT: 5;
			case BOTTOM_MIDDLE: 6;
			case BOTTOM_RIGHT: 7;
			case CENTER_CIRCLE: 8;
			case ROTATE_CIRCLE: 9;
			case ROTATE_CORNER: 10;
		}
	}
}

class StageXMLEditScreen extends UISoftcodedWindow {
	public var xml:Access;
	public var saveCallback:Void->Void;

	inline function translate(id:String, ?args:Array<Dynamic>)
		return TU.translate("stageXMLEditScreen." + id, args);

	public function new(xml:Access, saveCallback:Void->Void, type:String = "Unknown") {
		this.xml = xml;
		this.saveCallback = saveCallback;
		super("layouts/stage/xmlEditScreen", [
			"stage" => StageEditor.instance.stage,
			"xml" => xml,
			"exID" => StageEditor.exID,
			"type" => type,
			"translate" => translate
		]);
	}

	override function saveData() {
		super.saveData();
		if(saveCallback != null) saveCallback();
	}
}
