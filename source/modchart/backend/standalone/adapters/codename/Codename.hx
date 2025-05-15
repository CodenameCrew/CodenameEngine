package modchart.backend.standalone.adapters.codename;

import flixel.FlxCamera;
import flixel.FlxSprite;
import funkin.backend.system.Conductor;
import funkin.game.Note;
import funkin.game.PlayState;
import funkin.game.Strum;
import funkin.options.Options;
import modchart.backend.standalone.IAdapter;

class Codename implements IAdapter {
	private var beatCrochet:Float = 0;

	public function onModchartingInitialization() {
		beatCrochet = Conductor.crochet;
	}

	public function isTapNote(sprite:FlxSprite) {
		return sprite is Note;
	}

	// Song related
	public function getSongPosition():Float {
		return Conductor.songPosition;
	}

	public function getCurrentBeat():Float {
		return Conductor.curBeatFloat;
	}

	public function getStaticCrochet():Float {
		return beatCrochet;
	}

	public function getBeatFromStep(step:Float):Float {
		return step * Conductor.stepsPerBeat;
	}

	public function arrowHit(arrow:FlxSprite) {
		if (arrow is Note) {
			final note:Note = cast arrow;
			return note.wasGoodHit;
		}
		return false;
	}

	public function isHoldEnd(arrow:FlxSprite) {
		if (arrow is Note) {
			final note:Note = cast arrow;
			return note.nextSustain == null;
		}
		return false;
	}

	public function getLaneFromArrow(arrow:FlxSprite) {
		if (arrow is Note) {
			final note:Note = cast arrow;
			return note.strumID;
		} else if (arrow is Strum) {
			final strum:Strum = cast arrow;
			return strum.ID;
		}
		return 0;
	}

	public function getPlayerFromArrow(arrow:FlxSprite) {
		if (arrow is Note) {
			final note:Note = cast arrow;
			return note.strumLine.ID;
		} else if (arrow is Strum) {
			final strum:Strum = cast arrow;
			return strum.strumLine.ID;
		}

		return 0;
	}

	public function getHoldParentTime(arrow:FlxSprite) {
		final note:Note = cast arrow;
		return note.sustainParent.strumTime;
	}

	// im so fucking sorry for those conditionals
	public function getKeyCount(?player:Int = 0):Int {
		return PlayState.instance != null
			&& PlayState.instance.strumLines != null
			&& PlayState.instance.strumLines.members != null
			&& PlayState.instance.strumLines.members[player] != null
			&& PlayState.instance.strumLines.members[player].members != null ? PlayState.instance.strumLines.members[player].members.length : 4;
	}

	public function getPlayerCount():Int {
		return PlayState.instance != null && PlayState.instance.strumLines != null ? PlayState.instance.strumLines.length : 2;
	}

	public function getTimeFromArrow(arrow:FlxSprite) {
		if (arrow is Note) {
			final note:Note = cast arrow;
			return note.strumTime;
		}

		return 0;
	}

	public function getHoldSubdivisions():Int
		return Options.modchartHoldSubdivisions;

	public function getDownscroll():Bool
		return Options.downscroll;

	public function getDefaultReceptorX(lane:Int, player:Int):Float {
		@:privateAccess
		return PlayState.instance.strumLines.members[player].members[lane].x;
	}

	public function getDefaultReceptorY(lane:Int, player:Int):Float {
		@:privateAccess
		return PlayState.instance.strumLines.members[player].members[lane].y;
	}

	public function getArrowCamera():Array<FlxCamera>
		return [PlayState.instance.camHUD];

	public function getCurrentScrollSpeed():Float {
		return PlayState.instance.scrollSpeed;
	}

	public function getArrowItems() {
		var drawMembers:Array<Array<Array<FlxSprite>>> = [];
		var strumLineMembers = PlayState.instance.strumLines.members;

		for (i in 0...strumLineMembers.length) {
			final sl = strumLineMembers[i];

			if (!sl.visible)
				continue;

			// setup list
			drawMembers[i] = [
				cast sl.members.copy(),
				[],
				[]
			];

			// preallocating first
			var st = 0;
			var nt = 0;
			sl.notes.forEachAlive((spr) -> {
				spr.isSustainNote ? st++ : nt++;
			});

			drawMembers[i][1].resize(nt);
			drawMembers[i][2].resize(st);

			var si = 0;
			var ni = 0;
			sl.notes.forEachAlive((spr) -> drawMembers[i][spr.isSustainNote ? 2 : 1][spr.isSustainNote ? si++ : ni++] = spr);
		}

		return drawMembers;
	}
}
