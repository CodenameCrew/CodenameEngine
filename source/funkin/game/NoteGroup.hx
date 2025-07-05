package funkin.game;

import flixel.util.FlxSort;
import funkin.backend.system.Conductor;

class NoteGroup extends FlxTypedGroup<Note> {
	var __loopSprite:Note;
	var i:Int = 0;
	var __currentlyLooping:Bool = false;
	var __time:Float = -1.0;

	/**
	 * How many ms it should show a note before it should be hit
	 **/
	public var limit:Float = 1500;

	/**
	 * Preallocates the members array with nulls, but if theres anything in the array already it clears it
	 **/
	public inline function preallocate(len:Int) {
		members = cast new haxe.ds.Vector<Note>(len);
		length = len;
	}

	public inline function addNotes(notes:Array<Note>) {
		for(e in notes) add(e);
		sortNotes();
	}

	public inline function sortNotes() {
		sort(function(i, n1, n2) {
			if (n1.strumTime == n2.strumTime)
				return n1.isSustainNote ? 1 : -1;
			return FlxSort.byValues(FlxSort.DESCENDING, n1.strumTime, n2.strumTime);
		});
	}

	@:dox(hide) public var __forcedSongPos:Null<Float> = null;

	@:dox(hide) private inline function __getSongPos()
		return __forcedSongPos == null ? Conductor.songPosition : __forcedSongPos;

	public override function update(elapsed:Float) {
		i = length-1;
		__loopSprite = null;
		__time = __getSongPos();
		while(i >= 0) {
			__loopSprite = members[i--];
			if (__loopSprite == null || !__loopSprite.exists || !__loopSprite.active) {
				continue;
			}
			if (__loopSprite.strumTime - __time > limit)
				break;
			__loopSprite.update(elapsed);
		}
	}

	public override function draw() {
		@:privateAccess var oldDefaultCameras = FlxCamera._defaultCameras;
		@:privateAccess if (cameras != null) FlxCamera._defaultCameras = cameras;

		var oldCur = __currentlyLooping;
		__currentlyLooping = true;

		i = length-1;
		__loopSprite = null;
		__time = __getSongPos();
		while(i >= 0) {
			__loopSprite = members[i--];
			if (__loopSprite == null || !__loopSprite.exists || !__loopSprite.visible)
				continue;
			if (__loopSprite.strumTime - __time > limit) break;
			__loopSprite.draw();
		}
		__currentlyLooping = oldCur;

		@:privateAccess FlxCamera._defaultCameras = oldDefaultCameras;
	}

	/**
	 * Gets the correct order of notes
	 **/
	public function get(id:Int) {
		return members[length - 1 - id];
	}

	public override function forEach(noteFunc:Note->Void, recursive:Bool = false) {
		i = length-1;
		__loopSprite = null;
		__time = __getSongPos();

		var oldCur = __currentlyLooping;
		__currentlyLooping = true;

		while(i >= 0) {
			__loopSprite = members[i--];
			if (__loopSprite == null || !__loopSprite.exists)
				continue;
			if (__loopSprite.strumTime - __time > limit) break;
			noteFunc(__loopSprite);
		}
		__currentlyLooping = oldCur;
	}
	public override function forEachAlive(noteFunc:Note->Void, recursive:Bool = false) {
		forEach(function(note) {
			if (note.alive) noteFunc(note);
		}, recursive);
	}

	public override function remove(Object:Note, Splice:Bool = false):Note
	{
		if (members == null)
			return null;

		// TODO: maybe lastIndexOf
		var index:Int = members.indexOfFromLast(Object);

		if (index < 0)
			return null;

		// doesnt prevent looping from breaking
		if (Splice && __currentlyLooping && i >= index)
			i++;

		if (Splice)
		{
			members.splice(index, 1);
			length--;
		}
		else
			members[index] = null;

		if (_memberRemoved != null)
			_memberRemoved.dispatch(Object);

		return Object;
	}
}