package funkin.options.type;

import flixel.util.FlxColor;

/**
 * Option type that has a new button, and is green.
**/
class NewOption extends TextOption {
	public var iconSpr:FlxSprite;

	public function new(name:String, desc:String, callback:Void->Void) {
		super(name, desc, callback);
		itemHeight = 160;

		__text.color = FlxColor.LIME;
		__text.x = 100;

		iconSpr = new FlxSprite().loadGraphic(Paths.image("editors/new"));
		iconSpr.setPosition(90 - iconSpr.width, (__text.height - iconSpr.height) / 2);
		iconSpr.scale.set(1.4, 1.4);
		iconSpr.updateHitbox();
		iconSpr.offset.set(15, -15);
		add(iconSpr);
	}
}