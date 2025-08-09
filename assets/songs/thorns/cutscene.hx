//
import flixel.addons.util.FlxSimplex;

var self = this;
__script__.setParent(PlayState.instance);

var scream:FlxSound;
var red:FlxSprite;
var senpaiEvil:FlxSprite;
var timers:Array<FlxTimers> = [];
var dfx = 0;
var dfy = 0;

function create() {
	camHUD.visible = false;

	red = new FlxSprite().makeSolid(FlxG.width + 100, FlxG.height + 100, 0xFFff1b31);
	red.screenCenter();
	red.scrollFactor.set();
	add(red);

	senpaiEvil = new FlxSprite();
	senpaiEvil.frames = Paths.getSparrowAtlas('game/cutscenes/weeb/senpaiCrazy');
	senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
	senpaiEvil.animation.play('idle');
	senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * daPixelZoom));
	senpaiEvil.scrollFactor.set();
	senpaiEvil.updateHitbox();
	senpaiEvil.screenCenter();
	senpaiEvil.x += daPixelZoom * 51;
	dfx = senpaiEvil.x;
	dfy = senpaiEvil.y;
	add(senpaiEvil);

	timers.push(new FlxTimer().start(3.2, function(deadTime:FlxTimer)
	{
		FlxG.camera.fade(FlxColor.WHITE, 1.6, false, function() {
			remove(senpaiEvil, true);
			senpaiEvil.destroy();
			remove(red, true);
			red.destroy();

			FlxG.camera._fxFadeAlpha = 1;
		});
		timers.remove(deadTime);
	}));
	scream = FlxG.sound.play(Paths.sound('cutscenes/weeb/Senpai_Dies'), 1, false, null, true, function()
	{
		timers.push(new FlxTimer().start(0.4, function(swagTimer:FlxTimer) {
			FlxG.camera._fxFadeAlpha -= 0.15;

			if (FlxG.camera._fxFadeAlpha > 0.3) swagTimer.reset();
			else {
				timers.remove(swagTimer);
				camHUD.visible = true;
				self.startDialogue("assets/songs/" + PlayState.instance.SONG.meta.name.toLowerCase() + "/creepyDialogue.xml", self.close);
			}
		}));
	});
}

var sVal = 0;
var seed = FlxG.random.float(-4000, 4000);
var sShkv = 50; // shake range
var sSpeed = 240;

function update(elapsed:Float) {
	if(scream?.time > 2350) {
		sVal += sSpeed * elapsed;

		var vx = sShkv * FlxSimplex.simplexOctaves(sVal, seed, 0.07, 0.25, 4);
		var vy = sShkv * FlxSimplex.simplexOctaves(sVal + 500, seed, 0.07, 0.25, 4);

		senpaiEvil.setPosition(dfx + vx, dfy + vy);
	}
}

function destroy() {  // Since you can skip the cutscene  - Nex
	for (timer in timers) timer.cancel();
	senpaiEvil?.destroy();
	red?.destroy();
	FlxG.camera.stopFade();
	scream?.destroy();
	camHUD.visible = true;
}