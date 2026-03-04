package funkin.backend.shaders;

import haxe.Timer;
import openfl.filters.BitmapFilter;
import openfl.filters.BitmapFilterShader;
import openfl.display.BitmapData;
import openfl.display.DisplayObjectRenderer;
import openfl.display.BlendMode;
import openfl.display.Shader;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
	This BloomEffect was modified by heihua based on openfl.filters.BlurFilter.
	The BloomEffect class applies a bloom/glow visual effect to display objects. 
	A bloom effect extracts bright areas from an image, blurs them, and combines 
	them back to create a glowing halo around bright objects. This effect is 
	commonly used to simulate intense light, emissive materials, or to add a 
	dreamy, atmospheric quality to scenes.

	The effect consists of three stages:
	1. Extraction - Bright pixels above a threshold are extracted
	2. Blurring - The extracted bright areas are blurred horizontally and vertically
	3. Combination - The blurred result is blended back with the original image
**/
class BloomEffect extends BitmapFilter
{
	@:noCompletion private static var __blurShader:BlurShader;
	@:noCompletion private static var __combineShader:CombineShader;
	@:noCompletion private static var __extractShader:ExtractShader;
	@:noCompletion private static var __extractLowShader:ExtractLowShader;

	/**
		Values that are a power of 2 (such as 2, 4, 8, 16 and 32) are optimized to render 
		more quickly than other values.
	**/
	public var blurX(get, set):Float;

	/**
		Values that are a power of 2 (such as 2, 4, 8, 16 and 32) are optimized to render 
		more quickly than other values.
	**/
	public var blurY(get, set):Float;

	/**
		The downscaling factor for bloom rendering. Higher values significantly reduce 
		GPU performance cost, but setting values too high may cause noticeable flickering. 
		Recommended range is 8-24.
	**/
	public var quality(get, set):Float;

	/**
		The intensity of the bloom effect. Higher values produce more pronounced bloom.
	**/
	public var strength(get, set):Float;

	/**
		The brightness threshold for bloom extraction. Pixels brighter than this value 
		will contribute to the bloom effect. Value range is 0.0 to 1.0.
	**/
	public var threshold(get, set):Float;

	/**
		Enables extended rendering area to avoid edge artifacts. Enabling this option 
		will increase performance cost. Generally not required when rendering to camera.
	**/
	public var extension(get, set):Bool;

	/**
		Low-quality pixel sampling mode. Disabling it significantly reduces screen flickering,
		with minimal performance impact on desktop platforms but a higher
		performance cost on non-desktop platforms.
	**/
	public var useLowQualityExtract(get, set):Bool;

	/**
		The weights for calculating brightness (RGB to grayscale).
		Order: [Red, Green, Blue]. Default is [0.2126, 0.7152, 0.0722].
	**/
	public var weights(get, set):Array<Float>;

	/**
		The blend mode used when combining the bloom with the original image.
		BlendMode currently supports: (BlendMode.ADD, BlendMode.ALPHA, BlendMode.HARDLIGHT,
		BlendMode.LIGHTEN, BlendMode.MULTIPLY, BlendMode.OVERLAY, BlendMode.SCREEN,
		BlendMode.COLORDODGE, BlendMode.SOFTLIGHT).
		Default is BlendMode.ADD.
	**/
	public var blendMode(get, set):BlendMode;

	@:noCompletion private var __blurX:Float;
	@:noCompletion private var __blurY:Float;
	@:noCompletion private var __horizontalPasses:Int;
	@:noCompletion private var __quality:Float;
	@:noCompletion private var __verticalPasses:Int;
	@:noCompletion private var __strength:Float;
	@:noCompletion private var __threshold:Float;
	@:noCompletion private var __extension:Bool;
	@:noCompletion private var __useLowQualityExtract:Bool;
	@:noCompletion private var __weights:Array<Float>;
	@:noCompletion private var __blendMode:BlendMode;

	#if openfljs
	@:noCompletion private static function __init__()
	{
		untyped Object.defineProperties(BloomEffect.prototype, {
			"blurX": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_blurX (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_blurX (v); }")
			},
			"blurY": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_blurY (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_blurY (v); }")
			},
			"quality": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_quality (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_quality (v); }")
			},
			"strength": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_strength (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_strength (v); }")
			},
			"threshold": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_threshold (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_threshold (v); }")
			},
			"useLowQualityExtract": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_useLowQualityExtract (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_useLowQualityExtract (v); }")
			},
			"weights": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_weights (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_weights (v); }")
			},
			"blendMode": {
				get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_blendMode (); }"),
				set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_blendMode (v); }")
			},
		});
	}
	#end

	/**
		Initializes the bloom filter with the specified parameters.

		@param blurX   The amount to blur horizontally.
		@param blurY   The amount to blur vertically.
		@param quality The downscaling factor for bloom rendering (higher values reduce 
						 GPU cost but may cause flickering if too high).
		@param strength The intensity of the bloom effect.
		@param threshold The brightness threshold for bloom extraction (0.0 to 1.0).
		@param useLowQualityExtract Enables performance-optimized extraction with 
									potentially more flickering.
	**/
	public function new(blurX:Float = 50, blurY:Float = 50, quality:Float = 8, strength:Float = 0.6, threshold:Float = 0.6, useLowQualityExtract:Bool = true)
	{
		super();

		__blurShader = new BlurShader();
		__combineShader = new CombineShader();
		__extractShader = new ExtractShader();
		__extractLowShader = new ExtractLowShader();

		this.blurX = blurX;
		this.blurY = blurY;
		this.quality = quality;
		this.strength = strength;
		this.threshold = threshold;
		this.extension = false;
		this.useLowQualityExtract = useLowQualityExtract;
		this.weights = [0.2126, 0.7152, 0.0722];
		this.blendMode = BlendMode.ADD;

		__needSecondBitmapData = true;
		__preserveObject = true;
		__renderDirty = true;
	}

	public override function clone():BitmapFilter
	{
		var cloned = new BloomEffect(__blurX, __blurY, __quality, __strength, __threshold, __useLowQualityExtract);
		cloned.weights = __weights != null ? __weights.copy() : [0.2126, 0.7152, 0.0722];
		cloned.blendMode = __blendMode;
		return cloned;
	}

	@:noCompletion private override function __applyFilter(bitmapData:BitmapData, sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point):BitmapData
	{
		trace("Due to technical limitations, I'm unable to implement the bitmapData rendering method. If you know how to implement it, you're welcome to contribute this feature.");
		return sourceBitmapData;
	}

	@:noCompletion private override function __initShader(renderer:DisplayObjectRenderer, pass:Int, sourceBitmapData:BitmapData):Shader
	{
		final numBlurPasses = __horizontalPasses + __verticalPasses;

		switch pass
		{
			case 0:
				if (__useLowQualityExtract)
				{
					__extractLowShader.uThreshold.value[0] = __threshold;
					__extractLowShader.uQuality.value[0] = __quality;
					__extractLowShader.uWeights.value = __weights;
					return __extractLowShader;
				}
				else
				{
					__extractShader.uThreshold.value[0] = __threshold;
					__extractShader.uQuality.value[0] = __quality;
					__extractShader.uWeights.value = __weights;
					return __extractShader;
				}

			case _ if (pass <= numBlurPasses):
				final blurPass = pass - 1;
				final isHorizontal = blurPass < __horizontalPasses;

				final scalePass = isHorizontal ? blurPass : blurPass - __horizontalPasses;

				final scale = Math.pow(0.5, scalePass >> 1);
				final blurRadius = isHorizontal ? blurX * scale : blurY * scale;

				__blurShader.uRadius.value = isHorizontal ? [blurRadius / __quality, 0.0] : [0.0, blurRadius / __quality];
				__blurShader.uQuality.value[0] = __quality;
				__blurShader.uStrength.value[0] = Math.pow(__strength, 1.0 / numBlurPasses);

				return __blurShader;

			default:
				__combineShader.sourceBitmap.input = sourceBitmapData;
				__combineShader.uThreshold.value[0] = __threshold;
				__combineShader.uQuality.value[0] = __quality;
				__combineShader.uBlendMode.value[0] = cast __blendMode;
				return __combineShader;
		}
	}

	// Get & Set Methods
	@:noCompletion private function get_blurX():Float
	{
		return __blurX;
	}

	@:noCompletion private function set_blurX(value:Float):Float
	{
		if (value != __blurX)
		{
			__blurX = value;
			__renderDirty = true;

			if (!__extension)
			{
				// Setting it to 1 prevents bloom flickering at the screen edges
				__leftExtension = 1;
				__rightExtension = 1;
			}
			else
			{
				__leftExtension = (value > 0 ? Math.ceil(value) : 0);
				__rightExtension = __leftExtension;
			}

			__horizontalPasses = (value <= 0) ? 0 : Math.ceil(value * 0.0625 / quality) + 1;
			__numShaderPasses = __horizontalPasses + __verticalPasses + 2;
		}
		return value;
	}

	@:noCompletion private function get_blurY():Float
	{
		return __blurY;
	}

	@:noCompletion private function set_blurY(value:Float):Float
	{
		if (value != __blurY)
		{
			__blurY = value;
			__renderDirty = true;

			if (!__extension)
			{
				// Setting it to 1 prevents bloom flickering at the screen edges
				__topExtension = 1;
				__bottomExtension = 1;
			}
			else
			{
				__topExtension = (value > 0 ? Math.ceil(value) : 0);
				__bottomExtension = __topExtension;
			}

			__verticalPasses = (value <= 0) ? 0 : Math.ceil(value * 0.0625 / quality) + 1;
			__numShaderPasses = __horizontalPasses + __verticalPasses + 2;
		}
		return value;
	}

	@:noCompletion private function get_quality():Float
	{
		return __quality;
	}

	@:noCompletion private function set_quality(value:Float):Float
	{
		__horizontalPasses = (__blurX <= 0) ? 0 : Math.round(__blurX * 0.125 / value) + 1;
		__verticalPasses = (__blurY <= 0) ? 0 : Math.round(__blurY * 0.125 / value) + 1;
		__numShaderPasses = __horizontalPasses + __verticalPasses + 2;

		if (value != __quality)
			__renderDirty = true;
		return __quality = value;
	}

	@:noCompletion private function get_strength():Float
	{
		return __strength;
	}

	@:noCompletion private function set_strength(value:Float):Float
	{
		if (value != __strength)
		{
			__strength = value;
			__renderDirty = true;
		}
		return value;
	}

	@:noCompletion private function get_threshold():Float
	{
		return __threshold;
	}

	@:noCompletion private function set_threshold(value:Float):Float
	{
		if (value != __threshold)
		{
			__threshold = value;
			__renderDirty = true;
		}
		return value;
	}

	@:noCompletion private function get_extension():Bool
	{
		return __extension;
	}

	@:noCompletion private function set_extension(value:Bool):Bool
	{
		if (value != __extension)
		{
			__extension = value;

			if (!value)
				__leftExtension = __rightExtension = __topExtension = __bottomExtension = 0;
			else
			{
				__leftExtension = __rightExtension = (__blurX > 0 ? Math.ceil(__blurX) : 0);
				__topExtension = __bottomExtension = (__blurY > 0 ? Math.ceil(__blurY) : 0);
			}

			__renderDirty = true;
		}
		return value;
	}

	@:noCompletion private function get_useLowQualityExtract():Bool
	{
		return __useLowQualityExtract;
	}

	@:noCompletion private function set_useLowQualityExtract(value:Bool):Bool
	{
		if (value != __useLowQualityExtract)
		{
			__useLowQualityExtract = value;
			__renderDirty = true;
		}
		return value;
	}

	@:noCompletion private function get_weights():Array<Float>
	{
		return __weights;
	}

	@:noCompletion private function set_weights(value:Array<Float>):Array<Float>
	{
		if (value != __weights)
		{
			__weights = value;
			__renderDirty = true;
		}
		return value;
	}

	@:noCompletion private function get_blendMode():BlendMode
	{
		return __blendMode;
	}

	@:noCompletion private function set_blendMode(value:BlendMode):BlendMode
	{
		if (value != __blendMode)
		{
			__blendMode = value;
			__renderDirty = true;
		}
		return value;
	}
}

private class BlurShader extends BitmapFilterShader
{
	@:glFragmentSource("
uniform sampler2D openfl_Texture;
uniform float uStrength;

varying mat2 vBlurCoord0;
varying mat2 vBlurCoord1;
varying vec2 vBlurCoord2;
varying mat2 vBlurCoord3;
varying mat2 vBlurCoord4;

varying float invQuality;

void main(void) {
	if ((all(greaterThanEqual(vBlurCoord2, vec2(0.0))) && all(lessThanEqual(vBlurCoord2, vec2(1.0)))) == false) return;

	vec4 sum = texture2D(openfl_Texture, clamp(vBlurCoord0[0], 0.0, invQuality)) * 0.028532;
	sum += texture2D(openfl_Texture, clamp(vBlurCoord0[1], 0.0, invQuality)) * 0.067234;
	sum += texture2D(openfl_Texture, clamp(vBlurCoord1[0], 0.0, invQuality)) * 0.124009;
	sum += texture2D(openfl_Texture, clamp(vBlurCoord1[1], 0.0, invQuality)) * 0.179044;
	sum += texture2D(openfl_Texture, clamp(vBlurCoord2, 0.0, invQuality)) * 0.202360;
	sum += texture2D(openfl_Texture, clamp(vBlurCoord3[0], 0.0, invQuality)) * 0.179044;
	sum += texture2D(openfl_Texture, clamp(vBlurCoord3[1], 0.0, invQuality)) * 0.124009;
	sum += texture2D(openfl_Texture, clamp(vBlurCoord4[0], 0.0, invQuality)) * 0.067234;
	sum += texture2D(openfl_Texture, clamp(vBlurCoord4[1], 0.0, invQuality)) * 0.028532;
	gl_FragColor = sum * uStrength;
}
	")
	@:glVertexSource("
attribute vec4 openfl_Position;
attribute vec2 openfl_TextureCoord;

uniform mat4 openfl_Matrix;

uniform vec2 uRadius;
uniform vec2 uTextureSize;
uniform float uQuality;

varying mat2 vBlurCoord0;
varying mat2 vBlurCoord1;
varying vec2 vBlurCoord2;
varying mat2 vBlurCoord3;
varying mat2 vBlurCoord4;

varying float invQuality;

void main(void) {
	vec4 pos = openfl_Position;
	invQuality = 1.0 / uQuality;

	pos.xy *= invQuality;
	gl_Position = openfl_Matrix * pos;

	vec2 r = uRadius / uTextureSize;
	vec2 coord = openfl_TextureCoord * invQuality;
	vBlurCoord0[0] = coord - r;
	vBlurCoord0[1] = coord - r * 0.25;
	vBlurCoord1[0] = coord - r * 0.5;
	vBlurCoord1[1] = coord - r * 0.75;
	vBlurCoord2 = coord;
	vBlurCoord3[0] = coord + r * 0.25;
	vBlurCoord3[1] = coord + r * 0.5;
	vBlurCoord4[0] = coord + r * 0.75;
	vBlurCoord4[1] = coord + r;
}
	")
	public function new()
	{
		super();

		uStrength.value = [1.0];
		uRadius.value = [0, 0];
		uQuality.value = [8];
	}

	@:noCompletion private override function __update():Void
	{
		#if !macro
		uTextureSize.value = [__texture.input.width, __texture.input.height];
		#end

		super.__update();
	}
}

private class ExtractLowShader extends BitmapFilterShader
{
	@:glFragmentSource("
uniform sampler2D openfl_Texture;
uniform float uThreshold;
uniform vec3 uWeights;
varying vec2 vTexCoord;

void main(void) {
	if ((all(greaterThanEqual(vTexCoord, vec2(0.0))) && all(lessThanEqual(vTexCoord, vec2(1.0)))) == false) return;

	vec4 texel = texture2D(openfl_Texture, vTexCoord);
	float brightness = min(dot(texel.rgb, uWeights), 1.0);
	float mask = smoothstep(uThreshold, uThreshold + 0.1, brightness);
	gl_FragColor = texel * mask;
}
	")
	@:glVertexSource("
attribute vec4 openfl_Position;
attribute vec2 openfl_TextureCoord;
uniform mat4 openfl_Matrix;
uniform vec2 openfl_TextureSize;
uniform float uQuality;
varying vec2 vTexCoord;

void main(void) {
	vec4 pos = openfl_Position;
	pos.xy /= uQuality;
	gl_Position = openfl_Matrix * pos;
	vTexCoord = openfl_TextureCoord;
}
	")
	public function new()
	{
		super();

		uThreshold.value = [0.6];
		uQuality.value = [8];
		uWeights.value = [0.2126, 0.7152, 0.0722];
	}
}

private class ExtractShader extends BitmapFilterShader
{
	@:glFragmentSource("
uniform sampler2D openfl_Texture;
uniform vec2 openfl_TextureSize;
uniform float uThreshold;
uniform float uQuality;
uniform vec3 uWeights;
varying vec2 vTexCoord;
varying vec4 border;

void main(void) {
	if ((all(greaterThanEqual(vTexCoord, border.xy)) && all(lessThanEqual(vTexCoord, border.zw))) == false) return;
	
	float quality = floor(uQuality) / 2.0;
	vec2 texelSize = 1.0 / openfl_TextureSize;
	
	vec4 accumulated = vec4(0.0);
	int sampleCount = 0;


	for (float dx = -quality; dx <= quality; dx += 2.0) {
		for (float dy = -quality; dy <= quality; dy += 2.0) {
			vec2 sampleCoord = vTexCoord + vec2(dx, dy) * texelSize;

			vec4 texel = texture2D(openfl_Texture, sampleCoord);
			float brightness = min(dot(texel.rgb, uWeights), 1.0);
			float mask = smoothstep(uThreshold, uThreshold + 0.1, brightness);
			accumulated += texel * mask;
			sampleCount++;
		}
	}

	gl_FragColor = accumulated / float(sampleCount);
}
	")
	@:glVertexSource("
attribute vec4 openfl_Position;
attribute vec2 openfl_TextureCoord;
uniform mat4 openfl_Matrix;
uniform vec2 openfl_TextureSize;
uniform float uQuality;
varying vec2 vTexCoord;
varying vec4 border;

void main(void) {
	vec4 pos = openfl_Position;
	pos.xy /= uQuality;

	vec2 size = 1.0 / openfl_TextureSize * uQuality;
	border = vec4(size, vec2(1.0) - size);

	gl_Position = openfl_Matrix * pos;
	vTexCoord = openfl_TextureCoord;
}
	")
	public function new()
	{
		super();

		uThreshold.value = [0.6];
		uQuality.value = [8];
		uWeights.value = [0.2126, 0.7152, 0.0722];
	}
}

private class CombineShader extends BitmapFilterShader
{
	@:glFragmentSource("
uniform sampler2D openfl_Texture;
uniform sampler2D sourceBitmap;
uniform float uThreshold;
uniform int uBlendMode;
varying vec4 textureCoords;

vec4 blendScreen(vec4 src, vec4 bloom) {
	return vec4(1.0) - (vec4(1.0) - src) * (vec4(1.0) - bloom);
}

vec4 blendMultiply(vec4 src, vec4 bloom) {
	return src * bloom;
}

vec4 blendLighten(vec4 src, vec4 bloom) {
	return max(src, bloom);
}

vec4 blendOverlay(vec4 src, vec4 bloom) {
	vec4 result = vec4(0.0);
	for (int i = 0; i < 4; i++) {
		if (src[i] < 0.5) {
			result[i] = 2.0 * src[i] * bloom[i];
		} else {
			result[i] = 1.0 - 2.0 * (1.0 - src[i]) * (1.0 - bloom[i]);
		}
	}
	return result;
}

vec4 blendColorDodge(vec4 src, vec4 bloom) {
	vec4 result = vec4(0.0);
	for (int i = 0; i < 4; i++) {
		if (bloom[i] < 1.0) {
			result[i] = min(1.0, src[i] / (1.0 - bloom[i]));
		} else {
			result[i] = 1.0;
		}
	}
	return result;
}

vec4 blendSoftLight(vec4 src, vec4 bloom) {
	vec4 result = vec4(0.0);
	for (int i = 0; i < 4; i++) {
		if (bloom[i] < 0.5) {
			result[i] = src[i] - (1.0 - 2.0 * bloom[i]) * src[i] * (1.0 - src[i]);
		} else {
			float d = (src[i] <= 0.25) ? ((16.0 * src[i] - 12.0) * src[i] + 4.0) * src[i] : sqrt(src[i]);
			result[i] = src[i] + (2.0 * bloom[i] - 1.0) * (d - src[i]);
		}
	}
	return result;
}

vec4 blendAlpha(vec4 src, vec4 bloom) {
	return src + bloom * (1.0 - src.a);
}

void main(void) {
	vec4 src = texture2D(sourceBitmap, textureCoords.xy);
	vec4 bloom = texture2D(openfl_Texture, textureCoords.zw);

	vec4 result;
	if(uBlendMode == 0)
		result = src + bloom;
	else if(uBlendMode == 1)
		result = blendAlpha(src, bloom);
	else if(uBlendMode == 5)
		result = blendOverlay(src, bloom);
	else if(uBlendMode == 8)
		result = blendLighten(src, bloom);
	else if(uBlendMode == 9)
		result = blendMultiply(src, bloom);
	else if(uBlendMode == 11)
		result = blendOverlay(src, bloom);
	else if(uBlendMode == 12)
		result = blendScreen(src, bloom);
	else if(uBlendMode == 15)
		result = blendColorDodge(src, bloom);
	else if(uBlendMode == 17)
		result = blendSoftLight(src, bloom);
	else
		result = src + bloom;

	gl_FragColor = result;
}
	")
	@:glVertexSource("
attribute vec4 openfl_Position;
attribute vec2 openfl_TextureCoord;
uniform mat4 openfl_Matrix;
uniform vec2 openfl_TextureSize;
uniform float uQuality;
varying vec4 textureCoords;

void main(void) {
	gl_Position = openfl_Matrix * openfl_Position;
	textureCoords = vec4(openfl_TextureCoord, openfl_TextureCoord / uQuality);
}
	")
	public function new()
	{
		super();

		uQuality.value = [8];
		uThreshold.value = [0.6];
		uBlendMode.value = [0];
	}
}