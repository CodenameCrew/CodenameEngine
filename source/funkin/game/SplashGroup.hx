package funkin.game;

import haxe.xml.Access;

class SplashGroup extends FlxTypedGroup<Splash> {
	/**
	 * Whenever the splash group has successfully loaded or not.
	 */
	public var valid:Bool = true;

	/**
	 * XML data for the note splashes.
	 */
	public var xml:Access;

	/**
	 * Animation names sorted by strum IDs.
	 * Use `getSplashAnim` to get one.
	 */
	public var animationNames:Array<Array<String>> = [];

	/**
	 * Creates a new Splash group
	 * @param path Path to the splash data (xml)
	 */
	public function new(path:String) {
		super();

		try {
			xml = new Access(Xml.parse(Assets.getText(path)).firstElement());

			if (!xml.has.sprite) throw "The <splash> element requires a sprite attribute.";
			var splash = createSplash(xml.att.sprite);
			setupAnims(xml, splash);
			pregenerateSplashes(splash);
			add(splash);

			// immediatly draw once and put image in GPU to prevent freezes
			// TODO: change to graphics cache
			splash.drawComplex(FlxG.camera);
		} catch(e:Dynamic) {
			Logs.trace('Couldn\'t parse splash data for "${path}": ${e.toString()}', ERROR);
			valid = false;
		}
		maxSize = 8;
	}

	function createSplash(imagePath:String) {
		var splash = new Splash();
		splash.antialiasing = true;
		splash.active = splash.visible = false;
		splash.loadSprite(Paths.image(imagePath));
		if (xml.has.scale) splash.scale.scale(Std.parseFloat(xml.att.scale).getDefault(1));
		if (xml.has.alpha) splash.alpha = Std.parseFloat(xml.att.alpha).getDefault(1);
		if (xml.has.antialiasing) splash.antialiasing = xml.att.antialiasing == "true";
		return splash;
	}

	function setupAnims(xml:Access, splash:Splash) {
		for(strum in xml.nodes.strum) {
			var id:Null<Int> = Std.parseInt(strum.att.id);
			if (id != null) {
				animationNames[id] = [];
				for(anim in strum.nodes.anim) {
					if (!anim.has.name) continue;
					XMLUtil.addXMLAnimation(splash, anim, false);
					animationNames[id].push(anim.att.name);
				}
			}
		}

		// if (animationNames.length <= 0)
		//		animationNames.push([]);

		for(anim in xml.nodes.anim) {
			if (!anim.has.name) continue;
			XMLUtil.addXMLAnimation(splash, anim, false);
			for(a in animationNames) {
				if (a == null) continue;
				a.push(anim.att.name);
			}
		}
		splash.animation.finishCallback = function(name:String) {
			splash.active = splash.visible = false;
		};
	}

	function pregenerateSplashes(splash:Splash) {
		// make 7 additional splashes
		for(i in 0...7) {
			var spr = Splash.copyFrom(splash);
			spr.animation.finishCallback = function(name:String) {
				spr.active = spr.visible = false;
				spr.strum = null;
				spr.strumID = null;
			};
			add(spr);
		}
	}

	public function getSplashAnim(id:Int):String {
		if (animationNames.length <= 0) return null;
		id %= animationNames.length;
		if (animationNames[id] == null || animationNames[id].length <= 0) return null;
		return animationNames[id][FlxG.random.int(0, animationNames[id].length - 1)];
	}

	var __splash:Splash;
	public function showOnStrum(strum:Strum) {
		if (!valid) return null;
		__splash = recycle();

		__splash.strum = strum;
		__splash.strumID = strum.ID;

		__splash.cameras = strum.lastDrawCameras;
		__splash.setPosition(strum.x + ((strum.width - __splash.width) / 2), strum.y + ((strum.height - __splash.height) / 2));
		__splash.active = __splash.visible = true;
		__splash.playAnim(getSplashAnim(strum.ID), true);
		__splash.scrollFactor.set(strum.scrollFactor.x, strum.scrollFactor.y);

		return __splash;
	}
}