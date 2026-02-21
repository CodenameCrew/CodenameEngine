package funkin.game;

import haxe.xml.Access;

import hscript.IHScriptCustomBehaviour;

import funkin.game.Stage.StageCharPos;
import funkin.game.Stage.StageCharPosInfo;

import funkin.backend.utils.XMLUtil;

import funkin.backend.scripting.Script;
import funkin.backend.scripting.ScriptPack;
import funkin.backend.scripting.events.stage.StageXMLEvent;

import funkin.backend.system.interfaces.IBeatReceiver;

import flixel.group.FlxGroup;
import flixel.math.FlxPoint;

import flixel.util.FlxSignal.FlxTypedSignal;

using StringTools;

/**
 * A class that handles loading a stage and putting the sprites into the state.
**/
class StageLayer extends FlxTypedGroup<FlxBasic> implements IBeatReceiver implements IHScriptCustomBehaviour {
	private static final __instanceFields = Type.getInstanceFields(StageLayer);

	public var name:String;

	private var stageSprites:Map<String, Int> = [];
	private var stageLayers:Map<String, Int> = [];

	public var onAddSprite:FlxTypedSignal<FlxObject -> Void> = new FlxTypedSignal();
	public var onAddLayer:FlxTypedSignal<StageLayer -> Void> = new FlxTypedSignal();

	public inline function getSprite(name:String):Null<Dynamic> {
		return stageSprites.exists(name) ? this.members[stageSprites[name]] : null;
	}

	public inline function getLayer(name:String):Null<StageLayer> {
		return stageLayers.exists(name) ? cast this.members[stageLayers[name]] : null;
	}

	public function new(name:String = "stage") {
		super();
		this.name = name;
	}

	public function addSprite(name:String, spr:FlxObject):FlxObject {
		this.add(spr);
		stageSprites.set(name, this.members.indexOf(spr)); // TODO: faster way to set the index

		onAddSprite.dispatch(spr);

		return spr;
	}

	public function addLayer(name:String, layer:StageLayer):StageLayer {
		this.add(layer);
		stageLayers.set(name, this.members.indexOf(layer));
		
		onAddLayer.dispatch(layer);

		return layer;
	}

	public function beatHit(curBeat:Int) {
		for(m in members) if(m != null && m is IBeatReceiver) cast(m, IBeatReceiver).beatHit(curBeat);
	}
	public function stepHit(curStep:Int) {
		for(m in members) if(m != null && m is IBeatReceiver) cast(m, IBeatReceiver).stepHit(curStep);
	}
	public function measureHit(curMeasure:Int) {
		for(m in members) if(m != null && m is IBeatReceiver) cast(m, IBeatReceiver).measureHit(curMeasure);
	}

	public function hget(name:String):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('get_$name'))
			return Reflect.getProperty(this, name);
		if(stageSprites.exists(name)) return this.members[stageSprites[name]];
		if(stageLayers.exists(name)) return this.members[stageLayers[name]];
		return null;
	}

	public function hset(name:String, val:Dynamic):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('set_$name')) {
			Reflect.setProperty(this, name, val);
			return val;
		}
		if(stageSprites.exists(name)) return this.members[stageSprites[name]] = val;
		if(stageLayers.exists(name)) return this.members[stageLayers[name]] = val;
		return null;
	}
}

class NewStage extends StageLayer {
	private static final __instanceFields = Type.getInstanceFields(NewStage);

	public static function getStage(name:String):NewStage {
		return new NewStage(name);
	}

	private static final DEFAULT_ATTRIBUTES:Array<String> = ["name", "startCamPosX", "startCamPosY", "zoom", "folder"];

	private static inline function getDefaultPos(name:String):StageCharPosInfo {
		return switch(name) {
			case "boyfriend" | "bf" | "player": 
				{x: 770, y: 100, scroll: 1, flip: true};
			case "girlfriend" | "gf": 
				{x: 400, y: 130, scroll: 0.95, flip: false};
			case "dad" | "opponent": 
				{x: 100, y: 100, scroll: 1, flip: false};
			default: 
				{x: 0, y: 0, scroll: 1, flip: false};
		}
	}

	public final fileName:String;
	public final xmlFilePath:String;
	public final scriptFilePath:String;

	public var xmlFile:Access;

	public var script:Script;
	public var allowScripts:Bool = true;
	public var xmlImportedScripts:Array<XMLImportedScriptInfo> = [];
	
	public var defaultZoom:Float = 1.05;
	public var spritesParentFolder = "";
	public var extra:Map<String, String> = [];
	public var startCam:FlxPoint = FlxPoint.get();

	// Callbacks
	public var onStageScriptLoad:Script -> Void;
	public var onPostStageCreation:StageXMLEvent->Void;
	
	public var onPrepareInfo:Access -> XMLImportedScriptInfo;
	public var onRemoveInfo:Script -> Void;
	
	public var onXMLLoaded:(StageXMLEvent)->Array<Access> = null;
	public var onNodeLoaded:(Access, Dynamic)->Dynamic = null;
	public var onNodeFinished:(Access, Dynamic)->Void = null;
	public var onXMLPostLoaded:(Access, Array<Access>)->Array<Access> = null;

	public var onStartCamSet:FlxPoint -> Float -> Void;
	public var onRatingSet:Float->Float->FlxBasic;
	
	public var onStageDestroy:NewStage -> Void;
	public var onSilentDestroy:Script -> Void;

	private var characterPosLookup:Map<String, StageCharPos> = [];

	/**
	 * Sets the sprites in the script, so you can access them by the name.
	**/
	public function setStagesSprites(script:Script)
		for (k=>e in stageSprites) script.set(k, this.members[e]);

	public function new(stage:String, load:Bool = false) {
		super();

		fileName = stage;
		xmlFilePath = Paths.xml('stages/$fileName');
		scriptFilePath = Paths.script('data/stages/$fileName');
		if (Assets.exists(xmlFilePath)) {
			try xmlFile = new Access(Xml.parse(Assets.getText(xmlFilePath)).firstElement())
			catch (e) Logs.trace('Couldn\'t load stage "$xmlFilePath": ${e.message}', ERROR);
		}

		if (load) loadStage();
	}

	private var stageEvent:StageXMLEvent;

	private function loadStage(loadAll:Bool = false) {
		if (allowScripts) {
			script = Script.create(scriptFilePath);
			// Performed by "onStageScriptLoad"
			// PlayState.instance.scripts.add(stageScript);
			if (onStageScriptLoad != null) onStageScriptLoad(script);
			script.load();
		}

		if (xmlFile == null) {
			postLoadStage(null);
			return;
		}

		loadStartCam();

		this.name = xmlFile.getAtt("name").getDefault(fileName);

		if (onStartCamSet != null) 
			onStartCamSet(startCam, defaultZoom);

		if (xmlFile.has.folder) {
			spritesParentFolder = xmlFile.att.folder;
			if (!spritesParentFolder.endsWith("/"))
				spritesParentFolder += "/";
		}

		// Load custom attributes
		loadCustomAttributes();

		var elems:Array<Access> = [];

		// some way to tag that the sprites are from the group
		checkMemoryMode(xmlFile, loadAll, elems);
		/*
		for (node in xmlFile.elements)
		{
			if (node.name == "high-memory" && (!Options.lowMemoryMode || forceLoadAll))
				for (e in node.elements)
					__pushNcheckNode(elems, e);
			else if (node.name == "low-memory" && (Options.lowMemoryMode || forceLoadAll))
				for (e in node.elements)
					__pushNcheckNode(elems, e);
			else
				__pushNcheckNode(elems, node);
		}
		*/

		// This should be performed by the "onXMLLoaded" callback
		/*
		if (PlayState.instance == state) {
			event = EventManager.get(StageXMLEvent).recycle(this, stageXML, elems);
			elems = PlayState.instance.gameAndCharsEvent("onStageXMLParsed", event).elems;
		}
		*/
		if(onXMLLoaded != null) {
			stageEvent = EventManager.get(StageXMLEvent).recycle(this, xmlFile, elems);
			elems = onXMLLoaded(stageEvent);
		}
		
		loadLayer(this, elems);

		postLoadStage(elems);
	}

	private inline function loadStartCam() {
		startCam.x = Std.parseFloat(xmlFile.getAtt("startCamPosX")).getDefaultFloat(0);
		startCam.y = Std.parseFloat(xmlFile.getAtt("startCamPosY")).getDefaultFloat(0);
		defaultZoom = Std.parseFloat(xmlFile.getAtt("zoom")).getDefaultFloat(1.05);
		/*
		var parsed:Null<Float>;
		if ((parsed = Std.parseFloat(xmlFile.getAtt("startCamPosX"))).isNotNull())
			startCam.x = parsed;
		if ((parsed = Std.parseFloat(xmlFile.getAtt("startCamPosY"))).isNotNull())
			startCam.y = parsed;
		if ((parsed = Std.parseFloat(xmlFile.getAtt("zoom"))).isNotNull())
			defaultZoom = parsed;
		*/
	}

	private inline function loadCustomAttributes() {
		for (att in xmlFile.x.attributes())
			if (!DEFAULT_ATTRIBUTES.contains(att))
				extra.set(att, xmlFile.x.get(att));
	}

	private function loadLayer(layer:StageLayer, elems:Array<Access>) {
		for(node in elems) {
			var sprite = switch(node.name) {
				case "layer":
					if (!node.has.name) continue;
					var layerName = node.att.name;
					var layer = new StageLayer(layerName);
					// recursive so it will allow nested layers
					loadLayer(layer, [for(n in node.elements) n]);
					addLayer(layerName, layer);
				case "sprite" | "spr" | "sparrow":
					if (!node.has.sprite || !node.has.name) continue;

					var spr = XMLUtil.createSpriteFromXML(node, spritesParentFolder, LOOP);
					addSprite(spr.name, spr);
				case "box" | "solid":
					if (!node.has.name || !node.has.width || !node.has.height)
						continue;

					var isSolid = node.name == "solid";

					var spr = new FunkinSprite();
					var w:Int = Std.parseInt(node.att.width);
					var h:Int = Std.parseInt(node.att.height);
					var c:flixel.util.FlxColor = (node.has.color) ? CoolUtil.getColorFromDynamic(node.att.color) : -1;
					if (isSolid) spr.makeSolid(w, h, c);
					else spr.makeGraphic(w, h, c);

					if (isSolid) node.x.remove("updateHitbox");
					node.x.remove("width"); node.x.remove("height"); node.x.remove("color");
					XMLUtil.loadSpriteFromXML(spr, node, "", NONE, false);

					addSprite(spr.name, spr);
				case "boyfriend" | "bf" | "player":
					setCharPos("boyfriend", node, getDefaultPos("boyfriend"));
				case "girlfriend" | "gf":
					setCharPos("girlfriend", node, getDefaultPos("girlfriend"));
				case "dad" | "opponent":
					setCharPos("dad", node, getDefaultPos("dad"));
				case "character" | "char":
					if (!node.has.name) continue;
					setCharPos(node.att.name, node);
				case "ratings" | "combo":
					if(onRatingSet == null) continue;
					var ratingPos = {
						x: Std.parseFloat(node.getAtt("x")),
						y: Std.parseFloat(node.getAtt("y"))
					}
					onRatingSet(ratingPos.x, ratingPos.y);
				case "use-extension" | "extension" | "ext":
					if(XMLImportedScriptInfo.shouldLoadBefore(node)) continue;
					if(onPrepareInfo != null && onPrepareInfo(node) == null) continue;
					null;
				default: null;
			}

			if(onNodeLoaded != null) {
				sprite = onNodeLoaded(node, sprite);
			}

			if (sprite != null) {
				for (e in node.nodes.property)
					XMLUtil.applyXMLProperty(sprite, e);
			}

			if(onNodeFinished != null) {
				onNodeFinished(node, sprite);
			}
		}
	}

	private function postLoadStage(?elems:Array<Access>) {
		for(defaultChar in ["girlfriend", "dad", "boyfriend"]) {
			if(!characterPosLookup.exists(defaultChar))
				setCharPos(defaultChar, null, getDefaultPos(defaultChar));
		}

		if(allowScripts) {
			setStagesSprites(this.script);

			// i know this for gets run twice under, but its better like this in case a script modifies the short lived ones, i dont wanna save them in an array; more dynamic like this  - Nex
			for (info in xmlImportedScripts) if (info.importStageSprites) {
				var script = info.getScript();
				if (script != null)
					setStagesSprites(script);
			}

			// idk lemme check anyways just in case scripts did smth  - Nex
			//if (event != null) PlayState.instance.gameAndCharsEvent("onPostStageCreation", event);
			if(onPostStageCreation != null && stageEvent != null)
				onPostStageCreation(stageEvent);

			// shortlived scripts destroy when the stage finishes setting up  - Nex
			for (info in xmlImportedScripts) if (info.shortLived) {
				var script = info.getScript();
				if (script == null) continue;

				//PlayState.instance.scripts.remove(script);
				if(onRemoveInfo != null)
					onRemoveInfo(script);
				script.destroy();
			}
		}

		if(xmlFile != null && onXMLPostLoaded != null) {
			elems = onXMLPostLoaded(xmlFile, elems);
		}
	}

	private function setCharPos(name:String, ?node:Access, ?defaultCharPos:StageCharPosInfo) {
		var charPos = new StageCharPos();
		charPos.visible = charPos.active = false;
		charPos.name = name;

		if(defaultCharPos != null) {
			charPos.setPosition(defaultCharPos.x, defaultCharPos.y);
			charPos.scrollFactor.set(defaultCharPos.scroll, defaultCharPos.scroll);
			charPos.flipX = defaultCharPos.flip;
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

			// Scaling
			if (node.has.scale) {
				var scale:Float = Std.parseFloat(node.att.scale).getDefaultFloat(1);
				charPos.scale.set(scale, scale);
			}
			if (node.has.scalex) charPos.scale.x = Std.parseFloat(node.att.scalex).getDefaultFloat(1);
			if (node.has.scaley) charPos.scale.y = Std.parseFloat(node.att.scaley).getDefaultFloat(1);

			// Scroll Factor
			if (node.has.scroll) {
				var scroll:Float = Std.parseFloat(node.att.scroll).getDefaultFloat(1);
				charPos.scrollFactor.set(scroll, scroll);
			}
			if (node.has.scrollx) charPos.scrollFactor.x = Std.parseFloat(node.att.scrollx).getDefaultFloat(1);
			if (node.has.scrolly) charPos.scrollFactor.y = Std.parseFloat(node.att.scrolly).getDefaultFloat(1);
		}
		return add(characterPosLookup[name] = charPos);
	}

	/**
	 * Checks if a character is flipped or not.
	 * @param posName The name of the character position
	 * @param def The default value
	**/
	public inline function isCharFlipped(posName:String, isPlayer:Bool = false)
		return characterPosLookup.exists(posName) ? characterPosLookup[posName].flipX : isPlayer;

	/**
	 * Applies the character position to the character.
	 * @param char The character to apply the position to.
	 * @param posName The name of the character position.
	 * @param id ?????? no fucking clue why does it have an ID it's never used!!!!!!!!!!!!!!!!
	**/
	public function applyCharPos(char:Character, posName:String, id:Float = 0) {
		// Should I add the characters to the "stageSprites" list?
		var charName:String = char.curCharacter;
		var charPos:Null<StageCharPos> = characterPosLookup.exists(charName) ? characterPosLookup.get(charName) : characterPosLookup.get(posName);
		if(charPos != null) {
			charPos.prepareCharacter(char, id);
			this.insert(this.members.indexOf(charPos), char);
		}
		else 
			this.add(char);
	}

	/**
	 * Same of destroy, but doesn't call the various script events.
	 * @param destroySprites Whether the stage sprites should be destroyed
	 * @param destroyScript Whether the stage script should be destroyed
	**/
	public function destroySilently(destroySprites:Bool = true, destroyScript:Bool = true) {
		if (destroyScript && script != null) {
			// if (PlayState.instance == state && PlayState.instance.scripts != null) PlayState.instance.scripts.remove(stageScript);
			if (onSilentDestroy != null) onSilentDestroy(this.script);
			script.destroy();
		}

		startCam.put();
		
		// Properly destroy the sprites here.
		super.destroy();
	}

	override function destroy() {
		// if (PlayState.instance == state && PlayState.instance.scripts != null) PlayState.instance.gameAndCharsCall("onStageDestroy", [this]);
		if (onStageDestroy != null) onStageDestroy(this);
		script?.call("destroy");
		destroySilently();
	}

	@:dox(hide) private function checkMemoryMode(xml:Access, loadAll:Bool, elems:Array<Access>) {
		for(node in xml.elements) {
			if (node.name == "high-memory" && (!Options.lowMemoryMode || loadAll))
				for (e in node.elements)
					pushNode(e, elems);
			else if (node.name == "low-memory" && (Options.lowMemoryMode || loadAll))
				for (e in node.elements)
					pushNode(e, elems);
			else if (node.name == "layer")
				checkMemoryMode(node, loadAll, elems); // recursive check in layers
			else
				pushNode(node, elems);
		}
	}

	@:dox(hide) private function pushNode(node:Access, elems:Array<Access>) {
		elems.push(node);
		if ((node.name == "use-extension" || node.name == "extension" || node.name == "ext") && XMLImportedScriptInfo.shouldLoadBefore(node))
			if (onPrepareInfo != null) // :3
				onPrepareInfo(node);
	}

	// bruh...
	override function hget(name:String):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('get_$name'))
			return Reflect.getProperty(this, name);
		return super.hget(name);
	}

	override function hset(name:String, val:Dynamic):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('set_$name')) {
			Reflect.setProperty(this, name, val);
			return val;
		}
		return super.hset(name, val);
	}

	// Backwards compatibility
	public var stagePath(get, never):String;
	public var stageFile(get, never):String;
	public var stageName(get, set):String;
	public var stageScript(get, never):Script;

	public var characterPoses(get, never):Map<String, StageCharPos>;

	function get_stageScript():Script { return this.script; }

	function get_stagePath():String { return this.xmlFilePath; }

	function get_stageFile():String { return this.fileName; }

	function get_stageName():String { return this.name; }

	function set_stageName(name:String):String { return this.name = name; }

	function get_characterPoses():Map<String, StageCharPos> { return this.characterPosLookup; }
}
