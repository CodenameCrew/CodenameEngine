function create() {
	importScript("data/scripts/pixel");
	pixelNotesForBF = false;
	enablePixelUI = true;
	enableCameraHacks = false;
	playCutscenes = true;
}

function postCreate() {
	if(stage.stageName != 'tank') return;
	for(i in 0...6) {
		var spr = stage.getSprite("tank" + i);
		if (spr != null) spr.visible = false;
	}
}

function postUpdate(elapsed) {
	for(s in strumLines) {
		for(i in 0...4) {
			var n = s.members[i];
			if (n == null) continue;
			n.angle = Math.sin(curBeatFloat + (i * 0.45)) * 35;
		}
	}


	// for(s in strumLines) {
	// 	for(i in 0...4) {
	// 		var n = s.members[i];
	// 		n.y = FlxG.height - 200;
	// 		n.angle = 180;
	// 	}
	// }

	// if (curSection != null)
	//     defaultCamZoom = curSection.mustHitSection ? 0.9 : 0.5;
}
