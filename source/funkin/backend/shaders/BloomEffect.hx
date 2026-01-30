package funkin.backend.shaders;

import haxe.Timer;
#if !flash
import openfl.filters.BitmapFilter;
import openfl.filters.BitmapFilterShader;
import openfl.display.BitmapData;
import openfl.display.DisplayObjectRenderer;
import openfl.display.Shader;
import openfl.geom.Point;
import openfl.geom.Rectangle;
#if lime
import lime._internal.graphics.ImageDataUtil; // TODO

#end

/**
	The BlurFilter class lets you apply a blur visual effect to display
	objects. A blur effect softens the details of an image. You can produce
	blurs that range from a softly unfocused look to a Gaussian blur, a hazy
	appearance like viewing an image through semi-opaque glass. When the
	`quality` property of this filter is set to low, the result is a
	softly unfocused look. When the `quality` property is set to
	high, it approximates a Gaussian blur filter. You can apply the filter to
	any display object(that is, objects that inherit from the DisplayObject
	class), such as MovieClip, SimpleButton, TextField, and Video objects, as
	well as to BitmapData objects.

	To create a new filter, use the constructor `new
	BlurFilter()`. The use of filters depends on the object to which you
	apply the filter:


	* To apply filters to movie clips, text fields, buttons, and video, use
	the `filters` property(inherited from DisplayObject). Setting
	the `filters` property of an object does not modify the object,
	and you can remove the filter by clearing the `filters`
	property.
	* To apply filters to BitmapData objects, use the
	`BitmapData.applyFilter()` method. Calling
	`applyFilter()` on a BitmapData object takes the source
	BitmapData object and the filter object and generates a filtered image as a
	result.


	If you apply a filter to a display object, the
	`cacheAsBitmap` property of the display object is set to
	`true`. If you remove all filters, the original value of
	`cacheAsBitmap` is restored.

	This filter supports Stage scaling. However, it does not support general
	scaling, rotation, and skewing. If the object itself is scaled
	(`scaleX` and `scaleY` are not set to 100%), the
	filter effect is not scaled. It is scaled only when the user zooms in on
	the Stage.

	A filter is not applied if the resulting image exceeds the maximum
	dimensions. In AIR 1.5 and Flash Player 10, the maximum is 8,191 pixels in
	width or height, and the total number of pixels cannot exceed 16,777,215
	pixels.(So, if an image is 8,191 pixels wide, it can only be 2,048 pixels
	high.) In Flash Player 9 and earlier and AIR 1.1 and earlier, the
	limitation is 2,880 pixels in height and 2,880 pixels in width. If, for
	example, you zoom in on a large movie clip with a filter applied, the
	filter is turned off if the resulting image exceeds the maximum
	dimensions.
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(openfl.geom.Point)
@:access(openfl.geom.Rectangle)
@:final class BloomEffect extends BitmapFilter
{
	@:noCompletion private static var __blurShader:BlurShader = new BlurShader();
	@:noCompletion private static var __combineShader:CombineShader = new CombineShader();
	@:noCompletion private static var __extractShader:ExtractShader = new ExtractShader();

	/**
		The amount of horizontal blur. Valid values are from 0 to 255(floating
		point). The default value is 4. Values that are a power of 2(such as 2,
		4, 8, 16 and 32) are optimized to render more quickly than other values.
	**/
	public var blurX(get, set):Float;

	/**
		The amount of vertical blur. Valid values are from 0 to 255(floating
		point). The default value is 4. Values that are a power of 2(such as 2,
		4, 8, 16 and 32) are optimized to render more quickly than other values.
	**/
	public var blurY(get, set):Float;

	/**
		The number of times to perform the blur. The default value is
		`BitmapFilterQuality.LOW`, which is equivalent to applying the
		filter once. The value `BitmapFilterQuality.MEDIUM` applies the
		filter twice; the value `BitmapFilterQuality.HIGH` applies it
		three times and approximates a Gaussian blur. Filters with lower values
		are rendered more quickly.

		For most applications, a `quality` value of low, medium, or
		high is sufficient. Although you can use additional numeric values up to
		15 to increase the number of times the blur is applied, higher values are
		rendered more slowly. Instead of increasing the value of
		`quality`, you can often get a similar effect, and with faster
		rendering, by simply increasing the values of the `blurX` and
		`blurY` properties.

		You can use the following BitmapFilterQuality constants to specify
		values of the `quality` property:

		* `BitmapFilterQuality.LOW`
		* `BitmapFilterQuality.MEDIUM`
		* `BitmapFilterQuality.HIGH`
	**/
	public var quality(get, set):Float;

	public var strength(get, set):Float;

	public var threshold(get, set):Float;

	@:noCompletion private var __blurX:Float;
	@:noCompletion private var __blurY:Float;
	@:noCompletion private var __horizontalPasses:Int;
	@:noCompletion private var __quality:Float;
	@:noCompletion private var __verticalPasses:Int;
	@:noCompletion private var __strength:Float;
	@:noCompletion private var __threshold:Float;

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
		});
	}
	#end

	/**
		Initializes the filter with the specified parameters. The default values
		create a soft, unfocused image.

		@param blurX   The amount to blur horizontally. Valid values are from 0 to
						 255.0(floating-point value).
		@param blurY   The amount to blur vertically. Valid values are from 0 to
						 255.0(floating-point value).
		@param quality The number of times to apply the filter. You can specify
						 the quality using the BitmapFilterQuality constants:


						* `openfl.filters.BitmapFilterQuality.LOW`

						* `openfl.filters.BitmapFilterQuality.MEDIUM`

						* `openfl.filters.BitmapFilterQuality.HIGH`


						 High quality approximates a Gaussian blur. For most
						 applications, these three values are sufficient. Although
						 you can use additional numeric values up to 15 to achieve
						 different effects, be aware that higher values are rendered
						 more slowly.
		@param strength The intensity of the bloom effect. Default is 1.0.
		@param threshold The brightness threshold for bloom. Pixels brighter than
						 this value will bloom. Default is 0.6.
	**/
	public function new(blurX:Float = 4, blurY:Float = 4, quality:Float = 0.5, strength:Float = 1.0, threshold:Float = 0.6)
	{
		super();

		this.blurX = blurX;
		this.blurY = blurY;
		this.quality = quality;
		this.strength = strength;
		this.threshold = threshold;

		__needSecondBitmapData = true;
		__preserveObject = true;
		__renderDirty = true;
	}

	public override function clone():BitmapFilter
	{
		return new BloomEffect(__blurX, __blurY, __quality, __strength, __threshold);
	}

	@:noCompletion private override function __applyFilter(bitmapData:BitmapData, sourceBitmapData:BitmapData, sourceRect:Rectangle,
			destPoint:Point):BitmapData
	{
		#if lime
		var time = Timer.stamp();
		var finalImage = ImageDataUtil.gaussianBlur(bitmapData.image, sourceBitmapData.image, sourceRect.__toLimeRectangle(), destPoint.__toLimeVector2(),
			__blurX, __blurY, __quality);
		var elapsed = Timer.stamp() - time;
		// trace("blurX: " + __blurX + " blurY: " + __blurY + " quality: " + __quality + " elapsed: " + elapsed * 1000 + "ms");
		if (finalImage == bitmapData.image) return bitmapData;
		#end
		return sourceBitmapData;
	}

	@:noCompletion private override function __initShader(renderer:DisplayObjectRenderer, pass:Int, sourceBitmapData:BitmapData):Shader
	{
		#if !macro
		final numBlurPasses = __horizontalPasses + __verticalPasses;

		switch pass
		{
			case 0:
				__extractShader.uThreshold.value = [__threshold];
				return __extractShader;

			case _ if (pass <= numBlurPasses):
				final blurPass = pass - 1;
				final isHorizontal = blurPass < __horizontalPasses;

				final scalePass = isHorizontal ? blurPass : blurPass - __horizontalPasses;

				final scale = Math.pow(0.5, scalePass >> 1);
				final blurRadius = isHorizontal ? blurX * scale : blurY * scale;

				__blurShader.uRadius.value = isHorizontal ? [blurRadius, 0.0] : [0.0, blurRadius];

				return __blurShader;

			default:
				__combineShader.sourceBitmap.input = sourceBitmapData;
				__combineShader.offset.value = [0.0, 0.0];
				__combineShader.uStrength.value = [__strength];
				__combineShader.uThreshold.value = [__threshold];
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
			__leftExtension = (value > 0 ? Math.ceil(value) : 0);
			__rightExtension = __leftExtension;
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
			__topExtension = (value > 0 ? Math.ceil(value) : 0);
			__bottomExtension = __topExtension;
		}
		return value;
	}

	@:noCompletion private function get_quality():Float
	{
		return __quality;
	}

	@:noCompletion private function set_quality(value:Float):Float
	{
		// TODO: Quality effect with fewer passes?

		__horizontalPasses = (__blurX <= 0) ? 0 : Math.round(__blurX * (value / 4)) + 1;
		__verticalPasses = (__blurY <= 0) ? 0 : Math.round(__blurY * (value / 4)) + 1;

		__numShaderPasses = __horizontalPasses + __verticalPasses + 2;

		if (value != __quality) __renderDirty = true;
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
}

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
private class BlurShader extends BitmapFilterShader
{
	@:glFragmentSource("
		uniform sampler2D openfl_Texture;

		varying vec2 vBlurCoord0;
		varying vec2 vBlurCoord1;
		varying vec2 vBlurCoord2;
		varying vec2 vBlurCoord3;
		varying vec2 vBlurCoord4;
		varying vec2 vBlurCoord5;
		varying vec2 vBlurCoord6;

		void main(void) {
			vec4 sum = texture2D(openfl_Texture, vBlurCoord0) * 0.00443;
			sum += texture2D(openfl_Texture, vBlurCoord1) * 0.05399;
			sum += texture2D(openfl_Texture, vBlurCoord2) * 0.24197;
			sum += texture2D(openfl_Texture, vBlurCoord3) * 0.39894;
			sum += texture2D(openfl_Texture, vBlurCoord4) * 0.24197;
			sum += texture2D(openfl_Texture, vBlurCoord5) * 0.05399;
			sum += texture2D(openfl_Texture, vBlurCoord6) * 0.00443;

			gl_FragColor = sum;
		}
	")
	@:glVertexSource("
		attribute vec4 openfl_Position;
		attribute vec2 openfl_TextureCoord;

		uniform mat4 openfl_Matrix;

		uniform vec2 uRadius;
		uniform vec2 uTextureSize;

		varying vec2 vBlurCoord0;
		varying vec2 vBlurCoord1;
		varying vec2 vBlurCoord2;
		varying vec2 vBlurCoord3;
		varying vec2 vBlurCoord4;
		varying vec2 vBlurCoord5;
		varying vec2 vBlurCoord6;

		void main(void) {
			gl_Position = openfl_Matrix * openfl_Position;

			vec2 r = uRadius / uTextureSize;
			vBlurCoord0 = openfl_TextureCoord - r;
			vBlurCoord1 = openfl_TextureCoord - r * 0.75;
			vBlurCoord2 = openfl_TextureCoord - r * 0.5;
			vBlurCoord3 = openfl_TextureCoord;
			vBlurCoord4 = openfl_TextureCoord + r * 0.5;
			vBlurCoord5 = openfl_TextureCoord + r * 0.75;
			vBlurCoord6 = openfl_TextureCoord + r;
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

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
private class ExtractShader extends BitmapFilterShader
{
	@:glFragmentSource("
		uniform sampler2D openfl_Texture;
		uniform float uThreshold;
		varying vec2 vTexCoord;

		void main(void) {
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
		varying vec2 vTexCoord;

		void main(void) {
			gl_Position = openfl_Matrix * openfl_Position;
			vTexCoord = openfl_TextureCoord;
		}
	")
	public function new()
	{
		super();
		#if !macro
		uThreshold.value = [0.5];
		#end
	}
}

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
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
		varying vec4 textureCoords;

		void main(void) {
			gl_Position = openfl_Matrix * openfl_Position;
			textureCoords = vec4(openfl_TextureCoord, openfl_TextureCoord - offset / openfl_TextureSize);
		}
	")
	public function new()
	{
		super();
		#if !macro
		offset.value = [0, 0];
		uStrength.value = [1.0];
		uThreshold.value = [0.5];
		#end
	}
}
#else
typedef BlurFilter = flash.filters.BlurFilter;
#end
