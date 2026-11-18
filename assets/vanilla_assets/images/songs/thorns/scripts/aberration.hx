var aberration:CustomShader = null;
function create() {
	if(!Options.gameplayShaders) return;
	aberration = new CustomShader('chromaticAberration');
	setGeneralIntensity(Options.week6PixelPerfect ? 0.0005 : 0.005);
	camGame.addShader(aberration);
}

var intens:Float = 0;
function setGeneralIntensity(val:Float) {
	intens = val;
	aberration.redOff = [intens, 0];
	aberration.blueOff = [-intens, 0];
}

var canBump:Bool = false;
function aberrationCoolThing() {
	canBump = !canBump;
	if(!canBump) {
		if(Options.gameplayShaders) setGeneralIntensity(Options.week6PixelPerfect ? 0.0005 : 0.005);  // Just to make sure if anything goes wrong
		maxCamZoom = 1.35;
	} else maxCamZoom = 0;
}

function update(elapsed:Float) {
	if(Options.gameplayShaders && canBump && intens > (Options.week6PixelPerfect ? 0.0005 : 0.005)) setGeneralIntensity(intens - (Options.week6PixelPerfect ? 0.0001 : 0.001));
}

function beatHit(curBeat:Float) {
	if(canBump && curBeat % 2 != 0) {
		if(Options.gameplayShaders) setGeneralIntensity(Options.week6PixelPerfect ? 0.005 : 0.05);
		if(Options.camZoomOnBeat) {
			FlxG.camera.zoom += 0.015 * camZoomingStrength;
			camHUD.zoom += 0.03 * camZoomingStrength;
		}
	}
}