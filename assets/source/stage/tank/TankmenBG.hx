package stage.tank;

import funkin.backend.assets.Paths;
import funkin.backend.system.Conductor;

import flixel.FlxSprite;
import flixel.FlxG;

class TankmenBG {
	var strumTime = 0;
	var goingRight = false;
	var tankSpeed = 0.7;

	var endingOffset:Float;
	var sprite:FlxSprite;

	var killed = false;

	var grp:TankmenGroup; // A reference to the group

	function new(grp:TankmenGroup) {
		this.grp = grp;

		sprite = new FlxSprite();

		sprite.frames = Paths.getSparrowAtlas('stages/tank/tankmanKilled1');
		sprite.antialiasing = true;
		sprite.animation.addByPrefix('run', 'tankman running', 24, true);

		sprite.animation.play('run');

		sprite.updateHitbox();

		sprite.setGraphicSize(Std.int(sprite.width * 0.8));
		sprite.updateHitbox();
	}

	function resetShit(x:Float, y:Float, isGoingRight:Bool) {
		sprite.revive();
		sprite.setPosition(x, y);
		sprite.offset.set(0, 0);
		goingRight = isGoingRight;
		endingOffset = FlxG.random.float(50, 200);
		tankSpeed = FlxG.random.float(0.6, 1);
		sprite.animation.remove("shot");
		sprite.animation.addByPrefix('shot', 'John Shot ' + FlxG.random.int(1, 2), 24, false);
		sprite.animation.play("run");
		sprite.animation.curAnim.curFrame = FlxG.random.int(0, sprite.animation.curAnim.numFrames - 1);

		killed = false;
		sprite.flipX = goingRight;
	}

	function update(elapsed:Float) {
		sprite.visible = !(sprite.x >= FlxG.width * 1.5 || sprite.x <= FlxG.width * -0.5);

		if (sprite.animation.curAnim.name == 'run')
		{
			var endDirection:Float = (FlxG.width * 0.74) + endingOffset;

			if (goingRight) {
				endDirection = (FlxG.width * 0.02) - endingOffset;
				sprite.x = (endDirection + (Conductor.songPosition - strumTime) * tankSpeed);
			}
			else sprite.x = (endDirection - (Conductor.songPosition - strumTime) * tankSpeed);
		}

		if (Conductor.songPosition > strumTime)
		{
			sprite.animation.play('shot');
			sprite.animation.finishCallback = function(_) {
				killed = true;
				grp.grpTankmanRun.remove(sprite, true);
				sprite.kill();
				grp.tankmanPool.push(this);
				grp.tankmanRun.remove(this);
			}

			if (goingRight)
			{
				sprite.offset.y = 200;
				sprite.offset.x = 300;
			}
		}
	}
}