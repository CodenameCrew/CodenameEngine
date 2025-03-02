package funkin.game;


class SplashHandler extends FlxTypedGroup<Splash> {
	/**
	 * Map containing all of the splashes group.
	 */
	public var grpMap:Map<String, SplashGroup> = [];

	public function new() {
		super();
	}

	/**
	 * Returns a group of splashes, and creates it if it doesn't exist.
	 * @param path Path to the splashes XML (`Paths.xml('splashes/splash')`)
	 */
	public function getSplashGroup(name:String) {
		if (!grpMap.exists(name)) {
			var grp = new SplashGroup(Paths.xml('splashes/$name'));
			grpMap.set(name, grp);
		}
		return grpMap.get(name);
	}

	public override function destroy() {
		super.destroy();
		for(grp in grpMap)
			grp.destroy();
		grpMap = null;
	}

	var _firstDraw:Bool = true;
	public override function draw() {
		super.draw();
		if (_firstDraw != (_firstDraw = false))
			for(grp in grpMap)
				grp.draw();
	}

	var __grp:SplashGroup;
	public function showSplash(name:String, strum:Strum) {
		__grp = getSplashGroup(name);
		add(__grp.showOnStrum(strum));

		// max 8 rendered splashes
		while(members.length > 8)
			remove(members[0], true);
	}
}