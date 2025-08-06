package funkin.editors.charter;

import flixel.util.FlxSort;
import funkin.editors.charter.CharterBackdropGroup.EventBackdrop;

class CharterEventGroup extends FlxTypedGroup<CharterEvent> {
	public static var stopThisFuckingShitDudeIstg = false;
	public var eventsBackdrop:EventBackdrop;
	public var eventsRowText:UIText;

	public var autoSort:Bool = true;
	var __lastSort:Int = 0;

	public override function update(elapsed:Float) {
		super.update(elapsed);
		if (!CharterEventGroup.stopThisFuckingShitDudeIstg) filterEvents();
		if (autoSort && members.length != __lastSort)
			sortEvents();

		eventsRowText.y = FlxMath.lerp(eventsRowText.y, -40 + (members[0] != null ? Math.min(members[0].y, 0) : 0), 1/20);
	}

	public override function remove(v:CharterEvent, force:Bool = true):CharterEvent {
		v.ID = -1;
		return super.remove(v, force);
	}

	public override function draw() {
		for (event in members) {
			event.eventsBackdrop = eventsBackdrop;
			event.snappedToGrid = true;
			event.cameras = cameras;
		}
		super.draw();
	}

	public inline function sortEvents() {
		__lastSort = members.length;
		this.sort(sortEventsFilter);
		updateEventsIDs();
		updateEventsBackdrop();
	}

	public inline function updateEventsIDs()
		for (i => n in members) n.ID = i;

	public inline function updateEventsBackdrop()
		for (event in members)
			event.eventsBackdrop = eventsBackdrop;

	public inline function filterEvents() {
		for (event in members)
			if (event.events.length == 0) {
				remove(event, true);
				event.kill();
			}
	}

	public dynamic function sortEventsFilter(i:Int, e1:CharterEvent, e2:CharterEvent)
		return FlxSort.byValues(FlxSort.ASCENDING, e1.step, e2.step);
}