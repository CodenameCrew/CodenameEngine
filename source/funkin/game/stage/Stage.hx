package funkin.game.stage;

import flixel.util.FlxColor;

import funkin.backend.utils.XMLUtil;
import funkin.backend.scripting.Script;
//import funkin.backend.scripting.events.stage.StageXMLEvent;
import funkin.backend.scripting.events.DynamicEvent; // temporary
import funkin.backend.system.interfaces.IBeatReceiver;

import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxStringUtil; 
import flixel.util.FlxStringUtil.LabelValuePair;
import flixel.util.FlxDestroyUtil;

import flixel.FlxSprite;
#if FLX_DEBUG
import flixel.FlxBasic;
#end

import haxe.xml.Access;
import hscript.IHScriptCustomBehaviour;

using StringTools;
using funkin.backend.utils.XMLUtil.XMLImportedScriptInfo;

class LayerGroup extends FlxTypedGroup<FlxSprite> {
	private final parentLayer:Layer;

	public function new(layer:Layer) {
		this.parentLayer = layer;
		super();
		memberAdded.add((spr) -> {
			if(spr is Layer)
				parentLayer.onAddLayer.dispatch(cast spr);
			else
				parentLayer.onAddSprite.dispatch(spr);

			parentLayer.updateHitbox();
		});
		memberRemoved.add((_) -> {
			parentLayer.updateHitbox();
		});
	}
}

/**
 * This is an organizational class that can update and render a bunch of `FlxSprite`s and `Layer`s.
 * @author Jamextreme140 & ItsLJcool
 */
class Layer extends FlxTypedSpriteGroup<FlxSprite> implements IBeatReceiver implements IHScriptCustomBehaviour {
	private static final __instanceFields:Array<String> = Type.getInstanceFields(Layer);

	/**
	 * The Layer Name
	 */
	public var name(default, null):String;

	/**
	 * Signal that triggers whenever a sprite is added. Similar to `group.memberAdded`, except sprite specific.
	 */
	public final onAddSprite:FlxTypedSignal<FlxSprite -> Void> = new FlxTypedSignal<FlxSprite -> Void>();

	/**
	 * Signal that triggers whenever a layer is added. Similar to `group.memberAdded`, except layer specific.
	 */
	public final onAddLayer:FlxTypedSignal<Layer -> Void> = new FlxTypedSignal<Layer -> Void>();

	/**
	 * Returns the parent layer in the Stage hierarchy.
	 * WARNING: can be `null`, normally indicating this is the main layer (i.e. the Stage itself).
	 */
	public var parent:Layer = null;

	/**
	 * Internal. Used for hitbox reference and rendering (soon...)
	 */
	private var _bounds(default, null):FlxRect = FlxRect.get(); // TODO: draw debug for bounding box

	public function new(name:String = 'stage_layer', ?parent:Layer) {
		super();
		this.name = name;
		this.parent = parent;
		group = FlxDestroyUtil.destroy(this.group); // get rid of the prev group implementation

		_sprites = cast (group = new LayerGroup(this)).members;
	}

	//region IBeatReceiver implementation
	public function beatHit(curBeat:Int) {
		for(m in members) if(m != null && m is IBeatReceiver) (cast m:IBeatReceiver).beatHit(curBeat);
	}
	public function stepHit(curStep:Int) {
		for(m in members) if(m != null && m is IBeatReceiver) (cast m:IBeatReceiver).stepHit(curStep);
	}
	public function measureHit(curMeasure:Int) {
		for(m in members) if(m != null && m is IBeatReceiver) (cast m:IBeatReceiver).measureHit(curMeasure);
	}
	//endregion
	
	private final stageSprites:Map<String, FlxSprite> = [];
	private final stageLayers:Map<String, Layer> = [];

	//region Stage Layer Management
	override function preAdd(Sprite:FlxSprite) {
		if(Sprite == null) return; 
		Sprite.x += x;
		Sprite.y += y;
		Sprite.alpha *= alpha;
		Sprite.cameras = _cameras; // _cameras instead of cameras because get_cameras() will not return null

		if (clipRect != null) clipRectTransform(Sprite, clipRect);
	}

	public override function add(obj:FlxSprite):FlxSprite {
		if(!(obj is Layer)) return super.add(obj);

		var layer:Layer = cast obj;
		if (stageLayers.exists(layer.name)) 
			return stageLayers.get(layer.name);

		stageLayers.set(layer.name, layer);
		return super.add(layer);
	}

	public override function insert(position:Int, obj:FlxSprite):FlxSprite {
		if(!(obj is Layer)) return super.insert(position, obj);

		var layer:Layer = cast obj;
		if (stageLayers.exists(layer.name)) 
			return stageLayers.get(layer.name);

		stageLayers.set(layer.name, layer);
		return super.insert(position, layer);
	}

	public override function remove(obj:FlxSprite, splice:Bool = false):FlxSprite {
		if(!(obj is Layer)) return super.remove(obj, splice);

		var layer:Layer = cast obj;
		stageLayers.remove(layer.name);
		return super.remove(layer, splice);
	}
	//endregion

	//region Stage Sprite Management
	public function addSprite(name:String, spr:FlxSprite):FlxSprite {
		if (stageSprites.exists(name)) return spr;

		this.add(spr);
		stageSprites.set(name, spr);

		return spr;
	}

	public function insertSprite(index:Int, name:String, spr:FlxSprite):FlxSprite {
		if (stageSprites.exists(name)) return spr;

		this.insert(index, spr);
		stageSprites.set(name, spr);

		return spr;
	}

	public function removeSprite(name:String, splice:Bool = false):Bool {
		if (!stageSprites.exists(name)) return false;

		var spr:FlxSprite = stageSprites.get(name);
		
		this.remove(spr, splice);
		stageSprites.remove(name);
		
		return true;
	}

	public inline function getSprite(name:String):Null<FlxSprite> {
		return stageSprites.exists(name) ? stageSprites[name] : null;
	}

	public inline function getLayer(name:String):Null<Layer> {
		return stageLayers.exists(name) ? stageLayers[name] : null;
	}
	//endregion

	//region IHScriptCustomBehaviour implementation
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
	//endregion

	override function draw() {
		// re-implementing the `onDraw` functionality from `FlxSprite` since `FlxSpriteGroup` didn't have this (it doesn't call `super.draw()`), so we have to add it back in ourselves
		if (__drawOverrided) {
			__drawOverrided = false;
			onDraw(this);
			__drawOverrided = true;
			return;
		}

		if (!visible || group.length == 0 || alpha <= 0.0)
			return;

		super.draw();
	}

	/**
	 * If false, it will check values of `x`, `y`, `width` and `height` of the members directly
	 * instead of checking recursively. This is faster but under some circumstances, 
	 * it might not be 100% accurate.
	 */
	public var updateHitboxDirty:Bool = false;

	override function updateHitbox() {
		if(group.length == 0) return;

		var x:Float = 0;
		var y:Float = 0;
		var width:Float = 0;
		var height:Float = 0;

		if (updateHitboxDirty) {
			x = findMinX();
			y = findMinY();
			width = findMaxX() - x;
			height = findMaxY() - y;
		}
		else {
			var minX:Float = Math.POSITIVE_INFINITY;
			var minY:Float = Math.POSITIVE_INFINITY;

			var maxX:Float = Math.NEGATIVE_INFINITY;
			var maxY:Float = Math.NEGATIVE_INFINITY;

			for (obj in group.members) {
				if (!__shouldUpdateBounds(obj)) continue;
				if (obj.x < minX) minX = obj.x;
				if (obj.y < minY) minY = obj.y;
				if (obj.x + obj.width > maxX) maxX = obj.x + obj.width;
				if (obj.y + obj.height > maxY) maxY = obj.y + obj.height;
			}
			x = minX;
			y = minY;
			width = maxX - minX;
			height = maxY - minY;
		}

		_bounds.set(x, y, width, height);

		frameWidth = Std.int(_bounds.width);
		frameHeight = Std.int(_bounds.height);

		centerOrigin();
	}

	override function getHitbox(?rect:FlxRect):FlxRect {
		rect ??= FlxRect.get();
		return rect.copyFrom(_bounds);
	}

	//region Methods From FlxSpriteGroup
	override function set_x(Value:Float):Float {
		if(exists && x != Value) _bounds.x += Value;
		return super.set_x(Value);
	}
	override function set_y(Value:Float):Float {
		if(exists && y != Value) _bounds.y += Value;
		return super.set_y(Value);
	}
	override function get_width():Float 
		return _bounds.width;
	override function get_height():Float 
		return _bounds.height;

	public override function findMinX():Float {
		if(group.length == 0) return 0;
		var value = Math.POSITIVE_INFINITY;

		for(m in group.members) {
			if (!__shouldUpdateBounds(m)) continue;

			var minX:Float;
			if(m is Layer) minX = cast(m, Layer).findMinX();
			else minX = m.x;

			if (minX < value) value = minX;
		}

		return value;
	}

	public override function findMaxX():Float {
		if(group.length == 0) return 0;
		var value = Math.NEGATIVE_INFINITY;

		for(m in group.members) {
			if (!__shouldUpdateBounds(m)) continue;

			var maxX:Float;
			if(m is Layer) maxX = cast(m, Layer).findMaxX();
			else maxX = m.x + m.width;

			if (maxX > value) value = maxX;
		}

		return value;
	}

	public override function findMinY():Float {
		if(group.length == 0) return 0;
		var value = Math.POSITIVE_INFINITY;

		for(m in group.members) {
			if (!__shouldUpdateBounds(m)) continue;

			var minY:Float;
			if(m is Layer) minY = cast(m, Layer).findMinY();
			else minY = m.y;

			if (minY < value) value = minY;
		}

		return value;
	}

	public override function findMaxY():Float {
		if(group.length == 0) return 0;
		var value = Math.NEGATIVE_INFINITY;

		for(m in group.members) {
			if (!__shouldUpdateBounds(m)) continue;

			var maxY:Float;
			if(m is Layer) maxY = cast(m, Layer).findMaxY();
			else maxY = m.y + m.height;

			if (maxY > value) value = maxY;
		}

		return value;
	}

	// We disabled these functions since everything is pre-calculated above
	@:dox(hide) override function findMaxXHelper():Float {
		#if FLX_DEBUG
		throw "This function is disabled";
		#end
		return 0;
	}
	@:dox(hide) override function findMaxYHelper():Float {
		#if FLX_DEBUG
		throw "This function is disabled";
		#end
		return 0;
	}
	@:dox(hide) override function findMinXHelper():Float {
		#if FLX_DEBUG
		throw "This function is disabled";
		#end
		return 0;
	}
	@:dox(hide) override function findMinYHelper():Float {
		#if FLX_DEBUG
		throw "This function is disabled";
		#end
		return 0;
	}
	//endregion

	private inline function __shouldUpdateBounds(m:FlxSprite):Bool {
		return m != null && m.exists && m.alive;
	}

	override function destroy() {
		super.destroy();
		FlxDestroyUtil.destroy(onAddSprite);
		FlxDestroyUtil.destroy(onAddLayer);
		_bounds = FlxDestroyUtil.put(_bounds);
		stageSprites.clear();
		stageLayers.clear();
	}

	override public function toString():String {
		return '(Stage Layer) $name: ${FlxStringUtil.getDebugString([
			LabelValuePair.weak("x", x),
			LabelValuePair.weak("y", y),
			LabelValuePair.weak("width", width),
			LabelValuePair.weak("height", height),
		])}';
	}
}

/**
 * A class that handles loading a stage and putting the sprites into the state.
 * Also you can use layers to organize your stage props more easily.
 * 
 * Usage example:
 * 
 * `myStage.xml`
 * 
 * ```xml
 * <!DOCTYPE codename-engine-stage>
 * <stage zoom="0.9" name="myStage" folder="stages/default/" startCamPosY="600" startCamPosX="1000">
 * 	<layer name="background">
 * 		<sprite name="bg" x="-600" y="-200" sprite="stageback" scroll="0.9" />
 * 		<sprite name="stageFront" x="-600" y="600" sprite="stagefront" scroll="0.9" />
 * 	</layer>
 * 	<girlfriend />
 * 	<dad />
 * 	<boyfriend />
 * 	<layer name="front">
 * 		<sprite name="stageCurtains" x="-500" y="-300" sprite="stagecurtains" scroll="1.3" />
 * 	</layer>
 * </stage>
 * ```
 * `myStage.hx`
 * 
 * ```haxe
 * function onSetup(stage:Stage):Bool {
 * 	if(stage.xmlFile == null) return false; // don't load on fail.
 * 	stage.onXMLLoaded = (_) -> {trace('stage parsed...');};
 * 	stage.onXMLPostLoaded = (_, _) -> {trace('stage loaded');};
 * 	return true;
 * }
 * var myStage = new Stage('myStage', onSetup);
 * add(myStage);
 * ```
 * 
 * @author Jamextreme140 & ItsLJcool
**/
class Stage extends Layer {
	private static final __instanceFields = Type.getInstanceFields(Stage);

	private static final DEFAULT_ATTRIBUTES:Array<String> = ["name", "startCamPosX", "startCamPosY", "zoom", "folder"];

	private static function getDefaultPos(name:String):StageCharPosInfo {
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

	//region Callbacks
	public var onStageScriptLoad:Script -> Void;
	//public var onPostStageCreation:StageXMLEvent->Void;
	public var onPostStageCreation:DynamicEvent->Void;
	
	//public var onXMLLoaded:(StageXMLEvent)->Array<Access> = null;
	public var onXMLLoaded:(DynamicEvent)->Access = null;
	public var onNodeInitalize:(Access)->Dynamic = null;
	public var onNodeLoaded:(Access, Dynamic)->Dynamic = null;
	public var onNodeFinished:(Access, Dynamic)->Void = null;
	public var onXMLPostLoaded:(Access, Access)->Access = null;

	public var onStartCamSet:FlxPoint -> Float -> Void;
	public var onRatingSet:Float->Float->FlxSprite;
	
	public var onStageDestroy:Stage -> Void;
	public var onSilentDestroy:Script -> Void;
	//endregion

	private var characterPosLookup:Map<String, StageCharPos> = [];

	public var hasLoaded:Bool = false;

	/**
	 * Sets the sprites in the script, so you can access them by the name.
	**/
	public function setStagesSprites(script:Script) {
		for (key=>ref in stageSprites) script.set(key, ref);
		for (key=>ref in stageLayers) script.set(key, ref);
	}

	public dynamic function prepareInfos(node:Access):Null<XMLImportedScriptInfo> {
		return null;
	}

	public dynamic function removeInfo(script:Script):Void {}

	/**
	 * Creates a new stage with a provided file name and an optional `setup` callback
	 * intented to be used for setting the rest of the callbacks like `onPostStageCreation`, `onRatingSet`, etc.
	 * If `setup` callback is null, the stage won't load and you must call `loadStage` manually.
	 * 
	 * @param stage The Stage File name (`myStage.xml`)
	 * @param setup Initial setup callback. Return `true` to load it upon creation.
	 */
	public function new(stage:String, ?setup:Stage -> Bool) {
		super(stage);

		fileName = stage;
		xmlFilePath = Paths.xml('stages/$fileName');
		scriptFilePath = Paths.script('data/stages/$fileName');
		if (Assets.exists(xmlFilePath)) {
			try xmlFile = new Access(Xml.parse(Assets.getText(xmlFilePath)).firstElement())
			catch (e) Logs.trace('Couldn\'t load stage "$xmlFilePath": ${e.message}', ERROR);
		}

		onAddSprite.add((obj:FlxSprite) -> script?.call("onAddSprite", [obj]));
		onAddLayer.add((layer:Layer) -> script?.call("onAddLayer", [layer]));

		if(setup != null && setup(this)) loadStage();
	}

	//private var stageEvent:StageXMLEvent;
	private var stageEvent:DynamicEvent;

	public function loadStage(loadAll:Bool = false):Void {
		if (hasLoaded) return;
		if (allowScripts) {
			script = Script.create(scriptFilePath);
			if (onStageScriptLoad != null) onStageScriptLoad(script);
			script.setParent(this);
			script.load();
			script.call("create");
			script.call("onStageLoad");
		}

		if (xmlFile == null) {
			this.name = fileName;
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

		var data:Access = new Access(Xml.parse(xmlFile.x.toString()).firstElement());
		// streamlined way to tag that the sprites are from the group
		checkMemoryMode(data, loadAll);

		if (onXMLLoaded != null) {
			//stageEvent = EventManager.get(StageXMLEvent).recycle(this, xmlFile, data);
			stageEvent = EventManager.get(DynamicEvent).recycle(this, xmlFile, data);
			data = onXMLLoaded(stageEvent);
		}
		
		loadLayer(this, data);

		postLoadStage(data);
		script?.call("postCreate");
		script?.call("onPostStageLoad");
		hasLoaded = true;
		data = null;
	}

	@:dox(hide) private static inline function __isExtensionNode(node:Access):Bool {
		return node.name == "use-extension" || node.name == "extension" || node.name == "ext";
	}

	//region Memory Mode Filtering
	@:dox(hide) private function checkMemoryMode(xml:Access, loadAll:Bool) {
		for(node in xml.elements) {
			switch(node.name) {
				case 'high-memory':
					if(Options.lowMemoryMode || !loadAll) {
						xml.x.removeChild(node.x);
						continue;
					}
				case 'low-memory':
					if(!Options.lowMemoryMode || !loadAll) {
						xml.x.removeChild(node.x);
						continue;
					}
				case 'layer':
					checkMemoryMode(node, loadAll); // recursive filter in layers
					continue;
			}

			if (__isExtensionNode(node) && node.shouldLoadBefore())
				prepareInfos(node);
		}
	}
	//endregion

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

	private function loadLayer(layer:Layer, data:Access) {
		var i:Int = 0; // local index count for Character setting

		var curRemoved:Map<String, String> = [];
		inline function tempRemove(xml:Xml, att:String) {
			if (xml.exists(att)) {
				curRemoved.set(att, xml.get(att));
				xml.remove(att);
			}
		}

		for(node in data.elements) {
			// If `onNodeInitalize` returns a valid value, then why waste time on checking other values, 
			// since we should only care about what the user sets it too. Optimizations be like:
			var sprite:Dynamic = (onNodeInitalize != null) ? onNodeInitalize(node) : null;
			if(sprite == null) {
				sprite = switch(node.name) {
					case 'layer':
						if (!node.has.name) continue;

						var layerName:String = node.att.name;
						var new_layer:Layer = new Layer(layerName, layer);
						// recursive so it will allow nested layers
						script?.call("onLoadLayer", [new_layer]);

						loadLayer(new_layer, node);
						layer.add(new_layer);
					
						script?.call("onPostLoadLayer", [new_layer]);
						new_layer;
					case "sprite" | "spr" | "sparrow":
						if (!node.has.name) continue;

						var spr = XMLUtil.createSpriteFromXML(node, spritesParentFolder, LOOP);
						layer.addSprite(spr.name, spr);
					case "box" | "solid":
						if (!node.has.name || !node.has.width || !node.has.height)
							continue;

						var isSolid = (node.name == "solid");

						var spr = new FunkinSprite();
						var w:Int = Std.parseInt(node.att.width);
						var h:Int = Std.parseInt(node.att.height);
						var c:flixel.util.FlxColor = (node.has.color) ? CoolUtil.getColorFromDynamic(node.att.color) : -1;
						
						if (isSolid) spr.makeSolid(w, h, c);
						else spr.makeGraphic(w, h, c);
						
						if(isSolid) tempRemove(node.x, "updateHitbox");
						for (a in ["width", "height", "color"]) tempRemove(node.x, a);

						XMLUtil.loadSpriteFromXML(spr, node, "", NONE, false);
						// mainly for the stage editor
						for (k => v in curRemoved)
							node.x.set(k, v);
						curRemoved.clear();

						layer.addSprite(spr.name, spr);
					case "boyfriend" | "bf" | "player":
						setCharPos("boyfriend", node, getDefaultPos("boyfriend"), layer, i);
					case "girlfriend" | "gf":
						setCharPos("girlfriend", node, getDefaultPos("girlfriend"), layer, i);
					case "dad" | "opponent":
						setCharPos("dad", node, getDefaultPos("dad"), layer, i);
					case "character" | "char":
						if (!node.has.name) continue;
						setCharPos(node.att.name, node, null, layer, i);
					case "ratings" | "combo":
						if (onRatingSet == null) continue;
						onRatingSet(Std.parseFloat(node.getAtt("x")), Std.parseFloat(node.getAtt("y")));
					case 'high-memory' | 'low-memory': // those doesn't count as layers
						loadLayer(layer, node);
						null;
					default:
						// moved it to be like this, so we can just update the inline function - LJ
						if (__isExtensionNode(node)) 
							if (node.shouldLoadBefore() || prepareInfos(node) == null)
								continue;
						null;
				}
			}

			if (onNodeLoaded != null) {
				final _prevSprite = sprite;
				sprite = onNodeLoaded(node, sprite);
				// cleanup since there will be a random sprite floating around in memory
				if (_prevSprite != sprite && _prevSprite != null) _prevSprite.destroy();
			}

			if (sprite != null) {
				i++;
				for (e in node.nodes.property)
					XMLUtil.applyXMLProperty(sprite, e);
			}

			if (onNodeFinished != null) {
				onNodeFinished(node, sprite);
			}
		}
	}

	private function postLoadStage(?data:Access) {
		for(defaultChar in ["girlfriend", "dad", "boyfriend"]) {
			if (!characterPosLookup.exists(defaultChar))
				setCharPos(defaultChar, null, getDefaultPos(defaultChar), this);
		}

		if (allowScripts) {
			setStagesSprites(this.script);

			// i know this for gets run twice under, but its better like this in case a script modifies the short lived ones, i dont wanna save them in an array; more dynamic like this  - Nex
			for (info in xmlImportedScripts) if (info.importStageSprites) {
				var scriptInfo = info.getScript();
				if (scriptInfo != null) setStagesSprites(scriptInfo);
			}

			// idk lemme check anyways just in case scripts did smth  - Nex
			if(onPostStageCreation != null && stageEvent != null)
				onPostStageCreation(stageEvent);

			// shortlived scripts destroy when the stage finishes setting up  - Nex
			for (info in xmlImportedScripts) if (info.shortLived) {
				var scriptInfo = info.getScript();
				if (scriptInfo == null) continue;

				removeInfo(scriptInfo);
				scriptInfo.destroy();
			}
		}

		if (xmlFile != null && onXMLPostLoaded != null) {
			data = onXMLPostLoaded(xmlFile, data);
		}
	}

	private function setCharPos(name:String, ?node:Access, ?defaultCharPos:StageCharPosInfo, layer:Layer, index:Int = -1) {
		var charPos = new StageCharPos();
		charPos.visible = charPos.active = false;
		charPos.name = name;

		if (defaultCharPos != null) {
			charPos.setPosition(defaultCharPos.x, defaultCharPos.y);
			charPos.scrollFactor.set(defaultCharPos.scroll, defaultCharPos.scroll);
			charPos.flipX = defaultCharPos.flip;
		}

		if (node != null) {
			charPos.x = Std.parseFloat(node.getAtt("x")).getDefaultFloat(charPos.x);
			charPos.y = Std.parseFloat(node.getAtt("y")).getDefaultFloat(charPos.y);

			charPos.charSpacingX = Std.parseFloat(node.getAtt("spacingx")).getDefaultFloat(charPos.charSpacingX);
			charPos.charSpacingY = Std.parseFloat(node.getAtt("spacingy")).getDefaultFloat(charPos.charSpacingY);

			charPos.camxoffset = Std.parseFloat(node.getAtt("camxoffset")).getDefaultFloat(charPos.camxoffset);
			charPos.camyoffset = Std.parseFloat(node.getAtt("camyoffset")).getDefaultFloat(charPos.camyoffset);

			charPos.skewX = Std.parseFloat(node.getAtt("skewx")).getDefaultFloat(charPos.skewX);
			charPos.skewY = Std.parseFloat(node.getAtt("skewy")).getDefaultFloat(charPos.skewY);

			charPos.alpha = Std.parseFloat(node.getAtt("alpha")).getDefaultFloat(charPos.alpha);
			charPos.angle = Std.parseFloat(node.getAtt("angle")).getDefaultFloat(charPos.angle);
			charPos.flipX = (node.has.flip || node.has.flipX) ? (node.getAtt("flip") == "true" || node.getAtt("flipX") == "true") : charPos.flipX;
			charPos.zoomFactor = Std.parseFloat(node.getAtt("zoomfactor")).getDefaultFloat(charPos.zoomFactor);

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

		charPos.layer = layer;
		charPos.position = index;
		return characterPosLookup[name] = charPos;//layer.add(characterPosLookup[name] = charPos);
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
		if(charPos != null && charPos.position != -1) {
			charPos.prepareCharacter(char, id);
			// allows setting characters in different layers
			// their position (index) is relative to their layer
			var layerRef:Layer = charPos.layer;
			layerRef.insert(charPos.position, char);
		}
		else 
			this.add(char);
	}

	override function update(elapsed:Float) {
		script?.call("update", [elapsed]);
		super.update(elapsed);
		script?.call("postUpdate", [elapsed]);
	}

	override function draw() {
		script?.call("draw");
		super.draw();
		script?.call("postDraw");
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
		for(k in characterPosLookup.keys())
			FlxDestroyUtil.destroy(characterPosLookup.get(k));
		characterPosLookup.clear();
		
		// Properly destroy the sprites here.
		super.destroy();
	}

	override function destroy() {
		if (onStageDestroy != null) onStageDestroy(this);
		script?.call("destroy");
		destroySilently();
	}

	//region IHScriptCustomBehaviour implementation
	override function hget(name:String):Dynamic {
		// TODO: optimize this since "Type.getInstanceFields(Stage)" also gets the inherited fields from "Layer"
		if (__instanceFields.contains(name) || __instanceFields.contains('get_$name'))
			return Reflect.getProperty(this, name);

		// We should check PlayState last, and check sub-layers before.
		var og_val:Dynamic = super.hget(name);
		if (og_val != null) return og_val;

		if (PlayState.instance != null && (PlayState.__instanceFields.contains(name) || PlayState.__instanceFields.contains('get_$name')))
			return Reflect.getProperty(PlayState.instance, name);
		
		return null;
	}

	override function hset(name:String, val:Dynamic):Dynamic {
		if (__instanceFields.contains(name) || __instanceFields.contains('set_$name')) {
			Reflect.setProperty(this, name, val);
			return val;
		}

		var og_val:Dynamic = super.hget(name);
		if (og_val != null) return og_val;

		if (PlayState.instance != null && (PlayState.__instanceFields.contains(name) || PlayState.__instanceFields.contains('set_$name'))) {
			Reflect.setProperty(PlayState.instance, name, val);
			return val;
		}
		return null;
	}
	//endregion

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
	inline function applyCharStuff(char:Character, posName:String, id:Float = 0) { applyCharPos(char, posName, id); }
}

class StageCharPos extends FlxObject {
	public var extra:Map<String, Dynamic> = [];

	public var name:String;
	public var layer:Layer;
	public var position:Int = -1;
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
		if (!Std.isOfType(FlxG.state, funkin.editors.character.CharacterEditor)) {
			char.scale.x *= scale.x; char.scale.y *= scale.y;
		}
		char.cameraOffset += FlxPoint.weak(camxoffset, camyoffset);
		char.skew.x += skewX; char.skew.y += skewY;
		char.alpha *= alpha;
		char.angle += angle;
		char.zoomFactor *= zoomFactor;
	}

	public function getOldInfo(char:Character):OldCharInfo {
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
