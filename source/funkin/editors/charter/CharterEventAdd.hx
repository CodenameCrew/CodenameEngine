package funkin.editors.charter;

class CharterEventAdd extends UISliceSprite {
	var text:UIText;
	public var sprAlpha:Float = 0;
	public var step:Float = 0;

	public var curCharterEvent:CharterEvent = null;

	public var sideText:UIText;
	public var global:Bool = false;

	public function new(global:Bool) {
		super(0, 0, 100, 34, 'editors/charter/event-spr-add');

		this.global = global;
		flipX = (global != Options.charterSwapEventSides);

		sideText = new UIText(0, -40, 0, TU.translate("charter.eventType-" + (global ? "global" : "local")), 12);
		sideText.alignment = "center"; sideText.alpha = 0.75;

		text = new UIText(0, 0, 0, "");
		members.push(text);

		cursor = CLICK;
	}

	public override function onHovered() {
		super.onHovered();
		if (FlxG.mouse.justReleased && FlxG.state.subState == null) {
			if (curCharterEvent != null)
				Charter.instance.openSubState(new CharterEventScreenNew(curCharterEvent));
			else {
				CharterEventGroup.stopThisFuckingShitDudeIstg = true;
				var chartEvent = new CharterEvent(step, [], global);
				chartEvent.global = global;

				Charter.instance.createSelection([chartEvent]);
				Charter.instance.openSubState(new CharterEventScreenNew(chartEvent));
				sprAlpha = 0;
				alpha = sprAlpha * 0.75;
				text.alpha = sprAlpha;

				sideText.alpha = sprAlpha;
			}
		}
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.state.subState != null) return;
		text.follow(this, (global != Options.charterSwapEventSides) ? bWidth - text.width - (text.text == TU.translate("charter.addEvent") ? 15 : 20) : 20, (bHeight - text.height) / 2);
		sideText.follow(this, (bWidth/2) - (sideText.fieldWidth/2), -(sideText.height + 2));
		alpha = sprAlpha * 0.75;
		text.alpha = sprAlpha;

		sideText.alpha = sprAlpha;
	}

	public function updatePos(step:Float) {
		if (FlxG.state.subState != null) return;
		curCharterEvent = null;
		this.step = step;
		this.y = (step * 40) - (bHeight / 2);
		framesOffset = 0; bWidth = 37 + Math.ceil(text.width);
		updateStuff(global, false);
	}

	public function updateEdit(event:CharterEvent) {
		if (FlxG.state.subState != null) return;
		curCharterEvent = event;
		this.y = event.y;
		framesOffset = 9; bWidth = 27 + Math.ceil(text.width) + event.bWidth;
		updateStuff(event.global, true);
	}

	private function updateStuff(global:Bool = false, edit:Bool = false) {
		final lastStrumline = Charter.instance.strumLines.members[Charter.instance.strumLines.members.length-1];
		if (lastStrumline != null)
			x = (global != Options.charterSwapEventSides) ? lastStrumline.x + (40*lastStrumline.keyCount) : -(bWidth);
		else
			x = (global != Options.charterSwapEventSides) ? 0 : -(bWidth);

		final target = TU.translate("charter.eventType-" + (global ? "global" : "local"));
		if (sideText.text != target) sideText.text = target;

		final targetButtonText = TU.translate("charter." + (edit ? "edit" : "add") + "Event");
		if (text.text != targetButtonText) text.text = targetButtonText;
	}
}