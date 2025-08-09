package funkin.editors.charter;

import flixel.util.FlxSort;
import funkin.backend.chart.EventsData;

class CharterStrumLineGroup extends FlxTypedGroup<CharterStrumline> {
	var __pastStrumlines:Array<CharterStrumline>;
	var draggingObj:CharterStrumline = null;
	var draggingOffset:Float = 0;

	public var totalKeyCount(get, never):Int;
	private var __totalKeyCount:Int = -1;
	public function get_totalKeyCount():Int {
		if (__totalKeyCount != -1) return __totalKeyCount;

		var v:Int = 0;
		for (strumLine in members) v += strumLine.keyCount;
		return __totalKeyCount = v;
	}

	public var draggable:Bool = false;
	public var isDragging(get, never):Bool;
	public function get_isDragging():Bool
		return draggingObj != null;

	var __mousePos:FlxPoint = new FlxPoint();

	public override function update(elapsed:Float) {
		FlxG.mouse.getWorldPosition(cameras[0], __mousePos);
		for (strumLine in members) {
			if (strumLine == null) continue;
			strumLine.draggable = draggable;
			if (draggable && UIState.state.isOverlapping(strumLine.draggingSprite, @:privateAccess strumLine.draggingSprite.__rect) && FlxG.mouse.justPressed) {
				draggingObj = strumLine;
				strumLine.dragging = true;

				draggingOffset = __mousePos.x - strumLine.button.x;
				__pastStrumlines = members.copy();
				break;
			}
		}

		if (isDragging) {
			draggingObj.x = __mousePos.x - draggingOffset;
			this.sort(function(o, a, b) return FlxSort.byValues(o, a.x, b.x), -1);
			refreshStrumlineIDs();
		}

		for (i=>strum in members)
			if (strum != null && !strum.dragging) strum.x = CoolUtil.fpsLerp(strum.x, 40*strum.startingID, 0.225);

		if (Charter.instance.leftEventsBackdrop != null && members[0] != null) {
			Charter.instance.leftEventsBackdrop.x = members[0].button.x - Charter.instance.leftEventsBackdrop.width;
			Charter.instance.leftEventsBackdrop.alpha = members[0].strumLine.visible ? 0.9 : 0.4;

			if (Charter.instance.leftEventRowText != null)
				Charter.instance.leftEventRowText.x = members[0].button.x - Charter.instance.leftEventRowText.width - 42;
		}
		
		if (Charter.instance.rightEventsBackdrop != null && members[CoolUtil.maxInt(0, members.length-1)] != null) {
			Charter.instance.rightEventsBackdrop.x = members[members.length-1].x + (40*members[members.length-1].keyCount);
			Charter.instance.rightEventsBackdrop.alpha = members[CoolUtil.maxInt(0, members.length-1)].strumLine.visible ? 0.9 : 0.4;

			if (Charter.instance.rightEventRowText != null)
				Charter.instance.rightEventRowText.x = Charter.instance.rightEventsBackdrop.x + 42;
		}
		
		if (Charter.instance.strumlineLockButton != null && members[0] != null)
			Charter.instance.strumlineLockButton.x = members[0].x - (160);
		if (Charter.instance.strumlineAddButton != null && members[CoolUtil.maxInt(0, members.length-1)] != null)
			Charter.instance.strumlineAddButton.x = members[members.length-1].x + (40*members[members.length-1].keyCount);

		if ((FlxG.mouse.justReleased || !draggable) && isDragging)
			finishDrag();

		super.update(elapsed);
	}

	public function snapStrums() {
		for (i=>strum in members)
			if (strum != null && !strum.dragging) strum.x = 40*strum.startingID;
	}

	public function orderStrumline(strumLine:CharterStrumline, newID:Int) {
		__pastStrumlines = members.copy();

		members.remove(strumLine);
		members.insert(newID, strumLine);

		refreshStrumlineIDs();
		finishDrag(false);
	}

	public function finishDrag(?addToUndo:Bool = true) {
		if (isDragging)
			draggingObj.dragging = false;

		// Undo
		if (addToUndo) {
			var oldID = __pastStrumlines.indexOf(draggingObj);
			var newID = members.indexOf(draggingObj);
			if (newID != oldID) Charter.undos.addToUndo(COrderStrumLine(newID, oldID, newID));
		}

		draggingObj = null;
		fixEvents();
		refreshStrumlineIDs();
	}

	public inline function fixEvents() {
		for (eventsGroup in [Charter.instance.leftEventsGroup, Charter.instance.rightEventsGroup]) {
			for (i in eventsGroup) {
				for (j in i.events) {
					var paramTypes:Array<EventParamInfo> = EventsData.getEventParams(j.name);
					for (i => param in paramTypes) {
						if (param.type != TStrumLine) continue;
						j.params[i] = members.indexOf(__pastStrumlines[j.params[i]]);
					}
				}
			}
		}
		__pastStrumlines = null;
	}

	public inline function refreshStrumlineIDs() {
		__totalKeyCount = -1;
		@:privateAccess
		for (strumLine in members) strumLine.__startingID = -1;
	}

	public function getStrumlineFromID(id:Int) {
		var v:Int = 0;
		for (strumLine in members) {
			v += strumLine.keyCount;
			if (id < v) return strumLine;
		}
		return members.last();
	}

	override function draw() @:privateAccess {
		var i:Int = 0;
		var basic:FlxBasic = null;

		var oldDefaultCameras = FlxCamera._defaultCameras;
		if (cameras != null)
			FlxCamera._defaultCameras = cameras;

		while (i < length)
		{
			basic = members[i++];
			if (basic != null && basic != draggingObj && basic.exists && basic.visible)
				basic.draw();
		}
		if (draggingObj != null) draggingObj.draw();

		FlxCamera._defaultCameras = oldDefaultCameras;
	}
}