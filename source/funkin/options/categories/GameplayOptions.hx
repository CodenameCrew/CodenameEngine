package funkin.options.categories;

import flixel.util.FlxTimer;
import funkin.backend.system.Conductor;

class GameplayOptions extends TreeMenuScreen {
	var __metronome = FlxG.sound.load(Paths.sound(Flags.DEFAULT_CHARTER_METRONOME_SOUND));
	var offsetSetting:NumOption;

	public function new() {
		super('optionsTree.gameplay-name', 'optionsTree.gameplay-desc', 'GameplayOptions.');

		add(new Checkbox(getNameID('downscroll'), getDescID('downscroll'), 'downscroll'));
		add(new Checkbox(getNameID('ghostTapping'), getDescID('ghostTapping'), 'ghostTapping'));
		add(new Checkbox(getNameID('naughtyness'), getDescID('naughtyness'), 'naughtyness'));
		add(new Checkbox(getNameID('camZoomOnBeat'), getDescID('camZoomOnBeat'), 'camZoomOnBeat'));
		add(new Checkbox(getNameID('autoPause'), getDescID('autoPause'), 'autoPause', __changeAutoPause));
		add(offsetSetting = new NumOption(getNameID('songOffset'), getDescID('songOffset'), -999, 999, 1, 'songOffset', __changeOffset));
		add(new SliderOption(getNameID('volumeMusic'), getDescID('volumeMusic'), 0, 1, 1, 5, 'volumeMusic', -1, __changeVolumeMusic));
		add(new SliderOption(getNameID('volumeSFX'), getDescID('volumeSFX'), 0, 1, 1, 5, 'volumeSFX'));

		add(new Separator());
		add(new TextOption('optionsMenu.advanced', 'optionsTree.gameplay.advanced-desc', ' >', () ->
			parent.addMenu(new AdvancedGameplayOptions())));
	}

	private function __changeAutoPause() FlxG.autoPause = Options.autoPause;
	private function __changeOffset(offset:Float) Conductor.songOffset = offset;
	private function __changeVolumeMusic(value:Float) FlxG.sound.defaultMusicGroup.volume = value;

	var __lastBeat:Int = 0;
	var __lastSongBeat:Int = 0;

	override function update(elapsed:Float) {
		super.update(elapsed);
		FlxG.camera.zoom = CoolUtil.fpsLerp(FlxG.camera.zoom, 1, 0.1);

		if (offsetSetting.selected) {
			if (__lastBeat != Conductor.curBeat) {
				FlxG.camera.zoom += 0.03;
				__lastBeat = Conductor.curBeat;
			}

			var beat = Math.floor(Conductor.getTimeInBeats(FlxG.sound.music.time));
			if (__lastSongBeat != beat) {
				__metronome.replay();
				__lastSongBeat = beat;
			}
		}
	}

	override function changeSelection(change:Int, force:Bool = false) {
		super.changeSelection(change, force);
		if (offsetSetting.selected) FlxG.sound.music.volume = 0.5;
		else FlxG.sound.music.volume = 1;
	}

	override function close() {
		super.close();

		FlxG.camera.zoom = 1;
		FlxG.sound.music.volume = 1;
	}
}

class AdvancedGameplayOptions extends TreeMenuScreen {
	public function new() {
		super('optionsMenu.advanced', 'optionsTree.gameplay.advanced-desc', 'GameplayOptions.Advanced.');

		add(new Checkbox(getNameID('streamedMusic'), getDescID('streamedMusic'), 'streamedMusic'));
		add(new Checkbox(getNameID('streamedVocals'), getDescID('streamedVocals'), 'streamedVocals'));
	}
}