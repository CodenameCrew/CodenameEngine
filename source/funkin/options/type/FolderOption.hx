package funkin.options.type;

import flixel.util.FlxColor;

/**
 * Option type that has a folder button, and is yellow.
 * - its kinda useless but if NewOption exists then so can this
**/
class FolderOption extends TextOption {
	public var iconSpr:FlxSprite;

	public function new(name:String, desc:String, callback:Void->Void) {
		super(name, desc, callback);

		__text.color = editorFlashColor = 0xFFFFAA44;
		__text.x = 100;

		iconSpr = new FlxSprite().loadGraphic(Paths.image("editors/folder"));
		iconSpr.setPosition(90 - iconSpr.width, (__text.height - iconSpr.height) / 2);
		iconSpr.scale.set(1.4, 1.4);
		iconSpr.updateHitbox();
		iconSpr.offset.set(15, -15);
		add(iconSpr);
	}
}