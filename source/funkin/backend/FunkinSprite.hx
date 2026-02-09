package funkin.backend;

import animate.FlxAnimate;
import animate.FlxAnimateController.FlxAnimateAnimation;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.animation.FlxAnimation;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.typeLimit.OneOfTwo;
import funkin.backend.scripting.events.sprite.PlayAnimContext;
import funkin.backend.system.interfaces.IBeatReceiver;
import funkin.backend.system.interfaces.IOffsetCompatible;
import funkin.backend.utils.XMLUtil.AnimData;
import funkin.backend.utils.XMLUtil.BeatAnim;
import funkin.backend.utils.XMLUtil.IXMLEvents;
import haxe.io.Path;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxAngle;
import animate.internal.RenderTexture;
import animate.FlxAnimateFrames;

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

class FunkinSprite extends FlxAnimate implements IBeatReceiver implements IOffsetCompatible implements IXMLEvents
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

	//Backwards compatibility
	public var animateAtlas(get, never):FunkinSprite;

	public var globalCurFrame(get, set):Int;

	/**
	 * ODD interval -> not aligned to beats
	 * EVEN interval -> aligned to beats
	 */
	public var beatInterval(default, set):Int = 2;
	public var beatOffset:Int = 0;
	public var skipNegativeBeats:Bool = false;

	public var animateSettings:FlxAnimateSettings = {};

	var _rect2:FlxRect;

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
		applyStageMatrix = true;
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
			spr.animation.copyFrom(source.animation);
			spr.visible = source.visible;
			spr.alpha = source.alpha;
			spr.antialiasing = source.antialiasing;
			spr.scale.set(source.scale.x, source.scale.y);
			spr.scrollFactor.set(source.scrollFactor.x, source.scrollFactor.y);

			if (casted != null) {
				spr.skew.set(casted.skew.x, casted.skew.y);
				spr.animOffsets = casted.animOffsets.copy();
				spr.zoomFactor = casted.zoomFactor;
			}
		}
		return spr;
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		// hate how it looks like but hey at least its optimized and fast  - Nex
		if (!debugMode && isAnimFinished()) {
			var name = getAnimName() + '-loop';
			if (hasAnim(name))
				playAnim(name, null, lastAnimContext);
		}
	}

	override function initVars() {
		super.initVars();
		_rect2 = FlxRect.get();
	}

	public function loadSprite(path:String, Unique:Bool = false, Key:String = null)
	{
		var noExt = Path.withoutExtension(path);
		frames = Paths.getFrames(path, true, null, null, animateSettings);
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

	public override function draw() {
		// re-implementing the `onDraw` functionality from `FlxSprite` since `FlxAnimate` didn't have this, so we have to add it back in ourselves
	    if (this.isAnimate && this.__drawOverrided) {
	        this.__drawOverrided = false;
	        this.onDraw(this);
	        this.__drawOverrided = true;
			return;
	    }
	    super.draw();
	}

	// ANIMATE ATLAS DRAWING
	#if REGION

	public override function destroy()
	{
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

		_rect2 = FlxDestroyUtil.put(_rect2);
	}
	#end

	// ZOOM FACTOR
	private inline function __shouldDoZoomFactor()
		return zoomFactorEnabled && zoomFactor != 1;

	private inline function __prepareZoomFactor(?rect:FlxRect, camera:FlxCamera):FlxRect {
		if (Flags.USE_LEGACY_ZOOM_FACTOR)
			return (rect ?? FlxRect.get()).set(
				camera.width * 0.5,
				camera.height * 0.5,
				(camera.scaleX > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleX, 1, zoomFactor)),
				(camera.scaleY > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleY, 1, zoomFactor))
			);
		else
			return (rect ?? FlxRect.get()).set(
				camera.width * 0.5 + camera.scroll.x * scrollFactor.x,
				camera.height * 0.5 + camera.scroll.y * scrollFactor.y,
				(camera.scaleX > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleX, 1, zoomFactor)),
				(camera.scaleY > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.scaleY, 1, zoomFactor))
			);
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
		if (AnimName == null || (!hasAnim(AnimName) && !debugMode))
			return;

		if (Force == null) {
			var anim = animDatas.get(AnimName);
			Force = anim != null && anim.forced;
		}

		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = getAnimOffset(AnimName);
		frameOffset.set(daOffset.x, daOffset.y);
		daOffset.putWeak();

		lastAnimContext = Context;
	}

	public inline function addAnim(name:String, prefix:String, frameRate:Float = 24, ?looped:Bool, ?forced:Bool, ?indices:Array<Int>, x:Float = 0, y:Float = 0, animType:XMLAnimType = NONE, animateAtlasLabel:Bool = false)
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
			forced: forced,
			label: animateAtlasLabel
		});
	}

	public inline function removeAnim(name:String) {
		animation.remove(name);
	}

	public function getAnim(name:String):OneOfTwo<FlxAnimation, FlxAnimateAnimation> {
		return animation.getByName(name);
	}

	public inline function getAnimOffset(name:String)
	{
		if (animOffsets.exists(name))
			return animOffsets[name];
		return FlxPoint.weak(0, 0);
	}

	public inline function hasAnim(AnimName:String):Bool
		return animation.exists(AnimName);

	public inline function getAnimName()
		return animation.name;

	public inline function isAnimReversed():Bool
		return animation.curAnim?.reversed ?? false;

	public inline function getNameList():Array<String>
		return animation.getNameList();

	public inline function stopAnim()
		animation.stop();

	public inline function isAnimFinished()
		return animation.curAnim?.finished ?? true;

	public inline function isAnimAtEnd()
		return animation.curAnim?.isAtEnd ?? false;

	override function updateAnimation(elapsed:Float) {
		if (animEnabled)
			super.updateAnimation(elapsed);
	}

	// Backwards compat (the names used to be all different and it sucked, please lets use the same format in the future)  - Nex
	@:dox(hide) public inline function hasAnimation(AnimName:String) return hasAnim(AnimName);
	@:dox(hide) public inline function removeAnimation(name:String) return removeAnim(name);
	@:dox(hide) public inline function stopAnimation() return stopAnim();
	#end

	// Getter / Setters

	@:noCompletion private function set_beatInterval(v:Int) {
		if (v < 1)
			v = 1;

		return beatInterval = v;
	}

	@:noCompletion
	@:deprecated("`FunkinSprite.animateAtlas` is deprecated, just use `FunkinSprite` instead")
	public function get_animateAtlas():FunkinSprite
    	return isAnimate ? this : null;

	@:noCompletion private inline function get_globalCurFrame()
		return animation.curAnim?.curFrame ?? 0;

	@:noCompletion private inline function set_globalCurFrame(val:Int) {
		if (animation.curAnim != null)
			animation.curAnim.curFrame = val;
		return val;
	}

	override function prepareDrawMatrix(matrix:FlxMatrix, camera:FlxCamera):Void {
		matrix.translate(-origin.x, -origin.y);

		if (frameOffsetAngle != null && frameOffsetAngle != angle)
		{
			var angleOff = (frameOffsetAngle - angle) * FlxAngle.TO_RAD;
			var cos = Math.cos(angleOff);
			var sin = Math.sin(angleOff);
			// cos doesnt need to be negated
			matrix.rotateWithTrig(cos, -sin);
			matrix.translate(-frameOffset.x, -frameOffset.y);
			matrix.rotateWithTrig(cos, sin);
		}
		else
			matrix.translate(-frameOffset.x, -frameOffset.y);

		matrix.translate(origin.x, origin.y);

		super.prepareDrawMatrix(matrix, camera);

		if(__shouldDoZoomFactor()) {
			__prepareZoomFactor(_rect2, camera);
			matrix.setTo(
				matrix.a * _rect2.width, matrix.b * _rect2.height,
				matrix.c * _rect2.width, matrix.d * _rect2.height,
				(matrix.tx - _rect2.x) * _rect2.width + _rect2.x,
				(matrix.ty - _rect2.y) * _rect2.height + _rect2.y,
			);
		}
	}

	override function checkFlipX() {
		return super.checkFlipX() != camera.flipX;
	}
	override function checkFlipY() {
		return super.checkFlipY() != camera.flipY;
	}
}
