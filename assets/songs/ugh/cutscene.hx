import funkin.system.FunkinSprite;

var tankman:FunkinSprite;
var tankTalk1, tankTalk2, bfBeep, distorto:FlxSound;
var timers:Array<FlxTimer> = [];
var destroyDistorto:Bool = true;

function create() {
	FlxTween.tween(FlxG.camera, {zoom: 1}, 0.7, {ease: FlxEase.quadInOut});
	game.camHUD.visible = false;

	tankman = new FunkinSprite(game.dad.x + game.dad.globalOffset.x + 520, game.dad.y + game.dad.globalOffset.y + 225);
	tankman.antialiasing = true;
	tankman.loadSprite(Paths.image('game/cutscenes/tank/ugh-tankman'));
	tankman.animateAtlas.anim.addBySymbol('1', 'TANK TALK 1 P1', 0, false);
	tankman.animateAtlas.anim.addBySymbol('2', 'TANK TALK 1 P2', 0, false);

	game.insert(game.members.indexOf(game.dad), tankman);
	game.dad.visible = false;

	focusOn(game.dad);
	game.persistentUpdate = true;

	tankTalk1 = FlxG.sound.load(Paths.sound('cutscenes/tank/ugh-1'));
	tankTalk2 = FlxG.sound.load(Paths.sound('cutscenes/tank/ugh-2'));
	bfBeep = FlxG.sound.load(Paths.sound('cutscenes/tank/ugh-beep'));
	bfBeep.onComplete = function() {
		game.boyfriend.dance();
	};
	distorto = FlxG.sound.load(Paths.music('DISTORTO'));
	distorto.volume = 0;
	distorto.play();
	distorto.fadeIn(5, 0, 0.5);

	tankman.playAnim('1');
	tankTalk1.play();

	timer(3, function() {
		focusOn(game.boyfriend);

		timer(1.5, function() {
			game.boyfriend.playAnim("singUP");
			bfBeep.play();

			timer(1.5, function() {
				focusOn(game.dad);
				tankTalk2.play();
				tankman.playAnim('2');

				timer(6.1, function() {
					destroyDistorto = false;
					distorto.fadeOut((Conductor.crochet / 1000) * 5, 0);
					close();
				});
			});
		});
	});
}

function timer(duration:Float, callBack:Void->Void) {
	timers.push(new FlxTimer().start(duration, function(timer) {
		timers.remove(timer);
		callBack();
	}));
}

function focusOn(char) {
	var camPos = char.getCameraPosition();
	game.camFollow.setPosition(camPos.x, camPos.y);
	camPos.put();
}

function destroy() {
	game.remove(tankman);
	game.camHUD.visible = true;
	game.dad.visible = true;
	for(timer in timers) timer.cancel();
	for(thing in [tankTalk1, tankTalk2, bfBeep, tankman]) thing.destroy();
	if(destroyDistorto) distorto.destroy();
}