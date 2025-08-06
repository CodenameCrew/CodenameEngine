package funkin.backend;

import flixel.addons.effects.FlxSkewedSprite;
import flixel.animation.FlxAnimation;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.typeLimit.OneOfTwo;
import flxanimate.animate.FlxAnim.FlxSymbolAnimation;
import funkin.backend.scripting.events.sprite.PlayAnimContext;
import funkin.backend.system.interfaces.IBeatReceiver;
import funkin.backend.system.interfaces.IOffsetCompatible;
import funkin.backend.utils.XMLUtil.AnimData;
import funkin.backend.utils.XMLUtil.BeatAnim;
import funkin.backend.utils.XMLUtil.IXMLEvents;
import haxe.io.Path;

enum abstract XMLAnimType(Int)
{
	var NONE = 0;
	var BEAT = 1;
	var LOOP = 2;

	public static function fromString(str:String, def:XMLAnimType = XMLAnimType.NONE)
	{
		return switch (StringTools.trim(str).toLowerCase())
		{
			case "none": NONE;
			case "beat" | "onbeat": BEAT;
			case "loop": LOOP;
			default: def;
		}
	}

	@:to public function toString():String {
		return switch (cast this)
		{
			case NONE: "none";
			case BEAT: "beat";
			case LOOP: "loop";
		}
	}
}

class FunkinSprite extends FlxSkewedSprite implements IBeatReceiver implements IOffsetCompatible implements IXMLEvents
{
	public var extra:Map<String, Dynamic> = [];

	public var spriteAnimType:XMLAnimType = NONE;
	public var beatAnims:Array<BeatAnim> = [];
	public var name:String;
	public var zoomFactor:Float = 1;
	public var debugMode:Bool = false;
	public var animDatas:Map<String, AnimData> = [];
	public var animEnabled:Bool = true;
	public var zoomFactorEnabled:Bool = true;

	public var globalCurFrame(get, set):Int;

	/**
	 * ODD interval -> not aligned to beats
	 * EVEN interval -> aligned to beats
	 */
	public var beatInterval(default, set):Int = 2;
	public var beatOffset:Int = 0;
	public var skipNegativeBeats:Bool = false;

	public var animateAtlas:FlxAnimate;
	@:noCompletion public var atlasPlayingAnim:String;
	@:noCompletion public var atlasPath:String;

	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y);

		if (SimpleGraphic != null)
		{
			if (SimpleGraphic is String)
				loadSprite(cast SimpleGraphic);
			else
				loadGraphic(SimpleGraphic);
		}

		moves = false;
	}

	/**
	 * Gets the graphics and copies other properties from another sprite (Works both for `FlxSprite` and `FunkinSprite`!).
	 */
	public static function copyFrom(source:FlxSprite):FunkinSprite
	{
		var spr = new FunkinSprite();
		var casted:FunkinSprite = null;
		if (source is FunkinSprite)
			casted = cast source;

		@:privateAccess {
			spr.setPosition(source.x, source.y);
			spr.frames = source.frames;
			if (casted != null && casted.animateAtlas != null && casted.atlasPath != null)
				spr.loadSprite(casted.atlasPath);
			spr.animation.copyFrom(source.animation);
			spr.visible = source.visible;
			spr.alpha = source.alpha;
			spr.antialiasing = source.antialiasing;
			spr.scale.set(source.scale.x, source.scale.y);
			spr.scrollFactor.set(source.scrollFactor.x, source.scrollFactor.y);

			if (casted != null) {
				spr.skew.set(casted.skew.x, casted.skew.y);
				spr.transformMatrix = casted.transformMatrix;
				spr.matrixExposed = casted.matrixExposed;
				spr.animOffsets = casted.animOffsets.copy();
			}
		}
		return spr;
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (animateAtlas != null)
			animateAtlas.update(elapsed);

		// hate how it looks like but hey at least its optimized and fast  - Nex
		if (!debugMode && isAnimFinished()) {
			var name = getAnimName() + '-loop';
			if (hasAnimation(name))
				playAnim(name, null, lastAnimContext);
		}
	}

	public function loadSprite(path:String, Unique:Bool = false, Key:String = null)
	{
		var noExt = Path.withoutExtension(path);
		if (Assets.exists('$noExt/Animation.json'))
		{
			atlasPath = noExt;
			animateAtlas = new FlxAnimate(x, y, noExt);
		}
		else
		{
			frames = Paths.getFrames(path, true);
		}
		return this;
	}

	public function onPropertySet(property:String, value:Dynamic) {
		if (property.startsWith("velocity") || property.startsWith("acceleration"))
			moves = true;
	}

	private var countedBeat = 0;
	public function beatHit(curBeat:Int)
	{
		if(!animEnabled) return;
		if (lastAnimContext != LOCK && beatAnims.length > 0 && (curBeat + beatOffset) % beatInterval == 0)
		{
			// TODO: find a solution without countedBeat
			var anim = beatAnims[FlxMath.wrap(countedBeat++, 0, beatAnims.length - 1)];
			if (anim.name != null && anim.name != "null" && anim.name != "none")
				playAnim(anim.name, anim.forced);
		}
	}

	public function stepHit(curBeat:Int)
	{
	}

	public function measureHit(curMeasure:Int)
	{
	}

	// ANIMATE ATLAS DRAWING
	#if REGION
	public override function draw()
	{
		if (animateAtlas != null)
		{
			copyAtlasValues();
			animateAtlas.draw();
		}
		else
		{
			super.draw();
		}
	}

	public function copyAtlasValues()
	{
		@:privateAccess {
			animateAtlas.cameras = cameras; // investigate if we can use _cameras
			animateAtlas.scrollFactor = scrollFactor;
			animateAtlas.scale = scale;
			animateAtlas.offset = offset;
			animateAtlas.frameOffset = frameOffset;
			animateAtlas.x = x;
			animateAtlas.y = y;
			animateAtlas.angle = angle;
			animateAtlas.alpha = alpha;
			animateAtlas.visible = visible;
			animateAtlas.flipX = flipX;
			animateAtlas.flipY = flipY;
			animateAtlas.shader = shader;
			animateAtlas.shaderEnabled = shaderEnabled;
			animateAtlas.antialiasing = antialiasing;
			animateAtlas.skew = skew;
			animateAtlas.transformMatrix = transformMatrix;
			animateAtlas.matrixExposed = matrixExposed;
			animateAtlas.colorTransform = colorTransform;
		}
	}

	public override function destroy()
	{
		animateAtlas = FlxDestroyUtil.destroy(animateAtlas);

		if (animOffsets != null) {
			for (key in animOffsets.keys()) {
				final point = animOffsets[key];
				animOffsets.remove(key);
				if (point != null)
					point.put();
			}
			animOffsets = null;
		}
		super.destroy();
	}
	#end

	// ZOOM FACTOR
	private inline function __shouldDoZoomFactor()
		return zoomFactorEnabled && zoomFactor != 1;

	public override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
	{
		if (camera == null)
			camera = FlxG.camera;

		var r = super.getScreenBounds(newRect, camera);

		if(__shouldDoZoomFactor()) {
			r.x -= camera.width / 2;
			r.y -= camera.height / 2;

			var ratio = (camera.zoom > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.zoom, 1, zoomFactor));
			r.x *= ratio;
			r.y *= ratio;
			r.width *= ratio;
			r.height *= ratio;

			r.x += camera.width / 2;
			r.y += camera.height / 2;
		}
		return r;
	}

	override public function isOnScreen(?camera:FlxCamera):Bool
	{
		if (forceIsOnScreen)
			return true;

		if (camera == null)
			camera = FlxG.camera;

		var bounds = getScreenBounds(_rect, camera);
		if (bounds.width == 0 && bounds.height == 0)
			return false;
		return camera.containsRect(bounds);
	}

	// ZOOM FACTOR RENDERING
	public override function doAdditionalMatrixStuff(matrix:FlxMatrix, camera:FlxCamera)
	{
		super.doAdditionalMatrixStuff(matrix, camera);
		if(__shouldDoZoomFactor()) {
			matrix.translate(-camera.width / 2, -camera.height / 2);

			var requestedZoom = (camera.zoom >= 0 ? Math.max : Math.min)(FlxMath.lerp(1, camera.zoom, zoomFactor), 0);
			var diff = requestedZoom / camera.zoom;
			matrix.scale(diff, diff);
			matrix.translate(camera.width / 2, camera.height / 2);
		}
	}

	// OFFSETTING
	#if REGION
	public var animOffsets:Map<String, FlxPoint> = new Map<String, FlxPoint>();

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = FlxPoint.get(x, y);
	}

	public function switchOffset(anim1:String, anim2:String)
	{
		var old = animOffsets[anim1];
		animOffsets[anim1] = animOffsets[anim2];
		animOffsets[anim2] = old;
	}
	#end

	// PLAYANIM
	#if REGION
	public var lastAnimContext:PlayAnimContext = DANCE;

	public function playAnim(AnimName:String, ?Force:Null<Bool>, Context:PlayAnimContext = NONE, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (AnimName == null)
			return;

		if (Force == null) {
			var anim = animDatas.get(AnimName);
			Force = anim != null && anim.forced;
		}

		if (animateAtlas != null)
		{
			@:privateAccess
			// if (!animateAtlas.anim.animsMap.exists(AnimName) && !animateAtlas.anim.symbolDictionary.exists(AnimName)) return;
			animateAtlas.anim.play(AnimName, Force, Reversed, Frame);
			atlasPlayingAnim = AnimName;
		}
		else
		{
			if (!animation.exists(AnimName) && !debugMode)
				return;
			animation.play(AnimName, Force, Reversed, Frame);
		}

		var daOffset = getAnimOffset(AnimName);
		frameOffset.set(daOffset.x, daOffset.y);
		daOffset.putWeak();

		lastAnimContext = Context;
	}

	public inline function addAnim(name:String, prefix:String, frameRate:Float = 24, ?looped:Bool, ?forced:Bool, ?indices:Array<Int>, x:Float = 0, y:Float = 0, animType:XMLAnimType = NONE)
	{
		return XMLUtil.addAnimToSprite(this, {
			name: name,
			anim: prefix,
			fps: frameRate,
			loop: looped == null ? animType == LOOP : looped,
			animType: animType,
			x: x,
			y: y,
			indices: indices,
			forced: forced
		});
	}

	public inline function removeAnim(name:String)
	{
		if (animateAtlas != null)
			@:privateAccess animateAtlas.anim.animsMap.remove(name);
		else
			animation.remove(name);
	}

	public function getAnim(name:String):OneOfTwo<FlxAnimation, FlxSymbolAnimation>
	{
		if(animateAtlas != null)
			return animateAtlas.anim.getByName(name);
		return animation.getByName(name);
	}

	public inline function getAnimOffset(name:String)
	{
		if (animOffsets.exists(name))
			return animOffsets[name];
		return FlxPoint.weak(0, 0);
	}

	public inline function hasAnim(AnimName:String):Bool @:privateAccess
		return animateAtlas != null ? (animateAtlas.anim.animsMap.exists(AnimName)
			|| animateAtlas.anim.symbolDictionary.exists(AnimName)) : animation.exists(AnimName);

	public inline function getAnimName() {
		return (animateAtlas != null) ? atlasPlayingAnim : animation.name;
	}

	public inline function isAnimReversed():Bool {
		return animateAtlas != null ? animateAtlas.anim.reversed : animation.curAnim != null ? animation.curAnim.reversed : false;
	}

	public inline function getNameList():Array<String> {
		if (animateAtlas != null)
			return [for (name in @:privateAccess animateAtlas.anim.animsMap.keys()) name];
		else
			return animation.getNameList();
	}

	public inline function stopAnim()
	{
		if (animateAtlas != null)
			animateAtlas.anim.pause();
		else
			animation.stop();
	}

	public inline function isAnimFinished() {
		return animateAtlas != null ? animateAtlas.anim.finished : (animation.curAnim != null ? animation.curAnim.finished : true);
	}

	public inline function isAnimAtEnd() {
		return animateAtlas != null ? animateAtlas.anim.isAtEnd : (animation.curAnim != null ? animation.curAnim.isAtEnd : false);
	}

	override function updateAnimation(elapsed:Float) {
		if (animEnabled)
			super.updateAnimation(elapsed);
	}

	// Backwards compat (the names used to be all different and it sucked, please lets use the same format in the future)  - Nex
	public inline function hasAnimation(AnimName:String) return hasAnim(AnimName);
	public inline function removeAnimation(name:String) return removeAnim(name);
	public inline function stopAnimation() return stopAnim();
	#end

	// Getter / Setters

	@:noCompletion private function set_beatInterval(v:Int) {
		if (v < 1)
			v = 1;

		return beatInterval = v;
	}

	@:noCompletion private inline function get_globalCurFrame() {
		return animateAtlas != null ? (animateAtlas.anim.curFrame) : (animation.curAnim != null ? animation.curAnim.curFrame : 0);
	}
	@:noCompletion private inline function set_globalCurFrame(val:Int) {
		return animateAtlas != null ? (animateAtlas.anim.curFrame = val) : (animation.curAnim != null ? animation.curAnim.curFrame = val : val);
	}
}
