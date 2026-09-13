package funkin.editors.stage.elements;

import funkin.editors.stage.elements.StageSpriteButton;
import funkin.editors.stage.StageEditor;
import flixel.util.FlxColor;
import haxe.xml.Access;

class StageSolidButton extends StageSpriteButton {

	public function new(x:Float,y:Float, sprite:FunkinSprite, xml:Access) {
		super(x,y, sprite, xml);
		color = 0xFFD9FF50;
		hasAdvancedEdit = false;
	}

	public override function onEdit() {
		if(!FlxG.keys.pressed.SHIFT) {
			FlxG.state.openSubState(new StageSpriteEditScreen(this, "layouts/stage/solidEditScreen"));
		} else {
			FlxG.state.openSubState(new StageXMLEditScreen(this.xml, updateInfo, "Solid"));
		}
	}
}