package funkin.options.categories;

class AppearanceOptions extends TreeMenuScreen {
	// use for changing the text
	var framerateOption:NumOption;
	var maxFrameRate:Int = 240;
	public function new() {
		super('optionsTree.appearance-name', 'optionsTree.appearance-desc', 'AppearanceOptions.');

		add(framerateOption = new NumOption(getNameID('framerate'), getDescID('framerate'),
			30, maxFrameRate + 1, 1,
			'framerate', __changeFPS
		));
		// fixes framerate dropping to 30 (minimum) when framerate is 0 (unlimited)
		if (framerateOption.currentValue == 0) {
			framerateOption.currentValue = maxFrameRate + 1;
			__changeFPS(framerateOption.currentValue);
		}
		add(new Checkbox(getNameID('flashingMenu'), getDescID('flashingMenu'), 'flashingMenu'));
		add(new Checkbox(getNameID('colorHealthBar'), getDescID('colorHealthBar'), 'colorHealthBar'));
		add(new Checkbox(getNameID('week6PixelPerfect'), getDescID('week6PixelPerfect'), 'week6PixelPerfect'));

		add(new Separator());
		add(new TextOption('optionsMenu.advanced', 'optionsTree.appearance.advanced-desc', ' >', () ->
			parent.addMenu(new AdvancedAppearanceOptions())));
	}

	private function __changeFPS(value:Float) {
		var framerate = Math.floor(value);
		@:privateAccess if (framerate > maxFrameRate) {
			// the reflect call from NumOption is before the changedCallback so i have to set it manually again
			Options.framerate = framerate = 0;
			framerateOption.__number.text = TextOption.OPTION_VALUE_PREFIX + translate('framerate-unlimited');
		}
		if (FlxG.updateFramerate < framerate) FlxG.drawFramerate = FlxG.updateFramerate = framerate;
		else FlxG.updateFramerate = FlxG.drawFramerate = framerate;
	}
}

class AdvancedAppearanceOptions extends TreeMenuScreen {
	var qualityOptions:Array<OptionType> = [];

	public function new() {
		super('optionsMenu.advanced', 'optionsTree.appearance.advanced-desc', 'AppearanceOptions.Advanced.');

		add(new ArrayOption(getNameID('quality'), getDescID('quality'),
			[0, 1, 2], [getID('quality-low'), getID('quality-high'), getID('quality-custom')],
			'quality', __changeQuality
		));

		for (option in (qualityOptions = [
			new Checkbox(getNameID('antialiasing'), getDescID('antialiasing'), 'antialiasing', __changeAntialiasing),
			new Checkbox(getNameID('lowMemoryMode'), getDescID('lowMemoryMode'), 'lowMemoryMode'),
			new Checkbox(getNameID('gameplayShaders'), getDescID('gameplayShaders'), 'gameplayShaders')
		])) 
			add(option);

		add(new Checkbox(getNameID('gpuOnlyBitmaps'), getDescID('gpuOnlyBitmaps'), 'gpuOnlyBitmaps'));

		updateQualityOptions();
	}

	private function updateQualityOptions() {
		for (option in qualityOptions) {
			option.locked = Options.quality != 2;
			if (option is Checkbox) {
				final checkbox:Checkbox = cast option;
				checkbox.checked = Reflect.field(checkbox.parent, checkbox.optionName);
			}
			else if (option is SliderOption) {
				final slider:SliderOption = cast option;
				slider.currentValue = Reflect.field(slider.parent, slider.optionName);
			}
			else if (option is NumOption) {
				final num:NumOption = cast option;
				num.currentValue = Reflect.field(num.parent, num.optionName);
			}
			else if (option is ArrayOption) {
				final array:ArrayOption = cast option;
				array.currentSelection = Reflect.field(array.parent, array.optionName);
			}
		}
	}

	private function __changeQuality(value:Dynamic) {
		Options.applyQuality();
		updateQualityOptions();
	}

	private function __changeAntialiasing() {
		FlxG.game.stage.quality = (FlxG.enableAntialiasing = Options.antialiasing) ? BEST : LOW;
	}
}
