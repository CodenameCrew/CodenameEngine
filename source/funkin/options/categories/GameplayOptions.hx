package funkin.options.categories;

import flixel.util.FlxTimer;
import funkin.backend.system.Conductor;

class GameplayOptions extends OptionsScreen {
	var __metronome = FlxG.sound.load(Paths.sound('editors/charter/metronome'));

	var offsetSetting:NumOption;

	public override function new() {
		super("Gameplay", 'Change Gameplay options such as Downscroll, Scroll Speed, Naughtyness...', null, 'LEFT_FULL', 'A_B');
		add(new Checkbox(
			"Downscroll",
			"If checked, notes will go from up to down instead of down to up, as if they're falling.",
			"downscroll"));
		add(new Checkbox(
			"Ghost Tapping",
			"If unchecked, trying to hit any strum that have no note that can be hit will cause a miss.",
			"ghostTapping"));
		add(offsetSetting = new NumOption(
			"Song Offset",
			"Changes the offset that songs should start with.",
			-999, // minimum
			999, // maximum
			1, // change
			"songOffset", // save name or smth
			__changeOffset)); // callback
		add(new Checkbox(
			"Naughtyness",
			"If unchecked, will censor the Week 7 cutscenes.",
			"naughtyness"));
		add(new Checkbox(
			"Camera Zoom on Beat",
			"If unchecked, will stop the camera from zooming in every 4 beats",
			"camZoomOnBeat"));
	}

	private function __changeOffset(offset)
		Conductor.songOffset = offset;

	var __lastBeat:Int = 0;
	var __lastSongBeat:Int = 0;

	override function update(elapsed) {
		super.update(elapsed);
		FlxG.camera.zoom = CoolUtil.fpsLerp(FlxG.camera.zoom, 1, 0.04);

		if (offsetSetting.selected) {
			FlxG.sound.music.volume = 0.5;
			if (__lastBeat != Conductor.curBeat) {
				FlxG.camera.zoom += 0.03;
				__lastBeat = Conductor.curBeat;
			}

			var beat = Math.floor(Conductor.getStepForTime(FlxG.sound.music.time) / Conductor.stepsPerBeat);
			if (__lastSongBeat != beat) {
				__metronome.replay();
				__lastSongBeat = beat;
			}
		}
		else FlxG.sound.music.volume = 1;
	}

	public override function close() {
		// To remove this timer move super.update(elapsed); to the end, but im afraid it will cause stuff to break
		new FlxTimer().start(0.0000001, (_) -> {
			FlxG.camera.zoom = 1;
			FlxG.sound.music.volume = 1;
		});
		super.close();
	}
}