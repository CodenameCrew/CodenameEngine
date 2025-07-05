import lime.app.Application;
import funkin.system.FunkinSprite;
import funkin.options.Options;

var tankman, pico:FunkinSprite;
var bf, gf:Character;
var stressCutscene:FlxSound;
var step:Int = 0;

function create() {
	// FlxTween.tween(FlxG.camera, {zoom: 1}, 0.7, {ease: FlxEase.quadInOut});
	game.camHUD.visible = false;
	game.persistentUpdate = true;

	game.gf.visible = false;
	gf = new Character(game.gf.x + game.gf.globalOffset.x - 115, game.gf.y + game.gf.globalOffset.y + 85, "gf-tankmen");
	gf.scrollFactor.set(0.95, 0.95);
	gf.playAnim("dance-cutscene");
	game.insert(game.members.indexOf(game.gf) + 1, gf);

	game.boyfriend.visible = false;
	bf = new Character(game.boyfriend.x + game.boyfriend.globalOffset.x, game.boyfriend.y + game.boyfriend.globalOffset.y - 350, "boyfriend", true);
	bf.scrollFactor.set(0.95, 0.95);
	game.insert(game.members.indexOf(game.boyfriend) + 1, bf);

	stressCutscene = FlxG.sound.load(Paths.sound(Options.naughtyness ? 'cutscenes/tank/stress' : 'cutscenes/tank/stress-censor'));

	stressCutscene.play();
	stressCutscene.onComplete = function() {
		for(spr in [gf, tankman, pico]) {
			spr.destroy();
			game.remove(spr);
		}
		game.camHUD.visible = game.dad.visible = game.gf.visible = true;
		close();
	};

	tankman = new FunkinSprite(game.dad.x + game.dad.globalOffset.x + 520, game.dad.y + game.dad.globalOffset.y + 225);
	tankman.antialiasing = true;
	tankman.loadSprite(Paths.image('game/cutscenes/tank/stress-tankman'));
	tankman.animateAtlas.anim.addBySymbol('p1', 'TANK TALK 3 P1 UNCUT', 0, false);
	tankman.animateAtlas.anim.addBySymbol('p2', 'TANK TALK 3 P2 UNCUT', 0, false);
	tankman.playAnim('p1');

	pico = new FunkinSprite(game.gf.x + game.gf.globalOffset.x + 150, game.gf.y + game.gf.globalOffset.y + 395);
	pico.antialiasing = true;
	pico.loadSprite(Paths.image('game/cutscenes/tank/stress-pico'));
	pico.animateAtlas.anim.addBySymbol('die', 'GF Time to Die sequence', 24, false);
	pico.animateAtlas.anim.addBySymbol('saves', 'Pico Saves them sequence', 24, false);
	pico.animateAtlas.anim.addBySymbol('idle', 'Pico Dual Wield on Speaker idle', 24, true);
	pico.scrollFactor.set(0.95, 0.95);
	pico.playAnim("idle");
	pico.visible = false;
	game.insert(game.members.indexOf(game.gf) + 1, pico);

	game.insert(game.members.indexOf(game.dad) + 1, tankman);
	game.dad.visible = false;
	focusOn(game.dad);
}

function update(elapsed) {
	switch(step) {
		case 0:
			lipSync(tankman, 0, 16750);
			if (stressCutscene.time > 15100) {
				step = 1;
				focusOn(game.gf);
				pico.visible = true;
				pico.playAnim('die', true);

				// removes old gf to free ram
				game.remove(gf);
				gf.destroy();

				FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom * 1.3}, 2.1, {ease: FlxEase.quadInOut});
			}
		case 1:
			lipSync(tankman, 0, 16750);
			if (stressCutscene.time > 17300) {
				FlxG.camera.zoom = 0.8;
				step = 2;
				pico.playAnim('saves', true);
				game.remove(bf);
				bf.destroy();
				game.boyfriend.visible = true;
				game.boyfriend.playAnim('bfCatch');
				game.boyfriend.animation.finishCallback = function(anim:String) {
					game.boyfriend.dance();
					game.boyfriend.animation.finishCallback = null;
				};
			}
		case 2:
			if (stressCutscene.time > 19600) {
				tankman.playAnim('p2', true);
				step = 3;
			}
		case 3:
			lipSync(tankman, 19500, stressCutscene.length);
			if (stressCutscene.time > 20300) {
				game.camFollow.y += 180;
				game.camFollow.x -= 80;
				step = 4;
			}
		case 4:
			lipSync(tankman, 19500, stressCutscene.length);
			pico.animation.finishCallback = pico.playAnim("idle");

			if(stressCutscene.time > 31500) {
				focusOn(game.boyfriend, true);
				FlxG.camera.zoom = game.defaultCamZoom * 1.4;
				FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.1}, 0.5, {ease: FlxEase.elasticOut});
				game.boyfriend.playAnim('singUPmiss');
				game.boyfriend.animation.finishCallback = function(anim:String)
				{
					FlxG.camera.zoom /= 1.4;
					focusOn(game.dad, true);
					game.boyfriend.dance();
					game.boyfriend.animation.finishCallback = null;
				};
				step = 5;
			}
	}
}

function lipSync(char:FunkinSprite, begin:Float, end:Float) {
	char.animateAtlas.anim.curFrame = Std.int(FlxMath.remapToRange(stressCutscene.time, begin, end, 0, char.animateAtlas.anim.length-1));
}

function focusOn(char, snap:Bool = false) {
	var camPos = char.getCameraPosition();
	game.camFollow.setPosition(camPos.x, camPos.y);
	if(snap) FlxG.camera.snapToTarget();
	camPos.put();
}