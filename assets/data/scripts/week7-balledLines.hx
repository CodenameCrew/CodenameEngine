var sound:FlxSound;

function create() {
	sound = FlxG.sound.load(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, !Options.naughtyness ? [1, 3, 8, 13, 17, 21] : null)));
	sound.onComplete = () -> FlxG.sound.music.fadeIn(4, 0.2, 1);
}

function postDeathStart() {
	sound.play();
	FlxG.sound.music.volume = 0.2;
}