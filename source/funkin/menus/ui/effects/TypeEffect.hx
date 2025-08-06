package funkin.menus.ui.effects;

import flixel.tweens.FlxEase;
import funkin.menus.ui.effects.RegionEffect;

class TypeEffect extends RegionEffect {
	public var interval:Float = 0.075;
	var lastIndex:Int = -1;
	// These let you make the text do a cool fade in when it appears.
	public var alphaStart:Float = 1;
	public var alphaEase:EaseFunction = FlxEase.quadOut;
	// More stuff for fade in, this adds a y offset.
	public var offsetStart:Float = 0.0;
	public var offsetEase:EaseFunction = FlxEase.quadOut;
	// Funny noises. You just kinda `effect.addSound(PATH)` and boom.
	public var sounds:Array<flixel.sound.FlxSound> = [];
	public var randomSound:Bool = true; // do them in order or play a random one.
	var curSound:Int = -1;

	override function modify(index:Int, lineIndex:Int, renderData:AlphabetRenderData):Void {
		if (effectTime < interval * index) {
			renderData.alpha = 0.0;
			return;
		}

		if (index > lastIndex && sounds.length > 0) {
			lastIndex = index;
			curSound = (randomSound) ? FlxG.random.int(0, sounds.length - 1) : (curSound + 1) % sounds.length;
			sounds[curSound].time = 0;
			sounds[curSound].play();
		}

		var scale = Math.min((effectTime - interval * index) / interval, 1.0);
		renderData.alpha *= FlxMath.lerp(alphaStart, 1.0, alphaEase(scale));
		renderData.offsetY += offsetStart * (1.0 - offsetEase(scale));
	}

	public function addSound(path:String) {
		sounds.push(FlxG.sound.load(Paths.sound(path)));
	}

	public function clearSounds() {
		sounds.splice(0, sounds.length);
	}

	public function resetTimer() {
		// mainly for sound playing.
		effectTime = 0;
		lastIndex = -1;
		curSound = -1;
	}
}