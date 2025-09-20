import stage.tank.TankmenBG;

var tankmanGroup:TankmenGroup = {
	tankmanPool: [],
	tankmanRun: [],
	grpTankmanRun: new FlxTypedGroup<FlxSprite>()
}

var spawnTimes = []; // [[time, direction]]

function recycleTankman() {
	if(tankmanGroup.tankmanPool.length == 0) {
		return new TankmenBG(tankmanGroup);
	} else {
		return tankmanGroup.tankmanPool.shift(); // can be pop but it causes it to be less random
	}
}

function getTankman(data:Array<Float>) {
	var tankman:TankmenBG = recycleTankman();
	tankman.strumTime = data[0];
	tankman.resetShit(500, 200 + FlxG.random.int(50, 100), data[1] < 2);
	return tankman;
}

function postCreate() {
	//grpTankmanRun = new FlxTypedGroup();
	insert(members.indexOf(gf) - 1, tankmanGroup.grpTankmanRun);
	if(inCutscene) tankmanGroup.grpTankmanRun.visible = false;

	/*var tempTankman:TankmenBG = recycleTankman();
	tempTankman.strumTime = 10;
	tempTankman.resetShit(20, 600, true);
	tankmanRun.push(tempTankman);
	grpTankmanRun.add(tempTankman.sprite);*/
	graphicCache.cache(Paths.image('stages/tank/tankmanKilled1'));

	for (note in strumLines.members[2].notes.members) {
		if (FlxG.random.bool(16)) {
			spawnTimes.push([note.strumTime, note.noteData]);
		}
	}

	//spawnTimes.reverse(); // no need to reverse it since the notes are already reversed
}

function onStartCountdown() {
	if(PlayState.instance.seenCutscene) tankmanGroup.grpTankmanRun.visible = true;
}

function spawnTankmen() {
	var time = Conductor.songPosition;
	//trace(spawnTimes);
	while(spawnTimes.length > 0 && spawnTimes[spawnTimes.length-1][0] - 1500 < time) {
		var tankmen = getTankman(spawnTimes.pop());

		//trace("Spawning Tankman", tankmen.sprite.offset, tankmen.goingRight);

		tankmanGroup.tankmanRun.push(tankmen);
		tankmanGroup.grpTankmanRun.add(tankmen.sprite);
	}
}

function update(elapsed) {
	spawnTankmen();

	var length = tankmanGroup.tankmanRun.length;
	for(i in 0...length) {
		var reverseIndex = length - i - 1;
		var tankmen = tankmanGroup.tankmanRun[reverseIndex];
		tankmen.update(elapsed);
	}
}
