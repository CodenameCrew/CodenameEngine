package funkin.editors.charter;

import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import funkin.backend.chart.ChartData.ChartEvent;
import funkin.backend.chart.EventsData;
import funkin.backend.system.Conductor;
import funkin.game.Character;
import funkin.game.Stage;

using StringTools;

class CharterEventScreenNew extends MusicBeatSubstate {
	public var cam:FlxCamera;
	public var eventCam:FlxCamera;
	public var chartEvent:CharterEvent;

	public var events:Array<ChartEvent> = [];
	public var eventsList:UIButtonList<EventButtonNew>;

	public var eventName:UIText;

	public var paramsPanel:FlxGroup;
	public var paramsFields:Array<FlxBasic> = [];

	public var downIndicator:UIText;

	public var bWidth:Float;

	var bg:UISliceSprite;

	public function new(?chartEvent:Null<CharterEvent>) {
		if (chartEvent != null) this.chartEvent = chartEvent;
		super();
	}

	public override function create() {
		super.create();

		FlxG.sound.music.pause(); // prevent the song from continuing
		Charter.instance.vocals.pause();
		for (strumLine in Charter.instance.strumLines.members) strumLine.vocals.pause();

		events = chartEvent.events.copy();

		FlxG.state.persistentUpdate = true;

		camera = cam = new FlxCamera();
		cam.bgColor = 0;

		eventCam = new FlxCamera();
		eventCam.bgColor = 0;

		FlxG.cameras.add(cam, false);
		FlxG.cameras.add(eventCam, false);

		bg = new UISliceSprite(0, 0, 0, 0, 'editors/ui/inputbox');
		bg.alpha = 0.75;
		bg.cameras = [cam];
		bg.setPosition(0, 0);
		add(bg);

		paramsPanel = new FlxGroup();
		paramsPanel.cameras = [eventCam];
		add(paramsPanel);

		eventName = new UIText(0, 0, 0, "", 24);
		eventName.cameras = [eventCam];
		add(eventName);

		downIndicator = new UIText(0, 0, 0, "↓", 16);
		downIndicator.cameras = [eventCam];
		downIndicator.scrollFactor.set();
		downIndicator.borderSize = 2;
		downIndicator.alpha = 0;
		add(downIndicator);

		eventsList = new UIButtonList<EventButtonNew>(10, 10, 75, 570, null, FlxPoint.get(75, 40), null, 0);
		eventsList.alpha = 0;
		eventsList.cameras = [cam];
		eventsList.addButton.callback = () -> {
			__ignoreLastClick = true; // Stop closing >:D
			openSubState(new CharterEventTypeSelection(function(eventName) {
				events.push({
					time: Conductor.getTimeForStep(chartEvent.step),
					params: [],
					name: eventName
				});
				eventsList.add(new EventButtonNew(events[events.length-1], CharterEvent.generateEventIcon(events[events.length-1]), events.length-1, this, eventsList));
				changeTab(events.length-1);
			}, chartEvent.step));
		};
		for (k=>i in events)
			eventsList.add(new EventButtonNew(i, CharterEvent.generateEventIcon(i), k, this, eventsList));
		add(eventsList);

		// this took forever to find out omg >:D -lunar
		eventsList.cameraSpacing = 0; eventsList.topHeight = 0;

		changeTab(0);
		boundWindow();
	}

	public var curEvent:Int = -1;
	public var winHeight:Float = 0;

	public function changeTab(id:Int, save:Bool = true) {
		if (save)
			saveCurTab();

		// destroy old elements
		paramsFields = [];
		for(e in paramsPanel) {
			e.destroy();
			paramsPanel.remove(e);
		}

		winHeight = eventName.y + eventName.height + 6;
		eventCam.scroll.y = 0;

		if (id >= 0 && id < events.length) {
			curEvent = id;
			var curEvent = events[curEvent];
			eventName.text = curEvent.name;
			bWidth = eventName.x + eventName.width+16;

			// add new elements
			for(k=>param in EventsData.getEventParams(curEvent.name)) {
				function addLabel() {
					var label:UIText = new UIText(eventName.x+6, winHeight, 0, param.name);
					winHeight += label.height + 4;
					paramsPanel.add(label);

					bWidth = Math.max(bWidth, label.x+label.width+10);
				};

				var value:Dynamic = CoolUtil.getDefault(curEvent.params[k], param.defValue);
				var lastAdded = switch(param.type) {
					case TString:
						addLabel();
						var textBox:UITextBox = new UITextBox(eventName.x+6, winHeight, cast value);
						paramsPanel.add(textBox); paramsFields.push(textBox);
						textBox;
					case TBool:
						winHeight += 2;
						var checkbox = new UICheckbox(eventName.x+8, winHeight, param.name, cast value);
						paramsPanel.add(checkbox); paramsFields.push(checkbox);
						checkbox;
					case TInt(min, max, step):
						addLabel();
						var numericStepper = new UINumericStepper(eventName.x+6, winHeight, cast value, step.getDefault(1), 0, min, max);
						paramsPanel.add(numericStepper); paramsFields.push(numericStepper);
						numericStepper;
					case TFloat(min, max, step, precision):
						addLabel();
						var numericStepper = new UINumericStepper(eventName.x+6, winHeight, cast value, step.getDefault(1), precision, min, max);
						paramsPanel.add(numericStepper); paramsFields.push(numericStepper);
						numericStepper;
					case TStrumLine:
						addLabel();
						var dropdown = new UIDropDown(eventName.x+6, winHeight, 320, 32, [for(k=>s in cast(FlxG.state, Charter).strumLines.members) 'Strumline #${k+1} (${s.strumLine.characters[0]})'], cast value);
						paramsPanel.add(dropdown); paramsFields.push(dropdown);
						dropdown;
					case TColorWheel:
						addLabel();
						var colorWheel = new UIColorwheel(eventName.x+6, winHeight, value is String ? FlxColor.fromString(value) : Std.int(value));
						paramsPanel.add(colorWheel); paramsFields.push(colorWheel);
						colorWheel;
					case TDropDown(options):
						addLabel();
						var optionIndex = options.indexOf(cast value);
						if(optionIndex < 0) {
							optionIndex = 0;
						}
						var dropdown = new UIDropDown(eventName.x+6, winHeight, 320, 32, options, optionIndex);
						paramsPanel.add(dropdown); paramsFields.push(dropdown);
						dropdown;
					case TCharacter:
						addLabel();
						var charFileList = Character.getList(false);
						var textBox:UIAutoCompleteTextBox = new UIAutoCompleteTextBox(eventName.x+6, winHeight, cast value);
						textBox.suggestItems = charFileList;
						paramsPanel.add(textBox); paramsFields.push(textBox);
						textBox;
					case TStage:
						addLabel();
						var stageFileList = Stage.getList(false);
						var textBox:UIAutoCompleteTextBox = new UIAutoCompleteTextBox(eventName.x+6, winHeight, cast value);
						textBox.suggestItems = stageFileList;
						paramsPanel.add(textBox); paramsFields.push(textBox);
						textBox;
					default:
						paramsFields.push(null);
						null;
				}
				if (lastAdded is UISliceSprite) {
					winHeight += cast(lastAdded, UISliceSprite).bHeight + 4;
					bWidth = Math.max(bWidth, eventName.x + 6 + cast(lastAdded, UISliceSprite).bWidth + 6 + 10);
				}
				else if (lastAdded is FlxSprite) {
					winHeight += cast(lastAdded, FlxSprite).height + 6;
					bWidth = Math.max(bWidth, eventName.x + 6 + cast(lastAdded, FlxSprite).width + 6 + 10);
				}
			}
		} else {
			eventName.text = "No event";
			curEvent = -1;

			bWidth = eventName.x + eventName.width+16;
		}

		winHeight = Math.max(winHeight, (eventsList.buttonSize.y * (eventsList.buttons.length + 1))-4) + 10;
		bWidth += 10+75+10+4; // add events list width to account for event name being on a diff cam +4 because margins >:D
		update(0);
	}

	public function boundWindow() {
		var screenPos:FlxPoint = CoolUtil.pointToScreenPosition(FlxPoint.get(chartEvent.x, chartEvent.y + chartEvent.bHeight));
		screenPos.x -= chartEvent.global ? -8 : 68+12; screenPos.y += 8;

		bg.bWidth = cam.width = cast bWidth-6;
		bg.bHeight = cam.height = cast winHeight + 10;
		eventsList.bHeight = cast winHeight - 10;

		// Bound stuff from being off screen 
		var screenSpaceY:Float = (screenPos.y + winHeight + 10) - FlxG.height;
		screenPos.x = FlxMath.bound(screenPos.x, 4, (FlxG.width - 20) - bWidth - 4); // FlxG.width - 20 for the scroll bar on the right
		if (screenSpaceY > -8) { // border of 8 of screen >:D
			bg.bHeight -= cast screenSpaceY + 8; cam.height -= cast screenSpaceY + 8;

			screenSpaceY -= 20; // events list is slight diff with its camera
			if (screenSpaceY > -8) eventsList.bHeight -= cast screenSpaceY + 8;
		}

		cam.x = screenPos.x; cam.y = screenPos.y;

		eventCam.x = cam.x+10+75+10; eventCam.y = cam.y+10;
		eventCam.width = bg.bWidth-(10+75+10); eventCam.height = bg.bHeight - 20;

		screenPos.put();
	}

	@:noCompletion var __clickedWhileHovering = false;
	@:noCompletion var __ignoreLastClick:Bool = false;
	var sinner:Float = 0;
	override public function update(elapsed:Float) {
		var mousepoint = FlxG.mouse.getPositionInCameraView(cam);
		boundWindow();

		if (FlxG.mouse.justPressed && (FlxMath.inBounds(mousepoint.x, 0, bg.bWidth) && FlxMath.inBounds(mousepoint.y, 0, bg.bHeight))) __clickedWhileHovering = true;

		var boundingParamY:Float = 0;
		var lastParamSprite:FlxObject = paramsFields != null ? cast paramsFields[paramsFields.length-1] : null;
		if (lastParamSprite != null) boundingParamY = lastParamSprite.y;

		if (FlxMath.inBounds(mousepoint.x, 0, bg.bWidth) && FlxMath.inBounds(mousepoint.y, 0, bg.bHeight)) {
			Charter.instance.shouldScroll = false;
			if (FlxMath.inBounds(mousepoint.x, 10+75+10, eventCam.width) && FlxMath.inBounds(mousepoint.y, 10, eventCam.height)) {
				var boundingParamYHeight:Float = boundingParamY;
				if (lastParamSprite != null) {
					if (lastParamSprite is UISliceSprite) boundingParamYHeight += cast(lastParamSprite, UISliceSprite).bHeight;
					else if (lastParamSprite is FlxSprite) boundingParamYHeight += cast(lastParamSprite, FlxSprite).height;
				}

				if (boundingParamYHeight > eventCam.height)
					eventCam.scroll.y = CoolUtil.bound(eventCam.scroll.y - (FlxG.mouse.wheel * 12), 0, boundingParamYHeight - eventCam.height);
			}
		} else if (Charter.instance.curContextMenu == null && ((FlxG.mouse.justReleased && !__clickedWhileHovering) || FlxG.mouse.wheel != 0)) {
			if (__ignoreLastClick) 
				__ignoreLastClick = false;
			else {
				Charter.instance.shouldScroll = true;
				quit();
			}
		}
		super.update(elapsed);
		
		if (FlxG.mouse.justReleased) __clickedWhileHovering = false;

		sinner += elapsed;

		downIndicator.setPosition(((eventCam.width/2)) - (downIndicator.fieldWidth/2), (eventCam.height-downIndicator.height) - 2 - (FlxMath.fastSin(sinner*2) * 2));
		downIndicator.alpha = CoolUtil.fpsLerp(downIndicator.alpha, (eventCam.scroll.y+eventCam.height > boundingParamY) ? 0 : 1, 1/3);
	}

	public function quit() {
		CharterEventGroup.stopThisFuckingShitDudeIstg = false;
		saveCurTab();

		if (events.length <= 0)
			Charter.instance.deleteSelection([chartEvent]);
		else if (events.length > 0) {
			var oldEvents:Array<ChartEvent> = chartEvent.events.copy();
			chartEvent.events = [for (i in eventsList.buttons.members) i.event];

			Charter.undos.addToUndo(CEditEvent(chartEvent, oldEvents, [for (event in events) Reflect.copy(event)]));
		}
		chartEvent.refreshEventIcons();
		Charter.instance.updateBPMEvents();
		close();
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
	public override function destroy() {
		super.destroy();
		FlxG.cameras.remove(cam);
		FlxG.cameras.remove(eventCam);
	}
}

class EventButtonNew extends UIButton {
	public var icon:FlxSprite = null;
	public var event:ChartEvent = null;
	public var deleteButton:UIButton;
	public var deleteIcon:FlxSprite;

	public function new(event:ChartEvent, icon:FlxSprite, id:Int, substate:CharterEventScreenNew, parent:UIButtonList<EventButtonNew>) {
		this.icon = icon;
		this.event = event;
		super(0, 0, null, function() {
			substate.changeTab(id);
			for(i in parent.buttons.members)
				i.alpha = i == this ? 1 : 0.25;
		}, 73, 40);
		autoAlpha = false;

		members.push(icon);
		icon.setPosition(18 - icon.width / 2, 20 - icon.height / 2);

		deleteButton = new UIButton(bWidth - 30, y + (bHeight - 26) / 2, null, function () {
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