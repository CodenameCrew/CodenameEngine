package funkin.editors.charter;

import funkin.backend.chart.ChartData.ChartEvent;
import funkin.backend.system.Conductor;
import flixel.group.FlxGroup;
import funkin.backend.chart.EventsData;
import flixel.util.FlxColor;

using StringTools;

class CharterEventScreen extends UISubstateWindow {
	//public var cam:FlxCamera;
	public var chartEvent:CharterEvent;

	public var step:Float = 0;
	public var events:Array<ChartEvent> = [];
	public var eventsList:UIButtonList<EventButton>;

	public var eventName:UIText;

	public var paramsPanel:FlxGroup;
	public var paramsFields:Array<FlxBasic> = [];

	public var saveButton:UIButton;
	public var closeButton:UIButton;

	public function new(step:Float, ?chartEvent:Null<CharterEvent>) {
		if (chartEvent != null) this.chartEvent = chartEvent;
		this.step = step;
		super();
	}

	public override function create() {
		var creatingEvent:Bool = chartEvent == null;
		if (creatingEvent) chartEvent = new CharterEvent(step, []);

		winTitle = creatingEvent ? "Create Event Group" : "Edit Event Group";
		winWidth = 960;

		super.create();

		FlxG.sound.music.pause(); // prevent the song from continuing
		Charter.instance.vocals.pause();
		for (strumLine in Charter.instance.strumLines.members) strumLine.vocals.pause();

		events = chartEvent.events.copy();

		eventsList = new UIButtonList<EventButton>(0,0,75, 570, "", FlxPoint.get(73, 40), null, 0);
		eventsList.drawTop = false;
		eventsList.addButton.callback = () -> openSubState(new CharterEventTypeSelection(function(eventName) {
			events.push({
				time: Conductor.getTimeForStep(chartEvent.step),
				params: [],
				name: eventName
			});
			eventsList.add(new EventButton(events[events.length-1], CharterEvent.generateEventIcon(events[events.length-1]), events.length-1, this, eventsList));
			changeTab(events.length-1);
		}));
		for (k=>i in events)
			eventsList.add(new EventButton(i, CharterEvent.generateEventIcon(i), k, this, eventsList));
		add(eventsList);

		paramsPanel = new FlxGroup();
		add(paramsPanel);

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y + windowSpr.bHeight - 16 - 32, "Save & Close", function() {
			saveCurTab();
			chartEvent.refreshEventIcons();

			if (events.length <= 0 && !creatingEvent)
				Charter.instance.deleteSelection([chartEvent]);
			else if (events.length > 0) {
				var oldEvents:Array<ChartEvent> = chartEvent.events.copy();
				chartEvent.events = [
					for (i in eventsList.buttons.members) i.event
				];

				if (creatingEvent && events.length > 0)
					Charter.instance.createSelection([chartEvent]);
				else {
					chartEvent.events = [for (i in eventsList.buttons.members) i.event];
					chartEvent.refreshEventIcons();
					Charter.instance.updateBPMEvents();

					Charter.undos.addToUndo(CEditEvent(chartEvent, oldEvents, [for (event in events) Reflect.copy(event)]));
				}
			}

			close();
		});
		saveButton.x -= saveButton.bWidth;
		add(saveButton);

		closeButton = new UIButton(saveButton.x - 10, saveButton.y, "Close", ()->close());
		closeButton.color = 0xFFFF0000;
		closeButton.x -= closeButton.bWidth;
		add(closeButton);

		eventName = new UIText(eventsList.bWidth + windowSpr.x + 15, windowSpr.y + 41, 0, "", 24);
		add(eventName);

		changeTab(0);
	}

	public var curEvent:Int = -1;

	public function changeTab(id:Int, save:Bool = true) {
		if (save)
			saveCurTab();

		// destroy old elements
		paramsFields = [];
		for(e in paramsPanel) {
			e.destroy();
			paramsPanel.remove(e);
		}

		if (id >= 0 && id < events.length) {
			curEvent = id;
			var curEvent = events[curEvent];
			eventName.text = curEvent.name;
			// add new elements
			var y:Float = eventName.y + eventName.height + 10;
			for(k=>param in EventsData.getEventParams(curEvent.name)) {
				function addLabel() {
					var label:UIText = new UIText(eventName.x, y, 0, param.name);
					y += label.height + 4;
					paramsPanel.add(label);
				};

				var value:Dynamic = CoolUtil.getDefault(curEvent.params[k], param.defValue);
				var lastAdded = switch(param.type) {
					case TString:
						addLabel();
						var textBox:UITextBox = new UITextBox(eventName.x, y, cast value);
						paramsPanel.add(textBox); paramsFields.push(textBox);
						textBox;
					case TBool:
						var checkbox = new UICheckbox(eventName.x, y, param.name, cast value);
						paramsPanel.add(checkbox); paramsFields.push(checkbox);
						checkbox;
					case TInt(min, max, step):
						addLabel();
						var numericStepper = new UINumericStepper(eventName.x, y, cast value, step.getDefault(1), 0, min, max);
						paramsPanel.add(numericStepper); paramsFields.push(numericStepper);
						numericStepper;
					case TFloat(min, max, step, precision):
						addLabel();
						var numericStepper = new UINumericStepper(eventName.x, y, cast value, step.getDefault(1), precision, min, max);
						paramsPanel.add(numericStepper); paramsFields.push(numericStepper);
						numericStepper;
					case TStrumLine:
						addLabel();
						var dropdown = new UIDropDown(eventName.x, y, 320, 32, [for(k=>s in cast(FlxG.state, Charter).strumLines.members) 'Strumline #${k+1} (${s.strumLine.characters[0]})'], cast value);
						paramsPanel.add(dropdown); paramsFields.push(dropdown);
						dropdown;
					case TColorWheel:
						addLabel();
						var colorWheel = new UIColorwheel(eventName.x, y, value is String ? FlxColor.fromString(value) : Std.int(value));
						paramsPanel.add(colorWheel); paramsFields.push(colorWheel);
						colorWheel;
					case TDropDown(options):
						addLabel();
						var dropdown = new UIDropDown(eventName.x, y, 320, 32, options, Std.int(Math.abs(options.indexOf(cast value))));
						paramsPanel.add(dropdown); paramsFields.push(dropdown);
						dropdown;
					default:
						paramsFields.push(null);
						null;
				}
				if (lastAdded is UISliceSprite)
					y += cast(lastAdded, UISliceSprite).bHeight + 4;
				else if (lastAdded is FlxSprite)
					y += cast(lastAdded, FlxSprite).height + 6;
			}
		} else {
			eventName.text = "No event";
			curEvent = -1;
		}
	}

	public function saveCurTab() {
		if (curEvent < 0) return;

		events[curEvent].params = [
			for(p in paramsFields) {
				if (p is UIDropDown) {
					var dataParams = EventsData.getEventParams(events[curEvent].name);
					if (dataParams[paramsFields.indexOf(p)].type == TStrumLine) cast(p, UIDropDown).index;
					else cast(p, UIDropDown).label.text;
				}
				else if (p is UINumericStepper) {
					var stepper = cast(p, UINumericStepper);
					@:privateAccess stepper.__onChange(stepper.label.text);
					if (stepper.precision == 0) // int
						Std.int(stepper.value);
					else
						stepper.value;
				}
				else if (p is UITextBox)
					cast(p, UITextBox).label.text;
				else if (p is UICheckbox)
					cast(p, UICheckbox).checked;
				else if (p is UIColorwheel)
					cast(p, UIColorwheel).curColor;
				else
					null;
			}
		];
	}
}

class EventButton extends UIButton {
	public var icon:FlxSprite = null;
	public var event:ChartEvent = null;
	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public function new(event:ChartEvent, icon:FlxSprite, id:Int, substate:CharterEventScreen, parent:UIButtonList<EventButton>) {
		this.icon = icon;
		this.event = event;
		super(0,0,"" ,function() {
			substate.changeTab(id);
			for(i in parent.buttons.members)
				i.alpha = i == this ? 1 : 0.25;
		},73,40);
		autoAlpha = false;

		members.push(icon);
		icon.setPosition(18 - icon.width / 2, 20 - icon.height / 2);

		deleteButton = new UIButton(bWidth - 30, y + (bHeight - 26) / 2, "", function () {
			substate.events.splice(id, 1);
			substate.changeTab(id, false);
			parent.remove(this);
		}, 26, 26);
		deleteButton.color = FlxColor.RED;
		deleteButton.autoAlpha = false;
		members.push(deleteButton);

		deleteIcon = new FlxSprite(deleteButton.x + (15/2), deleteButton.y + 4).loadGraphic(Paths.image('editors/delete-button'));
		deleteIcon.antialiasing = false;
		members.push(deleteIcon);
	}

	override function update(elapsed) {
		super.update(elapsed);

		deleteButton.selectable = selectable;
		deleteButton.shouldPress = shouldPress;

		icon.setPosition(x + (18 - icon.width / 2),y + (20 - icon.height / 2));
		deleteButton.setPosition(x + (bWidth - 30), y + (bHeight - 26) / 2);
		deleteIcon.setPosition(deleteButton.x + (10/2), deleteButton.y + 4);
	}
}