package funkin.options.categories;

class MobileOptions extends TreeMenuScreen {
	public function new() {
		super('optionsTree.mobile-name', 'optionsTree.mobile-desc', 'MobileOptions.');

		add(new Checkbox(getNameID('controls'), getDescID('controls'), 'touchControls'));
		add(new ArrayOption(getNameID('layout'), getDescID('layout'),
			['hitbox', 'buttons', 'arrows', 'dpad'],
			['MobileOptions.layout-hitbox', 'MobileOptions.layout-buttons', 'MobileOptions.layout-arrows', 'MobileOptions.layout-dpad'],
			'touchSongLayout'));
		add(new ArrayOption(getNameID('buttonScroll'), getDescID('buttonScroll'),
			['downscroll', 'upscroll'],
			['MobileOptions.buttonScroll-down', 'MobileOptions.buttonScroll-up'],
			'touchButtonScroll'));
		add(new Checkbox(getNameID('middlescroll'), getDescID('middlescroll'), 'middlescroll'));
		add(new Checkbox(getNameID('controlsInMenus'), getDescID('controlsInMenus'), 'touchMenuPad'));
		add(new Checkbox(getNameID('gestures'), getDescID('gestures'), 'touchGestures'));
		add(new Checkbox(getNameID('haptics'), getDescID('haptics'), 'touchHaptics'));
		add(new Checkbox(getNameID('movePad'), getDescID('movePad'), 'touchMovePad'));

		add(new Separator());
		add(new SliderOption(getNameID('hitboxOpacity'), getDescID('hitboxOpacity'), 0, 1, 0.05, 10, 'touchHitboxAlpha'));
		add(new SliderOption(getNameID('opacity'), getDescID('opacity'), 0.1, 1, 0.05, 9, 'touchButtonAlpha'));
		add(new SliderOption(getNameID('scale'), getDescID('scale'), 0.6, 1.6, 0.05, 10, 'touchScale'));
		add(new SliderOption(getNameID('padX'), getDescID('padX'), 0.05, 0.95, 0.05, 9, 'touchPadX'));
		add(new SliderOption(getNameID('padY'), getDescID('padY'), 0.05, 0.95, 0.05, 9, 'touchPadY'));
		add(new NumOption(getNameID('safeInset'), getDescID('safeInset'), 0, 96, 4, 'touchSafeInset'));

		add(new Separator());
		add(new Checkbox(getNameID('fillScreen'), getDescID('fillScreen'), 'touchFillScreen', () -> Options.applySettings()));
		add(new Checkbox(getNameID('optimize'), getDescID('optimize'), 'mobileOptimize', () -> Options.applySettings()));
	}
}
