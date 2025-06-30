function create() {
	if (!Options.gameplayShaders) {
		disableScript();
		return;
	}
	vignette = new CustomShader('coloredVignette');
	vignette.color = [0, 0, 0];
	vignette.amount = 1;
	vignette.strength = 1 - (health / 2) / 1.5;
	camGame.addShader(vignette);
}

function update(elapsed:Float) {
	var bg = stage.stageSprites.get('bg');
	var targetStrength:Float = 1 - (health / 2) / 1.5;
	if (bg.animation.name == 'lightning' && !bg.animation.finished)
		vignette.strength = 0.075;
	else
		vignette.strength = lerp(vignette.strength, targetStrength, 0.1);
}

function onGameOver() {
	FlxTween.tween(vignette, {"strength": 0.075}, 1, {ease: FlxEase.quadOut});
}
