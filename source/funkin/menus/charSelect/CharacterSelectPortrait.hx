package funkin.menus.charSelect;

import flixel.util.FlxColor;

class CharacterSelectPortrait extends FunkinSprite
{
	public var portName:String = "none";

	public var slotNumber:Int = 0;

	public var pageSlots:Int = 0;

	public var selected:Bool = false;

	public final portBaseWidth:Int = 235;
	public final portBaseHeight:Int = 219;

	var cent:FlxPoint;

	public function new(portName:String, slotNumber:Int, pageSlots:Int, unselectedAnim:String, transitionsAnim:String, selectedAnim:String,
			transitionuAnim:String, pageCenter:FlxPoint)
	{
		super(0, 0);

		this.portName = portName;
		this.slotNumber = slotNumber;
		this.pageSlots = pageSlots;

		zoomFactor = 0;
		scrollFactor.set();

		frames = Paths.getSparrowAtlas("menus/charSelect/portraits/" + portName);

		animation.addByPrefix('unselected', unselectedAnim, 24, false);
		animation.addByPrefix('transitions', transitionsAnim, 24, false);
		animation.addByPrefix('selected', selectedAnim, 24, false);
		animation.addByPrefix('transitionu', transitionuAnim, 24, false);

		playAnim("unselected", true);
		color = FlxColor.GRAY;

		cent = pageCenter;

		scale.set(0.75, 0.75);
		updateHitbox();

		doPositioning(cent);

		antialiasing = Options.antialiasing;
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (animation.finished)
		{
			if (getAnimName() == "transitions")
			{
				animation.play("selected", true);
			}
			else if (getAnimName() == "transitionu")
			{
				animation.play("unselected", true);
			}
		}
	}

	public function select()
	{
		if (!selected)
		{
			selected = true;
			animation.play("transitions", true);
			color = FlxColor.WHITE;
		}
	}

	public function unselect()
	{
		if (selected)
		{
			selected = false;
			animation.play("transitionu", true);
			color = FlxColor.GRAY;
		}
	}

	public function doPositioning(center:FlxPoint)
	{
		var padding = 40;

		x = center.x - 110;
		y = center.y - 110;

		x += ((slotNumber % 3) - 1) * ((portBaseWidth * scale.x) + padding);

		y += (Math.floor(slotNumber / 3) - 1) * ((portBaseHeight * scale.y) + padding);

		if (pageSlots % 2 == 0)
		{
			x += ((portBaseWidth * scale.x) + padding) / 2;
			y += ((portBaseHeight * scale.y) + padding) / 2;
		}

		x -= (width) / 2;
		y -= (portBaseHeight * scale.y) / 2;
	}
}
