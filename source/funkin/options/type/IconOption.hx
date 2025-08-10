package funkin.options.type;

import funkin.game.HealthIcon;

/**
 * Option type that has an icon.
 * Used for the credits menu.
**/
class IconOption extends TextOption {
	public var iconSpr:HealthIcon;

	public function new(name:String, desc:String, icon:String, callback:Void->Void) {
		super(name, desc, callback);

		__text.x = 100;

		iconSpr = new HealthIcon(icon, false);
		iconSpr.setPosition(90 - iconSpr.width, (__text.height - iconSpr.height) / 2);
		iconSpr.sprTracker = __text;
		iconSpr.sprTrackerAlignment = LEFT;
		if (Math.max(iconSpr.width, iconSpr.height) > 150) iconSpr.setUnstretchedGraphicSize(150, 150);
		add(iconSpr);
	}
}