package funkin.game;

import flixel.util.FlxSort;
import funkin.backend.system.Conductor;

/**
 * Group of notes, that handles updating and rendering only the visible notes.
 * To only get the visible notes you gotta do `group.forEach()` or `group.forEachAlive()` instead of `group.members`.
**/
class NoteGroup extends FlxTypedGroup<Note>
{
	var __loopSprite:Note;
	var i:Int = 0;
	var __currentlyLooping:Bool = false;

	/**
	 * Lazy?? lazy?????? but its ok cause i want to pool things so we won't need this
	 */
	public var held:Array<Note> = new Array<Note>();

	/**
	 * Preallocates the members array with nulls, but if theres anything in the array already it clears it
	**/
	public inline function preallocate(len:Int)
	{
		members = cast new haxe.ds.Vector<Note>(len);
		length = len;
	}

	/**
	 * Adds an array of notes to the group, and sorts them.
	**/
	public inline function addNotes(notes:Array<Note>)
	{
		for (e in notes)
			add(e);
		sortNotes();
	}

	/**
	 * Sorts the notes in the group.
	**/
	public inline function sortNotes()
	{
		sort(__sortFunc, FlxSort.DESCENDING);
	}

	@:noCompletion
	function __sortFunc(order:Int, a:Note, b:Note)
	{
		return FlxSort.byValues(order, a.strumTime, b.strumTime);
	}

	inline function loopSpriteTooFar():Bool
	{
		return __loopSprite.strum.getDistance(__loopSprite) > __loopSprite.strumLine.drawDistanceMax;
	}

	public override function update(elapsed:Float)
	{
		i = length - 1;
		__loopSprite = null;
		while (i >= 0)
		{
			__loopSprite = members[i--];
			if (__loopSprite == null || !__loopSprite.exists || !__loopSprite.active)
				continue;
			if (loopSpriteTooFar())
				break;
			__loopSprite.update(elapsed);
		}
	}

	public override function draw() @:privateAccess {
		var oldDefaultCameras = FlxCamera._defaultCameras;
		if (_cameras != null)
			FlxCamera._defaultCameras = _cameras;

		var renderingSustains = true;
		var oldCur = __currentlyLooping;
		__currentlyLooping = true;

		i = length - 1;
		__loopSprite = null;
		while (i >= 0)
		{
			__loopSprite = members[i--];
			if (__loopSprite == null || !__loopSprite.exists || !__loopSprite.visible)
				continue;
			if (loopSpriteTooFar())
				break;
			__loopSprite.draw();
		}
		__currentlyLooping = oldCur;

		FlxCamera._defaultCameras = oldDefaultCameras;
	}

	/**
	 * Gets the correct order of notes
	**/
	public function get(id:Int)
	{
		return members[length - 1 - id];
	}

	public override function forEach(noteFunc:Note->Void, recursive:Bool = false)
	{
		i = length - 1;
		__loopSprite = null;

		var oldCur = __currentlyLooping;
		__currentlyLooping = true;

		while (i >= 0)
		{
			__loopSprite = members[i--];
			if (__loopSprite == null || !__loopSprite.exists)
				continue;
			if (loopSpriteTooFar())
				break;
			noteFunc(__loopSprite);
		}
		__currentlyLooping = oldCur;
	}

	public override function forEachAlive(noteFunc:Note->Void, recursive:Bool = false)
	{
		forEach(function(note)
		{
			if (note.alive)
				noteFunc(note);
		}, recursive);
	}

	public override function remove(Object:Note, Splice:Bool = false):Note
	{
		if (members == null)
			return null;

		var index:Int = members.lastIndexOf(Object);

		if (index < 0)
			return null;

		// doesn't prevent looping from breaking
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
