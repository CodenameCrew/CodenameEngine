var dir = 2;

function onDance(event) {
	event.cancel();

	playAnim("idle" + Std.string(dir), true, "DANCE");
}

function onPlaySingAnim(event) {
	dir = FlxG.random.int(0, 1) + (event.direction == 0 ? 3 : 1);
	event.cancel();

	playAnim("shoot" + Std.string(dir), true);
}

function update(elapsed) {
	var animName = getAnimName();
	if (animName == null || (animName.substr(0, 5) == "shoot" && isAnimFinished()))
		dance();
}