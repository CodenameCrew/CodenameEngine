package modchart.backend.standalone.adapters.codename;

import flixel.FlxCamera;
import flixel.FlxSprite;
import funkin.backend.system.Conductor;
import funkin.game.Note;
import funkin.game.PlayState;
import funkin.game.Splash;
import funkin.game.Strum;
import funkin.options.Options;
import modchart.backend.standalone.IAdapter;

class Codename implements IAdapter {
	public function new() {}

	public function onModchartingInitialization() {
		
	}

	public function isTapNote(sprite:FlxSprite)
		return sprite is Note;

	// Song related
	public function getSongPosition():Float
		return Conductor.songPosition;

	public function getCurrentBeat():Float
		return Conductor.curBeatFloat;

	public function getCurrentCrochet():Float
		return Conductor.crochet;

	public function getBeatFromStep(step:Float):Float
		return Conductor.getTimeInBeats(Conductor.getStepsInTime(step, Conductor.curChangeIndex), Conductor.curChangeIndex);

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
		} else if (arrow is Splash) {
			final splash:Splash = cast arrow;
			return splash.strumID;
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
		} else if (arrow is Splash) {
			final splash:Splash = cast arrow;
			return splash.strum.strumLine.ID;
		}

		return 0;
	}

	public function getHoldLength(item:FlxSprite):Float {
		final note:Note = cast item;
		return note.sustainLength;
	}

	public function getHoldParentTime(arrow:FlxSprite) {
		final note:Note = cast arrow;
		return note.sustainParent.strumTime;
	}

	// im so fucking sorry for those conditionals
	public function getKeyCount(?player:Int = 0):Int {
		return PlayState.instance != null
			&& PlayState.instance.strumLines != null
			&& PlayState.instance.strumLines.members[player] != null ? PlayState.instance.strumLines.members[player].members.length : 4;
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

	public function getHoldSubdivisions(hold:FlxSprite):Int {
		final val = Options.modchartingHoldSubdivisions;
		return val < 1 ? 1 : val;
	}

	public function getDownscroll():Bool
		return PlayState.instance.downscroll;

	public function getDefaultReceptorX(lane:Int, player:Int):Float
		return PlayState.instance.strumLines.members[player].members[lane].x;

	public function getDefaultReceptorY(lane:Int, player:Int):Float
		return PlayState.instance.strumLines.members[player].members[lane].y;

	public function getArrowCamera():Array<FlxCamera>
		return [PlayState.instance.camHUD];

	public function getCurrentScrollSpeed():Float
		return PlayState.instance.scrollSpeed * .45;

	// 0 receptors
	// 1 tap arrows
	// 2 hold arrows
	// 3 receptor attachments
	public function getArrowItems() {
		var pspr:Array<Array<Array<FlxSprite>>> = [];

		var strumLineMembers = PlayState.instance.strumLines.members;

		for (i in 0...strumLineMembers.length) {
			final sl = strumLineMembers[i];

			if (!sl.visible)
				continue;

			pspr[i] = [];
			pspr[i][0] = cast sl.members.copy();
			pspr[i][1] = [];
			pspr[i][2] = [];
			pspr[i][3] = [];

			var st = 0;
			var nt = 0;
			sl.notes.forEachAlive((spr) -> {
				spr.isSustainNote ? st++ : nt++;
			});

			pspr[i][1].resize(nt);
			pspr[i][2].resize(st);

			var si = 0;
			var ni = 0;
			sl.notes.forEachAlive((spr) -> pspr[i][spr.isSustainNote ? 2 : 1][spr.isSustainNote ? si++ : ni++] = spr);
		}

		for (grp in PlayState.instance.splashHandler.grpMap)
			grp.forEachAlive((spr) -> if (spr.strum != null && spr.active) pspr[spr.strum.strumLine.ID][3].push(spr));

		return pspr;
	}
}
