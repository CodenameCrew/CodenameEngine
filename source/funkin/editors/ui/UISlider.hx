package funkin.editors.ui;

import flixel.util.FlxColor;
using flixel.util.FlxSpriteUtil;
using StringTools;

typedef SliderSegement = {
	var start:Float;
	var end:Float;
	var size:Float;
}

class UISlider extends UISprite {
	public var segments:Array<SliderSegement> = [];
	public var barWidth:Int = 120;

	public var progressbar:UISprite;
	public var progressCentered:Bool;

	public var startText:UIText;
	public var endText:UIText;

	public var selectableBar:UISprite;
	public var selectableBarHighlight:UISprite;
	public var selectableHitbox:UISprite;

	public var value(default, set):Float = 0;
	public function set_value(newVal:Float):Float {
		newVal = FlxMath.bound(newVal, segments[0].start, segments[segments.length-1].end);
		__barProgress = __calcProgress(newVal); if (onChange != null) onChange(newVal);
		if (valueStepper != null) valueStepper.value = newVal;
		return value = newVal;
	}

	public var valueStepper:UINumericStepper;
	public var onChange:Float->Void;

	public function new(x:Float, y:Float, width:Int = 120, value:Float, segments:Array<SliderSegement>, centered:Bool) {
		this.segments = segments;
		this.barWidth = width;
		this.progressCentered = centered;

		super(x, y);

		makeGraphic(barWidth, 12, 0x00000000, true);
		this.drawRoundRect(0, 0, barWidth, 12, 8, 6, 0xFFC0C0C0);
		this.drawRoundRect(1, 1, barWidth-2, 12-2, 8, 5, 0xFF140013);
		cursor = BUTTON;

		progressbar = new UISprite(centered ? barWidth/2 : 0);
		progressbar.makeGraphic(barWidth, 8, 0x00000000, true);
		progressbar.drawRoundRect(2, 0, barWidth-4, 8, 8, 2, 0xFFFFFFFF);
		progressbar.origin.x = 0; progressbar.colorTransform.color = 0xFF67009B;
		members.push(progressbar);

		this.value = value;
		visualProgress = __barProgress;

		members.push(startText = new UIText(x, y, 0, Std.string(segments[0].start).replace("0.", ".")));
		members.push(endText = new UIText(x + (barWidth) + 8, y, 0, Std.string(segments[segments.length-1].end).replace("0.", ".")));

		for (i in 0...2) {
			var selectableBar:UISprite = new UISprite(x,y);
			selectableBar.loadGraphic(Paths.image("editors/ui/slider"));
			selectableBar.antialiasing = true;
			selectableBar.cursor = BUTTON;
			members.push(selectableBar);

			switch (i) {
				case 0: this.selectableBar = selectableBar;
				case 1: this.selectableBarHighlight = selectableBar; selectableBarHighlight.colorTransform.color = 0xFFFFFFFF; selectableBarHighlight.alpha = 0;
			}
		}

		selectableHitbox = new UISprite(x,y);
		selectableHitbox.makeSolid(barWidth, 18, -1);
		selectableHitbox.cursor = BUTTON;
		selectableHitbox.alpha = 0;
		members.push(selectableHitbox);

		valueStepper = new UINumericStepper(x - 64 - 64, y, 1, 0.01, 2, segments[0].start, segments[segments.length-1].end, 0, 16);
		valueStepper.antialiasing = valueStepper.label.antialiasing = true;
		valueStepper.onChange = function (text:String) {
			@:privateAccess valueStepper.__onChange(text);
			this.value = valueStepper.value;
			visualProgress = __barProgress;
		}
		members.push(valueStepper);
	}

	var __barProgress:Float = 0;
	var visualProgress:Float = 0;

	var __stepperWidth = 25;

	public override function update(elapsed:Float) {
		selectableHitbox.follow(this, 0, (height-selectableHitbox.height)/2);

		__stepperWidth = valueStepper.label.text.length <= 0 ? 25 : Std.int(valueStepper.label.textField.width) + 12;
		valueStepper.bWidth = Std.int(FlxMath.lerp(valueStepper.bWidth, __stepperWidth, 1/2.25));
		valueStepper.follow(this, -startText.width-10 - valueStepper.bWidth - 4, (height-valueStepper.bHeight)/2);

		var lastBarProgress:Float = __barProgress;

		if (selectableHitbox.hovered && FlxG.mouse.pressed) {
			var mousePos = FlxG.mouse.getScreenPosition(__lastDrawCameras[0], FlxPoint.get());
			__barProgress = FlxMath.bound(mousePos.x-x, 0, barWidth)/barWidth;
			mousePos.put();
		}

		if (__barProgress != lastBarProgress) {
			if (onChange != null) onChange(@:bypassAccessor value = __calcValue(__barProgress));
			valueStepper.value = value;
		}

		visualProgress = FlxMath.lerp(visualProgress, __barProgress, 1/2.25);
		progressbar.follow(this, progressCentered ? barWidth/2 : 0, (height-progressbar.height)/2);
		progressbar.scale.x = FlxMath.bound(visualProgress-(progressCentered?0.5:0),-1,1);
		progressbar.colorTransform.color = FlxColor.interpolate(progressbar.colorTransform.color, selectableHitbox.hovered ? 0xFF7F00BF : 0xFF67009B, 1/14);

		selectableBar.follow(this, (visualProgress * barWidth) - (selectableBar.width/2), (height-selectableBar.height)/2); selectableBarHighlight.follow(selectableBar);
		selectableBarHighlight.alpha = FlxMath.lerp(selectableBarHighlight.alpha, selectableHitbox.hovered ? 0.1: 0, 1/14);

		startText.follow(this, -startText.width-10, (height/2) - (startText.height/2));
		endText.follow(this, barWidth + 10, (height/2) - (endText.height/2));

		super.update(elapsed);
	}

	private function __calcValue(progress:Float):Float {
		var totalProgress:Float = 0;
		for (segment in segments) {
			if (progress < totalProgress + segment.size) {
				var relativeProgress = (progress - totalProgress) / segment.size;
				return FlxMath.remapToRange(relativeProgress, 0, 1, segment.start, segment.end);
			}
			totalProgress += segment.size;
		}
		return segments[segments.length-1].end;
	}

	private function __calcProgress(value:Float):Float {
		if (value >= segments[segments.length-1].end) return 1;
		if (value <= segments[0].start) return 0;

		var totalProgress:Float = 0;
		for (segment in segments) {
			if (value >= segment.start && value <= segment.end) {
				var relativeProgress = FlxMath.remapToRange(value, segment.start, segment.end, 0, 1);
				return totalProgress + relativeProgress * segment.size;
			}
			totalProgress += segment.size;
		}
		return -1;
	}
}