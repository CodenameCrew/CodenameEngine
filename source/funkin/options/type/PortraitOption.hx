package funkin.options.type;

import flixel.graphics.FlxGraphic;
import funkin.backend.shaders.CustomShader;

/**
 * Option type that has a portrait.
 * Used in the credits menu.
**/
class PortraitOption extends TextOption {
	public var portrait:FlxSprite = null;

	public function new(name:String, desc:String, callback:Void->Void, ?graphic:FlxGraphic, size:Int = 96, usePortrait:Bool = true) {
		super(name, desc, callback);
		__text.x = 100;

		if (graphic != null) addPortrait(graphic, size, usePortrait);
	}

	public function addPortrait(graphic:FlxGraphic, size:Int = 96, usePortrait:Bool = true) {
		if (portrait == null) {
			portrait = new FlxSprite();
			portrait.antialiasing = true;
			if(usePortrait) portrait.shader = new CustomShader('engine/circleProfilePicture');
			add(portrait);
		}
		portrait.loadGraphic(graphic);
		portrait.setUnstretchedGraphicSize(size, size, false);
		portrait.updateHitbox();
		portrait.setPosition(90 - portrait.width, 0);
	}
}