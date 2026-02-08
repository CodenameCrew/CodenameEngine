package funkin.backend.shaders;

import haxe.Timer;
import openfl.filters.BitmapFilter;
import openfl.filters.BitmapFilterShader;
import openfl.display.BitmapData;
import openfl.display.DisplayObjectRenderer;
import openfl.display.Shader;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
	The BloomEffect class applies a bloom/glow visual effect to display objects. 
	A bloom effect extracts bright areas from an image, blurs them, and combines 
	them back to create a glowing halo around bright objects. This effect is 
	commonly used to simulate intense light, emissive materials, or to add a 
	dreamy, atmospheric quality to scenes.
	
	The effect consists of three stages:
	1. Extraction - Bright pixels above a threshold are extracted
	2. Blurring - The extracted bright areas are blurred horizontally and vertically
	3. Combination - The blurred result is blended back with the original image
	
	You can apply the filter to any display object (objects that inherit from 
	DisplayObject), such as MovieClip, SimpleButton, TextField, and Video objects, 
	as well as to BitmapData objects.

	To create a new filter, use the constructor `new BloomEffect()`. The usage 
	depends on the target object:
	
	* For display objects: Use the `filters` property (inherited from DisplayObject).
	  Setting `filters` doesn't modify the object, and filters can be removed by 
	  clearing the `filters` property.
	* For BitmapData objects: Use the `BitmapData.applyFilter()` method, which 
	  takes the source BitmapData and filter object, generating a filtered result.
	
	Applying a filter to a display object sets its `cacheAsBitmap` property to 
	`true`. Removing all filters restores the original `cacheAsBitmap` value.
	
	This filter supports Stage scaling but not general scaling, rotation, or skewing. 
	If the object itself is scaled (`scaleX` and `scaleY` ≠ 100%), the filter 
	effect doesn't scale—it only scales when the Stage is zoomed.
	
	A filter won't be applied if the resulting image exceeds maximum dimensions:
	* AIR 1.5/Flash Player 10+: 8,191px width/height, 16,777,215 total pixels
	* Flash Player 9/AIR 1.1-: 2,880px width/height
	
	For example, zooming into a large filtered movie clip may disable the filter 
	if the resulting image exceeds these limits.
**/
@:access(openfl.geom.Point)
@:access(openfl.geom.Rectangle)
@:final class BloomEffect extends BitmapFilter
{
	@:noCompletion private static var __blurShader:BlurShader = new BlurShader();
	@:noCompletion private static var __combineShader:CombineShader = new CombineShader();
	@:noCompletion private static var __extractShader:ExtractShader = new ExtractShader();
	@:noCompletion private static var __extractLowShader:ExtractLowShader = new ExtractLowShader();

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
		Enables low-quality extraction to reduce performance cost. When disabled, 
		reduces flickering but has higher performance impact on non-desktop platforms.
	**/
	public var useLowQualityExtract(get, set):Bool;

	@:noCompletion private var __blurX:Float;
	@:noCompletion private var __blurY:Float;
	@:noCompletion private var __horizontalPasses:Int;
	@:noCompletion private var __quality:Float;
	@:noCompletion private var __verticalPasses:Int;
	@:noCompletion private var __strength:Float;
	@:noCompletion private var __threshold:Float;
	@:noCompletion private var __extension:Bool;
	@:noCompletion private var __useLowQualityExtract:Bool;

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
	public function new(blurX:Float = 10, blurY:Float = 10, quality:Float = #if desktop 24 #else 8 #end, strength:Float = 1, threshold:Float = 0.6, useLowQualityExtract:Bool = #if desktop false #else true #end)
	{
		super();

		this.blurX = blurX;
		this.blurY = blurY;
		this.quality = quality;
		this.strength = strength;
		this.threshold = threshold;
		this.extension = false;
		this.useLowQualityExtract = useLowQualityExtract;

		__needSecondBitmapData = true;
		__preserveObject = true;
		__renderDirty = true;
	}

	public override function clone():BitmapFilter
	{
		return new BloomEffect(__blurX, __blurY, __quality, __strength, __threshold, __useLowQualityExtract);
	}

	@:noCompletion private override function __applyFilter(bitmapData:BitmapData, sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point):BitmapData
	{
		trace('BloomEffect does not support bitmapData rendering functionality.');
		return sourceBitmapData;
	}

	@:noCompletion private override function __initShader(renderer:DisplayObjectRenderer, pass:Int, sourceBitmapData:BitmapData):Shader
	{
		#if !macro
		final numBlurPasses = __horizontalPasses + __verticalPasses;

		switch pass
		{
			case 0:
				if (__useLowQualityExtract)
				{
					__extractLowShader.uThreshold.value = [__threshold];
					__extractLowShader.uQuality.value = [__quality];
					return __extractLowShader;
				}
				else
				{
					__extractShader.uThreshold.value = [__threshold];
					__extractShader.uQuality.value = [__quality];
					return __extractShader;
				}

			case _ if (pass <= numBlurPasses):
				final blurPass = pass - 1;
				final isHorizontal = blurPass < __horizontalPasses;

				final scalePass = isHorizontal ? blurPass : blurPass - __horizontalPasses;

				final scale = Math.pow(0.5, scalePass >> 1);
				final blurRadius = isHorizontal ? blurX * scale : blurY * scale;

				__blurShader.uRadius.value = isHorizontal ? [blurRadius / __quality, 0.0] : [0.0, blurRadius / __quality];
				__blurShader.uQuality.value = [__quality];

				return __blurShader;

			default:
				__combineShader.sourceBitmap.input = sourceBitmapData;
				__combineShader.offset.value = [0.0, 0.0];
				__combineShader.uStrength.value = [__strength];
				__combineShader.uThreshold.value = [__threshold];
				__combineShader.uQuality.value = [__quality];
				return __combineShader;
		}
		#else
		return null;
		#end
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
			{
				// Setting it to 1 prevents bloom flickering at the screen edges
				__leftExtension = 1;
				__rightExtension = 1;
				__topExtension = 1;
				__bottomExtension = 1;
			}
			else
			{
				__leftExtension = (__blurX > 0 ? Math.ceil(__blurX) : 0);
				__rightExtension = __leftExtension;
				__topExtension = (__blurY > 0 ? Math.ceil(__blurY) : 0);
				__bottomExtension = __topExtension;
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
}

private class BlurShader extends BitmapFilterShader
{
	@:glFragmentSource("
		uniform sampler2D openfl_Texture;

		varying mat2 vBlurCoord0;
		varying mat2 vBlurCoord1;
		varying vec2 vBlurCoord2;
		varying mat2 vBlurCoord3;
		varying mat2 vBlurCoord4;

		void main(void) {
			if ((all(greaterThanEqual(vBlurCoord2, vec2(0.0))) && all(lessThanEqual(vBlurCoord2, vec2(1.0)))) == false) return;

			vec4 sum = texture2D(openfl_Texture, vBlurCoord0[0]) * 0.028532;
			sum += texture2D(openfl_Texture, vBlurCoord0[1]) * 0.067234;
			sum += texture2D(openfl_Texture, vBlurCoord1[0]) * 0.124009;
			sum += texture2D(openfl_Texture, vBlurCoord1[1]) * 0.179044;
			sum += texture2D(openfl_Texture, vBlurCoord2) * 0.202360;
			sum += texture2D(openfl_Texture, vBlurCoord3[0]) * 0.179044;
			sum += texture2D(openfl_Texture, vBlurCoord3[1]) * 0.124009;
			sum += texture2D(openfl_Texture, vBlurCoord4[0]) * 0.067234;
			sum += texture2D(openfl_Texture, vBlurCoord4[1]) * 0.028532;
			gl_FragColor = sum;
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

		void main(void) {
			vec4 pos = openfl_Position;
			pos.xy /= uQuality;
			gl_Position = openfl_Matrix * pos;

			vec2 r = uRadius / uTextureSize;
			vec2 coord = openfl_TextureCoord / uQuality;
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

		#if !macro
		uRadius.value = [0, 0];
		#end
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
		varying vec2 vTexCoord;

		void main(void) {
			if ((all(greaterThanEqual(vTexCoord, vec2(0.0))) && all(lessThanEqual(vTexCoord, vec2(1.0)))) == false) return;

			vec4 texel = texture2D(openfl_Texture, vTexCoord);
			float brightness = max(max(texel.r, texel.g), texel.b);
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

		#if !macro
		uThreshold.value = [0.6];
		#end
	}
}

private class ExtractShader extends BitmapFilterShader
{
	@:glFragmentSource("
    uniform sampler2D openfl_Texture;
		uniform vec2 openfl_TextureSize;
    uniform float uThreshold;
    uniform float uQuality;
    varying vec2 vTexCoord;

    void main(void) {
			if ((all(greaterThanEqual(vTexCoord, vec2(0.0))) && all(lessThanEqual(vTexCoord, vec2(1.0)))) == false) return;
			
			float quality = floor(uQuality) / 2.0;
			vec2 texelSize = 1.0 / openfl_TextureSize;
			
			vec4 accumulated = vec4(0.0);
			int sampleCount = 0;


			for (float dx = -quality; dx <= quality; dx += 2.0) {
				for (float dy = -quality; dy <= quality; dy += 2.0) {
					vec2 sampleCoord = vTexCoord + vec2(dx, dy) * texelSize;

					if ((all(greaterThanEqual(sampleCoord, vec2(0.0))) && all(lessThanEqual(sampleCoord, vec2(1.0)))) == false) continue;

					vec4 texel = texture2D(openfl_Texture, sampleCoord);
					float brightness = max(max(texel.r, texel.g), texel.b);
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

		#if !macro
		uThreshold.value = [0.6];
		#end
	}
}

private class CombineShader extends BitmapFilterShader
{
	@:glFragmentSource("
		uniform sampler2D openfl_Texture;
		uniform sampler2D sourceBitmap;
		uniform float uStrength;
		uniform float uThreshold;
		varying vec4 textureCoords;

		void main(void) {
			vec4 src = texture2D(sourceBitmap, textureCoords.xy);
			vec4 bloom = texture2D(openfl_Texture, textureCoords.zw);

			gl_FragColor = src + bloom * uStrength;
		}
	")
	@:glVertexSource("attribute vec4 openfl_Position;
		attribute vec2 openfl_TextureCoord;
		uniform mat4 openfl_Matrix;
		uniform vec2 openfl_TextureSize;
		uniform vec2 offset;
		uniform float uQuality;
		varying vec4 textureCoords;

		void main(void) {
			gl_Position = openfl_Matrix * openfl_Position;
			textureCoords = vec4(openfl_TextureCoord, (openfl_TextureCoord - offset / openfl_TextureSize) / uQuality);
		}
	")
	public function new()
	{
		super();

		#if !macro
		offset.value = [0, 0];
		uStrength.value = [1.0];
		uThreshold.value = [0.6];
		#end
	}
}