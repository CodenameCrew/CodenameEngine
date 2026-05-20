package funkin.backend.utils;

import flixel.util.FlxColor;
import flixel.util.typeLimit.OneOfTwo;
import funkin.backend.FunkinSprite.XMLAnimType;
import funkin.backend.FunkinSprite;
import funkin.game.Character;
import haxe.xml.Access;
import funkin.backend.scripting.Script;
import funkin.backend.scripting.DummyScript;
import funkin.backend.scripting.ScriptPack;
import funkin.backend.system.interfaces.IOffsetCompatible;
import animate.FlxAnimateFrames;

using StringTools;

@:dox(hide)
enum abstract ErrorCode(Int) {
	var OK = 0;
	var FAILED = 1;
	var MISSING_PROPERTY = 2;
	var TYPE_INCORRECT = 3;
	var VALUE_NULL = 4;
	var REFLECT_ERROR = 5;
}

@:dox(hide)
typedef TextFormat = { text:String, format:Dynamic }

/**
 * Class made to make XML parsing easier.
 * Used in Stage.hx, Character.hx, and more.
 */
final class XMLUtil {
	
	public static function applyXMLProperty(object:Dynamic, property:Access):ErrorCode {
		if (!property.has.name || !property.has.type || !property.has.value) {
			Logs.warn('Failed to apply XML property: XML Element is missing name, type, or value attributes.');
			return MISSING_PROPERTY;
		}

		var keys = property.att.name.split(".");
		var o = object;
		var isPath = false;
		while(keys.length > 1) {
			isPath = true;
			o = Reflect.getProperty(o, keys.shift());
		}

		var cleanValue = property.att.value.trim();
		var value:Dynamic = switch(property.att.type.toLowerCase()) {
			case "f" | "float" | "number":			Std.parseFloat(cleanValue);
			case "i" | "int" | "integer":			Std.parseInt(cleanValue);
			case "c" | "color":						FlxColor.fromString(cleanValue);
			case "s" | "string" | "str" | "text":	property.att.value; // Don't trim actual text strings
			case "b" | "bool" | "boolean":			cleanValue.toLowerCase() == "true";
			default:								return TYPE_INCORRECT;
		}
		if (value == null) return VALUE_NULL;

		if (Std.isOfType(object, IXMLEvents)) {
			cast(object, IXMLEvents).onPropertySet(property.att.name, value);
		}

		try {
			Reflect.setProperty(o, keys[0], value);
		} catch(e) {
			var str = 'Failed to apply XML property: $e on ${Type.getClass(object)}';
			if(isPath) {
				str += ' (Path: ${property.att.name})';
			}
			Logs.warn(str);
			return REFLECT_ERROR;
		}
		return OK;
	}

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

		if (node.has.applyStageMatrix) spr.applyStageMatrix = node.att.applyStageMatrix == "true";
		if (node.has.useRenderTexture) spr.useRenderTexture = node.att.useRenderTexture == "true";
		
		if(node.has.x) {
			var x:Null<Float> = Std.parseFloat(node.att.x.trim());
			if (x != null && !Math.isNaN(x)) spr.x = x;
		}
		if(node.has.y) {
			var y:Null<Float> = Std.parseFloat(node.att.y.trim());
			if (y != null && !Math.isNaN(y)) spr.y = y;
		}
		if (node.has.scroll) {
			var scroll:Null<Float> = Std.parseFloat(node.att.scroll.trim());
			if (scroll != null && !Math.isNaN(scroll)) spr.scrollFactor.set(scroll, scroll);
		}
		if (node.has.scrollx) {
			var scroll:Null<Float> = Std.parseFloat(node.att.scrollx.trim());
			if (scroll != null && !Math.isNaN(scroll)) spr.scrollFactor.x = scroll;
		}
		if (node.has.scrolly) {
			var scroll:Null<Float> = Std.parseFloat(node.att.scrolly.trim());
			if (scroll != null && !Math.isNaN(scroll)) spr.scrollFactor.y = scroll;
		}
		if (node.has.skewx) {
			var skew:Null<Float> = Std.parseFloat(node.att.skewx.trim());
			if (skew != null && !Math.isNaN(skew)) spr.skew.x = skew;
		}
		if (node.has.skewy) {
			var skew:Null<Float> = Std.parseFloat(node.att.skewy.trim());
			if (skew != null && !Math.isNaN(skew)) spr.skew.y = skew;
		}
		if (node.has.antialiasing) spr.antialiasing = node.att.antialiasing == "true";
		if (node.has.width) {
			var width:Null<Float> = Std.parseFloat(node.att.width.trim());
			if (width != null && !Math.isNaN(width)) spr.width = width;
		}
		if (node.has.height) {
			var height:Null<Float> = Std.parseFloat(node.att.height.trim());
			if (height != null && !Math.isNaN(height)) spr.height = height;
		}
		if (node.has.scale) {
			var scale:Null<Float> = Std.parseFloat(node.att.scale.trim());
			if (scale != null && !Math.isNaN(scale)) spr.scale.set(scale, scale);
		}
		if (node.has.scalex) {
			var scale:Null<Float> = Std.parseFloat(node.att.scalex.trim());
			if (scale != null && !Math.isNaN(scale)) spr.scale.x = scale;
		}
		if (node.has.scaley) {
			var scale:Null<Float> = Std.parseFloat(node.att.scaley.trim());
			if (scale != null && !Math.isNaN(scale)) spr.scale.y = scale;
		}
		if (node.has.graphicSize) {
			var graphicSize:Null<Int> = Std.parseInt(node.att.graphicSize.trim());
			if (graphicSize != null) spr.setGraphicSize(graphicSize, graphicSize);
		}
		if (node.has.graphicSizex) {
			var graphicSizex:Null<Int> = Std.parseInt(node.att.graphicSizex.trim());
			if (graphicSizex != null) spr.setGraphicSize(graphicSizex);
		}
		if (node.has.graphicSizey) {
			var graphicSizey:Null<Int> = Std.parseInt(node.att.graphicSizey.trim());
			if (graphicSizey != null) spr.setGraphicSize(0, graphicSizey);
		}
		if (node.has.flipX) spr.flipX = node.att.flipX == "true";
		if (node.has.flipY) spr.flipY = node.att.flipY == "true";
		if (node.has.updateHitbox && node.att.updateHitbox == "true") spr.updateHitbox();

		if (node.has.zoomfactor) {
			var zoom = Std.parseFloat(node.getAtt("zoomfactor").trim());
			if(zoom != null && !Math.isNaN(zoom)) spr.zoomFactor = zoom;
		}

		if (node.has.alpha) {
			var alph = Std.parseFloat(node.getAtt("alpha").trim());
			if(alph != null && !Math.isNaN(alph)) spr.alpha = alph;
		}

		if(node.has.color)
			spr.color = FlxColor.fromString(node.getAtt("color").trim()).getDefault(0xFFFFFFFF);

		if(node.has.angle) {
			var ang = Std.parseFloat(node.getAtt("angle").trim());
			if(ang != null && !Math.isNaN(ang)) spr.angle = ang;
		}

		if (node.has.playOnCountdown)
			spr.skipNegativeBeats = node.att.playOnCountdown == "true";
		if (node.has.beatInterval)
			spr.beatInterval = Std.parseInt(node.att.beatInterval.trim());
		if (node.has.interval)
			spr.beatInterval = Std.parseInt(node.att.interval.trim());
		if (node.has.beatOffset)
			spr.beatOffset = Std.parseInt(node.att.beatOffset.trim());

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
				indices: [for(i in 0...spr.frames.frames.length) i],
				label: false
			});
		}

		return spr;
	}

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
			indices: [],
			label: false
		};

		if (anim.has.name) animData.name = anim.att.name;
		if (anim.has.type) animData.animType = XMLAnimType.fromString(anim.att.type, animData.animType);
		if (anim.has.anim) animData.anim = anim.att.anim;
		
		if (anim.has.fps) {
			var fps = Std.parseFloat(anim.att.fps.trim());
			if (fps != null && !Math.isNaN(fps)) animData.fps = fps;
		}
		if (anim.has.x) {
			var x = Std.parseFloat(anim.att.x.trim());
			if (x != null && !Math.isNaN(x)) animData.x = x;
		}
		if (anim.has.y) {
			var y = Std.parseFloat(anim.att.y.trim());
			if (y != null && !Math.isNaN(y)) animData.y = y;
		}
		
		if (anim.has.loop) animData.loop = anim.att.loop == "true";
		if (anim.has.forced) animData.forced = anim.att.forced == "true";
		if (anim.has.indices) animData.indices = CoolUtil.parseNumberRange(anim.att.indices);
		if (anim.has.label) animData.label = anim.att.label == "true";

		return animData;
	}

	public static function addXMLAnimation(sprite:FlxSprite, anim:Access, loop:Bool = false):ErrorCode {
		var animType:XMLAnimType = NONE;
		if (Std.isOfType(sprite, FunkinSprite)) {
			animType = cast(sprite, FunkinSprite).spriteAnimType;
		}

		return addAnimToSprite(sprite, extractAnimFromXML(anim, animType, loop));
	}

	public static function addAnimToSprite(sprite:FlxSprite, animData:AnimData):ErrorCode {
		if (animData.name != null) {
			if (animData.fps <= 0 #if web || animData.fps == null #end) animData.fps = 24;

			if (Std.isOfType(sprite.frames, FlxAnimateFrames)) {
				if(animData.anim == null)
					return MISSING_PROPERTY;

				var animateAnim = cast(sprite, FunkinSprite).anim;

				if (animData.label) {
					if (animData.indices != null && animData.indices.length > 0)
						animateAnim.addByFrameLabelIndices(animData.name, animData.anim, animData.indices, animData.fps, animData.loop);
					else
						animateAnim.addByFrameLabel(animData.name, animData.anim, animData.fps, animData.loop);
				} else {
					if (animData.indices != null && animData.indices.length > 0)
						animateAnim.addBySymbolIndices(animData.name, animData.anim, animData.indices, animData.fps, animData.loop);
					else
						animateAnim.addBySymbol(animData.name, animData.anim, animData.fps, animData.loop);
				}
			} else {
				if (animData.indices != null && animData.indices.length > 0) {
					if (animData.anim == null)
						sprite.animation.add(animData.name, animData.indices, animData.fps, animData.loop);
					else
						sprite.animation.addByIndices(animData.name, animData.anim, animData.indices, "", animData.fps, animData.loop);
				} else
					sprite.animation.addByPrefix(animData.name, animData.anim, animData.fps, animData.loop);
			}

			if (Std.isOfType(sprite, IOffsetCompatible))
				cast(sprite, IOffsetCompatible).addOffset(animData.name, animData.x, animData.y);

			if (Std.isOfType(sprite, FunkinSprite)) {
				var xmlSpr:FunkinSprite = cast sprite;
				var name = animData.name;
				switch(animData.animType) {
					case BEAT:
						xmlSpr.beatAnims.push({
							name: name,
							forced: animData.forced.getDefault(defaultForcedCheck(name, xmlSpr))
						});
					case LOOP:
						xmlSpr.playAnim(name, animData.forced.getDefault(defaultForcedCheck(name, xmlSpr)));
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
		return Std.isOfType(sprite, Character) && (animName.startsWith("idle") || animName.startsWith("danceLeft") || animName.startsWith("danceRight")) ? false : sprite.spriteAnimType == BEAT;

	public static inline function fixXMLText(text:String) {
		var v:String;
		return [for(l in text.split("\n")) if ((v = l.trim()) != "") v].join("\n");
	}

	public static function fixSpacingInNode(node:Access):Access {
		var arr = Lambda.array(node.x);
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
	public var importStageSprites:Bool = false;
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
		if (Std.isOfType(daScript, DummyScript)) {
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
	var label:Bool;
	var ?forced:Bool;
}

typedef BeatAnim = {
	var name:String;
	var forced:Bool;
}

interface IXMLEvents {
	public function onPropertySet(property:String, value:Dynamic):Void;
}
