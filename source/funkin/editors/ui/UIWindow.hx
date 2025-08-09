package funkin.editors.ui;

class UIWindow extends UISliceSprite {
	public var titleSpr:UIText;
	public var collapsable:Bool = false;
	public var content:FlxTypedGroup<FlxBasic>;

	public override function new(x:Float, y:Float, w:Int, h:Int, ?title:String) {
		super(x, y, w, h,  "editors/ui/normal-popup");

		if(title != null && title.length != 0) {
			members.push(titleSpr = new UIText(x + 25, y, bWidth - 50, title, 15, -1));
			titleSpr.y = y + ((30 - titleSpr.height) / 2);
		}

		content = new FlxTypedGroup<FlxBasic>();
		members.push(content);
		FlxG.sound.play(Paths.sound(Flags.DEFAULT_EDITOR_WINDOWAPPEAR_SOUND));
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		cursor = ARROW;

		if(collapsable) {
			__rect.set(x, y, bWidth, topHeight);

			if(UIState.state.isOverlapping(this, __rect)) {
				cursor = CLICK;
				if(FlxG.mouse.justPressed) {
					content.exists = !content.exists;
					drawMiddle = !drawMiddle;
					drawBottom = !drawBottom;
				}
			} else {
				if(!content.exists) {
					cursor = null;
				}
			}
		}

		__rect.x = x;
		__rect.width = bWidth;
		if(content.exists) {
			__rect.y = y+topHeight;
			__rect.height = bHeight-topHeight;
		}
		hovered = content.exists && UIState.state.isOverlapping(this, __rect);
	}
}
