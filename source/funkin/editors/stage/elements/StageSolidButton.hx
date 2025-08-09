package funkin.editors.stage.elements;

import flixel.util.FlxColor;
import haxe.xml.Access;

class StageSolidButton extends StageSpriteButton {

	public function new(x:Float,y:Float, sprite:FunkinSprite, xml:Access) {
		super(x,y, sprite, xml);
		color = 0xFFD9FF50;
	}

	public override function onEdit() {
		// TODO: implement
	}
}