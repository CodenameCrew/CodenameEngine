var self = this;
__script__.setParent(PlayState.instance);

function create() {
	var red:FlxSprite;
	red = new FlxSprite().makeSolid(FlxG.width + 100, FlxG.height + 100, 0xFFff1b31);
	red.screenCenter();
	red.scrollFactor.set();
	red.alpha = 0;
	add(red);

	// reorder dad
	remove(dad);
	insert(PlayState.instance.members.indexOf(red) + 1, dad);

	playDadUpdate = true;
	dad.animation.finishCallback = (name:String) -> {
		if(name == "idle") {
			dad.animation.finishCallback = null;
			playDadUpdate = false;

			new FlxTimer().start(0.3, function(swagTimer:FlxTimer) {
				red.alpha += 0.15;
				camHUD.alpha -= 0.15;
				var c = FlxMath.lerp(255, 0, red.alpha);
				dad.color = FlxColor.fromRGB(c, c, c, 255);
				if(red.alpha < 1) swagTimer.reset();
				else {
					if (Options.gameplayShaders) {
						aberration = new CustomShader('chromaticAberration');
						camGame.addShader(aberration);
						change = true;
					}

					FlxG.camera.followLerp = 0;
					FlxTween.tween(camGame.scroll, {x: -366, y: 192}, 3, {
						ease: FlxEase.cubeInOut,
						onComplete: (_) -> {self.close();}
					});
				}
			});
		}
	}
	if(dad.animation.curAnim.name != "idle")
		dad.playAnim("idle", true);
	else if(dad.animation.curAnim.finished)
		dad.animation.finishCallback("idle");
}

var playDadUpdate = false;
function postUpdate(elapsed) {
	if(playDadUpdate)
		dad.update(elapsed);
}

var change:Bool = false;
var aberration:CustomShader = null;
function update(elapsed:Float) {
	if(change && intens < (Options.week6PixelPerfect ? 0.005 : 0.005)) setGeneralIntensity(intens + 0.00001);
}

var intens:Float = 0;
function setGeneralIntensity(val:Float) {
	intens = val;
	aberration.redOff = [intens, 0];
	aberration.blueOff = [-intens, 0];
}