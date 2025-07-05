package funkin.backend.utils;

import funkin.backend.FunkinSprite;
import funkin.game.Character;
import funkin.backend.system.ErrorCode;
import funkin.backend.FunkinSprite.XMLAnimType;
import flixel.util.FlxColor;
import haxe.xml.Access;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.DummyScript;
import funkin.backend.scripting.ScriptPack;
import flixel.util.typeLimit.OneOfTwo;
import funkin.backend.system.interfaces.IOffsetCompatible;

using StringTools;

typedef TextFormat = { text:String, format:Dynamic }

/**
 * Class made to make XML parsing easier.
 */
class XMLUtil {

	/**
	 * Applies a property XML node to an object.
	 * @param object Object to which the xml property will be applied
	 * @param property `property` node.
	 */
	public static function applyXMLProperty(object:Dynamic, property:Access):ErrorCode {
		if (!property.has.name || !property.has.type || !property.has.value) {
			Logs.trace('Failed to apply XML property: XML Element is missing name, type, or value attributes.', WARNING);
			return MISSING_PROPERTY;
		}

		var keys = property.att.name.split(".");
		var o = object;
		var isPath = false;
		while(keys.length > 1) {
			isPath = true;
			o = Reflect.getProperty(o, keys.shift());
			// TODO: support arrays
		}

		var value:Dynamic = switch(property.att.type.toLowerCase()) {
			case "f" | "float" | "number":			Std.parseFloat(property.att.value);
			case "i" | "int" | "integer" | "color":	Std.parseInt(property.att.value);
			case "s" | "string" | "str" | "text":	property.att.value;
			case "b" | "bool" | "boolean":			property.att.value.toLowerCase() == "true";
			default:								return TYPE_INCORRECT;
		}
		if (value == null) return VALUE_NULL;

		if (object is IXMLEvents) {
			cast(object, IXMLEvents).onPropertySet(property.att.name, value);
		}

		try {
			Reflect.setProperty(o, keys[0], value);
		} catch(e) {
			var str = 'Failed to apply XML property: $e on ${Type.getClass(object)}';
			if(isPath) {
				str += ' (Path: ${property.att.name})';
			}
			Logs.trace(str, WARNING);
			return REFLECT_ERROR;
		}
		return OK;
	}

	/**
	 * Overrides a sprite based on a XML node.
	 */
	public static function loadSpriteFromXML(spr:FunkinSprite, node:Access, parentFolder:String = "", defaultAnimType:XMLAnimType = BEAT, loadGraphic:Bool = true):FunkinSprite {
		if (parentFolder == null) parentFolder = "";

		spr.name = node.getAtt("name");
		spr.antialiasing = true;
		if (loadGraphic)
			spr.loadSprite(Paths.image('$parentFolder${node.getAtt("sprite").getDefault(spr.name)}', null, true));

		spr.spriteAnimType = defaultAnimType;
		if (node.has.type) {
			spr.spriteAnimType = XMLAnimType.fromString(node.att.type, spr.spriteAnimType);
		}

		if(node.has.x) {
			var x:Null<Float> = Std.parseFloat(node.att.x);
			if (x.isNotNull()) spr.x = x;
		}
		if(node.has.y) {
			var y:Null<Float> = Std.parseFloat(node.att.y);
			if (y.isNotNull()) spr.y = y;
		}
		if (node.has.scroll) {
			var scroll:Null<Float> = Std.parseFloat(node.att.scroll);
			if (scroll.isNotNull()) spr.scrollFactor.set(scroll, scroll);
		}
		if (node.has.scrollx) {
			var scroll:Null<Float> = Std.parseFloat(node.att.scrollx);
			if (scroll.isNotNull()) spr.scrollFactor.x = scroll;
		}
		if (node.has.scrolly) {
			var scroll:Null<Float> = Std.parseFloat(node.att.scrolly);
			if (scroll.isNotNull()) spr.scrollFactor.y = scroll;
		}
		if (node.has.skewx) {
			var skew:Null<Float> = Std.parseFloat(node.att.skewx);
			if (skew.isNotNull()) spr.skew.x = skew;
		}
		if (node.has.skewy) {
			var skew:Null<Float> = Std.parseFloat(node.att.skewy);
			if (skew.isNotNull()) spr.skew.y = skew;
		}
		if (node.has.antialiasing) spr.antialiasing = node.att.antialiasing == "true";
		if (node.has.width) {
			var width:Null<Float> = Std.parseFloat(node.att.width);
			if (width.isNotNull()) spr.width = width;
		}
		if (node.has.height) {
			var height:Null<Float> = Std.parseFloat(node.att.height);
			if (height.isNotNull()) spr.height = height;
		}
		if (node.has.scale) {
			var scale:Null<Float> = Std.parseFloat(node.att.scale);
			if (scale.isNotNull()) spr.scale.set(scale, scale);
		}
		if (node.has.scalex) {
			var scale:Null<Float> = Std.parseFloat(node.att.scalex);
			if (scale.isNotNull()) spr.scale.x = scale;
		}
		if (node.has.scaley) {
			var scale:Null<Float> = Std.parseFloat(node.att.scaley);
			if (scale.isNotNull()) spr.scale.y = scale;
		}
		if (node.has.graphicSize) {
			var graphicSize:Null<Int> = Std.parseInt(node.att.graphicSize);
			if (graphicSize.isNotNull()) spr.setGraphicSize(graphicSize, graphicSize);
		}
		if (node.has.graphicSizex) {
			var graphicSizex:Null<Int> = Std.parseInt(node.att.graphicSizex);
			if (graphicSizex.isNotNull()) spr.setGraphicSize(graphicSizex);
		}
		if (node.has.graphicSizey) {
			var graphicSizey:Null<Int> = Std.parseInt(node.att.graphicSizey);
			if (graphicSizey.isNotNull()) spr.setGraphicSize(0, graphicSizey);
		}
		if (node.has.flipX) spr.flipX = node.att.flipX == "true";
		if (node.has.flipY) spr.flipY = node.att.flipY == "true";
		if (node.has.updateHitbox && node.att.updateHitbox == "true") spr.updateHitbox();

		if (node.has.zoomfactor)
			spr.zoomFactor = Std.parseFloat(node.getAtt("zoomfactor")).getDefault(spr.zoomFactor);

		if (node.has.alpha)
			spr.alpha = Std.parseFloat(node.getAtt("alpha")).getDefault(spr.alpha);

		if(node.has.color)
			spr.color = FlxColor.fromString(node.getAtt("color")).getDefault(0xFFFFFFFF);

		if (node.has.playOnCountdown)
			spr.skipNegativeBeats = node.att.playOnCountdown == "true";
		if (node.has.beatInterval)
			spr.beatInterval = Std.parseInt(node.att.beatInterval);
		if (node.has.beatOffset)
			spr.beatOffset = Std.parseInt(node.att.beatOffset);

		if(node.hasNode.anim) {
			for(anim in node.nodes.anim)
				addXMLAnimation(spr, anim);
		} else if (spr.frames != null && spr.frames.frames != null) {
			addAnimToSprite(spr, {
				name: "idle",
				anim: null,
				fps: 24,
				loop: spr.spriteAnimType == LOOP,
				animType: spr.spriteAnimType,
				x: 0,
				y: 0,
				indices: [for(i in 0...spr.frames.frames.length) i]
			});
		}

		return spr;
	}

	/**
	 * Creates a new sprite based on a XML node.
	 */
	public static inline function createSpriteFromXML(node:Access, parentFolder:String = "", defaultAnimType:XMLAnimType = BEAT, ?cl:Class<FunkinSprite>, ?args:Array<Dynamic>, loadGraphic:Bool = true):FunkinSprite {
		if(cl == null) cl = FunkinSprite;
		if(args == null) args = [];
		return loadSpriteFromXML(Type.createInstance(cl, args), node, parentFolder, defaultAnimType, loadGraphic);
	}

	public static function extractAnimFromXML(anim:Access, animType:XMLAnimType = NONE, loop:Bool = false):AnimData {
		var animData:AnimData = {
			name: null,
			anim: null,
			fps: 24,
			loop: loop,
			animType: animType,
			x: 0,
			y: 0,
			indices: []
		};

		if (anim.has.name) animData.name = anim.att.name;
		if (anim.has.type) animData.animType = XMLAnimType.fromString(anim.att.type, animData.animType);
		if (anim.has.anim) animData.anim = anim.att.anim;
		if (anim.has.fps) animData.fps = Std.parseFloat(anim.att.fps).getDefault(animData.fps);
		if (anim.has.x) animData.x = Std.parseFloat(anim.att.x).getDefault(animData.x);
		if (anim.has.y) animData.y = Std.parseFloat(anim.att.y).getDefault(animData.y);
		if (anim.has.loop) animData.loop = anim.att.loop == "true";
		if (anim.has.forced) animData.forced = anim.att.forced == "true";
		if (anim.has.indices) animData.indices = CoolUtil.parseNumberRange(anim.att.indices);

		return animData;
	}
	/**
	 * Adds an XML animation to `sprite`.
	 * @param sprite Destination sprite
	 * @param anim Animation (Must be a `anim` XML node)
	 */
	public static function addXMLAnimation(sprite:FlxSprite, anim:Access, loop:Bool = false):ErrorCode {
		var animType:XMLAnimType = NONE;
		if (sprite is FunkinSprite) {
			animType = cast(sprite, FunkinSprite).spriteAnimType;
		}

		return addAnimToSprite(sprite, extractAnimFromXML(anim, animType, loop));
	}

	public static function addAnimToSprite(sprite:FlxSprite, animData:AnimData):ErrorCode {
		if (animData.name != null) {
			if (animData.fps <= 0 #if web || animData.fps == null #end) animData.fps = 24;

			if (sprite is FunkinSprite && cast(sprite, FunkinSprite).animateAtlas != null) {
				var animateAnim = cast(sprite, FunkinSprite).animateAtlas.anim;
				if(animData.anim == null)
					return MISSING_PROPERTY;

				if (animData.indices != null && animData.indices.length > 0)
					animateAnim.addBySymbolIndices(animData.name, animData.anim, animData.indices, animData.fps, animData.loop);
				else
					animateAnim.addBySymbol(animData.name, animData.anim, animData.fps, animData.loop);
			} else {
				if (animData.indices != null && animData.indices.length > 0) {
					if (animData.anim == null)
						sprite.animation.add(animData.name, animData.indices, animData.fps, animData.loop);
					else
						sprite.animation.addByIndices(animData.name, animData.anim, animData.indices, "", animData.fps, animData.loop);
				} else
					sprite.animation.addByPrefix(animData.name, animData.anim, animData.fps, animData.loop);
			}

			if (sprite is IOffsetCompatible)
				cast(sprite, IOffsetCompatible).addOffset(animData.name, animData.x, animData.y);

			if (sprite is FunkinSprite) {
				var xmlSpr = cast(sprite, FunkinSprite);
				var name = animData.name;
				switch(animData.animType) {
					case BEAT:
						xmlSpr.beatAnims.push({
							name: name,
							forced: animData.forced.getDefault(defaultForcedCheck(name, xmlSpr))
						});
					case LOOP:
						xmlSpr.animation.play(name, animData.forced.getDefault(defaultForcedCheck(name, xmlSpr)));
					default:
						// nothing
				}
				xmlSpr.animDatas.set(name, animData);
			}
			return OK;
		}
		return MISSING_PROPERTY;
	}

	public static inline function defaultForcedCheck(animName:String, sprite:FunkinSprite):Bool
		return sprite is Character && (animName.startsWith("idle") || animName.startsWith("danceLeft") || animName.startsWith("danceRight")) ? false : sprite.spriteAnimType == BEAT;

	public static inline function fixXMLText(text:String) {
		var v:String;
		return [for(l in text.split("\n")) if ((v = l.trim()) != "") v].join("\n");
	}

	/**
	 * WARNING: will edit directly the node!
	 */
	public static function fixSpacingInNode(node:Access):Access {
		var arr = [for(x in node.x) x];
		for(i => n in arr) {
			if(n.nodeType == PCData) {
				if(i == 0) n.nodeValue = n.nodeValue.ltrim();
				if(i == arr.length - 1) n.nodeValue = n.nodeValue.rtrim();
				if(n.nodeValue.contains("\n")) {
					var a = n.nodeValue.split("\n");
					n.nodeValue = [for(i => x in a) i == 0 ? x.rtrim() : i == arr.length - 1 ? x.ltrim() : x.trim()].join("\n");
				}
			}
		}
		return node;
	}

	public static function getTextFormats(_node:OneOfTwo<Xml, Access>, currentFormat:Dynamic = null, parsedSegments:Array<TextFormat> = null):Array<TextFormat> {
		var node:Xml = cast _node;
		if (currentFormat == null)
			currentFormat = {};
		if (parsedSegments == null)
			parsedSegments = [];

		for (child in node) {
			switch (child.nodeType) {
				case Element:
					if (child.nodeName == "format") {
						var format:Dynamic = Reflect.copy(currentFormat);
						@:privateAccess for (key => name in child.attributeMap) {
							Reflect.setField(format, key, name);
						}
						getTextFormats(child, format, parsedSegments);
					}
				case PCData:
					parsedSegments.push({ text: child.nodeValue, format: Reflect.copy(currentFormat) });
				default:
					// Ignore other node types
			}
		}

		return parsedSegments;
	}
}

class XMLImportedScriptInfo {
	public var path:String;
	public var shortLived:Bool = false;
	public var loadBefore:Bool = true;
	public var importStageSprites:Bool = false;  // maybe will change later??  - Nex
	public var parentScriptPack:ScriptPack = null;

	public function new(path:String, parentScriptPack:ScriptPack) {
		this.parentScriptPack = parentScriptPack;
		this.path = path;
	}

	public function getScript():Script
		return parentScriptPack == null ? null : parentScriptPack.getByPath(path);

	public static function prepareInfos(node:Access, parentScriptPack:ScriptPack, ?onScriptPreLoad:XMLImportedScriptInfo->Void):XMLImportedScriptInfo {
		if (!node.has.script || parentScriptPack == null) return null;

		var folder = node.getAtt("folder").getDefault("data/scripts/");
		if (!folder.endsWith("/")) folder += "/";

		var path = Paths.script(folder + node.getAtt("script"));
		var daScript = Script.create(path);
		if (daScript is DummyScript) {
			Logs.trace('Script Extension at ${path} does not exist.', ERROR);
			return null;
		}

		var infos = new XMLImportedScriptInfo(daScript.path, parentScriptPack);
		infos.shortLived = node.getAtt("isShortLived") == "true" || node.getAtt("shortLived") == "true";
		infos.importStageSprites = node.getAtt("importStageSprites") == "true";
		@:privateAccess infos.loadBefore = shouldLoadBefore(node);

		if (onScriptPreLoad != null) onScriptPreLoad(infos);
		parentScriptPack.add(daScript);
		daScript.set("scriptInfo", infos);
		daScript.load();

		return infos;
	}

	@:dox(hide) public static inline function shouldLoadBefore(node:Access):Bool
		return node.getAtt("loadBefore") != "false";
}

typedef AnimData = {
	var name:String;
	var anim:String;
	var fps:Float;
	var loop:Bool;
	var x:Float;
	var y:Float;
	var indices:Array<Int>;
	var animType:XMLAnimType;
	var ?forced:Bool;
}

typedef BeatAnim = {
	var name:String;
	var forced:Bool;
}

interface IXMLEvents {
	public function onPropertySet(property:String, value:Dynamic):Void;
}
