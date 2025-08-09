package funkin.menus.ui;

import flixel.animation.FlxAnimation;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;

class Slider extends FlxSprite {
	public var playSound:Bool = true;
	public var selected:Bool = false;
	public var value:Float;
	public var segments(default, set):Int;

	public var barWidth(default, set):Float;
	public var barHeight(default, null):Float;
	public var showSlider:Bool = true;

	public var barFramerate:Float = 24.0;
	var __animTime:Float = 0.0;
	var __frameTime:Int;
	var __curSegments:Int;
	var __barFrame:FlxFrame;
	var __barClipRect:FlxRect;
	var __valueWidth:Float;
	var __cornerWidth:Float;
	var __segmentWidth:Float;
	var __barWidth:Float;
	var __flipX:Bool;
	var __flipY:Bool;

	public function new(?x:Float, ?y:Float, value:Float = 0.5, barWidth:Float = 500, segments:Int = 5) {
		super(x, y);
		this.value = value;
		this.barWidth = barWidth;
		this.segments = segments;

		frames = Paths.getFrames('menus/options/slider');
		antialiasing = true;
	}

	override function initVars() {
		super.initVars();
		__barClipRect = FlxRect.get();
	}

	override function destroy() {
		super.destroy();
		__barFrame = FlxDestroyUtil.destroy(__barFrame);
		__barClipRect = FlxDestroyUtil.put(__barClipRect);
	}

	function playAnimOrDefault(a:String, d:String) {
		if (animation.exists(a)) animation.play(a);
		else animation.play(d);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		__frameTime = Math.floor((__animTime += elapsed) * barFramerate);

		if (animation.curAnim == null) {
			animation.play(selected ? 'selected' : 'unselected');
			__curSegments = CoolUtil.minInt(segments, Math.floor(value * (segments + 1)));
		}
		else {
			switch (animation.curAnim.name) {
				case 'selected': if (!selected) playAnimOrDefault('deselect', 'unselected');
				case 'unselected': if (selected) playAnimOrDefault('selecting', 'selected');
				case 'selecting' | 'segment': if (animation.finished) animation.play('selected');
				case 'deselect': if (animation.finished) animation.play('unselected');
			}

			if (__curSegments != (__curSegments = CoolUtil.minInt(segments, Math.floor(value * (segments + 1)))) && playSound) {
				FlxG.sound.play(Paths.sound('menu/volume')).pitch = 0.75 + __curSegments * 0.5 / (segments + 1);
				if (animation.curAnim.name == 'selected' && animation.exists('segment')) animation.play('segment');
			}
		}
	}

	override function isSimpleRender(?camera:FlxCamera):Bool return false;
	override function drawComplex(camera:FlxCamera) {
		__flipX = checkFlipX();
		__flipY = checkFlipY();
		__valueWidth = barWidth * value;

		var width = barWidth / (segments + 1), x = drawCorner(camera, 0, false);
		var end = barWidth - __cornerWidth, nextSegment = width - (segments == 0 ? 0 : __segmentWidth * 0.5);
		while (x < end) {
			if (x == (x = drawBar(camera, x, Math.min(nextSegment - x, end - x)))) break;
			if (x < end && x < nextSegment + __segmentWidth * 0.5) {
				x = drawSegment(camera, x, Math.min(__segmentWidth, nextSegment + __segmentWidth - x), CoolUtil.bound(x - end, 0, __segmentWidth));
			}
			nextSegment += width;
		}
		drawCorner(camera, x, true);

		if (showSlider) {
			_frame.prepareMatrix(_matrix, ANGLE_0, __flipX != camera.flipX, __flipY != camera.flipY);
			prepareDrawMatrix(camera, -_frame.sourceSize.x * 0.5 + (__flipX ? barWidth - __valueWidth : __valueWidth), -(_frame.sourceSize.y - barHeight) * 0.5);
			forceDrawFrame(camera, _frame);
		}
	}

	inline function prepareDrawMatrix(camera:FlxCamera, x:Float, y:Float) {
		_matrix.translate(-origin.x, -origin.y);

		if (frameOffsetAngle != null && frameOffsetAngle != angle) {
			var angleOff = (frameOffsetAngle - angle) * FlxAngle.TO_RAD;
			var cos = Math.cos(angleOff), sin = Math.sin(angleOff);

			_matrix.rotateWithTrig(cos, -sin);
			_matrix.translate(-frameOffset.x + x, -frameOffset.y + y);
			_matrix.rotateWithTrig(cos, sin);
		}
		else
			_matrix.translate(-frameOffset.x + x, -frameOffset.y + y);

		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0) {
			updateTrig();
			if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera)) {
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}

		doAdditionalMatrixStuff(_matrix, camera);
	}

	function forceDrawFrame(camera:FlxCamera, frame:FlxFrame) {
		if (layer != null)
			layer.drawPixels(this, camera, frame, frame.parent.bitmap, _matrix, colorTransform, blend, antialiasing, shaderEnabled ? shader : null);
		else
			camera.drawPixels(frame, frame.parent.bitmap, _matrix, colorTransform, blend, antialiasing, shaderEnabled ? shader : null);
	}

	function drawCorner(camera:FlxCamera, x:Float, flip:Bool):Float {
		var anim, frame;

		if (__valueWidth > x) {
			anim = getBarAnim(1, true);
			frame = frames.frames[anim.frames[__frameTime % anim.numFrames]];

			if (flip) __barClipRect.set(__cornerWidth - __valueWidth + x, 0, __valueWidth - x, frame.sourceSize.y);
			else __barClipRect.set(0, 0, __valueWidth - x, frame.sourceSize.y);
			__barFrame = frame.clipTo(__barClipRect, __barFrame);
			__barFrame.prepareMatrix(_matrix, ANGLE_0, flip != __flipX != camera.flipX, __flipY != camera.flipY);
			prepareDrawMatrix(camera, __flipX ? barWidth - x - frame.sourceSize.x : x, 0);
			forceDrawFrame(camera, __barFrame);
		}

		if (__valueWidth - x < __cornerWidth) {
			anim = getBarAnim(1, false);
			frame = frames.frames[anim.frames[__frameTime % anim.numFrames]];

			if (flip) __barClipRect.set(0, 0, __cornerWidth - __valueWidth + x, frame.sourceSize.y);
			else __barClipRect.set(__valueWidth - x, 0, __cornerWidth - __valueWidth + x, frame.sourceSize.y);
			__barFrame = frame.clipTo(__barClipRect, __barFrame);
			__barFrame.prepareMatrix(_matrix, ANGLE_0, flip != __flipX != camera.flipX, __flipY != camera.flipY);
			prepareDrawMatrix(camera, __flipX ? barWidth - x - frame.sourceSize.x : x, 0);
			forceDrawFrame(camera, __barFrame);
		}

		return x + __cornerWidth;
	}

	function drawBar(camera:FlxCamera, x:Float, width:Float):Float {
		if (width <= 0) return x;
		var anim, frame, s;

		if (__valueWidth > x) {
			anim = getBarAnim(0, true);
			frame = frames.frames[anim.frames[__frameTime % anim.numFrames]];
			s = width / frame.sourceSize.x;

			__barClipRect.set(0, 0, (__valueWidth - x) / s, frame.sourceSize.y);
			__barFrame = frame.clipTo(__barClipRect, __barFrame);
			__barFrame.prepareMatrix(_matrix, ANGLE_0, __flipX != camera.flipX, __flipY != camera.flipY);
			_matrix.scale(s, 1);
			prepareDrawMatrix(camera, __flipX ? barWidth - x - width : x, 0);
			forceDrawFrame(camera, __barFrame);
		}

		if (__valueWidth - x < width) {
			anim = getBarAnim(0, false);
			frame = frames.frames[anim.frames[__frameTime % anim.numFrames]];
			s = width / frame.sourceSize.x;

			__barClipRect.set((__valueWidth - x) / s, 0, (width - __valueWidth + x) / s, frame.sourceSize.y);
			__barFrame = frame.clipTo(__barClipRect, __barFrame);
			__barFrame.prepareMatrix(_matrix, ANGLE_0, __flipX != camera.flipX, __flipY != camera.flipY);
			_matrix.scale(s, 1);
			prepareDrawMatrix(camera, __flipX ? barWidth - x - width : x, 0);
			forceDrawFrame(camera, __barFrame);
		}

		return x + width;
	}

	function drawSegment(camera:FlxCamera, x:Float, width:Float, offset:Float):Float {
		if (width <= 0) return x;
		var anim, frame;

		if (__valueWidth > x) {
			anim = getBarAnim(2, true);
			frame = frames.frames[anim.frames[__frameTime % anim.numFrames]];

			__barClipRect.set(offset, 0, __valueWidth - x, frame.sourceSize.y);
			__barFrame = frame.clipTo(__barClipRect, __barFrame);
			__barFrame.prepareMatrix(_matrix, ANGLE_0, __flipX != camera.flipX, __flipY != camera.flipY);
			prepareDrawMatrix(camera, __flipX ? barWidth - x - width : x, 0);
			forceDrawFrame(camera, __barFrame);
		}

		if (__valueWidth - x < __segmentWidth) {
			anim = getBarAnim(2, false);
			frame = frames.frames[anim.frames[__frameTime % anim.numFrames]];

			__barClipRect.set(__valueWidth - x + offset, 0, __segmentWidth - offset - __valueWidth + x, frame.sourceSize.y);
			__barFrame = frame.clipTo(__barClipRect, __barFrame);
			__barFrame.prepareMatrix(_matrix, ANGLE_0, __flipX != camera.flipX, __flipY != camera.flipY);
			prepareDrawMatrix(camera, __flipX ? barWidth - x - width : x, 0);
			forceDrawFrame(camera, __barFrame);
		}

		return x + width;
	}

	function getBarAnim(type:Int, filled:Bool):FlxAnimation {
		var name = (type == 1 ? 'corner ' : (type == 2 ? 'segment ' : 'bar ')) + (filled ? 'filled0' : 'empty0');
		if (animation.exists(name)) return animation.getByName(name);

		animation.addByPrefix(name, name, barFramerate, true);
		return animation.getByName(name);
	}

	inline function sliderResetFrameSize() {
		frameWidth = Std.int(barWidth);
		frameHeight = Std.int(barHeight);
		_halfSize.set(0.5 * frameWidth, 0.5 * frameHeight);
		resetSize();
	}

	override function resetHelpers() {
		animation.addByPrefix('unselected', 'slider unselected0', 24, true);
		animation.addByPrefix('selected', 'slider selected0', 24, true);
		animation.addByPrefix('deselect', 'slider deselect0', 24, false);
		animation.addByPrefix('selecting', 'slider selecting0', 24, false);
		animation.addByPrefix('segment', 'slider segment0', 24, false);

		var anim, width;
		inline function checkSize(type) {
			barHeight = Math.max(barHeight, frames.frames[anim.frames[0]].sourceSize.y);
			width = frames.frames[anim.frames[0]].sourceSize.x;
			switch (type) {
				case 0: __barWidth = Math.max(__barWidth, width);
				case 1: __cornerWidth = Math.max(__cornerWidth, width);
				case 2: __segmentWidth = Math.max(__segmentWidth, width);
			}
		}

		barHeight = 0;
		for (type in 0...3) {
			if ((anim = getBarAnim(type, false)) != null) checkSize(type);
			if ((anim = getBarAnim(type, true)) != null) checkSize(type);
		}

		sliderResetFrameSize();
		resetSizeFromFrame();
		centerOrigin();

		if (FlxG.renderBlit) {
			dirty = true;
			updateFramePixels();
		}
	}

	override function set_frame(v:FlxFrame):FlxFrame {
		super.set_frame(v);
		if (v != null) sliderResetFrameSize();
		return v;
	}

	function set_barWidth(v:Float):Float {
		origin.x = _halfSize.x = 0.5 * (frameWidth = Std.int(barWidth = v));
		return v;
	}

	function set_segments(v:Int):Int return segments = CoolUtil.maxInt(v, 0);
}