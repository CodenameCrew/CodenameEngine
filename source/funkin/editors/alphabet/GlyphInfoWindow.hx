package funkin.editors.alphabet;

import flixel.math.FlxAngle;

class GlyphInfoWindow extends UIWindow {
	public var prefixBox:UITextBox;
	public var xBox:UINumericStepper; // LIVE
	public var yBox:UINumericStepper; // MJWF
	public var scaleXBox:UINumericStepper;
	public var scaleYBox:UINumericStepper;
	public var angleBox:UINumericStepper;
	public var colorModeDrop:UIDropDown;

	public var flipXBox:UICheckbox;
	public var flipYBox:UICheckbox;

	public var outlineTitle:UIText;
	public var outlineSep:UISprite;
	public var outlineCheck:UICheckbox;
	public var outlineBoxTitle:UIText;
	public var outlineBox:UITextBox;
	public var outlineOffTitle:UIText;
	public var outlineXBox:UINumericStepper;
	public var outlineYBox:UINumericStepper;

	public var targetPercent:Float = 0;
	public var outlinePercent:Float = 0;
	public var outlineAlphaMults:Array<Float>;
	public var outlineItems:Array<FlxSprite>;
	public var initialY:Array<Float> = [];

	var compon(get, never):AlphabetComponent;
	var data(get, never):AlphabetLetterData;

	public function new() {
		var width = 360;
		var height = 255;
		var margin = 30;
		var itemMargin = 15; // there was already a buncha variables so i thought why not follow
		var labelOffset = 24;
		super(FlxG.width - width - margin, FlxG.height - height - margin, width, height, "Glyph Info");

		function addLabelOn(ui:UISprite, text:String) {
			var title = new UIText(ui.x, ui.y - labelOffset, 0, text);
			members.push(title);
			return title;
		}

		prefixBox = new UITextBox(x + itemMargin, y + itemMargin + labelOffset * 2, "", 330);
		prefixBox.onChange = function(val) {
			var index = data.components.indexOf(compon);
			compon.anim = val;
			var anim = AlphabetEditor.instance.bigLetter.text + Std.string(index);
			AlphabetEditor.instance.bigLetter.animation.remove(anim);
			AlphabetEditor.instance.tape.animation.remove(anim);
			AlphabetEditor.instance.checkForFailed();
		}
		members.push(prefixBox);
		addLabelOn(prefixBox, "Animation Prefix");

		xBox = new UINumericStepper(prefixBox.x, prefixBox.y + prefixBox.bHeight + itemMargin + labelOffset, 0, 1, 2, null, null, 80);
		xBox.onChange = valueSet.bind(xBox, function(val) { // kinda dumb but blame cne ui
			compon.x = val;
		});
		members.push(xBox);

		members.push(new UIText(xBox.x + xBox.bWidth - 2, xBox.y + 9, 0, ",", 22));

		yBox = new UINumericStepper(xBox.x + xBox.bWidth + itemMargin, xBox.y, 0, 1, 2, null, null, 80);
		yBox.onChange = valueSet.bind(yBox, function(val) { // kinda dumb but blame cne ui
			compon.y = val;
		});
		members.push(yBox);
		addLabelOn(xBox, "Offset (x,y)");

		scaleXBox = new UINumericStepper(yBox.x + yBox.bWidth + itemMargin * 2, yBox.y, 1, 0.1, 2, null, null, 80);
		scaleXBox.onChange = valueSet.bind(scaleXBox, function(val) { // kinda dumb but blame cne ui
			compon.scaleX = val;
			if (outlineCheck.checked)
				data.components[compon.outIndex].scaleX = val;
		});
		members.push(scaleXBox);

		members.push(new UIText(scaleXBox.x + scaleXBox.bWidth - 2, scaleXBox.y + 9, 0, ",", 22));

		scaleYBox = new UINumericStepper(scaleXBox.x + scaleXBox.bWidth + itemMargin, scaleXBox.y, 1, 0.1, 2, null, null, 80);
		scaleYBox.onChange = valueSet.bind(scaleYBox, function(val) { // kinda dumb but blame cne ui
			compon.scaleY = val;
			if (outlineCheck.checked)
				data.components[compon.outIndex].scaleY = val;
		});
		members.push(scaleYBox);
		addLabelOn(scaleXBox, "Scale (x,y)");

		angleBox = new UINumericStepper(scaleYBox.x + scaleYBox.bWidth + itemMargin * 2, scaleYBox.y, 0, 1, 2, null, null, 80);
		angleBox.onChange = valueSet.bind(angleBox, function(val) { // kinda dumb but blame cne ui
			compon.shouldRotate = val != 0;
			compon.angle = val;
			compon.cos = Math.cos(val * FlxAngle.TO_RAD);
			compon.sin = Math.sin(val * FlxAngle.TO_RAD);

			if (outlineCheck.checked) {
				data.components[compon.outIndex].shouldRotate = compon.shouldRotate;
				data.components[compon.outIndex].angle = compon.angle;
				data.components[compon.outIndex].cos = compon.cos;
				data.components[compon.outIndex].sin = compon.sin;
			}
		});
		members.push(angleBox);
		addLabelOn(angleBox, "Angle");

		colorModeDrop = new UIDropDown(xBox.x, xBox.y + xBox.bHeight + itemMargin + labelOffset, 145, 32, ["TINT", "OFFSETS", "NONE"]);
		colorModeDrop.onChange = function(mode) {
			compon.colorMode = mode;
			@:privateAccess compon.hasColorMode = mode != AlphabetEditor.instance.tape.colorMode;
			if (outlineCheck.checked) {
				data.components[compon.outIndex].colorMode = mode;
				@:privateAccess data.components[compon.outIndex].hasColorMode = compon.hasColorMode;
			}
		};
		members.push(colorModeDrop);
		addLabelOn(colorModeDrop, "Color Mode");

		outlineCheck = new UICheckbox(colorModeDrop.x + colorModeDrop.bWidth + itemMargin * 2, colorModeDrop.y + 4, "Use Outline?");
		outlineCheck.onChecked = function(val) {
			targetPercent = val ? 1 : 0;

			for (i in 0...data.components.length) {
				var anim = AlphabetEditor.instance.bigLetter.text + i;
				AlphabetEditor.instance.bigLetter.animation.remove(anim);
				AlphabetEditor.instance.tape.animation.remove(anim);
			}

			if (val) {
				compon.outIndex = AlphabetEditor.instance.outlineIdx;
				
				var newOutline:AlphabetComponent = {
					refIndex: data.components.indexOf(compon),
					anim: outlineBox.label.text,

					x: outlineXBox.value,
					y: outlineYBox.value,
					scaleX: compon.scaleX,
					scaleY: compon.scaleY,

					shouldRotate: compon.shouldRotate,
					angle: compon.angle,
					cos: compon.cos,
					sin: compon.sin,

					flipX: compon.flipX,
					flipY: compon.flipY,

					hasColorMode: compon.hasColorMode,
					colorMode: compon.colorMode
				};

				data.components.insert(AlphabetEditor.instance.outlineIdx, newOutline);
				++data.startIndex;
			} else {
				compon.outIndex = null;
				data.components.splice(AlphabetEditor.instance.outlineIdx - 1, 1);
				--data.startIndex;
			}
		}
		members.push(outlineCheck);

		flipXBox = new UICheckbox(outlineCheck.x, outlineCheck.y - outlineCheck.height - 8, "Flip X?");
		flipXBox.onChecked = function(check:Bool) {
			compon.flipX = check;
			if (outlineCheck.checked)
				data.components[compon.outIndex].flipX = check;
		}
		members.push(flipXBox);

		flipYBox = new UICheckbox(flipXBox.x + flipXBox.width + itemMargin * 5, flipXBox.y, "Flip Y?");
		flipYBox.onChecked = function(check:Bool) {
			compon.flipY = check;
			if (outlineCheck.checked)
				data.components[compon.outIndex].flipY = check;
		}
		members.push(flipYBox);

		outlineTitle = new UIText(colorModeDrop.x, colorModeDrop.y + colorModeDrop.bHeight + itemMargin, 0, "Outline Data");
		members.push(outlineTitle);
		outlineSep = new UISprite(x + itemMargin, colorModeDrop.y + colorModeDrop.bHeight + itemMargin + 19);
		outlineSep.makeSolid(width - itemMargin * 2, 1, 0x40FFFFFF);
		members.push(outlineSep);

		outlineBox = new UITextBox(colorModeDrop.x, colorModeDrop.y + colorModeDrop.bHeight + itemMargin + labelOffset * 2 + 3, "", 190);
		outlineBox.onChange = function(val) {
			data.components[compon.outIndex].anim = val;
			var anim = AlphabetEditor.instance.bigLetter.text + Std.string(compon.outIndex);
			AlphabetEditor.instance.bigLetter.animation.remove(anim);
			AlphabetEditor.instance.tape.animation.remove(anim);
			AlphabetEditor.instance.checkForFailed();
		}
		members.push(outlineBox);
		outlineBoxTitle = addLabelOn(outlineBox, "Prefix");

		outlineXBox = new UINumericStepper(outlineBox.x + outlineBox.bWidth + itemMargin * 2, outlineBox.y, 0, 1, 2, null, null, 80);
		outlineXBox.onChange = valueSet.bind(outlineXBox, function(val) { // kinda dumb but blame cne ui
			if (outlineCheck.checked)
				data.components[compon.outIndex].x = val;
		});
		members.push(outlineXBox);

		members.push(new UIText(outlineXBox.x + outlineXBox.bWidth - 2, outlineXBox.y + 9, 0, ",", 22));

		outlineYBox = new UINumericStepper(outlineXBox.x + outlineXBox.bWidth + itemMargin, outlineXBox.y, 0, 1, 2, null, null, 80);
		outlineYBox.onChange = valueSet.bind(outlineYBox, function(val) { // kinda dumb but blame cne ui
			if (outlineCheck.checked)
				data.components[compon.outIndex].y = val;
		});
		members.push(outlineYBox);
		outlineOffTitle = addLabelOn(outlineXBox, "Offset (x,y)");

		for (mem in members) {
			if (mem is FlxObject)
				initialY.push(cast (mem, FlxObject).y);
		}
		outlineAlphaMults = [1.0, 0.9, 0.5, 0.15, 0.15, 0.5, 0.15, 0.15, 0.15, 0.15];
		outlineItems = [outlineTitle, outlineSep, outlineBoxTitle, outlineBox, outlineBox.label, outlineOffTitle, outlineXBox, outlineXBox.label, outlineYBox, outlineYBox.label];
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		outlinePercent = FlxMath.lerp(outlinePercent, targetPercent, elapsed * 10);
		bHeight = Std.int(255 + 105 * outlinePercent);
		y = FlxG.height - bHeight - 30;

		for (i in 0...outlineItems.length)
			outlineItems[i].alpha = outlinePercent * FlxMath.lerp(outlineAlphaMults[i], 1, outlinePercent * outlinePercent) * alpha;
		
		var yIdxOff = 0;
		for (i in 0...members.length) {
			if (members[i] is FlxObject)
				cast (members[i], FlxObject).y = initialY[i - yIdxOff] - (bHeight - 255);
			else
				++yIdxOff;
		}
	}

	public function updateInfo() {
		var com = compon;
		if (com == null) {
			for (item in members) {
				if (item is UISprite)
					cast(item, UISprite).selectable = false;
			}
			colorModeDrop.dropButton.selectable = false;
			return;
		}

		prefixBox.label.text = com.anim;
		xBox.value = com.x;
		yBox.value = com.y;
		scaleXBox.value = com.scaleX;
		scaleYBox.value = com.scaleY;
		angleBox.value = com.angle;
		@:privateAccess colorModeDrop.index = com.hasColorMode ? com.colorMode : AlphabetEditor.instance.tape.colorMode;
		@:privateAccess colorModeDrop.label.text = colorModeDrop.options[colorModeDrop.index];
		flipXBox.checked = com.flipX;
		flipYBox.checked = com.flipY;

		outlineCheck.checked = com.outIndex != null;
		outlineBox.label.text = "";
		outlineXBox.value = 0;
		outlineYBox.value = 0;
		targetPercent = 0;
		if (com.outIndex != null) {
			var out = data.components[com.outIndex];
			outlineBox.label.text = out.anim;
			outlineXBox.value = out.x;
			outlineYBox.value = out.y;
			targetPercent = 1;
		}

		for (item in members) {
			if (item is UISprite)
				cast(item, UISprite).selectable = true;
		}
		colorModeDrop.dropButton.selectable = true;
	}

	function valueSet(item:UINumericStepper, func:Dynamic, text:String) {
		@:privateAccess item.__onChange(text);
		func(item.value);
	}

	function get_compon() {
		return AlphabetEditor.instance.curSelectedComponent;
	}
	function get_data() {
		return AlphabetEditor.instance.curSelectedData;
	}
}