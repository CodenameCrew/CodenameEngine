package funkin.editors.charter;

import funkin.backend.system.Conductor;
import funkin.backend.chart.EventsData;

class CharterEventTypeSelection extends UISubstateWindow {
	var callback:String->Void;
	var eventStepTime:Float;

	var buttons:Array<UIButton> = [];

	var buttonsBG:UISliceSprite;
	var buttonCameras:FlxCamera;

	var upIndicator:UIText;
	var downIndicator:UIText;

	public function new(callback:String->Void, eventStepTime:Float) {
		super();
		this.callback = callback;
		this.eventStepTime = eventStepTime;
	}

	public override function create() {
		winTitle = TU.translate("charterEventTypeSelection.title");
		super.create();

		var w:Int = winWidth - 20;

		buttonCameras = new FlxCamera(Std.int(windowSpr.x+41), Std.int(windowSpr.y), w, (32 * 16));
		FlxG.cameras.add(buttonCameras, false);
		buttonCameras.bgColor = 0;

		buttonsBG = new UIWindow(10, 41, buttonCameras.width, buttonCameras.height, null);
		buttonsBG.frames = Paths.getFrames('editors/ui/inputbox');
		add(buttonsBG);

		var disableConductorEvents:Bool = false;
		var disableOnlyContinuousChanges:Bool = false;
		for (change in Conductor.bpmChangeMap) {
			if (change.continuous && MathUtil.greaterThanEqual(eventStepTime, change.stepTime) && MathUtil.lessThan(eventStepTime, change.endStepTime)) {
				disableOnlyContinuousChanges = MathUtil.equal(eventStepTime, change.stepTime); //allow time sig and instant bpm changes on the same event
				disableConductorEvents = !disableOnlyContinuousChanges;
			}
		}

		for(k=>eventName in EventsData.eventsList) {
			var visualName = eventName;
			var tuId = "charter.events." + TU.raw2Id(eventName);
			if(TU.exists(tuId))
				visualName = TU.translate(tuId);
			var button = new UIButton(0, (32 * k), visualName, function() {
				close();
				callback(eventName);
			}, w);
			button.autoAlpha = false;
			button.cameras = [buttonCameras];
			buttons.push(cast add(button));

			var icon = CharterEvent.generateEventIcon({
				name: eventName,
				time: 0,
				params: []
			});
			// icon.setGraphicSize(20, 20); // Std.int(button.bHeight - 12)
			icon.updateHitbox();
			icon.cameras = [buttonCameras];
			icon.x = button.x + 8;
			icon.y = button.y + Math.abs(button.bHeight - icon.height) / 2;
			add(icon);

			if (disableConductorEvents && (eventName == "Time Signature Change" || eventName == "Continuous BPM Change" || eventName == "BPM Change") || (disableOnlyContinuousChanges && eventName == "Continuous BPM Change")) {
				button.selectable = button.shouldPress = false;
				button.autoAlpha = true;
			}
		}

		windowSpr.bHeight = 61 + (32 * (17));

		add(new UIButton(10, windowSpr.bHeight-42, TU.translate("editor.cancel"), function() {
			close();
		}, w));

		upIndicator = new UIText(0, 0, 0, "↑", 18);
		upIndicator.cameras = [buttonCameras];
		upIndicator.scrollFactor.set();
		upIndicator.borderSize = 2;
		add(upIndicator);

		downIndicator = new UIText(0, 0, 0, "↓", 18);
		downIndicator.cameras = [buttonCameras];
		downIndicator.scrollFactor.set();
		downIndicator.borderSize = 2;
		add(downIndicator);
	}

	var sinner:Float = 0;
	override function update(elapsed:Float) {
		super.update(elapsed);
		sinner += elapsed;

		for (button in buttons)
			if (button.shouldPress) button.selectable = buttonsBG.hovered;

		buttonCameras.zoom = subCam.zoom;

		buttonCameras.x = -subCam.scroll.x + Std.int(windowSpr.x+10);
		buttonCameras.y = -subCam.scroll.y + Std.int(windowSpr.y+41);

		if (buttons.length > 16)
			buttonCameras.scroll.y = CoolUtil.bound(buttonCameras.scroll.y - (buttonsBG.hovered ? FlxG.mouse.wheel : 0) * 12, 0,
				(buttons[buttons.length-1].y + buttons[buttons.length-1].bHeight) - buttonCameras.height);

		upIndicator.setPosition((buttonsBG.bWidth/2) - (upIndicator.fieldWidth/2), 22 + (FlxMath.fastSin(sinner*2) * 4));
		downIndicator.setPosition((buttonsBG.bWidth/2) - (downIndicator.fieldWidth/2), (buttonsBG.bHeight-downIndicator.height-22) - (FlxMath.fastSin(sinner*2) * 4));

		upIndicator.alpha = CoolUtil.fpsLerp(upIndicator.alpha, (buttons[0].y + buttonCameras.scroll.y > buttons[0].bHeight) ? 1 : 0, 1/3);
		downIndicator.alpha = CoolUtil.fpsLerp(downIndicator.alpha, (buttonCameras.scroll.y+buttonCameras.height > buttons[buttons.length-1].y) ? 0 : 1, 1/3);
	}

	override function destroy() {
		super.destroy();

		if(buttonCameras != null) {
			if (FlxG.cameras.list.contains(buttonCameras))
				FlxG.cameras.remove(buttonCameras);
			buttonCameras = null;
		}
	}
}