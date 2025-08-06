package funkin.menus.ui;

import flixel.util.typeLimit.OneOfTwo;
import haxe.ds.Vector;
import funkin.menus.ui.effects.RegionEffect;

import flixel.animation.FlxAnimation;
import flixel.util.FlxDirectionFlags;
import flixel.math.FlxPoint;
import flixel.math.FlxAngle;
import flixel.FlxTypes;

import haxe.xml.Access;

using StringTools;
using flixel.util.FlxColorTransformUtil;

@:structInit
final class AlphabetOutline {
	public var anim:String;
	public var x:Float;
	public var y:Float;
}
@:structInit
final class AlphabetComponent {
	@:optional public var refIndex:Null<Int>;
	@:optional public var outIndex:Null<Int>;
	public var anim:String;
	public var x:Float;
	public var y:Float;

	// Precalculated values for angle
	public var shouldRotate:Bool;
	public var angle:Float;
	public var sin:Float;
	public var cos:Float;
	public var scaleX:Float;
	public var scaleY:Float;

	public var hasColorMode:Bool;
	public var colorMode:ColorMode;
}

@:structInit
final class AlphabetLetterData {
	@:optional public var isDefault:Bool = false;
	public var advance:Float;
	public var advanceEmpty:Bool;
	public var components:Array<AlphabetComponent>;
	public var startIndex:Int = 0;
}

enum abstract AlphabetAlignment(ByteUInt) from ByteUInt to ByteUInt {
	var LEFT;
	var CENTER;
	var RIGHT;

	public function getMultiplier():Float {
		return switch(this) {
			case CENTER: 0.5;
			case RIGHT: 1.0;
			default: 0.0;
		}
	}

	@:from
	public static function fromString(value:String):AlphabetAlignment
		return switch(value) {
			case "left": LEFT;
			case "center": CENTER;
			case "right": RIGHT;
			default: LEFT;
		}
}

enum abstract CaseMode(ByteUInt) from ByteUInt to ByteUInt {
	var NONE;
	var UPPER;
	var LOWER;

	@:from
	public static function fromString(value:String):CaseMode
		return switch(value) {
			case "none": NONE;
			case "upper": UPPER;
			case "lower": LOWER;
			default: NONE;
		}
}

enum abstract ColorMode(ByteInt) from ByteInt to ByteInt {
	var TINT = 0;
	var OFFSET = 1;
	var NONE = 2;

	public function setColorTransform(color:openfl.geom.ColorTransform, red:Float, green:Float, blue:Float, alpha:Float) {
		var moduloWorkaround:Int = this;
		var tintMult = Math.max(-moduloWorkaround + 1, 0);
		var tintOffset = Math.min(moduloWorkaround, 1);
		var offsetMult = (moduloWorkaround % 2) * 255;

		color.redMultiplier = red * tintMult + tintOffset;
		color.greenMultiplier = green * tintMult + tintOffset;
		color.blueMultiplier = blue * tintMult + tintOffset;
		color.redOffset = red * offsetMult;
		color.greenOffset = green * offsetMult;
		color.blueOffset = blue * offsetMult;
		color.alphaMultiplier = alpha;
	}
}

enum abstract AlphabetRenderMode(ByteUInt) from ByteUInt to ByteUInt {
	var DEFAULT = 0;
	var MONOSPACE = 1;
}

@:allow(funkin.editors.alphabet.AlphabetEditor)
@:allow(funkin.editors.alphabet.AlphabetMainDataScreen)
class Alphabet extends FlxSprite {
	public var effects:Array<RegionEffect> = [];
	var __renderData:AlphabetRenderData;
	var __component:AlphabetComponent;
	var __useDrawScale:Bool = false;
	var __drawScale:FlxPoint = FlxPoint.get(1, 1);

	public var text(default, set):String = "";
	@:isVar public var textWidth(get, set):Float;
	public var textHeight(get, null):Float;

	public var alignment:AlphabetAlignment = LEFT;
	public var forceCase:CaseMode = NONE;

	var __laneWidths:Array<Float> = [];
	var __forceWidth:Float = 0.0; // TODO: implement functionality for this.
	var __queueResize:Bool = false;
	var __animTime:Float = 0.0;
	var __ogForceScreen:Bool = false;

	public var originOffset:FlxPoint = FlxPoint.get();

	public var font(default, set):String;
	var colorMode:ColorMode = TINT;
	var defaultAdvance:Float = 40.0;
	var lineGap:Float = 75.0;
	var fps:Float = 24.0;
	var letterData:Map<String, AlphabetLetterData> = [];
	var defaults:Vector<AlphabetLetterData> = {
		var v = new Vector(3);
		v[0] = null;
		v[1] = null;
		v[2] = null;
		v;
	};
	var loaded:Vector<Array<String>> = {
		var v = new Vector(3);
		v[0] = [];
		v[1] = [];
		v[2] = [];
		v;
	};
	var manualLetters:Array<String> = [];
	var failedLetters:Array<String> = [];
	var failedOutlines:Array<String> = [];

	public var renderMode:AlphabetRenderMode = DEFAULT;

	// for menu shit
	public var targetY:Float = 0;
	public var isMenuItem:Bool = false;
	public var itemHeight:Float = 120;

	public function new(?x:Float, ?y:Float, ?text:String = "", ?font:OneOfTwo<String, Bool> = "normal") {
		super(x, y);
		this.text = text;
		if (font != "<SKIP>")
			this.font = (font is String) ? font : ((font == true) ? "bold" : "normal"); // == true just in case
		this.__renderData = new AlphabetRenderData(this);
	}

	override function update(elapsed:Float):Void {
		//super.update(elapsed);
		// FLXOBJECT UPDATE
		#if FLX_DEBUG
		@:privateAccess FlxBasic.activeCount += 1;
		#end

		last.set(x, y);

		if (path != null && path.active)
			path.update(elapsed);

		if (moves)
			updateMotion(elapsed);

		wasTouching = touching;
		touching = FlxDirectionFlags.NONE;
		// FLXOBJECT UPDATE END

		__animTime += elapsed;
		for (effect in effects)
			effect.effectTime += elapsed * effect.speed;

		if (isMenuItem) {
			var scaledY = targetY * 1.3;

			y = CoolUtil.fpsLerp(y, (scaledY * itemHeight) + (FlxG.height - height) * 0.5, 0.16);
			x = CoolUtil.fpsLerp(x, (targetY * 20) + 90, 0.16);
		}
	}

	override function draw():Void {
		__ogForceScreen = forceIsOnScreen;
		forceIsOnScreen = true;
		super.draw();
	}

	override function isSimpleRender(?camera:FlxCamera):Bool {
		return false; // maybe ill get simple render working another time??? not right now tho.
	}

	override function drawComplex(camera:FlxCamera):Void {
		forceIsOnScreen = __ogForceScreen;

		if (__queueResize)
			recalcSizes();
		var curLine = 0;
		var lastLine = 0;
		var daText = switch (forceCase) {
			case UPPER: text.toUpperCase();
			case LOWER: text.toLowerCase();
			case NONE: text;
		}

		var alignmentMultiplier = alignment.getMultiplier();

		var ogOffX = frameOffset.x;
		var ogOffY = frameOffset.y;
		frameOffset.x -= (textWidth - __laneWidths[0]) * alignmentMultiplier;

		var isGraphicsShader = shader != null && shader is flixel.graphics.tile.FlxGraphicsShader;
		var ogRed:Float = colorTransform.redMultiplier;
		var ogGreen:Float = colorTransform.greenMultiplier;
		var ogBlue:Float = colorTransform.blueMultiplier;
		var ogAlpha:Float = colorTransform.alphaMultiplier;

		var frameTime = Math.floor(__animTime * fps);

		var isMonospace = renderMode == MONOSPACE;

		for (i in 0...daText.length) {
			var cantrace = i == daText.length - 1;
			__renderData.reset(this, ogRed, ogGreen, ogBlue, ogAlpha, daText.charAt(i));
			for (effect in effects) {
				if (effect.willModify(i, i - lastLine, __renderData))
					effect.modify(i, i - lastLine, __renderData);
			}

			var letter = __renderData.letter;
			if (letter == "\n") {
				curLine++;
				lastLine = i + 1;
				frameOffset.x = ogOffX - (textWidth - __laneWidths[curLine]) * alignmentMultiplier;
				frameOffset.y -= lineGap;
				continue;
			}

			var data = getData(letter);

			if (data == null) {
				frameOffset.x -= defaultAdvance;
				continue;
			}

			var advance:Float = Math.NaN;

			for (i in 0...data.components.length) {
				__component = data.components[i];
				var anim = getLetterAnim(letter, data, __component, i);
				//if (cantrace)
					//trace(anim.name + " | " + __component.anim + " | " + frames.frames[anim.frames[0]]);
				advance = (Math.isNaN(advance)) ? getAdvance(letter, anim, data) : advance;

				if (anim == null || __renderData.alpha <= 0.0)
					continue;

				var frameToGet = frameTime % anim.numFrames;
				frame = frames.frames[anim.frames[frameToGet]];

				var offsetX = __component.x + __renderData.offsetX;
				var offsetY = frame.sourceSize.y - lineGap + __component.y + __renderData.offsetY;
				__useDrawScale = false;
				if (__component.refIndex != null) {
					var actualIdx = __component.refIndex + data.startIndex;
					var refCompon = data.components[actualIdx];
					var refAnim = getLetterAnim(letter, data, refCompon, actualIdx);
					var refFrameIdx = frameTime % refAnim.numFrames;
					var refFrame = frames.frames[refAnim.frames[refFrameIdx]];

					var diff = Math.min(
						(frame.sourceSize.x - refFrame.sourceSize.x),
						(frame.sourceSize.y - refFrame.sourceSize.y)
					);
					var diffScale = (diff == (frame.sourceSize.x - refFrame.sourceSize.x)) ? __component.scaleX : __component.scaleY;

					__useDrawScale = true;
					__drawScale.set(
						(refFrame.sourceSize.x * __component.scaleX + diff * diffScale) / frame.sourceSize.x,
						(refFrame.sourceSize.y * __component.scaleY + diff * diffScale) / frame.sourceSize.y
					);
					offsetX = __component.x * __drawScale.x + __renderData.offsetX + diff * 0.5 + refCompon.x;
					offsetY = refFrame.sourceSize.y - lineGap + __component.y * __drawScale.y + __renderData.offsetY + diff * 0.5 + refCompon.y;
				}

				if (isMonospace)
					offsetX -= (defaultAdvance - advance) * 0.5;
				frameOffset.x += offsetX;
				frameOffset.y += offsetY;
				if (!isOnScreen(camera)) {
					frameOffset.y -= offsetY;
					frameOffset.x -= offsetX;
					break;
				}

				if (__component.hasColorMode)
					__component.colorMode.setColorTransform(colorTransform, __renderData.red, __renderData.green, __renderData.blue, __renderData.alpha);
				else
					colorMode.setColorTransform(colorTransform, __renderData.red, __renderData.green, __renderData.blue, __renderData.alpha);

				if (isGraphicsShader)
					shader.setCamSize(_frame.frame.x, _frame.frame.y, _frame.frame.width, _frame.frame.height);
				drawLetter(camera);

				frameOffset.y -= offsetY;
				frameOffset.x -= offsetX;
			}
			frameOffset.x -= isMonospace ? defaultAdvance : advance;
		}
		__component = null;

		setColorTransform(ogRed, ogGreen, ogBlue, ogAlpha, 0, 0, 0, 0);
		frameOffset.set(ogOffX, ogOffY);
	}

	function drawLetter(camera) {
		_frame.prepareMatrix(_matrix, ANGLE_0, checkFlipX() != camera.flipX, checkFlipY() != camera.flipY);

		_matrix.translate(_frame.frame.width * -0.5, _frame.frame.height * -0.5);
		if (__useDrawScale)
			_matrix.scale(__drawScale.x, __drawScale.y);
		else
			_matrix.scale(__component.scaleX, __component.scaleY);
		if(__component.shouldRotate)
			_matrix.rotateWithTrig(__component.cos, __component.sin);
		_matrix.translate(_frame.frame.width * 0.5, _frame.frame.height * 0.5);

		_matrix.translate(-origin.x, -origin.y);

		if (frameOffsetAngle != null && frameOffsetAngle != angle)
		{
			var angleOff = (frameOffsetAngle - angle) * FlxAngle.TO_RAD;
			var cos = Math.cos(angleOff);
			var sin = Math.sin(angleOff);
			// cos doesnt need to be negated
			_matrix.rotateWithTrig(cos, -sin);
			_matrix.translate(-frameOffset.x, -frameOffset.y);
			_matrix.rotateWithTrig(cos, sin);
		}
		else
			_matrix.translate(-frameOffset.x, -frameOffset.y);

		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}

		doAdditionalMatrixStuff(_matrix, camera);

		if (layer != null)
			layer.drawPixels(this, camera, _frame, framePixels, _matrix, colorTransform, blend, antialiasing, shaderEnabled ? shader : null);
		else
			camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shaderEnabled ? shader : null);
	}

	override function updateHitbox():Void {
		offset.set(-0.5 * (width - textWidth), -0.5 * (height - textHeight));
		origin.set(textWidth * 0.5 + originOffset.x, textHeight * 0.5 + originOffset.y);
	}

	function recalcSizes():Void {
		__queueResize = false;
		var curLine = 0;
		var daText = switch (forceCase) {
			case UPPER: text.toUpperCase();
			case LOWER: text.toLowerCase();
			case NONE: text;
		}
		@:bypassAccessor textWidth = 0;
		textHeight = lineGap;
		__laneWidths = [0];
		for (i in 0...daText.length) {
			var letter = daText.charAt(i);
			if (letter == "\n") {
				textHeight += lineGap;
				__laneWidths.push(0);
				curLine++;
				continue;
			}

			var data = getData(letter);
			__laneWidths[curLine] += (data != null && data.components.length > 0) ? getAdvance(letter, getLetterAnim(letter, data, data.components[data.startIndex], data.startIndex), data) : defaultAdvance;
			@:bypassAccessor textWidth = Math.max(textWidth, __laneWidths[curLine]);
		}

		origin.set(textWidth * 0.5 + originOffset.x, textHeight * 0.5 + originOffset.y);
	}

	function getAdvance(letter:String, anim:FlxAnimation, data:AlphabetLetterData):Float {
		if (anim == null)
			return defaultAdvance;

		if (data.advanceEmpty && !data.isDefault) {
			data.advanceEmpty = false;
			data.advance = frames.frames[anim.frames[0]].sourceSize.x;
		}
		return (data.isDefault) ? frames.frames[anim.frames[0]].sourceSize.x : data.advance;
	}

	private function fastGetData(char:String):AlphabetLetterData {
		var data = letterData.get(char);

		if (data == null) {
			var charCode:Int = char.charCodeAt(0);
			if (charCode >= 'A'.code && charCode <= 'Z'.code && defaults[CaseMode.UPPER] != null)
				data = defaults[CaseMode.UPPER];
			else if (charCode >= 'a'.code && charCode <= 'z'.code && defaults[CaseMode.LOWER] != null)
				data = defaults[CaseMode.LOWER];
			else
				data = defaults[CaseMode.NONE];
		}

		return data;
	}

	function getData(char:String):AlphabetLetterData {
		if (failedLetters.contains(char)) return null;
		for (i in 0...3) { // this feels wrong
			if (loaded[i].contains(char))
				return defaults[i];
		}

		var data:AlphabetLetterData = fastGetData(char);

		if (data == null) {
			failedLetters.push(char);
			Logs.error('Character $char: Data not found.');
			return null;
		} else if (data.isDefault)
			loaded[defaultsIndexOf(data)].push(char);
		return data;
	}

	final function defaultsIndexOf(data:AlphabetLetterData):Int {
		//while(i < defaults.length) {
		for(i in 0...3) {
			if(defaults[i] == data)
				return i;
		}
		return -1;
	}

	function fastGetLetterAnim(char:String, data:AlphabetLetterData, component:AlphabetComponent, index:Int):FlxAnimation {
		var name = char + Std.string(index);

		var anim = (data.isDefault) ?
			component.anim.replace("LOWERLETTER", char.toLowerCase()).replace("UPPERLETTER", char.toUpperCase()).replace("LETTER", char) :
			component.anim;
		animation.addByPrefix(name, anim, fps);
		return animation.exists(name) ? animation.getByName(name) : null;
	}

	function getLetterAnim(char:String, data:AlphabetLetterData, component:AlphabetComponent, index:Int):FlxAnimation {
		if (data == null) return null;
		var name = char + Std.string(index);
		if (animation.exists(name)) return animation.getByName(name);

		var anim = (data.isDefault) ?
			component.anim.replace("LOWERLETTER", char.toLowerCase()).replace("UPPERLETTER", char.toUpperCase()).replace("LETTER", char) :
			component.anim;
		animation.addByPrefix(name, anim, fps);
		if (!animation.exists(name)) {
			failedLetters.push(char);
			var traceIndex = (component.refIndex != null) ? 'Outline For Component Index ${component.refIndex}' : 'Component Index ${index - data.startIndex}';
			Logs.error('Character $char: $traceIndex: Animation "$anim" not found.');
			return null;
		}
		return animation.getByName(name);
	}

	/*function getLetterOutline(char:String, component:AlphabetComponent, index:Int) {
		var name = char + "Outline" + Std.string(index);
		if (failedOutlines.contains(name)) return null;
		if (animation.exists(name)) return animation.getByName(name);

		animation.addByPrefix(name, component.outline.anim, fps);
		if (!animation.exists(name)) {
			failedOutlines.push(name);
			return null;
		}
		return animation.getByName(name);
	}*/

	function checkNode(node:Xml):Void {
		switch (node.nodeName) {
			case "spritesheet":
				if (frames == null)
					frames = Paths.getFrames(node.firstChild().nodeValue);
				else {
					for (frame in Paths.getFrames(node.firstChild().nodeValue).frames)
						frames.pushFrame(frame);
				}
			case "defaultAnim":
				var idx = ["UPPER", "LOWER"].indexOf(node.get("casing").toUpperCase()) + 1;

				var angle:Float = Std.parseFloat(node.get("angle")).getDefaultFloat(0.0);
				var rad = angle * FlxAngle.TO_RAD;
				var angleCos = Math.cos(rad);
				var angleSin = Math.sin(rad);

				var res:AlphabetLetterData = {
					isDefault: true,
					advance: 0.0,
					advanceEmpty: true,
					components: [{
						anim: node.firstChild().nodeValue,

						x: 0.0,
						y: 0.0,
						scaleX: Std.parseFloat(node.get("scaleX")).getDefaultFloat(1.0),
						scaleY: Std.parseFloat(node.get("scaleY")).getDefaultFloat(1.0),

						shouldRotate: angle != 0,
						angle: angle,
						cos: angleCos,
						sin: angleSin,

						hasColorMode: false,
						colorMode: 0
					}],
					startIndex: 0
				}

				defaults[idx] = res;
			case "composite":
				if(!node.exists("char")) {
					Logs.error("<composite> must have a char attribute", "Alphabet");
					return;
				}
				var startIndex:Int = 0;
				var componentsPushed:Int = 0;
				var char = node.get("char");
				var advance:Float = Std.parseFloat(node.get("advance"));
				var components:Array<AlphabetComponent> = [];
				for (component in node.elementsNamed("component")) {
					if(!component.exists("anim")) {
						Logs.error('Character $char: <component> must have a anim attribute', "Alphabet");
						return;
					}

					var angle:Float = Std.parseFloat(component.get("angle")).getDefaultFloat(0.0);
					var rad = angle * FlxAngle.TO_RAD;
					var angleCos = Math.cos(rad);
					var angleSin = Math.sin(rad);

					var xOff:Float = -Std.parseFloat(component.get("x")).getDefaultFloat(0.0);
					var yOff:Float = Std.parseFloat(component.get("y")).getDefaultFloat(0.0);
					var xScale:Float = Std.parseFloat(component.get("scaleX")).getDefaultFloat(1.0);
					var yScale:Float = Std.parseFloat(component.get("scaleY")).getDefaultFloat(1.0);

					var colorMode = ["tint", "offsets", "none"].indexOf(component.get("colorMode"));

					if (component.get("hasOutline") == "true") {
						components.insert(startIndex, {
							refIndex: componentsPushed,
							anim: component.get("outline"),

							x: Std.parseFloat(component.get("outlineX")).getDefaultFloat(0.0),
							y: Std.parseFloat(component.get("outlineY")).getDefaultFloat(0.0),
							scaleX: xScale,
							scaleY: yScale,

							shouldRotate: angle != 0,
							angle: angle,
							cos: angleCos,
							sin: angleSin,

							hasColorMode: colorMode >= 0,
							colorMode: colorMode,
						});
						++startIndex;
					}

					components.push({
						outIndex: (component.get("hasOutline") == "true") ? startIndex - 1 : null,
						anim: component.get("anim"),

						x: xOff,
						y: yOff,
						scaleX: xScale,
						scaleY: yScale,

						shouldRotate: angle != 0,
						angle: angle,
						cos: angleCos,
						sin: angleSin,

						hasColorMode: colorMode >= 0,
						colorMode: colorMode,
					});
					++componentsPushed;
				}
				letterData.set(char, {
					isDefault: false,
					advance: advance,
					advanceEmpty: Math.isNaN(advance),
					components: components,
					startIndex: startIndex
				});
				manualLetters.push(char);
			case "anim":
				if(!node.exists("char")) {
					Logs.error("<anim> must have a char attribute", "Alphabet");
					return;
				}
				var char = node.get("char");

				var angle:Float = Std.parseFloat(node.get("angle")).getDefaultFloat(0.0);
				var rad = angle * FlxAngle.TO_RAD;
				var angleCos = Math.cos(rad);
				var angleSin = Math.sin(rad);

				var xOff:Float = -Std.parseFloat(node.get("x")).getDefaultFloat(0.0);
				var yOff:Float = Std.parseFloat(node.get("y")).getDefaultFloat(0.0);
				var xScale:Float = Std.parseFloat(node.get("scaleX")).getDefaultFloat(1.0);
				var yScale:Float = Std.parseFloat(node.get("scaleY")).getDefaultFloat(1.0);
				var advance:Float = Std.parseFloat(node.get("advance"));

				var colorMode = ["tint", "offsets", "none"].indexOf(node.get("colorMode"));

				var components:Array<AlphabetComponent> = [];
				if (node.get("hasOutline") == "true") {
					components.insert(0, {
						refIndex: 0,
						anim: node.get("outline"),

						x: Std.parseFloat(node.get("outlineX")).getDefaultFloat(0.0),
						y: Std.parseFloat(node.get("outlineY")).getDefaultFloat(0.0),
						scaleX: xScale,
						scaleY: yScale,

						shouldRotate: angle != 0,
						angle: angle,
						cos: angleCos,
						sin: angleSin,

						hasColorMode: colorMode >= 0,
						colorMode: colorMode,
					});
				}

				components.push({
					outIndex: (node.get("hasOutline") == "true") ? 0 : null,
					anim: node.firstChild().nodeValue,

					x: xOff,
					y: yOff,
					scaleX: xScale,
					scaleY: yScale,

					shouldRotate: angle != 0,
					angle: angle,
					cos: angleCos,
					sin: angleSin,

					hasColorMode: colorMode >= 0,
					colorMode: colorMode,
				});
				letterData.set(char, {
					isDefault: false,
					advance: advance,
					advanceEmpty: Math.isNaN(advance),
					components: components,
					startIndex: (node.get("hasOutline") == "true") ? 1 : 0
				});
				manualLetters.push(char);
			case "languageSection": // used to only parse characters if a specific language is selected
				if(!node.exists("langs")) {
					Logs.error("<languageSection> must have a langs attribute", "Alphabet");
					return;
				}
				var langs = [for (lang in node.get("langs").split(",")) lang.trim()];
				// maybe add a way to toggle this off? like force it to add all
				if (langs.contains(Options.language)) {
					for (langNode in node.elements())
						checkNode(langNode);
				}
		}
	}

	function loadFont(value:String):Void {
		__queueResize = true;

		var xml:Xml = Xml.parse(Assets.getText(Paths.xml("alphabet/" + value))).firstElement();

		// reset old values
		letterData = new Map();
		defaults = {
			var v = new Vector(3);
			v[0] = null;
			v[1] = null;
			v[2] = null;
			v;
		}
		loaded = {
			var v = new Vector(3);
			v[0] = [];
			v[1] = [];
			v[2] = [];
			v;
		}
		failedLetters = [" "];

		defaultAdvance = Std.parseFloat(xml.get("advance")).getDefaultFloat(40.0);
		lineGap = Std.parseFloat(xml.get("lineGap")).getDefaultFloat(75.0);
		fps = Std.parseFloat(xml.get("fps")).getDefaultFloat(24.0);
		forceCase = xml.get("forceCasing").getDefault("none").toLowerCase();
		colorMode = (["offsets", "none"].indexOf(xml.get("colorMode")) + 1);
		antialiasing = xml.get("antialiasing").getDefault("true") == "true";

		frames = null;

		for (node in xml.elements())
			checkNode(node);
	}

	private static var alphabetProperties:Array<String> = ["fps", "advance", "lineGap", "forceCasing", "useColorOffsets", "antialiasing"];
	private static var componentProperties:Array<String> = ["name", "anim", "x", "y", "scaleX", "scaleY", "angle", "offsetX", "offsetY"];

	public function buildXML():Xml {
		var xml = Xml.createElement("alphabet");
		xml.set("fps", Std.string(fps));
		xml.set("advance", Std.string(defaultAdvance));
		xml.set("lineGap", Std.string(lineGap));
		xml.set("forceCasing", ["none", "upper", "lower"][forceCase]);
		xml.set("useColorOffsets", ["tint", "offsets", "none"][colorMode]);
		xml.set("antialiasing", antialiasing ? "true" : "false");

		xml.attributeOrder = alphabetProperties;

		/*for (component in components) {
			var componentXml = Xml.createElement("component");
			componentXml.attributeOrder = componentProperties;
			componentXml.set("name", component.name);
			componentXml.set("anim", component.anim);
			componentXml.set("x", Std.string(component.x));
			componentXml.set("y", Std.string(component.y));
			if(component.scaleX != 1) componentXml.set("scaleX", Std.string(component.scaleX));
			if(component.scaleY != 1) componentXml.set("scaleY", Std.string(component.scaleY));
			if(component.angle != 0) componentXml.set("angle", Std.string(component.angle));
			if(component.offsetX != 0) componentXml.set("offsetX", Std.string(component.offsetX));
			if(component.offsetY != 0) componentXml.set("offsetY", Std.string(component.offsetY));
			xml.addChild(componentXml);
		}*/

		return xml;
	}

	public function copyData(from:Alphabet) {
		if (from.font == this.font) return;

		__queueResize = true;
		@:bypassAccessor @:bypassAccessor this.font = from.font; // double bypass in case haxe gets finicky
		this.frames = from.frames;
		this.antialiasing = from.antialiasing;
		this.fps = from.fps;
		this.defaultAdvance = from.defaultAdvance;
		this.lineGap = from.lineGap;
		this.forceCase = from.forceCase;
		this.colorMode = from.colorMode;
		this.letterData = from.letterData;
		this.defaults = from.defaults;
		this.loaded = from.loaded;
		this.manualLetters = from.manualLetters;
		this.failedLetters = from.failedLetters;
		this.failedOutlines = from.failedOutlines;
	}

	override function destroy():Void {
		originOffset = FlxDestroyUtil.destroy(originOffset);
		__drawScale = FlxDestroyUtil.put(__drawScale);
		__renderData = null;
		__laneWidths = null;
		effects = null;
		letterData = null;
		defaults = null;
		manualLetters = null;
		failedLetters = null;
		failedOutlines = null;
		super.destroy();
	}

	function get_textWidth():Float {
		if (__queueResize)
			recalcSizes();
		return textWidth;
	}
	function set_textWidth(value:Float):Float {
		if(!__queueResize)
			__queueResize = __forceWidth != value;
		return __forceWidth = value;
	}

	override function get_width():Float {
		return textWidth * scale.x;
	}
	override function get_height():Float {
		return textHeight * scale.y;
	}

	function get_textHeight():Float {
		if (__queueResize)
			recalcSizes();
		return textHeight;
	}

	function set_text(value:String):String {
		if(!__queueResize)
			__queueResize = text != value;
		return text = value;
	}

	function set_font(value:String):String {
		if (font != value) {
			loadFont(font = value);
		}
		return value;
	}
}