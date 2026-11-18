function create() {
	game.camHUD.fade(0xFF000000, 0);

	var sound = FlxG.sound.load(Paths.sound('Lights_Shut_off'));
	sound.onComplete = function() {
		close();
	};
	sound.play();
}