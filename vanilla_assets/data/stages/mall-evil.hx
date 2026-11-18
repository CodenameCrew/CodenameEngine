var idk:CustomShader = null;
function create() {
	if(!Options.gameplayShaders) {
		disableScript();
		return;
	}

	idk = new CustomShader('coloredVignette');
	idk.color = [1, 0, 0];
	camGame.addShader(idk);
}

var adder:Int = 0;
function postUpdate(elapsed:Float) {  // Doing it like this so at least the red bump doesn't look too much instant
	var toAdd:Int = lerp(adder, 0, elapsed);
	idk.amount = camGame.zoom * camHUD.zoom + toAdd;
	idk.strength = (camGame.zoom - camHUD.zoom + toAdd) * 5;
	if(adder > 0) adder -= 0.0001 * camZoomingStrength;
}

function beatHit() {
	if(Options.camZoomOnBeat && camZooming && FlxG.camera.zoom < maxCamZoom && curBeat % camZoomingInterval == 0)
		adder = 0.05 * camZoomingStrength;
}