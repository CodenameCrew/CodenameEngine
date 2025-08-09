package funkin.backend.system.modules;

import flixel.FlxState;
import flixel.sound.FlxSound;
import funkin.backend.utils.NativeAPI;
import lime.media.AudioManager;
import lime.media.AudioSource;
import haxe.Timer;

/**
 * if you are stealing this keep this comment at least please lol
 *
 * hi gray itsa me yoshicrafter29 i fixed it hehe
 */
@:dox(hide)
class AudioSwitchFix {
	public static function onAudioDisconnected() @:privateAccess {
		var sources:Array<{source:AudioSource, playing:Bool, time:Float, gain:Float, pitch:Float, position:lime.math.Vector4}> = [];
		for (source in AudioSource.activeSources) {
			var wasPlaying = source.playing;
			sources.push({
				source: source,
				playing: wasPlaying,
				time: source.currentTime,
				gain: source.gain,
				pitch: source.pitch,
				position: source.position
			});

			source.__backend.dispose();
			if (wasPlaying) source.__backend.playing = true;
		}

		AudioManager.shutdown();
		AudioManager.init();
		// #if !lime_doc_gen
		// if (AudioManager.context.type == OPENAL)
		// {
		// 	var alc = AudioManager.context.openal;

		// 	var device = alc.openDevice();
		// 	var ctx = alc.createContext(device);
		// 	alc.makeContextCurrent(ctx);
		// 	alc.processContext(ctx);
		// }
		// #end
		
		for (d in sources) {
			d.source.__backend.init();
			d.source.currentTime = d.time;
			d.source.gain = d.gain;
			d.source.pitch = d.pitch;
			d.source.position = d.position;

			if (d.playing) d.source.play();
		}

		Main.changeID++;
		Main.audioDisconnected = false;
	}

	private static var timer:Timer;

	private static function onRun() if (Main.audioDisconnected) onAudioDisconnected();
	public static function init() {
		NativeAPI.registerAudio();
		if (timer == null) (timer = new Timer(1000)).run = onRun;
	}
}