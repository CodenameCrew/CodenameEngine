package funkin.backend.shaders;

import haxe.Exception;
import haxe.io.Path;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxStringUtil;
import hscript.IHScriptCustomBehaviour;
import openfl.display.BitmapData;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.display.Shader;
import openfl.display3D._internal.GLProgram;
import openfl.display3D._internal.GLShader;
import openfl.display3D.Program3D;
import openfl.utils._internal.Log;

using StringTools;
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.Program3D)
@:access(openfl.display.ShaderInput)
@:access(openfl.display.ShaderParameter)
class FunkinShader extends FlxShader implements IHScriptCustomBehaviour {
	#if REGION /* Backward Compatibility */
	private static var __instanceFields = Type.getInstanceFields(FunkinShader);
	private static var FRAGMENT_SHADER = 0;
	private static var VERTEX_SHADER = 1;

	public var glslVer(get, set):String;
	inline function get_glslVer():String return glVersion;
	inline function set_glslVer(v:String):String return glVersion = v;

	public var glRawFragmentSource(get, set):String;
	inline function get_glRawFragmentSource():String return __glFragmentSourceRaw;
	inline function set_glRawFragmentSource(v:String):String return __glFragmentSourceRaw = v;

	public var glRawVertexSource(get, set):String;
	inline function get_glRawVertexSource():String return __glVertexSourceRaw;
	inline function set_glRawVertexSource(v:String):String return __glVertexSourceRaw = v;

	// Unused... cne-openfl uses a different system
	var __cancelNextProcessGLData:Bool = false;
	public var onProcessGLData:FlxTypedSignal<(String, String)->Void> = new FlxTypedSignal<(String, String)->Void>();
	#end

	public static function getShaderCode(key:String, isFragment = true):Null<String> {
		var path = "shaders/" + key;
		key = Path.withoutExtension(key);

		final ext = Path.extension(path);
		if (ext == "") path = path + (isFragment ? ".frag" : ".vert");
		else isFragment = ext != "vert";

		path = Paths.getPath(path);
		return Assets.exists(path) ? Assets.getText(path) : null;
	}

	private static function processGLSLText(source:String, glVersion:String, isFragment:Bool, ?pragmas:Map<String, String>):String
		return Shader.processGLSLText(_processGLSLText(source, glVersion, isFragment, pragmas), glVersion, isFragment);

	private static function _processGLSLText(source:String, glVersion:String, isFragment:Bool, ?pragmas:Map<String, String>):String {
		var injectedFragColor = StringTools.contains(source, "out vec4"), canInjectFragColorFix = switch (glVersion) {
			case "300 es", "310 es", "320 es", "330", "400", "410", "420", "430", "440", "450", "460": isFragment;
			default: false;
		};
		if (pragmas != null) {
			final pragmaKeyword = ~/#pragma (\w+)/g;
			source = pragmaKeyword.map(source, (_) -> {
				var name = pragmaKeyword.matched(1), pragma:String;
				if (pragmas.exists(name)) pragma = pragmas.get(name);
				else {
					if (name != "header" && name != "body") return '#pragma $name';
					pragma = "";
				}

				var pragma = pragmas.get(name);
				if (name == "header" && canInjectFragColorFix && !injectedFragColor) {
					injectedFragColor = true;
					if (!StringTools.contains(pragma, "out vec4")) return processGLSLText(Shader.fragColorHeaderFix + pragma, glVersion, isFragment, pragmas);
				}
				return processGLSLText(pragma, glVersion, isFragment, pragmas);
			});
		}

		inline function tryGetShaderCode(key:String) {
			final s = getShaderCode(key, isFragment);
			if (s == null) {
				Logs.traceColored([
					Logs.logText('[Shader] ', RED),
					Logs.logText('Failed to import shader $key', RED),
				]);
				return "";
			}
			return s;
		}

		final includeKeyword = ~/#include ['"](.+)['"]/g;
		final importKeyword = ~/#import\s+<(.*)>/g;
		source = importKeyword.map(source, (_) ->
			return processGLSLText(tryGetShaderCode(importKeyword.matched(1)), glVersion, isFragment, pragmas) ?? "");

		return source = includeKeyword.map(source, (_) ->
			return processGLSLText(tryGetShaderCode(includeKeyword.matched(1)), glVersion, isFragment, pragmas) ?? "");
	}

	private static var __defaultsAvailable:Bool;
	private static var __glFragmentSourceDefault:String;
	private static var __glVertexSourceDefault:String;
	private static var __glFragmentPragmasDefault:Map<String, String>;
	private static var __glVertexPragmasDefault:Map<String, String>;
	private static var __glFragmentExtensionsDefault:Array<ShaderExtension>;
	private static var __glVertexExtensionsDefault:Array<ShaderExtension>;

	public var onGLUpdate:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

	public var fileName:String = "FunkinShader";
	public var fragFileName:String = "FunkinShader";
	public var vertFileName:String = "FunkinShader";

	public var shaderPrefix:String = "";
	public var fragmentPrefix:String = "";
	public var vertexPrefix:String = "";

	private var __immediate:Bool;

	public function new(?fragmentSource:String, ?vertexSource:String, ?version:String,
		?fragmentExtensions:Array<ShaderExtension>, ?vertexExtensions:Array<ShaderExtension>, immediate = false
	) {
		if (!__defaultsAvailable) {
			__glFragmentSourceDefault = __glFragmentSourceRaw;
			__glVertexSourceDefault = __glVertexSourceRaw;
			__glFragmentPragmasDefault = __glFragmentPragmas.copy();
			__glVertexPragmasDefault = __glVertexPragmas.copy();
			__glFragmentExtensionsDefault = __glFragmentExtensions ?? [];
			__glVertexExtensionsDefault = __glVertexExtensions ?? [];
			__defaultsAvailable = true;
		}

		__immediate = immediate;

		if (version != null) glVersion = version;
		if (vertexExtensions != null) glVertexExtensions = vertexExtensions;
		if (fragmentExtensions != null) glFragmentExtensions = fragmentExtensions;
		if (vertexSource != null) glVertexSource = vertexSource;
		if (fragmentSource != null) glFragmentSource = fragmentSource;

		super();

		if (!__isGenerated) {
			__isGenerated = true;
			__init();
		}
	}

	public function loadShader(name:String, ?version:String, immediate = false):FunkinShader {
		final fragment = getShaderCode(name, true), vertex = getShaderCode(name, false);

		glVersion = version;
		glVertexSource = vertex ?? __glVertexSourceDefault;
		glFragmentSource = fragment ?? __glFragmentSourceDefault;

		if (immediate) __init();
		return this;
	}

	override function __initGL():Void {
		if (__immediate) {
			__context = FlxG.stage.context3D;
			__enable();
		}
		super.__initGL();
	}

	override function __updateGL():Void {
		onGLUpdate.dispatch();
		super.__updateGL();
	}

	public function hget(name:String):Dynamic {
		if (__glSourceDirty || __data == null) __init();

		if (thisHasField(name) || thisHasField('get_${name}')) return Reflect.getProperty(this, name);
		else if (!Reflect.hasField(__data, name)) return null;

		final field:Dynamic = Reflect.field(__data, name);

		var cl:String = Type.getClassName(Type.getClass(field));

		// little problem we are facing boys...

		// cant do "field is ShaderInput" because ShaderInput has the @:generic metadata
		// aka instead of ShaderInput<Float> it gets built as ShaderInput_Float
		// this should be fine tho because we check the class, and the fields don't vary based on the type

		// thanks for looking in the code cne fans :D!! -lunar

		if (cl.startsWith("openfl.display.ShaderParameter"))
			return (field.__length > 1) ? field.value : field.value[0];
		else if (cl.startsWith("openfl.display.ShaderInput"))
			return field.input;
		return field;
	}

	public function hset(name:String, val:Dynamic):Dynamic {
		if (__glSourceDirty || __data == null) __init();

		if (thisHasField(name) || thisHasField('set_${name}')) {
			Reflect.setProperty(this, name, val);
			return val;
		}
		else if (!Reflect.hasField(__data, name)) {
			// ??? huh
			Reflect.setField(__data, name, val);
			return val;
		}

		var field = Reflect.field(__data, name);
		var cl = Type.getClassName(Type.getClass(field));
		var isNotNull = val != null;
		// cant do "field is ShaderInput" for some reason
		if (cl.startsWith("openfl.display.ShaderParameter")) {
			if (field.__length <= 1) {
				// that means we wait for a single number, instead of an array
				if (field.__isInt && isNotNull && !(val is Int)) {
					throw new ShaderTypeException(name, Type.getClass(val), 'Int');
					return null;
				} else
				if (field.__isBool && isNotNull && !(val is Bool)) {
					throw new ShaderTypeException(name, Type.getClass(val), 'Bool');
					return null;
				} else
				if (field.__isFloat && isNotNull && !(val is Float)) {
					throw new ShaderTypeException(name, Type.getClass(val), 'Float');
					return null;
				}
				return field.value = isNotNull ? [val] : null;
			} else {
				if (isNotNull && !(val is Array)) {
					throw new ShaderTypeException(name, Type.getClass(val), Array);
					return null;
				}
				return field.value = val;
			}
		} else if (cl.startsWith("openfl.display.ShaderInput")) {
			// shader input!!
			var bitmap:BitmapData;
			if (!isNotNull) bitmap = null;
			else if (val is BitmapData) bitmap = val;
			else if (val is FlxGraphic) bitmap = val.bitmap;
			else {
				throw new ShaderTypeException(name, Type.getClass(val), BitmapData);
				return null;
			}
			field.input = bitmap;
		}

		return val;
	}

	override function __buildSourcePrefix(isFragment:Bool):String {
		var result = super.__buildSourcePrefix(isFragment) + '\n$shaderPrefix';
		return isFragment ? result + '\n$fragmentPrefix' : result + '\n$vertexPrefix';
	}

	override function set_glFragmentExtensions(value:Array<ShaderExtension>):Array<ShaderExtension> {
		if (value == null) value = __glFragmentExtensionsDefault;
		if (value != __glFragmentExtensions) __glSourceDirty = true;
		return __glFragmentExtensions = value;
	}

	override function set_glVertexExtensions(value:Array<ShaderExtension>):Array<ShaderExtension> {
		if (value == null) value = __glVertexExtensionsDefault;
		if (value != __glVertexExtensions) __glSourceDirty = true;
		return __glVertexExtensions = value;
	}

	override function set_glVersion(value:Null<String>):String {
		if (value == null || value == "") value = Flags.DEFAULT_GLSL_VERSION;
		if ((__glVersionRaw = value) != __glVersion) {
			__glSourceDirty = true;
			if (__glVertexSourceRaw != null) __glVertexSource = processGLSLText(__glVertexSourceRaw, value, false, __glVertexPragmas);
			if (__glFragmentSourceRaw != null) __glFragmentSource = processGLSLText(__glFragmentSourceRaw, value, true, __glFragmentPragmas);
		}

		return __glVersion = value;
	}

	override function set_glFragmentSource(value:String):String {
		if (value == null || value == "") value = __glFragmentSourceDefault;
		if ((__glFragmentSourceRaw = value) != null) {
			if (__glVersion != (__glVersion = Shader.getGLSLTextVersion(value, __glVersionRaw)))
				__glSourceDirty = true;

			value = processGLSLText(value, __glVersion, true, __glFragmentPragmas);
		}

		if (value != __glFragmentSource) __glSourceDirty = true;
		return __glFragmentSource = value;
	}

	override function set_glVertexSource(value:String):String {
		if (value == null || value == "") value = __glVertexSourceDefault;
		if ((__glVertexSourceRaw = value) != null) {
			if (__glVersion != (__glVersion = Shader.getGLSLTextVersion(value, __glVersionRaw)))
				__glSourceDirty = true;

			value = processGLSLText(value, __glVersion, false, __glVertexPragmas);
		}

		if (value != __glVertexSource) __glSourceDirty = true;
		return __glVertexSource = value;
	}

	override function set_glFragmentPragmas(value:Map<String, String>):Map<String, String> {
		if (value == null) value = __glFragmentPragmasDefault;
		if (value != __glFragmentPragmas)
			__glSourceDirty = true;

		return __glFragmentPragmas = value;
	}

	override function set_glVertexPragmas(value:Map<String, String>):Map<String, String> {
		if (value == null) value = __glVertexPragmasDefault;
		if (value != __glVertexPragmas)
			__glSourceDirty = true;

		return __glVertexPragmas = value;
	}

	function registerParameter(name:String, type:String, isUniform:Bool):Void {
		__registerParameter(name, Program3D.getParameterTypeFromGLString(type, 1), 1, -1, isUniform, false, null);
	}

	public function toString():String
		return FlxStringUtil.getDebugString([for (field in Reflect.fields(data)) LabelValuePair.weak(field, Reflect.field(data, field))]);
}

class ShaderTemplates {
	#if REGION /* Backward Compatibility */
	public static final vertHeader:String = "attribute float openfl_Alpha;
attribute vec4 openfl_ColorMultiplier;
attribute vec4 openfl_ColorOffset;
attribute vec4 openfl_Position;
attribute vec2 openfl_TextureCoord;

varying float openfl_Alphav;
varying vec4 openfl_ColorMultiplierv;
varying vec4 openfl_ColorOffsetv;
varying vec2 openfl_TextureCoordv;

uniform mat4 openfl_Matrix;
uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;

attribute float alpha;
attribute vec4 colorMultiplier;
attribute vec4 colorOffset;

uniform bool hasColorTransform;";

	public static final vertBody:String = "openfl_TextureCoordv = openfl_TextureCoord;

if (hasColorTransform) {
	openfl_Alphav = openfl_Alpha * colorMultiplier.a;
	if (openfl_HasColorTransform) {
		openfl_ColorOffsetv = (openfl_ColorOffset / 255.0 * colorMultiplier) + (colorOffset / 255.0);
		openfl_ColorMultiplierv = openfl_ColorMultiplier * vec4(colorMultiplier.rgb, 1.0);
	}
	else {
		openfl_ColorOffsetv = colorOffset / 255.0;
		openfl_ColorMultiplierv = vec4(colorMultiplier.rgb, 1.0);
	}
}
else {
	openfl_Alphav = openfl_Alpha * alpha;
	if (openfl_HasColorTransform) {
		openfl_ColorOffsetv = (openfl_ColorOffset + colorOffset) / 255.0;
		openfl_ColorMultiplierv = openfl_ColorMultiplier;
	}
	else {
		openfl_ColorOffsetv = colorOffset / 255.0;
		openfl_ColorMultiplierv = vec4(1.0);
	}
}";

	public static final fragHeader:String = "varying float openfl_Alphav;
varying vec4 openfl_ColorMultiplierv;
varying vec4 openfl_ColorOffsetv;
varying vec2 openfl_TextureCoordv;

uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;
uniform sampler2D bitmap;

uniform bool hasTransform;
uniform bool hasColorTransform;

vec4 apply_flixel_transform(vec4 color) {
	if (!hasTransform) return color;
	else if (color.a <= 0.0 || openfl_Alphav == 0.0) return vec4(0.0);

	color.rgb /= color.a;
	color = clamp(openfl_ColorOffsetv + (color * openfl_ColorMultiplierv), 0.0, 1.0);
	return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
}

#define applyFlixelEffects(color) apply_flixel_transform(color)

vec4 flixel_texture2D(sampler2D bitmap, vec2 coord) {
	return apply_flixel_transform(texture2D(bitmap, coord));
}

uniform vec4 _camSize;

float map(float value, float min1, float max1, float min2, float max2) {
	return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

vec2 getCamPos(vec2 pos) {
	vec4 size = _camSize / vec4(openfl_TextureSize, openfl_TextureSize);
	return vec2(map(pos.x, size.x, size.x + size.z, 0.0, 1.0), map(pos.y, size.y, size.y + size.w, 0.0, 1.0));
}
vec2 camToOg(vec2 pos) {
	vec4 size = _camSize / vec4(openfl_TextureSize, openfl_TextureSize);
	return vec2(map(pos.x, 0.0, 1.0, size.x, size.x + size.z), map(pos.y, 0.0, 1.0, size.y, size.y + size.w));
}
vec4 textureCam(sampler2D bitmap, vec2 pos) {
	return flixel_texture2D(bitmap, camToOg(pos));
}";

	public static final fragBody:String = "gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
if (gl_FragColor.a == 0.0) discard;";

	public static final vertBackCompatVarList:Array<EReg> = [
		~/attribute float alpha/,
		~/attribute vec4 colorMultiplier/,
		~/attribute vec4 colorOffset/,
		~/uniform bool hasColorTransform/
	];

	public static final vertHeaderBackCompat:String = "attribute float openfl_Alpha;
attribute vec4 openfl_ColorMultiplier;
attribute vec4 openfl_ColorOffset;
attribute vec4 openfl_Position;
attribute vec2 openfl_TextureCoord;

varying float openfl_Alphav;
varying vec4 openfl_ColorMultiplierv;
varying vec4 openfl_ColorOffsetv;
varying vec2 openfl_TextureCoordv;

uniform mat4 openfl_Matrix;
uniform bool openfl_HasColorTransform;
uniform vec2 openfl_TextureSize;";

	public static final vertBodyBackCompat:String = "openfl_Alphav = openfl_Alpha;
openfl_TextureCoordv = openfl_TextureCoord;

if(openfl_HasColorTransform) {
	openfl_ColorMultiplierv = openfl_ColorMultiplier;
	openfl_ColorOffsetv = openfl_ColorOffset / 255.0;
}

gl_Position = openfl_Matrix * openfl_Position;";
	#end
}

class ShaderTypeException extends Exception {
	var has:Class<Dynamic>;
	var want:Class<Dynamic>;
	var name:String;

	public function new(name:String, has:Class<Dynamic>, want:Dynamic) {
		this.has = has;
		this.want = want;
		this.name = name;
		super('ShaderTypeException - Tried to set the shader uniform "${name}" as a ${Type.getClassName(has)}, but the shader uniform is a ${Std.string(want)}.');
	}
}