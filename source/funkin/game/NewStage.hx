package funkin.game;

import funkin.game.Stage.StageCharPos;
import funkin.game.Stage.StageCharPosInfo;
import funkin.backend.utils.XMLUtil;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.events.stage.StageXMLEvent;
import funkin.backend.system.interfaces.IBeatReceiver;

import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxSignal.FlxTypedSignal;

import flixel.system.FlxAssets.FlxShader;

import haxe.xml.Access;
import hscript.IHScriptCustomBehaviour;

using StringTools;

/**
 * A class that handles loading a stage and putting the sprites into the state.
**/
class StageLayer extends FlxTypedGroup<FlxBasic> implements IBeatReceiver implements IHScriptCustomBehaviour {
	private static final __instanceFields = Type.getInstanceFields(StageLayer);

	public var name:String;
	public var x(get, never):Float;
	public var y(get, never):Float;
	public var width(get, never):Float;
	public var height(get, never):Float;
	public var bounds(get, never):FlxRect;

	public var onAddSprite:FlxTypedSignal<FlxObject -> Void> = new FlxTypedSignal();
	public var onAddLayer:FlxTypedSignal<StageLayer -> Void> = new FlxTypedSignal();

	// TODO: better way to set all members that have the `shader` value ig??
	// Also use FlxAnimate's implementation on useRenderTexture so we can apply the shader onto all sprites as 1 sprite !!!
	public var shader(default, set):FlxShader;
	private function set_shader(s:FlxShader):FlxShader {
		for (key=>ref in this.members) cast(ref, FlxSprite).shader = s;
		this.shader = s;
		return s;
	}

	public inline function getSprite(name:String):Null<Dynamic> {
		return stageSprites.exists(name) ? stageSprites[name] : null;
	}

	public inline function getLayer(name:String):Null<StageLayer> {
		return stageLayers.exists(name) ? cast stageLayers[name] : null;
	}

	public function new(name:String = "stage_layer") {
		super();
		this.name = name;
	}

	private var stageSprites:Map<String, FlxBasic> = [];
	private var stageLayers:Map<String, StageLayer> = [];

	// Stage Sprite Management
	public function addSprite(name:String, spr:FlxObject):FlxObject {
		if (stageSprites.exists(name)) return spr;
		this.add(spr);

		stageSprites.set(name, spr);
		updateBounds();

		onAddSprite.dispatch(spr);

		return spr;
	}

	public function insertSprite(index:Int, name:String, spr:FlxObject):FlxObject {
		if (stageSprites.exists(name)) return spr;
		this.insert(index, spr);

		stageSprites.set(name, spr);
		updateBounds();

		onAddSprite.dispatch(spr);

		return spr;
	}

	public function removeSprite(name:String, splice:Bool = false):Bool {
		if (!stageSprites.exists(name)) return false;

		var spr:FlxBasic = stageSprites.get(name);
		stageSprites.remove(name);
		
		// If it's null we want to still attempt to remove the reference from the Array methinks.
		if (spr == null) {
			var idx:Int = this.members.indexOf(spr);
			if (idx < 0) return false;

			this.remove(this.members[idx], splice);
		} else
			this.remove(spr, splice);
		updateBounds();
		
		return true;
	}	

	// Stage Layer Management
	public function addLayer(layer:StageLayer):StageLayer {
		if (stageLayers.exists(layer.name)) return layer;
		
		this.add(layer);
		stageLayers.set(layer.name, layer);

		updateBounds();
		onAddLayer.dispatch(layer);

		return layer;
	}

	public function insertLayer(index:Int, layer:StageLayer):StageLayer {
		if (stageLayers.exists(layer.name)) return layer;

		this.insert(index, layer);
		stageLayers.set(layer.name, layer);

		updateBounds();
		onAddLayer.dispatch(layer);

		return layer;
	}

	public function removeLayer(layer:StageLayer, splice:Bool = false):Bool {
		if (!stageLayers.exists(layer.name)) return false;

		var layer:StageLayer = stageLayers.get(layer.name);
		stageLayers.remove(layer.name);
		
		// If it's null we want to still attempt to remove the reference from the Array methinks.
		if (layer == null) {
			var idx:Int = this.members.indexOf(layer);
			if (idx < 0) return false;

			this.remove(this.members[idx], splice);
		} else
			this.remove(layer, splice);
		updateBounds();
		
		return true;
	}

	// IBeatReceiver implementation
	public function beatHit(curBeat:Int) {
		for(m in members) if(m != null && m is IBeatReceiver) cast(m, IBeatReceiver).beatHit(curBeat);
	}
	public function stepHit(curStep:Int) {
		for(m in members) if(m != null && m is IBeatReceiver) cast(m, IBeatReceiver).stepHit(curStep);
	}
	public function measureHit(curMeasure:Int) {
		for(m in members) if(m != null && m is IBeatReceiver) cast(m, IBeatReceiver).measureHit(curMeasure);
	}

	// IHScriptCustomBehaviour implementation
	public function hget(name:String):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('get_$name'))
			return Reflect.getProperty(this, name);
		if (stageSprites.exists(name)) return stageSprites[name];
		if (stageLayers.exists(name)) return stageLayers[name];
		return null;
	}

	public function hset(name:String, val:Dynamic):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('set_$name')) {
			Reflect.setProperty(this, name, val);
			return val;
		}
		if (stageSprites.exists(name)) return stageSprites[name] = val;
		if (stageLayers.exists(name)) return stageLayers[name] = val;
		return null;
	}

	// then whatever below
	override function destroy() {
		super.destroy();
		_bounds.put();
	}

	private var _bounds:FlxRect = FlxRect.get();
	private function get_bounds():FlxRect { return _bounds; }

	private function updateBounds() {
		if (this.length == 0) return;

		// TODO: Optimize the code so that we don't run 4 for loops every time we update the bounds.
		// We should just do one giant loop and check the bounds all here without wasting time, keep the other functions for specific checks.
		var x = findMinX();
		var y = findMinY();
		var width = findMaxX() - x;
		var height = findMaxY() - y;

		_bounds.set(x, y, width, height);
	}

	// From FlxSpriteGroup

	private function findMinX():Float {
		if(this.length == 0) return 0;
		var value = Math.POSITIVE_INFINITY;

		for(m in this.members) {
			if(m == null) continue;

			var minX:Float;
			if(m is StageLayer) minX = cast(m, StageLayer).findMinX();
			else minX = cast(m, FlxObject).x;

			if (minX < value) value = minX;
		}

		return value;
	}

	private function findMaxX():Float {
		if(this.length == 0) return 0;
		var value = Math.NEGATIVE_INFINITY;

		for(m in this.members) {
			if(m == null) continue;

			var maxX:Float;
			if(m is StageLayer) maxX = cast(m, StageLayer).findMaxX();
			else {
				var obj:FlxObject = cast m;
				maxX = obj.x + obj.width;
			}

			if (maxX > value) value = maxX;
		}

		return value;
	}

	private function findMinY():Float {
		if(this.length == 0) return 0;
		var value = Math.POSITIVE_INFINITY;

		for(m in this.members) {
			if(m == null) continue;

			var minY:Float;
			if(m is StageLayer) minY = cast(m, StageLayer).findMinY();
			else minY = cast(m, FlxObject).y;

			if (minY < value) value = minY;
		}

		return value;
	}

	private function findMaxY():Float {
		if(this.length == 0) return 0;
		var value = Math.NEGATIVE_INFINITY;

		for(m in this.members) {
			if(m == null) continue;

			var maxY:Float;
			if(m is StageLayer) maxY = cast(m, StageLayer).findMaxY();
			else {
				var obj:FlxObject = cast m;
				maxY = obj.y + obj.height;
			}

			if (maxY > value) value = maxY;
		}

		return value;
	}

	private function get_x():Float 
		return _bounds.x;
	private function get_y():Float 
		return _bounds.y;
	private function get_width():Float
		return _bounds.width;
	private function get_height():Float 
		return _bounds.height;
}

class NewStage extends StageLayer {
	private static final __instanceFields = Type.getInstanceFields(NewStage);

	// TODO: Preload the Assets and scripts of the stage before returning 👀
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
	public var onNodeInitalize:(Access)->Dynamic = null;
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
		for (key=>ref in stageSprites) script.set(key, ref);

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

	public function loadStage(loadAll:Bool = false) {
		if (allowScripts) {
			script = Script.create(scriptFilePath);
			if (onStageScriptLoad != null) onStageScriptLoad(script);
			script.setParent(this);
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

		if (onXMLLoaded != null) {
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
	}

	private inline function loadCustomAttributes() {
		for (att in xmlFile.x.attributes())
			if (!DEFAULT_ATTRIBUTES.contains(att))
				extra.set(att, xmlFile.x.get(att));
	}

	private function loadLayer(layer:StageLayer, elems:Array<Access>) {
		for(node in elems) {
			// If `onNodeInitalize` returns a valid value, then why waste time on checking other values, since we should only care about what the user
			// sets it too. Optimizations be like:
			var sprite:Dynamic = (onNodeInitalize != null) ? onNodeInitalize(node) : null;
			if (sprite == null) sprite = switch(node.name) {
				case "layer":
					if (!node.has.name) continue;

					var layerName = node.att.name;
					var layer = new StageLayer(layerName);
					// recursive so it will allow nested layers
					loadLayer(layer, [for(n in node.elements) n]);
					addLayer(layer);
				case "sprite" | "spr" | "sparrow":
					if (!node.has.name) continue;

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
					if (onRatingSet == null) continue;
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

			if (onNodeLoaded != null) {
				sprite = onNodeLoaded(node, sprite);
			}

			if (sprite != null) {
				for (e in node.nodes.property)
					XMLUtil.applyXMLProperty(sprite, e);
			}

			if (onNodeFinished != null) {
				onNodeFinished(node, sprite);
			}
		}
	}

	private function postLoadStage(?elems:Array<Access>) {
		for(defaultChar in ["girlfriend", "dad", "boyfriend"]) {
			if (!characterPosLookup.exists(defaultChar))
				setCharPos(defaultChar, null, getDefaultPos(defaultChar));
		}

		if (allowScripts) {
			setStagesSprites(this.script);

			// i know this for gets run twice under, but its better like this in case a script modifies the short lived ones, i dont wanna save them in an array; more dynamic like this  - Nex
			for (info in xmlImportedScripts) if (info.importStageSprites) {
				var script = info.getScript();
				if (script != null) setStagesSprites(script);
			}

			// idk lemme check anyways just in case scripts did smth  - Nex
			if(onPostStageCreation != null && stageEvent != null)
				onPostStageCreation(stageEvent);

			// shortlived scripts destroy when the stage finishes setting up  - Nex
			for (info in xmlImportedScripts) if (info.shortLived) {
				var script = info.getScript();
				if (script == null) continue;

				if (onRemoveInfo != null) onRemoveInfo(script);
				script.destroy();
			}
		}

		if (xmlFile != null && onXMLPostLoaded != null) {
			elems = onXMLPostLoaded(xmlFile, elems);
		}
	}

	private function setCharPos(name:String, ?node:Access, ?defaultCharPos:StageCharPosInfo) {
		var charPos = new StageCharPos();
		charPos.visible = charPos.active = false;
		charPos.name = name;

		if (defaultCharPos != null) {
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
			if (onSilentDestroy != null) onSilentDestroy(this.script);
			script.destroy();
		}

		startCam.put();
		
		// Properly destroy the sprites here.
		super.destroy();
	}

	override function destroy() {
		if (onStageDestroy != null) onStageDestroy(this);
		script?.call("destroy");
		destroySilently();
	}

	@:dox(hide) private function checkMemoryMode(xml:Access, loadAll:Bool, elems:Array<Access>) {
		for(node in xml.elements) {
			if (node.name == "high-memory" && (!Options.lowMemoryMode || loadAll))
				for (e in node.elements) pushNode(e, elems);
			else if (node.name == "low-memory" && (Options.lowMemoryMode || loadAll))
				for (e in node.elements) pushNode(e, elems);
			else if (node.name == "layer") checkMemoryMode(node, loadAll, elems); // recursive check in layers
			else pushNode(node, elems);
		}
	}

	@:dox(hide) private function pushNode(node:Access, elems:Array<Access>) {
		elems.push(node);
		if ((node.name == "use-extension" || node.name == "extension" || node.name == "ext") && XMLImportedScriptInfo.shouldLoadBefore(node))
			if (onPrepareInfo != null) onPrepareInfo(node);
	}

	// bruh...
	override function hget(name:String):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('get_$name'))
			return Reflect.getProperty(this, name);
		if (PlayState.__instanceFields.contains(name) || PlayState.__instanceFields.contains('get_$name'))
			return Reflect.getProperty(PlayState.instance, name);
		return super.hget(name);
	}

	override function hset(name:String, val:Dynamic):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('set_$name')) {
			Reflect.setProperty(this, name, val);
			return val;
		}
		if (PlayState.__instanceFields.contains(name) || PlayState.__instanceFields.contains('set_$name')) {
			Reflect.setProperty(PlayState.instance, name, val);
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
