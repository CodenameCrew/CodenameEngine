package funkin.editors.ui.old;

import flixel.math.FlxRect;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;

class OldUISliceSpriteTri extends UISprite {
	public var bWidth(default, set):Int = 120;
	public var bHeight(default, set):Int = 20;
	public var framesOffset(default, set):Int = 0;

	public var incorporeal:Bool = false;

	public function new(x:Float, y:Float, w:Int, h:Int, path:String) {
		super(x, y);

		frames = Paths.getFrames(path);
		resize(w, h);

		calculateFrames();
		__genMesh();
	}

	public override function updateButton() {
		if (incorporeal) return;
		__rect.set(x, y, bWidth, bHeight);
		UIState.state.updateRectButtonHandler(this, __rect, onHovered);
	}

	public function resize(w:Int, h:Int) {
		bWidth = w;
		bHeight = h;
	}

	@:deprecated public var topAlpha:Null<Float> = null;
	@:deprecated public var middleAlpha:Null<Float> = null;
	@:deprecated public var bottomAlpha:Null<Float> = null;

	public var drawTop(default, set):Bool = true;
	public var drawMiddle(default, set):Bool = true;
	public var drawBottom(default, set):Bool = true;

	private function set_drawTop(value:Bool):Bool {
		if(value != drawTop) {
			drawTop = value;
			__meshDirty = true;
		}
		return value;
	}

	private function set_drawMiddle(value:Bool):Bool {
		if(value != drawMiddle) {
			drawMiddle = value;
			__meshDirty = true;
		}
		return value;
	}

	private function set_drawBottom(value:Bool):Bool {
		if(value != drawBottom) {
			drawBottom = value;
			__meshDirty = true;
		}
		return value;
	}

	var topleft:FlxFrame = null;
	var top:FlxFrame = null;
	var topright:FlxFrame = null;
	var middleleft:FlxFrame = null;
	var middle:FlxFrame = null;
	var middleright:FlxFrame = null;
	var bottomleft:FlxFrame = null;
	var bottom:FlxFrame = null;
	var bottomright:FlxFrame = null;

	public var topHeight:Int = 0;
	public var bottomHeight:Int = 0;
	public var leftWidth:Int = 0;
	public var rightWidth:Int = 0;

	override function set_frames(val) {
		super.set_frames(val);
		__framesDirty = true;
		return val;
	}

	function set_framesOffset(value:Int) {
		if(value != framesOffset) {
			framesOffset = value;
			__framesDirty = true;
		}
		return value;
	}

	function calculateFrames() {
		if(frames == null) return;
		topleft = frames.frames[framesOffset];
		top = frames.frames[framesOffset + 1];
		topright = frames.frames[framesOffset + 2];
		middleleft = frames.frames[framesOffset + 3];
		middle = frames.frames[framesOffset + 4];
		middleright = frames.frames[framesOffset + 5];
		bottomleft = frames.frames[framesOffset + 6];
		bottom = frames.frames[framesOffset + 7];
		bottomright = frames.frames[framesOffset + 8];

		leftWidth = Std.int(MathUtil.maxSmart(topleft.frame.width, middleleft.frame.width, bottomleft.frame.width));
		rightWidth = Std.int(MathUtil.maxSmart(topright.frame.width, middleright.frame.width, bottomright.frame.width));
		topHeight = Std.int(MathUtil.maxSmart(topleft.frame.height, top.frame.height, topright.frame.height));
		bottomHeight = Std.int(MathUtil.maxSmart(topleft.frame.height, top.frame.height, topright.frame.height));

		__meshDirty = true;
	}

	public override function draw() @:privateAccess {
		checkEmptyFrame();

		if (alpha != 0 && _frame.type != FlxFrameType.EMPTY) {
			if (__framesDirty) calculateFrames();
			if (__meshDirty) __genMesh();

			for (camera in cameras)
			{
				if (!camera.visible || !camera.exists || !isOnScreen(camera))
					continue;

				getScreenPosition(_point, camera).subtractPoint(offset);

				#if !flash
				camera.drawTriangles(graphic, vertices, indices, uvtData, colors, _point, blend, false, antialiasing, colorTransform, shader);
				#else
				camera.drawTriangles(graphic, vertices, indices, uvtData, colors, _point, blend, false, antialiasing);
				#end

				#if FLX_DEBUG
				FlxBasic.visibleCount++;
				#end
			}
		}

		super.drawMembers();
		__lastDrawCameras = cameras.copy();
	}

	var vertices:DrawData<Float> = new DrawData<Float>();
	var indices:DrawData<Int> = new DrawData<Int>();
	var uvtData:DrawData<Float> = new DrawData<Float>();
	var colors:DrawData<Int> = new DrawData<Int>();

	var __framesDirty:Bool = false;
	var __meshDirty:Bool = false;

	private function set_bWidth(value:Int):Int {
		if(value != bWidth) {
			bWidth = value;
			__meshDirty = true;
		}
		return value;
	}

	private function set_bHeight(value:Int):Int {
		if(value != bHeight) {
			bHeight = value;
			__meshDirty = true;
		}
		return value;
	}

	private static inline function getFixedSize(value:Float, total:Float):Float {
		return value * Math.min(total / (value * 2), 1);
	}

	private function __genMesh() {
		indices.length = 0;
		vertices.length = 0;
		//colors.length = 0;
		uvtData.length = 0;

		var sliceTL:Quad = null;
		var sliceTM:Quad = null;
		var sliceTR:Quad = null;
		var sliceML:Quad = null;
		var sliceMM:Quad = null;
		var sliceMR:Quad = null;
		var sliceBL:Quad = null;
		var sliceBM:Quad = null;
		var sliceBR:Quad = null;

		// TOP PART
		if (drawTop) {
			// TOP LEFT
			var topLeftWidth:Float = getFixedSize(topleft.frame.width, bWidth);
			var topLeftHeight:Float = getFixedSize(topleft.frame.height, bHeight);
			sliceTL = __genSliceQuad(
				0, 0,
				topLeftWidth, topLeftHeight,
				topleft, null, null
			);

			// TOP MIDDLE
			if (bWidth > topleft.frame.width + topright.frame.width) {
				var topWidth:Float = bWidth - topleft.frame.width - topright.frame.width;
				var topHeight:Float = getFixedSize(top.frame.height, bHeight);
				sliceTM = __genSliceQuad(
					topLeftWidth, 0,
					topWidth, topHeight,
					top, sliceTL, null
				);
			}

			// TOP RIGHT
			var topRightWidth:Float = getFixedSize(topright.frame.width, bWidth);
			var topRightHeight:Float = getFixedSize(topright.frame.height, bHeight);
			sliceTR = __genSliceQuad(
				bWidth - getFixedSize(topright.frame.width, bWidth), 0,
				topRightWidth, topRightHeight,
				topright, sliceTM, null
			);
		}

		if (drawMiddle && bHeight > top.frame.height + bottom.frame.height) {
			var middleHeight:Float = bHeight - getFixedSize(topleft.frame.height, bHeight) - getFixedSize(bottomleft.frame.height, bHeight);

			// MIDDLE LEFT
			var middleLeftWidth:Float = getFixedSize(middleleft.frame.width, bWidth);
			sliceML = __genSliceQuad(
				0, top.frame.height,
				middleLeftWidth, middleHeight,
				middleleft, null, sliceTL
			);

			// MIDDLE
			if (bWidth > getFixedSize(middleleft.frame.width, bWidth) + middleright.frame.width) {
				var middleWidth:Float = bWidth - middleleft.frame.width - middleright.frame.width;
				sliceMM = __genSliceQuad(
					topleft.frame.width, top.frame.height,
					middleWidth, middleHeight,
					middle, sliceML, sliceTM
				);
			}

			// MIDDLE RIGHT
			var middleRightWidth:Float = getFixedSize(middleright.frame.width, bWidth);
			sliceMR = __genSliceQuad(
				bWidth - getFixedSize(middleright.frame.width, bWidth), top.frame.height,
				middleRightWidth, middleHeight,
				middleright, sliceMM, sliceTR
			);
		}

		// BOTTOM
		if (drawBottom) {
			// BOTTOM LEFT
			var bottomLeftWidth:Float = getFixedSize(bottomleft.frame.width, bWidth);
			var bottomLeftHeight:Float = getFixedSize(bottomleft.frame.height, bHeight);
			//var bottomLeftHeight:Float = bottomleft.frame.height * Math.min(bHeight/(bottomleft.frame.height*2), 1);
			sliceBL = __genSliceQuad(
				0, bHeight - getFixedSize(bottomleft.frame.height, bHeight),
				bottomLeftWidth, bottomLeftHeight,
				bottomleft, null, sliceML
			);

			// BOTTOM MIDDLE
			if (bWidth > bottomleft.frame.width + bottomright.frame.width) {
				var bottomMiddleWidth:Float = bWidth - bottomleft.frame.width - bottomright.frame.width;
				var bottomMiddleHeight:Float = getFixedSize(bottom.frame.height, bHeight);
				sliceBM = __genSliceQuad(
					bottomleft.frame.width, bHeight - getFixedSize(bottom.frame.height, bHeight),
					bottomMiddleWidth, bottomMiddleHeight,
					bottom, sliceBL, sliceMM
				);
			}

			// BOTTOM RIGHT
			var bottomRightWidth:Float = getFixedSize(bottomright.frame.width, bWidth);
			var bottomRightHeight:Float = getFixedSize(bottomright.frame.height, bHeight);
			sliceBR = __genSliceQuad(
				bWidth - getFixedSize(bottomright.frame.width, bWidth),
				bHeight - getFixedSize(bottomright.frame.height, bHeight),
				bottomRightWidth, bottomRightHeight,
				bottomright, sliceBM, sliceMR
			);
		}

		__meshDirty = false;
	}

	private function __genSliceQuad(x:Float, y:Float, width:Float, height:Float, frame:FlxFrame, leftSlice:Quad, topSlice:Quad):Quad {
		var indicesOffset:Int = Std.int(vertices.length / 2);

		if(leftSlice != null && topSlice != null) {
			indices.push(topSlice.bl);
			indices.push(topSlice.br);
			indices.push(indicesOffset);

			indices.push(leftSlice.tr);
			indices.push(indicesOffset);
			indices.push(leftSlice.br);

			vertices.push(x + width);
			vertices.push(y + height);

			uvtData.push(frame.uv.width);
			uvtData.push(frame.uv.height);

			// add when openfl fixes this
			//colors.push(color);

			return new Quad(topSlice.bl, topSlice.br, indicesOffset, leftSlice.br);
		}
		if(leftSlice != null) {
			indices.push(leftSlice.tr);
			indices.push(indicesOffset);
			indices.push(indicesOffset + 1);

			indices.push(leftSlice.tr);
			indices.push(indicesOffset + 1);
			indices.push(leftSlice.br);

			vertices.push(x + width);
			vertices.push(y);
			vertices.push(x + width);
			vertices.push(y + height);

			uvtData.push(frame.uv.width);
			uvtData.push(frame.uv.y);
			uvtData.push(frame.uv.width);
			uvtData.push(frame.uv.height);

			// add when openfl fixes this
			//colors.push(color);
			//colors.push(color);

			return new Quad(leftSlice.tr, indicesOffset, indicesOffset + 1, leftSlice.br);
		}
		if(topSlice != null) {
			indices.push(topSlice.bl);
			indices.push(topSlice.br);
			indices.push(indicesOffset);

			indices.push(topSlice.bl);
			indices.push(indicesOffset);
			indices.push(indicesOffset + 1);

			vertices.push(x + width);
			vertices.push(y + height);
			vertices.push(x);
			vertices.push(y + height);

			uvtData.push(frame.uv.width);
			uvtData.push(frame.uv.height);
			uvtData.push(frame.uv.x);
			uvtData.push(frame.uv.height);

			// add when openfl fixes this
			//colors.push(color);
			//colors.push(color);

			return new Quad(topSlice.bl, topSlice.br, indicesOffset, indicesOffset + 1);
		}
		indices.push(indicesOffset);
		indices.push(indicesOffset + 1);
		indices.push(indicesOffset + 2);

		indices.push(indicesOffset);
		indices.push(indicesOffset + 2);
		indices.push(indicesOffset + 3);

		vertices.push(x);
		vertices.push(y);
		vertices.push(x + width);
		vertices.push(y);
		vertices.push(x + width);
		vertices.push(y + height);
		vertices.push(x);
		vertices.push(y + height);

		uvtData.push(frame.uv.x);
		uvtData.push(frame.uv.y);
		uvtData.push(frame.uv.width);
		uvtData.push(frame.uv.y);
		uvtData.push(frame.uv.width);
		uvtData.push(frame.uv.height);
		uvtData.push(frame.uv.x);
		uvtData.push(frame.uv.height);

		// add when openfl fixes this
		//colors.push(color);
		//colors.push(color);
		//colors.push(color);
		//colors.push(color);

		return new Quad(indicesOffset, indicesOffset + 1, indicesOffset + 2, indicesOffset + 3);
	}

	@:access(flixel.FlxCamera)
	override function getBoundingBox(camera:FlxCamera):FlxRect {
		getScreenPosition(_point, camera);

		_rect.set(_point.x, _point.y, bWidth, bHeight);
		_rect = camera.transformRect(_rect);

		// if (isPixelPerfectRender(camera))
		// 	  _rect.floor();

		return _rect;
	}

	override public function destroy():Void
	{
		vertices = null;
		indices = null;
		uvtData = null;
		colors = null;

		super.destroy();
	}
}

final class Quad {
	public var tl:Int;
	public var tr:Int;
	public var br:Int;
	public var bl:Int;

	public function new(tl:Int, tr:Int, br:Int, bl:Int) {
		this.tl = tl;
		this.tr = tr;
		this.br = br;
		this.bl = bl;
	}
}