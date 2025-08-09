public var lightningStrike:Bool = true;
public var lightningStrikeBeat:Int = 0;
public var lightningOffset:Int = 8;
public var thunderSFXamount:Int = 2;

function create() {
	for(i in 1...thunderSFXamount+1)
		FlxG.sound.load(Paths.sound('thunder_' + Std.string(i)));
	bg.playAnim('idle');
}
public function lightningStrikeShit():Void
{
	FlxG.sound.play(Paths.soundRandom('thunder_', 1, thunderSFXamount));
	bg.playAnim('lightning');

	lightningStrikeBeat = curBeat;
	lightningOffset = FlxG.random.int(8, 24);

	boyfriend.playAnim('scared', true, "SING"); // SING so that they don't get indefinitely looped
	gf.playAnim('scared', true, "SING");
}

function beatHit(curBeat) {
	if (lightningStrike && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
	{
		lightningStrikeShit();
	}
}