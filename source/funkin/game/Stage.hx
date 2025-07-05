package funkin.game;

import funkin.backend.scripting.events.StageXMLEvent;
import funkin.backend.scripting.events.StageNodeEvent;
import flixel.math.FlxPoint;
import flixel.FlxState;
import haxe.xml.Access;
import funkin.backend.utils.XMLUtil.XMLImportedScriptInfo;
import funkin.backend.system.interfaces.IBeatReceiver;
import funkin.backend.scripting.DummyScript;
import funkin.backend.scripting.Script;
import haxe.io.Path;

using StringTools;

class Stage extends FlxBasic implements IBeatReceiver {
	public var stageName:String = "";
	public var stageXML:Access;
	public var stagePath:String;
	public var stageSprites:Map<String, FlxSprite> = [];
	public var stageScript:Script;
	public var state:FlxState;
	public var characterPoses:Map<String, StageCharPos> = [];
	public var xmlImportedScripts:Array<XMLImportedScriptInfo> = [];

	private var spritesParentFolder = "";

	public function getSprite(name:String)
		return stageSprites[name];

	public function setStagesSprites(script:Script)
		for (k=>e in stageSprites) script.set(k, e);

	public function prepareInfos(node:Access)
		return XMLImportedScriptInfo.prepareInfos(node, PlayState.instance != null ? PlayState.instance.scripts : null, (infos) -> xmlImportedScripts.push(infos));

	public function new(stage:String, ?state:FlxState) {
		super();

		if (state == null) state = PlayState.instance;
		if (state == null) state = FlxG.state;
		this.state = state;

		stagePath = Paths.xml('stages/$stage');
		try if (Assets.exists(stagePath)) stageXML = new Access(Xml.parse(Assets.getText(stagePath)).firstElement())
		catch(e) Logs.trace('Couldn\'t load stage "$stage": ${e.message}', ERROR);

		if (PlayState.instance != null) {
			stageScript = Script.create(Paths.script('data/stages/$stage'));
			PlayState.instance.scripts.add(stageScript);
			stageScript.load();
		}

		var event = null;
		if (stageXML != null) {
			stageName = stageXML.getAtt("name").getDefault(stage);

			if (PlayState.instance != null) {
				var parsed:Null<Float>;
				if(stageXML.has.startCamPosX && (parsed = Std.parseFloat(stageXML.att.startCamPosX)) != null) PlayState.instance.camFollow.x = parsed;
				if(stageXML.has.startCamPosY && (parsed = Std.parseFloat(stageXML.att.startCamPosY)) != null) PlayState.instance.camFollow.y = parsed;
				if(stageXML.has.zoom && (parsed = Std.parseFloat(stageXML.att.zoom)) != null) PlayState.instance.defaultCamZoom = parsed;
			}
			if (stageXML.has.folder) {
				spritesParentFolder = stageXML.att.folder;
				if (!spritesParentFolder.endsWith("/")) spritesParentFolder += "/";
			}

			var elems = [];
			for(node in stageXML.elements) {
				if (node.name == "high-memory" && !Options.lowMemoryMode) for(e in node.elements) __pushNcheckNode(elems, e);
				else __pushNcheckNode(elems, node);
			}

			if (PlayState.instance != null) {
				event = EventManager.get(StageXMLEvent).recycle(this, stageXML, elems);
				elems = PlayState.instance.scripts.event("onStageXMLParsed", event).elems;
			}

			for(node in elems) {
				var sprite:Dynamic = switch(node.name) {
					case "sprite" | "spr" | "sparrow":
						if (!node.has.sprite || !node.has.name) continue;

						var spr = XMLUtil.createSpriteFromXML(node, spritesParentFolder, LOOP);

						if (!node.has.zoomfactor && PlayState.instance != null)
							spr.initialZoom = PlayState.instance.defaultCamZoom;

						stageSprites.set(spr.name, spr);
						state.add(spr);
						spr;
					case "box" | "solid":
						if (!node.has.name || !node.has.width || !node.has.height) continue;

						var spr = new FunkinSprite(
							(node.has.x) ? Std.parseFloat(node.att.x).getDefault(0) : 0,
							(node.has.y) ? Std.parseFloat(node.att.y).getDefault(0) : 0
						);

						// just to make sure, its better to apply these before it gets inside of xmlUtil (because of mainly updateHitbox i guess), so im removing them before it gets passed  - Nex
						var toRemove = ["x", "y", "width", "height", "color"];
						var isSolid = node.name == "solid";

						(isSolid ? spr.makeSolid : spr.makeGraphic)(
							Std.parseInt(node.att.width),
							Std.parseInt(node.att.height),
							(node.has.color) ? CoolUtil.getColorFromDynamic(node.att.color) : -1
						);

						if (isSolid) toRemove.push("updateHitbox");  // makesolid already calls updateHitbox  - Nex
						for (a in toRemove) node.x.remove(a);
						XMLUtil.loadSpriteFromXML(spr, node, "", NONE, false);

						if (!node.has.zoomfactor && PlayState.instance != null)
							spr.initialZoom = PlayState.instance.defaultCamZoom;

						stageSprites.set(node.getAtt("name"), spr);
						state.add(spr);
						spr;
					case "boyfriend" | "bf" | "player":
						addCharPos("boyfriend", node, {
							x: 770,
							y: 100,
							scroll: 1,
							flip: true
						});
					case "girlfriend" | "gf":
						addCharPos("girlfriend", node, {
							x: 400,
							y: 130,
							scroll: 0.95,
							flip: false
						});
					case "dad" | "opponent":
						addCharPos("dad", node, {
							x: 100,
							y: 100,
							scroll: 1,
							flip: false
						});
					case "character" | "char":
						if (!node.has.name) continue;
						addCharPos(node.att.name, node);
					case "ratings" | "combo":
						if (PlayState.instance == null) continue;
						PlayState.instance.comboGroup.setPosition(
							Std.parseFloat(node.getAtt("x")).getDefault(PlayState.instance.comboGroup.x),
							Std.parseFloat(node.getAtt("y")).getDefault(PlayState.instance.comboGroup.y)
						);
						PlayState.instance.add(PlayState.instance.comboGroup);
						PlayState.instance.comboGroup;
					case "use-extension" | "extension" | "ext":
						if (XMLImportedScriptInfo.shouldLoadBefore(node) || prepareInfos(node) == null) continue;
						null;
					default: null;
				}

				if(PlayState.instance != null) {
					sprite = PlayState.instance.scripts.event("onStageNodeParsed", EventManager.get(StageNodeEvent).recycle(this, node, sprite, node.name)).sprite;
				}

				if (sprite != null) {
					for(e in node.nodes.property)
						XMLUtil.applyXMLProperty(sprite, e);
				}
			}
		}

		if (characterPoses["girlfriend"] == null)
			addCharPos("girlfriend", null, {
				x: 400,
				y: 130,
				scroll: 0.95,
				flip: false
			});

		if (characterPoses["dad"] == null)
			addCharPos("dad", null, {
				x: 100,
				y: 100,
				scroll: 1,
				flip: false
			});

		if (characterPoses["boyfriend"] == null)
			addCharPos("boyfriend", null, {
				x: 770,
				y: 100,
				scroll: 1,
				flip: true
			});

		if (PlayState.instance == null) return;

		setStagesSprites(stageScript);

		// i know this for gets run twice under, but its better like this in case a script modifies the short lived ones, i dont wanna save them in an array; more dynamic like this  - Nex
		for (info in xmlImportedScripts) if (info.importStageSprites) {
			var script = info.getScript();
			if (script != null) setStagesSprites(script);
		}

		// idk lemme check anyways just in case scripts did smth  - Nex
		if (event != null) PlayState.instance.scripts.event("onPostStageCreation", event);

		// shortlived scripts destroy when the stage finishes setting up  - Nex
		for (info in xmlImportedScripts) if (info.shortLived) {
			var script = info.getScript();
			if (script == null) continue;

			PlayState.instance.scripts.remove(script);
			script.destroy();
		}
	}

	@:dox(hide) private function __pushNcheckNode(array:Array<Access>, node:Access) {
		array.push(node);
		if ((node.name == "use-extension" || node.name == "extension" || node.name == "ext") && XMLImportedScriptInfo.shouldLoadBefore(node))
			prepareInfos(node);
	}

	public function addCharPos(name:String, node:Access, ?nonXMLInfo:StageCharPosInfo):StageCharPos {
		var charPos = new StageCharPos();
		charPos.visible = charPos.active = false;

		if (nonXMLInfo != null) {
			charPos.setPosition(nonXMLInfo.x, nonXMLInfo.y);
			charPos.scrollFactor.set(nonXMLInfo.scroll, nonXMLInfo.scroll);
			charPos.flipX = nonXMLInfo.flip;
		}

		if (node != null) {
			charPos.x = Std.parseFloat(node.getAtt("x")).getDefault(charPos.x);
			charPos.y = Std.parseFloat(node.getAtt("y")).getDefault(charPos.y);
			charPos.camxoffset = Std.parseFloat(node.getAtt("camxoffset")).getDefault(charPos.camxoffset);
			charPos.camyoffset = Std.parseFloat(node.getAtt("camyoffset")).getDefault(charPos.camyoffset);
			charPos.skewX = Std.parseFloat(node.getAtt("skewx")).getDefault(charPos.skewX);
			charPos.skewY = Std.parseFloat(node.getAtt("skewy")).getDefault(charPos.skewY);
			charPos.alpha = Std.parseFloat(node.getAtt("alpha")).getDefault(charPos.alpha);
			charPos.flipX = (node.has.flip || node.has.flipX) ? (node.getAtt("flip") == "true" || node.getAtt("flipX") == "true") : charPos.flipX;

			var scale = Std.parseFloat(node.getAtt("scale")).getDefault(charPos.scale.x);
			charPos.scale.set(scale, scale);

			if (node.has.scroll) {
				var scroll:Null<Float> = Std.parseFloat(node.att.scroll);
				if (scroll != null) charPos.scrollFactor.set(scroll, scroll);
			} else {
				if (node.has.scrollx) {
					var scroll:Null<Float> = Std.parseFloat(node.att.scrollx);
					if (scroll != null) charPos.scrollFactor.x = scroll;
				}
				if (node.has.scrolly) {
					var scroll:Null<Float> = Std.parseFloat(node.att.scrolly);
					if (scroll != null) charPos.scrollFactor.y = scroll;
				}
			}
		}

		state.add(charPos);
		return characterPoses[name] = charPos;
	}

	public inline function isCharFlipped(posName:String, def:Bool = false)
		return characterPoses[posName] != null ? characterPoses[posName].flipX : def;

	public function applyCharStuff(char:Character, posName:String, id:Float = 0) {
		var charPos = characterPoses[char.curCharacter] != null ? characterPoses[char.curCharacter] : characterPoses[posName];
		if (charPos != null) {
			charPos.prepareCharacter(char, id);
			state.insert(state.members.indexOf(charPos), char);
		} else {
			state.add(char);
		}
	}

	public function beatHit(curBeat:Int) {}

	public function stepHit(curStep:Int) {}

	public function measureHit(curMeasure:Int) {}

	public static function getList(?mods:Bool = false):Array<String> {
		var list:Array<String> = [];
		for (path in Paths.getFolderContent('data/stages/', true, mods ? MODS : BOTH))
			if (Path.extension(path) == "xml" || Path.extension(path) == "hx") {
				var file:String = Path.withoutDirectory(Path.withoutExtension(path));
				if (!list.contains(file)) list.push(file);
			}

		return list;
	}
}

class StageCharPos extends FlxObject {
	public var charSpacingX:Float = 20;
	public var charSpacingY:Float = 0;
	public var camxoffset:Float = 0;
	public var camyoffset:Float = 0;
	public var skewX:Float = 0;
	public var skewY:Float = 0;
	public var alpha:Float = 1;
	public var flipX:Bool = false;
	public var scale:FlxPoint = FlxPoint.get(1, 1);

	public function new() {
		super();
		active = false;
		visible = false;
	}

	public override function destroy() {
		scale.put();
		super.destroy();
	}

	public function prepareCharacter(char:Character, id:Float = 0) {
		char.setPosition(x + (id * charSpacingX), y + (id * charSpacingY));
		char.scrollFactor.set(scrollFactor.x, scrollFactor.y);
		char.scale.x *= scale.x; char.scale.y *= scale.y;
		char.cameraOffset += FlxPoint.weak(camxoffset, camyoffset);
		char.skew.x += skewX; char.skew.y += skewY;
		char.alpha *= alpha;
	}
}
typedef StageCharPosInfo = {
	var x:Float;
	var y:Float;
	var flip:Bool;
	var scroll:Float;
}
