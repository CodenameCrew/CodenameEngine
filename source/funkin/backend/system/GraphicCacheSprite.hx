package funkin.backend.system;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.FlxGraphic;

/**
 * Dummy FlxSprite that allows you to cache FlxGraphics, and immediately send them to GPU memory.
 */
class GraphicCacheSprite extends FlxSprite {
	/**
	 * Array containing all of the graphics cached by this sprite.
	 */
	public var cachedGraphics:Array<FlxGraphic> = [];
	/**
	 * Array containing all of the non rendered (not sent to GPU) cached graphics.
	 */
	public var nonRenderedCachedGraphics:Array<FlxGraphic> = [];

	@:dox(hide)
	public function new() {
		super();
		moves = false;
		alpha = 0.0001;
		scale.set(0.001, 0.001);
	}

	/**
	 * Caches a graphic at specified path.
	 * @param path Path to the graphic.
	 * @return FlxGraphic
	 */
	public function cache(path:String):FlxGraphic return cacheGraphic(FlxG.bitmap.add(path));

	/**
	 * Caches a graphic.
	 * @param graphic The FlxGraphic
	 * @return FlxGraphic
	 */
	public function cacheGraphic(graphic:FlxGraphic):FlxGraphic {
		if (graphic != null && !cachedGraphics.contains(graphic)) {
			graphic.incrementUseCount();
			cachedGraphics.push(graphic);
			nonRenderedCachedGraphics.push(graphic);
		}
		return graphic;
	}

	/**
	 * Caches a frames.
	 * @param frames The FlxFramesCollection
	 * @return FlxFramesCollection
	 */
	public function cacheFrames(frames:FlxFramesCollection):FlxFramesCollection {
		if (frames != null) {
			@:privateAccess
			if (frames is FlxAtlasFrames) for (graphic in cast(frames, FlxAtlasFrames).usedGraphics) cacheGraphic(graphic);
			cacheGraphic(frames.parent);
		}
		return frames;
	}

	@:dox(hide)
	override function destroy() {
		for (g in cachedGraphics) g.decrementUseCount();

		graphic = null;
		super.destroy();
	}

	@:dox(hide)
	override function update(elapsed:Float) {}

	@:dox(hide)
	override function draw() {
		while (nonRenderedCachedGraphics.length != 0) {
			loadGraphic(nonRenderedCachedGraphics.pop());
			if (FlxG.renderTile) drawComplex(FlxG.camera);
			else drawSimple(FlxG.camera);
		}
	}
}