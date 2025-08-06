package funkin.editors.ui;

import flixel.graphics.frames.FlxFrame;

class UISliceSprite extends UISprite {
	public var bWidth:Int = 120;
	public var bHeight:Int = 20;
	public var framesOffset(default, set):Int = 0;

	public var incorporeal:Bool = false;

	public function new(x:Float, y:Float, w:Int, h:Int, path:String) {
		super(x, y);

		frames = Paths.getFrames(path);
		resize(w, h);
		calculateFrames();
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

	public var topAlpha:Null<Float> = null;
	public var middleAlpha:Null<Float> = null;
	public var bottomAlpha:Null<Float> = null;

	public var drawTop:Bool = true;
	public var drawMiddle:Bool = true;
	public var drawBottom:Bool = true;

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
		calculateFrames();
		return val;
	}

	function set_framesOffset(value:Int) {
		if(value != framesOffset) {
			framesOffset = value;
			calculateFrames();
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
	}

	@:pure private static inline function getFixedSize(value:Float, total:Float):Float {
		return value * Math.min(total / (value * 2), 1);
	}

	public override function draw() @:privateAccess {
		var lastPixelPerfect:Bool = cameras[0] != null ? cameras[0].pixelPerfectRender : false;
		if (cameras[0] != null) cameras[0].pixelPerfectRender = false;

		var topLeft = (flipX ? (flipY ? bottomright : topright) : (flipY ? bottomleft : topleft));
		var topMiddle = (flipY ? bottom : top);
		var topRight = (flipX ? (flipY ? bottomleft : topleft) : (flipY ? bottomright : topright));
		var middleLeft = (flipX ? middleright : middleleft);
		var middleRight = (flipX ? middleleft : middleright);
		var bottomLeft = (flipX ? (flipY ? topright : bottomright) : (flipY ? topleft : bottomleft));
		var bottomMiddle = (flipY ? top : bottom);
		var bottomRight = (flipX ? (flipY ? topleft : bottomleft) : (flipY ? topright : bottomright));

		var x:Float = this.x;
		var y:Float = this.y;

		if (visible && !(bWidth == 0 || bHeight == 0)) {
			var topLeftWidth:Float = getFixedSize(topLeft.frame.width, bWidth);
			var topLeftHeight:Float = getFixedSize(topLeft.frame.height, bHeight);
			//var topMiddleWidth:Float = getFixedSize(topMiddle.frame.width, bWidth);
			var topMiddleHeight:Float = getFixedSize(topMiddle.frame.height, bHeight);
			var topRightWidth:Float = getFixedSize(topRight.frame.width, bWidth);
			var topRightHeight:Float = getFixedSize(topRight.frame.height, bHeight);
			var middleLeftWidth:Float = getFixedSize(middleLeft.frame.width, bWidth);
			//var middleLeftHeight:Float = getFixedSize(middleLeft.frame.height, bHeight);
			//var middleMiddleWidth:Float = getFixedSize(middle.frame.width, bWidth);
			//var middleMiddleHeight:Float = getFixedSize(middle.frame.height, bHeight);
			var middleRightWidth:Float = getFixedSize(middleRight.frame.width, bWidth);
			//var middleRightHeight:Float = getFixedSize(middleRight.frame.height, bHeight);
			var bottomLeftWidth:Float = getFixedSize(bottomLeft.frame.width, bWidth);
			var bottomLeftHeight:Float = getFixedSize(bottomLeft.frame.height, bHeight);
			//var bottomMiddleWidth:Float = getFixedSize(bottomMiddle.frame.width, bWidth);
			var bottomMiddleHeight:Float = getFixedSize(bottomMiddle.frame.height, bHeight);
			var bottomRightWidth:Float = getFixedSize(bottomRight.frame.width, bWidth);
			var bottomRightHeight:Float = getFixedSize(bottomRight.frame.height, bHeight);

			var oldAlpha = alpha;
			// TOP
			if (drawTop) {
				// TOP LEFT
				if(topAlpha != null) alpha = topAlpha;
				frame = topLeft;
				setPosition(x, y);
				__setSize(
					topLeftWidth,
					topLeftHeight
				);
				super.drawSuper();

				// TOP
				if (bWidth > topLeft.frame.width + topRight.frame.width) {
					frame = topMiddle;
					setPosition(x + topLeft.frame.width, y);
					__setSize(
						bWidth - topLeft.frame.width - topRight.frame.width,
						topMiddleHeight
					);
					super.drawSuper();
				}

				// TOP RIGHT
				setPosition(x + bWidth - topRightWidth, y);
				frame = topRight;
				__setSize(
					topRightWidth,
					topRightHeight
				);
				super.drawSuper();
			}

			// MIDDLE
			if (drawMiddle && bHeight > topMiddle.frame.height + bottomMiddle.frame.height) {
				if(middleAlpha != null) alpha = middleAlpha;
				var middleHeight:Float = bHeight - topLeftHeight - bottomLeftHeight;

				// MIDDLE LEFT
				frame = middleLeft;
				setPosition(x, y + topMiddle.frame.height);
				__setSize(middleLeftWidth, middleHeight);
				super.drawSuper();

				if (bWidth > (middleLeftWidth) + middleRight.frame.width) {
					// MIDDLE
					frame = middle;
					setPosition(x + topLeft.frame.width, y + topMiddle.frame.height);
					__setSize(bWidth - middleLeft.frame.width - middleRight.frame.width, middleHeight);
					super.drawSuper();
				}

				// MIDDLE RIGHT
				frame = middleRight;
				setPosition(x + bWidth - (topRightWidth), y + topMiddle.frame.height);
				__setSize(middleRightWidth, middleHeight);
				super.drawSuper();
			}

			// BOTTOM
			if (drawBottom) {
				if(bottomAlpha != null) alpha = bottomAlpha;
				// BOTTOM LEFT
				frame = bottomLeft;
				setPosition(x, y + bHeight - (bottomLeftHeight));
				__setSize(
					bottomLeftWidth,
					bottomLeftHeight
				);
				super.drawSuper();

				if (bWidth > bottomLeft.frame.width + bottomRight.frame.width) {
					// BOTTOM
					frame = bottomMiddle;
					setPosition(x + bottomLeft.frame.width, y + bHeight - (bottomMiddleHeight));
					__setSize(bWidth - bottomLeft.frame.width - bottomRight.frame.width, bottomMiddleHeight);
					super.drawSuper();
				}

				// BOTTOM RIGHT
				frame = bottomRight;

				setPosition(
					x + bWidth - (bottomRightWidth),
					y + bHeight - (bottomRightHeight)
				);
				__setSize(
					bottomRightWidth,
					bottomRightHeight
				);
				super.drawSuper();

			}
			alpha = oldAlpha;
		}
		if (cameras[0] != null) cameras[0].pixelPerfectRender = lastPixelPerfect;

		setPosition(x, y);
		super.drawMembers();
	}

	private function __setSize(Width:Float, Height:Float) {
		var newScaleX:Float = Width / frameWidth;
		var newScaleY:Float = Height / frameHeight;
		scale.set(newScaleX, newScaleY);

		if (Width <= 0)
			scale.x = newScaleY;
		else if (Height <= 0)
			scale.y = newScaleX;

		updateHitbox();
	}
}