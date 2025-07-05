var fastCarCanDrive:Bool = true;

function create()
	resetFastCar();

function update(elapsed:Float)
{
	if (!fastCarCanDrive && fastCar.x > 2000) {
		resetFastCar();
		fastCarCanDrive = true;
	}

	var offset = Math.sin(curBeatFloat / 4) * Math.cos(curBeatFloat / 16) * 85;

	// back limo drive
	if (Options.lowMemoryMode) {
		bgLimo.frameOffset.x = offset;
	} else {
		for(e in [bgLimo, dancer1, dancer2, dancer3, dancer4, dancer5]) {
			e.frameOffset.x = offset;
		}
	}
}
function beatHit(curBeat:Int)
	if (FlxG.random.bool(10) && fastCarCanDrive)
		fastCarDrive();

function resetFastCar()
{
	fastCar.x = -12600;
	fastCar.y = FlxG.random.int(140, 250);
	fastCar.velocity.x = 0;
	fastCar.moves = false;
	fastCarCanDrive = true;
}
function fastCarDrive()
{
	FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

	fastCar.velocity.x = FlxG.random.int(170, 220) * 60 * 3;
	fastCar.moves = true;
	fastCarCanDrive = false;
}