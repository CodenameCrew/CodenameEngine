package funkin.editors.ui;

import flixel.math.FlxPoint;

class UIScrollBar extends UISprite {
	public var length:Float;
	public var start:Float;
	public var size:Float;

	public var thumb:UISliceSprite;
	public var thumbIcon:FlxSprite;

	public var value:Float;

	public var onChange:Float->Void;

	public function new(x:Float, y:Float, length:Float, start:Float, size:Float, w:Int = 20, ?h:Int) {
		super(x, y, Paths.image("editors/ui/scrollbar-bg"));
		scale.y = h.getDefault(Std.int(FlxG.height - y));
		alpha = 0.5;
		updateHitbox();
		this.start = start;
		this.size = size;
		this.length = length;

		thumb = new UISliceSprite(0, 0, w, h, 'editors/ui/scrollbar');
		thumb.cursor = CLICK;
		members.push(thumb);

		thumbIcon = new FlxSprite(0, 0, Paths.image('editors/ui/scrollbar-icon'));
		members.push(thumbIcon);
	}

	public var isScrolling:Bool = false;

	public override function update(elapsed:Float) {
		var lastHovered = hovered;
		var lastHoveredThumb = thumb.hovered;
		super.update(elapsed);
		thumb.follow(this, 0, FlxMath.remapToRange(start, -(size/2), length + size, 0, height));
		thumb.bHeight = Std.int(FlxMath.remapToRange(size, -(size/2), length + size, 0, height));

		thumbIcon.follow(thumb, 0, Std.int((thumb.bHeight - thumbIcon.height) / 2));
		thumbIcon.alpha = thumb.bHeight > 30 ? 1 : 0;

		if ((lastHovered || lastHoveredThumb) && FlxG.mouse.justPressed) isScrolling = true;

		if (isScrolling) {
			thumb.framesOffset = 18;
			var mousePos = FlxG.mouse.getScreenPosition(__lastDrawCameras[0], FlxPoint.get());
			var yPos = CoolUtil.bound(FlxMath.remapToRange(mousePos.y, y, y+height, -(size/2), length + size), 0, length);
			if (yPos >= 0 && yPos < length) {
				value = yPos;
				if (onChange != null)
					onChange(value);
			}
			mousePos.put();
		} 
		if (FlxG.mouse.justReleased && isScrolling) {
			isScrolling = false;
			thumb.framesOffset = lastHoveredThumb ? 9 : 0;
		}
	}
}