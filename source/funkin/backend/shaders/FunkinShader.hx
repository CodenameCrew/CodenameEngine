package funkin.backend.shaders;

import haxe.io.Path;
import haxe.Exception;

import hscript.IHScriptCustomBehaviour;

import openfl.display.BitmapData;
import openfl.display.Shader;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.display.ShaderPrecision;
import openfl.display.ShaderInput;
import openfl.display3D._internal.GLProgram;
import openfl.display3D._internal.GLShader;
import openfl.display3D.Program3D;
import openfl.utils._internal.Log;
import openfl.utils.GLSLSourceAssembler;

import flixel.addons.display.FlxRuntimeShader;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxStringUtil;

@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.Program3D)
@:access(openfl.display.ShaderInput)
@:access(openfl.display.ShaderParameter)
class FunkinShader extends FlxRuntimeShader implements IHScriptCustomBehaviour {
	public var onGLUpdate:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

	public function new(?fragmentSource:String, ?vertexSource:String, ?version:String) {
		super(fragmentSource, vertexSource, version);
	}

	public static function fromFile(fragmentPath:String, ?vertexPath:String, ?version:String):FunkinShader {
		return new FunkinShader().loadShaderFile(fragmentPath, vertexPath, version);
	}

	public function loadShaderFile(fragmentPath:String, ?vertexPath:String, ?version:String):FunkinShader {
		if (vertexPath == null) {
			final idx = fragmentPath.lastIndexOf(".");
			if (idx == -1) vertexPath = fragmentPath;
			else vertexPath = fragmentPath.substr(0, idx);
		}

		_fromFile(FlxRuntimeShader._getPath(fragmentPath, false), FlxRuntimeShader._getPath(vertexPath, true), version);

		return this;
	}

	#if REGION /* IHScriptCustomBehaviour */
	public function hget(name:String):Dynamic {
		if (__glSourceDirty) __init();

		if (__thisHasField(name) || __thisHasField('get_${name}')) return Reflect.getProperty(this, name);
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
		if (__glSourceDirty) __init();

		if (__thisHasField(name) || __thisHasField('set_${name}')) {
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
	#end

	override function __updateGL():Void {
		onGLUpdate.dispatch();
		super.__updateGL();
	}

	override function __createAssembler():Void {
		__glSourceAssembler = new FunkinShaderSourceAssembler(this);
	}

	override function toString():String {
		return __cacheProgramId != null ? 'FunkinShader(${__cacheProgramId})' : 'FunkinShader';
	}

	#if REGION /* Deprecated */
	public var shaderPrefix:String = "";
	public var fragmentPrefix:String = "";
	public var vertexPrefix:String = "";
	#end

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

	public var fileName(get, set):String;
	inline function get_fileName():String return _fragmentFilePath ?? _vertexFilePath ?? "FunkinShader";
	inline function set_fileName(v:String):String return _fragmentFilePath = _vertexFilePath = v;

	public var fragFileName(get, set):String;
	inline function get_fragFileName():String return _fragmentFilePath ?? "FunkinShader";
	inline function set_fragFileName(v:String):String return _fragmentFilePath = v;

	public var vertFileName(get, set):String;
	inline function get_vertFileName():String return _vertexFilePath ?? "FunkinShader";
	inline function set_vertFileName(v:String):String return _vertexFilePath = v;

	function registerParameter(name:String, type:String, isUniform:Bool) {
		__registerParameter(name, Shader.getParameterTypeFromGLSL(type, false), StringTools.startsWith(type, "sampler"), 1, null, isUniform, null);
	}

	// Unused... cne-openfl uses a different system
	var __cancelNextProcessGLData:Bool = false;
	public var onProcessGLData:FlxTypedSignal<(String, String)->Void> = new FlxTypedSignal<(String, String)->Void>();
	#end
}

class FunkinShaderSourceAssembler extends FlxRuntimeShader.FlxShaderSourceAssembler {
	final funkinParent:FunkinShader;

	public function new(parent:FunkinShader) {
		super(funkinParent = parent);
	}

	override function assembleSource(source:String, ?pragmas:Map<String, String>, ?extensions:Map<String, String>,
		?version:String, isVertex:Bool, useCompatibility:Bool = true, precisionHint:ShaderPrecision = FULL):String
	{
		if (version == null) version = Flags.DEFAULT_GLSL_VERSION;

		if (source == null) {
			// There's nothing to assemble with, but just return it with a prefix instead anyway.
			var dataVersion = GLSLSourceAssembler.__getVersion(version);
			return __appendPrefix(null, dataVersion.versionNumber, dataVersion.versionProfile, extensions, isVertex, precisionHint);
		}

		if (pragmas != null) {
			source = GLSLSourceAssembler.__getPragmaFinder().map(source, (glPragmaFinder:EReg) -> {
				var pragma = glPragmaFinder.matched(1);
				return pragmas.exists(pragma) ? '/*pragma $pragma*/\n' + pragmas.get(pragma) + '\n' : 'pragma $pragma';
			});
		}

		function includeERegCallback(finder:EReg) {
			var include = finder.matched(1);
			var included = __getIncludeSource(include, isVertex);
			return included != null ? '/*include $include*/\n' + included : '/*Unknown include $include*/\n';
		}

		source = GLSLSourceAssembler.__getIncludeFinder().map(source, includeERegCallback);
		source = __getImportFinder().map(source, includeERegCallback);

		var data = GLSLSourceAssembler.__getSource(source, version);
		extensions = __buildExtensions(GLSLSourceAssembler.__getExtensions(source, extensions == null ? new Map() : extensions.copy()),
			data.versionNumber, data.versionProfile, isVertex);

		if (useCompatibility) {
			data.source = __applyCompatibility(data.source, data.versionNumber, data.versionProfile, isVertex);
		}

		return __appendPrefix(data.source, data.versionNumber, data.versionProfile, extensions, isVertex, precisionHint);
	}

	override function __getIncludeSource(include:String, fromVertex:Bool):Null<String> {
		final path = Paths.getPath('shaders/' + include);
		if (Assets.exists(path)) return Assets.getText(path);

		final fallback = __getIncludeSource(include, fromVertex);
		if (fallback != null) return fallback;

		Logs.traceColored([
			Logs.logText('[Shader] ', RED),
			Logs.logText('Failed to import shader $include', RED),
		]);
		return null;
	}

	override function __appendPrefix(source:String, versionNumber:Int, versionProfile:String, extensions:Map<String, String>, isVertex:Bool,
			precisionHint:Null<ShaderPrecision>):String
	{
		var result = super.__appendPrefix(null, versionNumber, versionProfile, extensions, isVertex, precisionHint) + "\n";

		result += funkinParent.shaderPrefix + "\n" + (isVertex ? funkinParent.vertexPrefix : funkinParent.fragmentPrefix) + "\n";

		if (source != null) {
			if (!isVertex && versionNumber >= 300 && versionProfile != "compatibility" && !StringTools.contains(source, "out vec4")) {
				result += "out vec4 openfl_FragColor;\n";
			}
			result += source;
		}

		return result;
	}

	private static inline function __getImportFinder():EReg {
		return ~/(?:^|\s)#import\s+(?|"([^"]+)"|'([^']+)'|([^\s]+))/g;
	}
}

#if REGION /* Backward Compatibility */
class ShaderTemplates {
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

if (hasColorTransform)
{
	openfl_Alphav = openfl_Alpha * colorMultiplier.a;
	if (openfl_HasColorTransform)
	{
		openfl_ColorOffsetv = (openfl_ColorOffset / 255.0 * colorMultiplier) + (colorOffset / 255.0);
		openfl_ColorMultiplierv = openfl_ColorMultiplier * vec4(colorMultiplier.rgb, 1.0);
	}
	else
	{
		openfl_ColorOffsetv = colorOffset / 255.0;
		openfl_ColorMultiplierv = vec4(colorMultiplier.rgb, 1.0);
	}
}
else
{
	openfl_Alphav = openfl_Alpha * alpha;
	if (openfl_HasColorTransform)
	{
		openfl_ColorOffsetv = (openfl_ColorOffset + colorOffset) / 255.0;
		openfl_ColorMultiplierv = openfl_ColorMultiplier;
	}
	else
	{
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
uniform bool premultiplyAlpha;

vec4 apply_flixel_transform(vec4 color)
{
	if (!hasTransform) return color;
	else if (color.a <= 0.0 || openfl_Alphav == 0.0) return vec4(0.0);

	// this is just solely for ASTC compressed textures.
	// ...also in flixel_texture2D, it also converts to linear alpha anyway.
	if (!premultiplyAlpha) color.rgb /= color.a;

	color = clamp(openfl_ColorOffsetv + (color * openfl_ColorMultiplierv), 0.0, 1.0);
	return vec4(color.rgb * color.a * openfl_Alphav, color.a * openfl_Alphav);
}
#define applyFlixelEffects(color) apply_flixel_transform(color)

vec4 flixel_texture2D(sampler2D bitmap, vec2 coord)
{
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
}
#end

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