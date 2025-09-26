package funkin.game;

import flixel.util.typeLimit.OneOfTwo;
import funkin.editors.character.CharacterEditor;
import flixel.FlxState;
import flixel.math.FlxPoint;
import haxe.xml.Access;
import funkin.backend.utils.XMLUtil.XMLImportedScriptInfo;
import funkin.backend.system.interfaces.IBeatReceiver;
import funkin.backend.scripting.DummyScript;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.events.stage.*;
import funkin.backend.system.interfaces.IBeatReceiver;
import haxe.io.Path;
import haxe.xml.Access;

using StringTools;

/**
 * A class that handles loading a stage and putting the sprites into the state.
**/
class Stage extends FlxBasic implements IBeatReceiver {
	public var extra:Map<String, Dynamic> = [];

	public var stageXML:Access;
	public var stagePath:String;
	public var stageFile:String;
	public var stageName:String;
	public var stageSprites:Map<String, FlxSprite> = [];
	public var stageScript:Script;
	public var state:FlxState;
	public var characterPoses:Map<String, StageCharPos> = [];
	public var xmlImportedScripts:Array<XMLImportedScriptInfo> = [];

	public var defaultZoom:Float = 1.05;
	public var startCam = new FlxPoint();

	public var onXMLLoaded:(Access, Array<Access>)->Array<Access> = null;
	public var onNodeLoaded:(Access, Dynamic)->Dynamic = null;
	public var onNodeFinished:(Access, Dynamic)->Void = null;
	public var onAddSprite:(FlxObject)->Void = null;
	public var onXMLPostLoaded:(Access, Array<Access>)->Array<Access> = null;

	public var spritesParentFolder = "";

	public inline function getSprite(name:String)
		return stageSprites[name];

	/**
	 * Sets the sprites in the script, so you can access them by the name.
	**/
	public function setStagesSprites(script:Script)
		for (k=>e in stageSprites) script.set(k, e);

	public function prepareInfos(node:Access)
		return  PlayState.instance == null ? null : XMLImportedScriptInfo.prepareInfos(node, PlayState.instance.scripts, (infos) -> xmlImportedScripts.push(infos));

	public function new(stage:String, ?state:FlxState, autoLoad:Bool = true) {
		super();

		if (state == null) state = PlayState.instance;
		if (state == null) state = FlxG.state;
		this.state = state;

		stageFile = stage;
		stagePath = Paths.xml('stages/$stageFile');
		try if (Assets.exists(stagePath)) stageXML = new Access(Xml.parse(Assets.getText(stagePath)).firstElement())
		catch(e) Logs.trace('Couldn\'t load stage "$stageFile": ${e.message}', ERROR);

		if (autoLoad) loadXml(stageXML);
	}

	public static var DEFAULT_ATTRIBUTES:Array<String> = ["name", "startCamPosX", "startCamPosY", "zoom", "folder"];

	public function loadXml(xml:Access, forceLoadAll:Bool = false) {
		if (PlayState.instance == state) {
			stageScript = Script.create(Paths.script('data/stages/$stageFile'));
			PlayState.instance.scripts.add(stageScript);
			stageScript.load();
		}

		var event = null;
		var elems:Array<Access> = [];
		if (xml != null) {
			var parsed:Null<Float>;
			if((parsed = Std.parseFloat(xml.getAtt("startCamPosX"))).isNotNull()) startCam.x = parsed;
			if((parsed = Std.parseFloat(xml.getAtt("startCamPosY"))).isNotNull()) startCam.y = parsed;
			if((parsed = Std.parseFloat(xml.getAtt("zoom"))).isNotNull()) defaultZoom = parsed;

			stageName = xml.getAtt("name").getDefault(stageFile);

			if (PlayState.instance == state) {
				if(xml.has.startCamPosX) PlayState.instance.camFollow.x = startCam.x;
				if(xml.has.startCamPosY) PlayState.instance.camFollow.y = startCam.y;
				if(xml.has.zoom) PlayState.instance.defaultCamZoom = defaultZoom;
			}
			if (xml.has.folder) {
				spritesParentFolder = xml.att.folder;
				if (!spritesParentFolder.endsWith("/")) spritesParentFolder += "/";
			}

			// Load custom attributes
			for(att in xml.x.attributes())
				if(!DEFAULT_ATTRIBUTES.contains(att))
					extra.set(att, xml.x.get(att));

			// some way to tag that the sprites are from the group
			for(node in xml.elements) {
				if (node.name == "high-memory" && (!Options.lowMemoryMode || forceLoadAll)) for(e in node.elements) __pushNcheckNode(elems, e);
				else if (node.name == "low-memory" && (Options.lowMemoryMode || forceLoadAll)) for(e in node.elements) __pushNcheckNode(elems, e);
				else __pushNcheckNode(elems, node);
			}

			if (PlayState.instance == state) {
				event = EventManager.get(StageXMLEvent).recycle(this, stageXML, elems);
				elems = PlayState.instance.gameAndCharsEvent("onStageXMLParsed", event).elems;
			}
			if(onXMLLoaded != null) {
				elems = onXMLLoaded(xml, elems);
			}

			for(node in elems) {
				var sprite:Dynamic = switch(node.name) {
					case "sprite" | "spr" | "sparrow":
						if (!node.has.sprite || !node.has.name) continue;

						var spr = XMLUtil.createSpriteFromXML(node, spritesParentFolder, LOOP);

						stageSprites.set(spr.name, spr);
						addSprite(spr);
					case "box" | "solid":
						if (!node.has.name || !node.has.width || !node.has.height) continue;

						var isSolid = node.name == "solid";

						var spr = new FunkinSprite();
						(isSolid ? spr.makeSolid : spr.makeGraphic)(
							Std.parseInt(node.att.width),
							Std.parseInt(node.att.height),
							(node.has.color) ? CoolUtil.getColorFromDynamic(node.att.color) : -1
						);

						if (isSolid) node.x.remove("updateHitbox");
						for (a in ["width", "height", "color"]) node.x.remove(a);
						XMLUtil.loadSpriteFromXML(spr, node, "", NONE, false);

						stageSprites.set(spr.name, spr);
						addSprite(spr);
					case "boyfriend" | "bf" | "player":
						addCharPos("boyfriend", node, getDefaultPos("boyfriend"));
					case "girlfriend" | "gf":
						addCharPos("girlfriend", node, getDefaultPos("girlfriend"));
					case "dad" | "opponent":
						addCharPos("dad", node, getDefaultPos("dad"));
					case "character" | "char":
						if (!node.has.name) continue;
						addCharPos(node.att.name, node);
					case "ratings" | "combo":
						if (PlayState.instance != state) continue;
						PlayState.instance.comboGroup.setPosition(
							Std.parseFloat(node.getAtt("x")).getDefaultFloat(PlayState.instance.comboGroup.x),
							Std.parseFloat(node.getAtt("y")).getDefaultFloat(PlayState.instance.comboGroup.y)
						);
						PlayState.instance.add(PlayState.instance.comboGroup);
						PlayState.instance.comboGroup;
					case "use-extension" | "extension" | "ext":
						if (XMLImportedScriptInfo.shouldLoadBefore(node) || prepareInfos(node) == null) continue;
						null;
					default: null;
				}

				if(PlayState.instance == state) {
					sprite = PlayState.instance.gameAndCharsEvent("onStageNodeParsed", EventManager.get(StageNodeEvent).recycle(this, node, sprite, node.name)).sprite;
				}
				if(onNodeLoaded != null) {
					sprite = onNodeLoaded(node, sprite);
				}

				if (sprite != null) {
					for(e in node.nodes.property)
						XMLUtil.applyXMLProperty(sprite, e);
				}

				if(onNodeFinished != null) {
					onNodeFinished(node, sprite);
				}
			}
		}

		if (characterPoses["girlfriend"] == null)
			addCharPos("girlfriend", null, getDefaultPos("girlfriend"));

		if (characterPoses["dad"] == null)
			addCharPos("dad", null, getDefaultPos("dad"));

		if (characterPoses["boyfriend"] == null)
			addCharPos("boyfriend", null, getDefaultPos("boyfriend"));

		if (PlayState.instance == state) {
			setStagesSprites(stageScript);

			// i know this for gets run twice under, but its better like this in case a script modifies the short lived ones, i dont wanna save them in an array; more dynamic like this  - Nex
			for (info in xmlImportedScripts) if (info.importStageSprites) {
				var script = info.getScript();
				if (script != null) setStagesSprites(script);
			}

			// idk lemme check anyways just in case scripts did smth  - Nex
			if (event != null) PlayState.instance.gameAndCharsEvent("onPostStageCreation", event);

			// shortlived scripts destroy when the stage finishes setting up  - Nex
			for (info in xmlImportedScripts) if (info.shortLived) {
				var script = info.getScript();
				if (script == null) continue;

				PlayState.instance.scripts.remove(script);
				script.destroy();
			}
		}
		if(onXMLPostLoaded != null) {
			elems = onXMLPostLoaded(xml, elems);
		}
	}

	public static function getDefaultPos(name:String):StageCharPosInfo {
		return switch(name) {
			case "boyfriend" | "bf" | "player": {
				x: 770,
				y: 100,
				scroll: 1,
				flip: true
			};
			case "girlfriend" | "gf": {
				x: 400,
				y: 130,
				scroll: 0.95,
				flip: false
			};
			case "dad" | "opponent": {
				x: 100,
				y: 100,
				scroll: 1,
				flip: false
			};
			default: {
				x: 0,
				y: 0,
				scroll: 1,
				flip: false
			};
		}
	}

	@:dox(hide) private function __pushNcheckNode(array:Array<Access>, node:Access) {
		array.push(node);
		if ((node.name == "use-extension" || node.name == "extension" || node.name == "ext") && XMLImportedScriptInfo.shouldLoadBefore(node))
			prepareInfos(node);
	}

	/**
	 * Adds a character position to the stage.
	 * @param name The name of the character
	 * @param node The XML node
	 * @param nonXMLInfo (Optional) Non-XML information
	**/
	public function addCharPos(name:String, node:Access, ?nonXMLInfo:StageCharPosInfo):StageCharPos {
		var charPos = new StageCharPos();
		charPos.visible = charPos.active = false;
		charPos.name = name;

		if (nonXMLInfo != null) {
			charPos.setPosition(nonXMLInfo.x, nonXMLInfo.y);
			charPos.scrollFactor.set(nonXMLInfo.scroll, nonXMLInfo.scroll);
			charPos.flipX = nonXMLInfo.flip;
		}

		if (node != null) {
			charPos.x = Std.parseFloat(node.getAtt("x")).getDefault(charPos.x);
			charPos.y = Std.parseFloat(node.getAtt("y")).getDefault(charPos.y);
			charPos.charSpacingX = Std.parseFloat(node.getAtt("spacingx")).getDefault(charPos.charSpacingX);
			charPos.charSpacingY = Std.parseFloat(node.getAtt("spacingy")).getDefault(charPos.charSpacingY);
			charPos.camxoffset = Std.parseFloat(node.getAtt("camxoffset")).getDefault(charPos.camxoffset);
			charPos.camyoffset = Std.parseFloat(node.getAtt("camyoffset")).getDefault(charPos.camyoffset);
			charPos.skewX = Std.parseFloat(node.getAtt("skewx")).getDefault(charPos.skewX);
			charPos.skewY = Std.parseFloat(node.getAtt("skewy")).getDefault(charPos.skewY);
			charPos.alpha = Std.parseFloat(node.getAtt("alpha")).getDefault(charPos.alpha);
			charPos.angle = Std.parseFloat(node.getAtt("angle")).getDefault(charPos.angle);
			charPos.flipX = (node.has.flip || node.has.flipX) ? (node.getAtt("flip") == "true" || node.getAtt("flipX") == "true") : charPos.flipX;
			charPos.zoomFactor = Std.parseFloat(node.getAtt("zoomfactor")).getDefault(charPos.zoomFactor);

			if (node.has.scale) {
				var scale:Null<Float> = Std.parseFloat(node.att.scale);
				if (scale.isNotNull()) charPos.scale.set(scale, scale);
			}
			if (node.has.scalex) {
				var scale:Null<Float> = Std.parseFloat(node.att.scalex);
				if (scale.isNotNull()) charPos.scale.x = scale;
			}
			if (node.has.scaley) {
				var scale:Null<Float> = Std.parseFloat(node.att.scaley);
				if (scale.isNotNull()) charPos.scale.y = scale;
			}

			if (node.has.scroll) {
				var scroll:Null<Float> = Std.parseFloat(node.att.scroll);
				if (scroll != null) charPos.scrollFactor.set(scroll, scroll);
			}
			if (node.has.scrollx) {
				var scroll:Null<Float> = Std.parseFloat(node.att.scrollx);
				if (scroll != null) charPos.scrollFactor.x = scroll;
			}
			if (node.has.scrolly) {
				var scroll:Null<Float> = Std.parseFloat(node.att.scrolly);
				if (scroll != null) charPos.scrollFactor.y = scroll;
			}
		}

		return addSprite(characterPoses[name] = charPos);
	}

	function addSprite<T:FlxObject>(sprite:T):T {
		state.add(sprite);
		if(onAddSprite != null) onAddSprite(sprite);
		return sprite;
	}

	/**
	 * Checks if a character is flipped or not.
	 * @param posName The name of the character position
	 * @param def The default value
	**/
	public inline function isCharFlipped(posName:String, def:Bool = false)
		return characterPoses[posName] != null ? characterPoses[posName].flipX : def;

	/**
	 * Applies the character stuff to the character.
	 * Adds the character to the stage, or inserts it into the stage.
	 * @param char The character
	 * @param posName The name of the character position
	 * @param id The ID of the character
	**/
	public function applyCharStuff(char:Character, posName:String, id:Float = 0) {
		var charPos = characterPoses[char.curCharacter] != null ? characterPoses[char.curCharacter] : characterPoses[posName];
		if (charPos != null) {
			charPos.prepareCharacter(char, id);
			state.insert(state.members.indexOf(charPos), char);
		} else {
			state.add(char);
		}
	}

	/**
	 * Same of destroy, but doesn't call the various script events.
	 * @param destroySprites Whether the stage sprites should be destroyed
	 * @param destroyScript Whether the stage script should be destroyed
	**/
	public function destroySilently(destroySprites:Bool = true, destroyScript:Bool = true) {
		if (destroyScript && stageScript != null) {
			if (PlayState.instance == state && PlayState.instance.scripts != null) PlayState.instance.scripts.remove(stageScript);
			stageScript.destroy();
		}

		if (destroySprites)
			for (e in stageSprites)
				e?.destroy();

		startCam.put();
		super.destroy();
	}

	public override function destroy() {
		if (PlayState.instance == state && PlayState.instance.scripts != null) PlayState.instance.gameAndCharsCall("onStageDestroy", [this]);
		stageScript?.call("destroy");
		destroySilently();
	}

	public function beatHit(curBeat:Int) {}

	public function stepHit(curStep:Int) {}

	public function measureHit(curMeasure:Int) {}

	/**
	 * Gets a list of stages that are available to be used.
	 * @param mods Whenever only the mods folder should be checked
	**/
	public static function getList(?mods:Bool = false, ?xmlOnly:Bool = false):Array<String> {
		var list:Array<String> = [];
		var extensions:Array<String> = ["xml"];
		if (!xmlOnly) extensions.push("hx");

		for (path in Paths.getFolderContent("data/stages/", false, mods ? MODS : BOTH)) {
			var extension = Path.extension(path);
			if (extensions.contains(extension)) {
				list.pushOnce("test");
				list.pushOnce(Path.withoutExtension(path));
			}
		}

		return list;
	}
}

class StageCharPos extends FlxObject {
	public var extra:Map<String, Dynamic> = [];

	public var name:String;
	public var charSpacingX:Float = 20;
	public var charSpacingY:Float = 0;
	public var camxoffset:Float = 0;
	public var camyoffset:Float = 0;
	public var skewX:Float = 0;
	public var skewY:Float = 0;
	public var alpha:Float = 1;
	public var flipX:Bool = false;
	public var scale:FlxPoint = FlxPoint.get(1, 1);
	public var zoomFactor:Float = 1;

	public function new() {
		super();
		active = false;
		visible = false;
	}

	public override function destroy() {
		scale.put();
		super.destroy();
	}

	private var _id:Float = -1;

	private var oldInfo:OldCharInfo = null;

	public function prepareCharacter(char:Character, id:Float = 0) {
		_id = id;
		oldInfo = getOldInfo(char);
		char.setPosition(x + (id * charSpacingX), y + (id * charSpacingY));
		char.scrollFactor.set(scrollFactor.x, scrollFactor.y);
		if (!Std.isOfType(FlxG.state, CharacterEditor)) {
			char.scale.x *= scale.x; char.scale.y *= scale.y;
		}
		char.cameraOffset += FlxPoint.weak(camxoffset, camyoffset);
		char.skew.x += skewX; char.skew.y += skewY;
		char.alpha *= alpha;
		char.angle += angle;
		char.zoomFactor *= zoomFactor;
	}

	public function getOldInfo(char:Character) {
		return {
			x: char.x, y: char.y,
			scrollX: char.scrollFactor.x, scrollY: char.scrollFactor.y,
			scaleX: char.scale.x, scaleY: char.scale.y,
			camxoffset: char.cameraOffset.x, camyoffset: char.cameraOffset.y,
			skewX: char.skew.x, skewY: char.skew.y,
			alpha: char.alpha, zoomFactor: char.zoomFactor,
			angle: char.angle
		}
	}

	public function revertCharacter(char:Character) {
		if(oldInfo == null) return;
		for(field in Reflect.fields(oldInfo)) {
			switch(field) {
				case "scrollX": char.scrollFactor.x = oldInfo.scrollX;
				case "scrollY": char.scrollFactor.y = oldInfo.scrollY;
				case "scaleX": char.scale.x = oldInfo.scaleX;
				case "scaleY": char.scale.y = oldInfo.scaleY;
				case "camxoffset": char.cameraOffset.x = oldInfo.camxoffset;
				case "camyoffset": char.cameraOffset.y = oldInfo.camyoffset;
				case "skewX": char.skew.x = oldInfo.skewX;
				case "skewY": char.skew.y = oldInfo.skewY;
				default: Reflect.setProperty(char, field, Reflect.field(oldInfo, field));
			}
		}
		oldInfo = null;
	}
}
typedef StageCharPosInfo = {
	var x:Float;
	var y:Float;
	var flip:Bool;
	var scroll:Float;
}

typedef OldCharInfo = {
	var x:Float;
	var y:Float;
	var scrollX:Float;
	var scrollY:Float;
	var scaleX:Float;
	var scaleY:Float;
	var camxoffset:Float;
	var camyoffset:Float;
	var skewX:Float;
	var skewY:Float;
	var alpha:Float;
	var zoomFactor:Float;
	var angle:Float;
}
