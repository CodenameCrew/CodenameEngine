package funkin.options.categories;

import funkin.backend.system.framerate.Framerate;

class AppearanceOptions extends TreeMenuScreen {
	var debugOption:TextOption;
	var lastFPSDebugMode:Int = 1; 

	public function new() {
		super('optionsTree.appearance-name', 'optionsTree.appearance-desc', 'AppearanceOptions.');

		add(new NumOption(getNameID('framerate'), getDescID('framerate'),
			30, 240, 1,
			'framerate', __changeFPS
		));
		add(new Checkbox(getNameID('fpsCounter'), getDescID('fpsCounter'), 'fpsCounter', __changeFPSCounter));
		add(new Checkbox(getNameID('flashingMenu'), getDescID('flashingMenu'), 'flashingMenu'));
		add(new Checkbox(getNameID('colorHealthBar'), getDescID('colorHealthBar'), 'colorHealthBar'));
		add(new Checkbox(getNameID('week6PixelPerfect'), getDescID('week6PixelPerfect'), 'week6PixelPerfect'));

		add(new Separator());
		add(new TextOption('optionsMenu.advanced', 'optionsTree.appearance.advanced-desc', ' >', () ->
			parent.addMenu(new AdvancedAppearanceOptions())));

		__changeFPSCounter();
	}

	private function __changeFPS(value:Float) {
		var framerate = Math.floor(value);
		if (FlxG.updateFramerate < framerate) FlxG.drawFramerate = FlxG.updateFramerate = framerate;
		else FlxG.updateFramerate = FlxG.drawFramerate = framerate;
	}

	private function __changeFPSCounter() {
		if (Framerate.debugMode != 0) lastFPSDebugMode = Framerate.debugMode;
		Framerate.debugMode = Options.fpsCounter ? (lastFPSDebugMode ?? 1) : 0;
		
		if (Options.fpsCounter) {
			if (debugOption == null) {
				insert(2, debugOption = new TextOption(getNameID('fpsAdvanced'), getDescID('fpsAdvanced'), ' >', () -> parent.addMenu(new FramerateAppearanceOptions())));
			}
		} else if (debugOption != null) {
			remove(debugOption, true);
			debugOption = flixel.util.FlxDestroyUtil.destroy(debugOption);
			if (curSelected >= length) changeSelection(0, true);
		}
	}
}

class AdvancedAppearanceOptions extends TreeMenuScreen {
	var qualityOptions:Array<OptionType> = [];

	public function new() {
		super('optionsMenu.advanced', 'optionsTree.appearance.advanced-desc', 'AppearanceOptions.Advanced.');

		add(new ArrayOption(getNameID('quality'), getDescID('quality'),
			[0, 1, 2], [getID('quality-low'), getID('quality-high'), getID('quality-custom')],
			'quality', __changeQuality, null
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

class FramerateAppearanceOptions extends TreeMenuScreen {
	public function new() {
		super('optionsMenu.advanced', 'optionsTree.appearance.advanced-desc', 'AppearanceOptions.Advanced.');

		// add(new Checkbox("other fps counter stuff idk", "we all lowkey eat poop", ''));

		// add(new Separator());
		add(new Checkbox(getNameID('fpsCounterConductor'), getDescID('fpsCounterConductor'), 'fpsCounterConductor', () -> Framerate.conductorInfo.visible = Options.fpsCounterConductor));
		add(new Checkbox(getNameID('fpsCounterFlixel'), getDescID('fpsCounterFlixel'), 'fpsCounterFlixel', () -> Framerate.flixelInfo.visible = Options.fpsCounterFlixel));
		add(new Checkbox(getNameID('fpsCounterSystem'), getDescID('fpsCounterSystem'), 'fpsCounterSystem', () -> Framerate.systemInfo.visible = Options.fpsCounterSystem));
		add(new Checkbox(getNameID('fpsCounterAssets'), getDescID('fpsCounterAssets'), 'fpsCounterAssets', () -> Framerate.assetInfo.visible = Options.fpsCounterAssets));
		#if (gl_stats && !disable_cffi && (!html5 || !canvas))
		add(new Checkbox(getNameID('fpsCounterStats'), getDescID('fpsCounterStats'), 'fpsCounterStats', () -> Framerate.statsInfo.visible = Options.fpsCounterStats));
		#end
	}
}
