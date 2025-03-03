package funkin.backend.utils;

import openfl.display.BitmapData;
import openfl.display.IBitmapDrawable;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.TextureBase;
import openfl.geom.Rectangle;

import flixel.util.FlxColor;
import flixel.FlxG;

@:access(openfl.display.BitmapData)
@:access(openfl.display.IBitmapDrawable)
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.display3D.Context3D)
class BitmapUtil {
	/**
	 * Hardware check a BitmapData whether its good to go to do hardware performs.
	 * @param bmap BitmapData
	 * @param strict Bool
	 * @return Bool Whether if bitmapdata is good to go to continue to do hardware performs.
	 */
	public static function hardwareCheck(bmap:BitmapData, strict = false):Bool
		return bmap != null && bmap.__texture != null && (!strict || (bmap.image == null || bmap.__textureVersion >= bmap.image.version));

	/**
	 * Clears a BitmapData texture.
	 * @param bmap BitmapData
	 * @param color FlxColor
	 * @param depth Bool
	 * @param stencil Bool
	 */
	public static function clear(bmap:BitmapData, color:FlxColor = 0, depth = false, stencil = false) {
		if (bmap.__texture != null) clearTexture(bmap.__texture, color, depth, stencil);
		else bmap.__fillRect(bmap.rect, color, false);
	}

	/**
	 * Clears a OpenGL Texture.
	 * @param texture TextureBase
	 * @param color FlxColor
	 * @param depth Bool
	 * @param stencil Bool
	 */
	public static function clearTexture(texture:TextureBase, color:FlxColor, depth = false, stencil = false) {
		flush();

		final gl = texture.__context.gl;

		gl.bindFramebuffer(gl.FRAMEBUFFER, texture.__glFramebuffer != null ? texture.__glFramebuffer : texture.__getGLFramebuffer(false, 0, 0));

		gl.colorMask(true, true, true, true);
		gl.clearColor(color.redFloat, color.greenFloat, color.blueFloat, color.alphaFloat);
		if (depth) {
			gl.depthMask(true);
			gl.clearDepth(1);
		}
		if (stencil) {
			gl.stencilMask(0xFF);
			gl.clearStencil(0);
		}
		gl.disable(gl.SCISSOR_TEST);
		gl.clear(gl.COLOR_BUFFER_BIT);

		gl.bindFramebuffer(gl.FRAMEBUFFER, null);
	}

	/**
	 * Resizes a BItmapData without having to recreate a BitmapData.
	 * @param bmap BitmapData
	 * @param width Int
	 * @param height Int
	 * @param regen Bool
	 */
	public static function resize(bmap:BitmapData, width:Int, height:Int, regen = false) {
		if (bmap.width == width && bmap.height == height) return;
		if (bmap.rect == null) bmap.rect = new Rectangle(0, 0, width, height);
		bmap.__resize(width, height);

		if (regen) {
			final texture = FlxG.stage.context3D.createTexture(width, height, BGRA, true);
			if (bmap.__texture == null) bmap.__texture.dispose();
			bmap.__textureContext = (bmap.__texture = texture).__textureContext;
			if (bmap.image != null) {
				bmap.image.fillRect(bmap.image.rect, 0);
				bmap.image.resize(width, height);
			}
			bmap.getTexture(FlxG.stage.context3D);
		}
		else {
			if (bmap.image != null) bmap.image.resize(width, height);
			if (hardwareCheck(bmap, true)) resizeTexture(bmap.__texture, width, height);
			else bmap.getTexture(FlxG.stage.context3D);
		}

		bmap.__indexBufferContext = bmap.__framebufferContext = bmap.__textureContext;
		bmap.__framebuffer = bmap.__texture.__glFramebuffer;
		bmap.__stencilBuffer = bmap.__texture.__glStencilRenderbuffer;
		bmap.__vertexBuffer = null;
		bmap.getVertexBuffer(FlxG.stage.context3D);

		if (bmap.__surface != null) bmap.__surface.flush();
	}

	/**
	 * Resizes a OpenGL Texture
	 * @param texture TextureBase
	 * @param width Int
	 * @param height Int
	 */
	public static function resizeTexture(texture:TextureBase, width:Int, height:Int) {
		if (texture.__alphaTexture != null) resizeTexture(texture.__alphaTexture, width, height);
		if (texture.__width == width && texture.__height == height) return;

		final context = texture.__context;
		if (context == null) return;

		final gl = context.gl;
		if (gl == null) return;

		texture.__width = width = Math.floor(Math.min(width, FlxG.bitmap.maxTextureSize));
		texture.__height = height = Math.floor(Math.min(height, FlxG.bitmap.maxTextureSize));

		final cacheRTT = context.__state.renderToTexture,
			cacheRTTDepthStencil = context.__state.renderToTextureDepthStencil,
			cacheRTTAntiAlias = context.__state.renderToTextureAntiAlias,
			cacheRTTSurfaceSelector = context.__state.renderToTextureSurfaceSelector;

		context.__bindGLTexture2D(texture.__textureID);
		gl.texImage2D(texture.__textureTarget, 0, texture.__internalFormat, width, height, 0, texture.__format, gl.UNSIGNED_BYTE, null);

		if (texture.__glFramebuffer != null || texture.__glDepthRenderbuffer != null) {
			if (texture.__glDepthRenderbuffer != null) gl.deleteRenderbuffer(texture.__glDepthRenderbuffer);
			texture.__glDepthRenderbuffer = null;

			if (texture.__glStencilRenderbuffer != null) gl.deleteRenderbuffer(texture.__glStencilRenderbuffer);
			texture.__glStencilRenderbuffer = null;

			if (texture.__glFramebuffer != null) gl.deleteFramebuffer(texture.__glFramebuffer);
			texture.__glFramebuffer = null;

			texture.__getGLFramebuffer(false, 0, 0);
		}

		if (cacheRTT != null)
			context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
		else
			context.setRenderToBackBuffer();
	}

	/**
	 * Create a Hardware BitmapData without initializing software side.
	 * @param width Int
	 * @param height Int
	 * @return BitmapData Hardware BitmapData.
	 */
	public static function create(width:Int, height:Int, format:Context3DTextureFormat = BGRA):BitmapData {
		width = Math.ceil(Math.min(width, FlxG.bitmap.maxTextureSize));
		height = Math.ceil(Math.min(height, FlxG.bitmap.maxTextureSize));

		if (FlxG.stage.context3D != null) {
			final texture = FlxG.stage.context3D.createTexture(width, height, format, true);
			final bmap = new BitmapData(0, 0, true, 0);
			bmap.__textureContext = (bmap.__texture = texture).__textureContext;
			bmap.__resize(width, height);
			bmap.__isValid = true;
			return bmap;
		}
		else
			return new BitmapData(width, height, true, 0);
	}

	/**
	 * Transitions a Hardware to Hardware only BitmapData.
	 * @param bmap BitmapData
	 */
	public static function toHardware(bmap:BitmapData):Void {
		if (Main.forceGPUOnlyBitmapsOff) return;

		final context = FlxG.stage.context3D;
		if (context == null || bmap.image == null) return;

		if (!hardwareCheck(bmap)) {
			#if openfl_power_of_two bmap.image.powerOfTwo = true; #end
			bmap.image.premultiplied = true;

			bmap.__textureContext = context.__context;
			bmap.__texture = context.createTexture(bmap.width, bmap.height, BGRA, true);
			bmap.getTexture(context);
		}
		bmap.readable = false;
		bmap.image.data = null;
		bmap.image = null;
	}

	/**
	 * Returns the most present color in a Bitmap.
	 * @param bmap Bitmap
	 * @return FlxColor Color that is the most present.
	 */
	public static function getMostPresentColor(bmap:BitmapData):FlxColor {
		// map containing all the colors and the number of times they've been assigned.
		var colorMap:Map<FlxColor, Float> = [];
		var color:FlxColor = 0;
		var fixedColor:FlxColor = 0;

		for(y in 0...bmap.height) {
			for(x in 0...bmap.width) {
				color = bmap.getPixel32(x, y);
				fixedColor = 0xFF000000 + (color % 0x1000000);
				if (!colorMap.exists(fixedColor))
					colorMap[fixedColor] = 0;
				colorMap[fixedColor] += color.alphaFloat;
			}
		}

		var mostPresentColor:FlxColor = 0;
		var mostPresentColorCount:Float = -1;
		for(c=>n in colorMap) {
			if (n > mostPresentColorCount) {
				mostPresentColorCount = n;
				mostPresentColor = c;
			}
		}
		return mostPresentColor;
	}
	/**
	 * Returns the most present saturated color in a Bitmap.
	 * @param bmap Bitmap
	 * @return FlxColor Color that is the most present.
	 */
	public static function getMostPresentSaturatedColor(bmap:BitmapData):FlxColor {
		// map containing all the colors and the number of times they've been assigned.
		var colorMap:Map<FlxColor, Float> = [];
		var color:FlxColor = 0;
		var fixedColor:FlxColor = 0;

		for(y in 0...bmap.height) {
			for(x in 0...bmap.width) {
				color = bmap.getPixel32(x, y);
				fixedColor = 0xFF000000 + (color % 0x1000000);
				if (!colorMap.exists(fixedColor))
					colorMap[fixedColor] = 0;
				colorMap[fixedColor] += color.alphaFloat * 0.33 + (0.67 * (color.saturation * (2 * (color.lightness > 0.5 ? 0.5 - (color.lightness) : color.lightness))));
			}
		}

		var mostPresentColor:FlxColor = 0;
		var mostPresentColorCount:Float = -1;
		for(c=>n in colorMap) {
			if (n > mostPresentColorCount) {
				mostPresentColorCount = n;
				mostPresentColor = c;
			}
		}
		return mostPresentColor;
	}

	inline private static function flush() {
		FlxG.stage.context3D.__flushGLFramebuffer();
		FlxG.stage.context3D.__flushGLViewport();
	}
}