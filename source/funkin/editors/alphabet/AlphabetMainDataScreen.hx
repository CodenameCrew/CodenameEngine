package funkin.editors.alphabet;

import flixel.math.FlxRect;
import funkin.editors.alphabet.AlphabetEditor;
import funkin.menus.ui.Alphabet;

using StringTools;

// TODO: add translations
class AlphabetMainDataScreen extends UISubstateWindow {
	var bigLetter:Alphabet;
	var tape:Alphabet;

	public var saveButton:UIButton;
	public var closeButton:UIButton;
	public var helpButton:UIButton;

	public var fpsStepper:UINumericStepper;
	public var advanceStepper:UINumericStepper;
	public var lineGapStepper:UINumericStepper;

	public var caseDropdown:UIDropDown;
	public var colorDropdown:UIDropDown;

	public var regTextBox:UITextBox;
	public var upperTextBox:UITextBox;
	public var lowerTextBox:UITextBox;

	public var targetPercent:Float = 0.0;
	public var helpBG:UISliceSprite;
	public var helpTxt:UIText;
	public var helpScroll:UIScrollBar;

	public override function create() {
		bigLetter = AlphabetEditor.instance.bigLetter;
		tape = AlphabetEditor.instance.tape;

		// temporary until translated
		var helpDesc = 
"FPS - Frames per second. You get it.
Advance - Actually a backup advance value for missing characters and spaces.
Line Gap - How many pixels to move down when a new line is created.

Force Casing - Whether to force the text casing to uppercase, lowercase, or neither.
Color Mode - How to color the alphabet.
TINT muliplies the channels, perfect for white letters.
OFFSETS adds to the channels, perfect for black letters.
NONE simply disables coloring.

Backup Prefixes - What prefix to use if a glyph is not predefined.
Uppercase and Lowercase will default to regular if it is left blank.
LETTER will be substituted with the provided glyph.
UPPERLETTER will be substituted with the uppercase glyph.
LOWERLETTER will be substituted with the lowercase glyph.
UPPERLETTER and LOWERLETTTER can be used in any backup prefix.";

		winTitle = "Alphabet Properties";
		winWidth = 420; winHeight = 520;

		super.create();

		function addLabelOn(ui:UISprite, text:String)
			add(new UIText(ui.x, ui.y - 24, 0, text));

		var title:UIText;
		add(title = new UIText(windowSpr.x + 20, windowSpr.y + 30 + 16, 0, "Edit Main Alphabet Data", 28));

		fpsStepper = new UINumericStepper(title.x, title.y + title.height + 38, AlphabetEditor.instance.bigLetter.fps, 1, 2, 0.01, null, 120);
		add(fpsStepper);
		addLabelOn(fpsStepper, "FPS");

		advanceStepper = new UINumericStepper(fpsStepper.x + 140, fpsStepper.y, AlphabetEditor.instance.bigLetter.defaultAdvance, 1, 2, 0, null, 120);
		add(advanceStepper);
		addLabelOn(advanceStepper, "Advance");

		lineGapStepper = new UINumericStepper(advanceStepper.x + 140, advanceStepper.y, AlphabetEditor.instance.bigLetter.lineGap, 1, 2, 0, null, 120);
		add(lineGapStepper);
		addLabelOn(lineGapStepper, "Line Gap");

		caseDropdown = new UIDropDown(fpsStepper.x, fpsStepper.y + fpsStepper.bHeight + 50, 206, 32, ["NONE", "UPPER", "LOWER"], tape.forceCase);
		add(caseDropdown);
		addLabelOn(caseDropdown, "Force Casing");

		colorDropdown = new UIDropDown(caseDropdown.x + caseDropdown.bWidth + 20, caseDropdown.y, 206, 32, ["TINT", "OFFSETS", "NONE"], tape.colorMode);
		add(colorDropdown);
		addLabelOn(colorDropdown, "Color Mode");

		var regPrefix = (tape.defaults[0] != null) ? tape.defaults[0].components[0].anim : "";
		regTextBox = new UITextBox(caseDropdown.x, caseDropdown.y + caseDropdown.bHeight + 50, regPrefix, 368);
		add(regTextBox);
		addLabelOn(regTextBox, "Backup Prefix (Regular)");

		var upperPrefix = (tape.defaults[1] != null) ? tape.defaults[1].components[0].anim : "";
		upperTextBox = new UITextBox(regTextBox.x, regTextBox.y + regTextBox.bHeight + 35, upperPrefix, 368);
		add(upperTextBox);
		addLabelOn(upperTextBox, "Backup Prefix (Uppercase)");

		var lowerPrefix = (tape.defaults[2] != null) ? tape.defaults[2].components[0].anim : "";
		lowerTextBox = new UITextBox(upperTextBox.x, upperTextBox.y + upperTextBox.bHeight + 35, lowerPrefix, 368);
		add(lowerTextBox);
		addLabelOn(lowerTextBox, "Backup Prefix (Lowercase)");

		saveButton = new UIButton(windowSpr.x + windowSpr.bWidth - 20 - 125, windowSpr.y + windowSpr.bHeight - 16 - 32, TU.translate("editor.saveClose"), function() {
			saveInfo();
			close();
		}, 125);
		add(saveButton);

		closeButton = new UIButton(saveButton.x - 20, saveButton.y, TU.translate("editor.close"), function() {
			close();
		}, 125);
		add(closeButton);
		closeButton.color = 0xFFFF0000;
		closeButton.x -= closeButton.bWidth;

		helpButton = new UIButton(closeButton.x - 20, closeButton.y, "?", function() {
			targetPercent = 1.0 - targetPercent;
		}, 32);
		add(helpButton);
		helpButton.x -= helpButton.bWidth;

		helpBG = new UISliceSprite(windowSpr.x + windowSpr.bWidth - 20, windowSpr.y, 340, windowSpr.bHeight, 'editors/ui/context-bg');
		helpBG.alpha = 0.0;
		add(helpBG);

		helpTxt = new UIText(helpBG.x + 20, helpBG.y + 20, helpBG.bWidth - 60, helpDesc);
		helpTxt.clipRect = new FlxRect(0, 0, helpTxt.width, helpBG.bHeight - 40);
		helpTxt.alpha = 0.0;
		add(helpTxt);

		helpScroll = new UIScrollBar(helpBG.x + helpBG.bWidth - 30, helpBG.y + 20, (helpTxt.height - helpTxt.clipRect.height), 0, (helpTxt.clipRect.height / helpTxt.height), 20, helpBG.bHeight - 40);
		helpScroll.size *= helpScroll.height;
		helpScroll.start -= helpScroll.size * 0.5;
		helpScroll.alpha = 0.0;
		helpScroll.onChange = function(v) {
			helpTxt.clipRect.y = v;
			helpTxt.offset.y = v;
			helpTxt.clipRect = helpTxt.clipRect;
			helpScroll.start = v - helpScroll.size * 0.5;
		}
		add(helpScroll);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		helpBG.alpha = FlxMath.lerp(helpBG.alpha, targetPercent, elapsed * 15);
		helpBG.x = windowSpr.x + windowSpr.bWidth - 20 + 40 * helpBG.alpha;
		helpTxt.alpha = helpBG.alpha;
		helpTxt.x = helpBG.x + 20;
		helpScroll.alpha = helpScroll.thumb.alpha = helpScroll.thumbIcon.alpha = helpBG.alpha;
		helpScroll.x = helpBG.x + helpBG.bWidth - 30;
	}

	public function saveInfo() {
		@:privateAccess fpsStepper.__onChange(fpsStepper.label.text);
		@:privateAccess advanceStepper.__onChange(advanceStepper.label.text);
		@:privateAccess lineGapStepper.__onChange(lineGapStepper.label.text);

		bigLetter.fps = tape.fps = fpsStepper.value;
		bigLetter.defaultAdvance = tape.defaultAdvance = advanceStepper.value;
		bigLetter.lineGap = tape.lineGap = lineGapStepper.value;

		bigLetter.forceCase = tape.forceCase = caseDropdown.index;
		bigLetter.colorMode = tape.colorMode = colorDropdown.index;

		// give the letter loading another chance
		tape.animation.destroyAnimations();
		bigLetter.animation.destroyAnimations();
		tape.failedLetters.splice(1, tape.failedLetters.length - 1);

		setDefault(0, regTextBox.label.text);
		setDefault(1, upperTextBox.label.text);
		setDefault(2, lowerTextBox.label.text);
	}

	function setDefault(index:Int, name:String) {
		tape.loaded[index].splice(0, tape.loaded[index].length);
		if (name.trim() == "") {
			tape.defaults[index] = null;
			return;
		}

		if (tape.defaults[index] != null) {
			tape.defaults[index].components[0].anim = name;
			trace(tape.defaults[index].components[0].anim);
			return;
		}

		final newData:AlphabetLetterData = {
			isDefault: true,
			advance: 0.0,
			advanceEmpty: true,
			components: [{
				anim: name,

				x: 0.0,
				y: 0.0,
				scaleX: 1.0,
				scaleY: 1.0,

				shouldRotate: false,
				angle: 0.0,
				cos: 1.0,
				sin: 0.0,

				hasColorMode: false,
				colorMode: 0
			}],
			startIndex: 0
		};
		tape.defaults[index] = newData;
	}
}