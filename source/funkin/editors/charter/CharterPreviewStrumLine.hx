package funkin.editors.charter;

import funkin.game.Note;

class CharterPreviewStrumLine extends FlxTypedGroup<FlxSprite>
{
	public function new(x:Float, y:Float, scale:Float, spacing:Float, keyCount:Int, scrollSpeed:Float){
		super();
		updatePos(x, y, scale, spacing, keyCount, scrollSpeed);
	}

	private var note:FlxSprite;

	public function generateStrums(x:Float, y:Float, scale:Float, spacing:Float, keyCount:Int, scrollSpeed:Float){
		for (member in members){
			member.destroy();
		}
		clear();
			
		var strumAnimPrefix = ["left", "down", "up", "right"];
		for (i in 0...keyCount){
			var strum = new FlxSprite();
			strum.frames = Paths.getFrames("game/notes/default");
			strum.setGraphicSize(Std.int((strum.width * 0.7) * scale));
			strum.updateHitbox();

			var animPrefix = strumAnimPrefix[i % 4];
			strum.animation.addByPrefix('static', 'arrow${animPrefix.toUpperCase()}');
			strum.animation.play('static');
			strum.alpha = 0.4;
			add(strum);
		}

		note = new FlxSprite();
		note.frames = Paths.getFrames("game/notes/default");
		note.setGraphicSize(Std.int((note.width * 0.7) * scale));
		note.updateHitbox();
		note.animation.addByPrefix('purple', 'purple0');
		note.animation.play('purple');
		note.alpha = 0.4;
		add(note);
	}

	var noteTime:Float = FlxG.height;
	var scroll:Float = 1.0;

	public function updatePos(x:Float, y:Float, scale:Float, spacing:Float, keyCount:Int, scrollSpeed:Float){
		if (members.length-1 != keyCount) //strumline + note
			generateStrums(x, y, scale, spacing, keyCount, scrollSpeed);

		for (i in 0...keyCount){
			var strum = members[i];

			strum.x = CoolUtil.fpsLerp(strum.x, x + (Note.swagWidth * scale * spacing * i), 0.2);
			strum.y = CoolUtil.fpsLerp(strum.y, y + (Note.swagWidth*0.5) - (Note.swagWidth * scale * 0.5), 0.2);
			strum.scale.x = strum.scale.y = CoolUtil.fpsLerp(strum.scale.x, 0.7 * scale, 0.2);
			strum.updateHitbox();
		}


		scroll = CoolUtil.fpsLerp(scroll, scrollSpeed, 0.2);
		noteTime -= FlxG.elapsed * scroll * 1000 * 0.45;
		if (noteTime <= 0.0)
			noteTime = FlxG.height;

		note.x = members[0].x;
		note.y = members[0].y + noteTime;
		note.scale.x = note.scale.y = members[0].scale.x;
		note.updateHitbox();
		note.alpha = CoolUtil.fpsLerp(note.alpha, scrollSpeed == 0.0 ? 0.0 : 0.4, 0.2);
	}
}