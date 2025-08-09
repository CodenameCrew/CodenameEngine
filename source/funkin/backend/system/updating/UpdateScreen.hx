package funkin.backend.system.updating;

import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.ui.FlxBar;
import funkin.backend.FunkinText;
import funkin.backend.shaders.CustomShader;
import funkin.backend.system.updating.UpdateUtil.UpdateCheckCallback;
import funkin.menus.TitleState;

class UpdateScreen extends MusicBeatState {
	public var updater:AsyncUpdater;

	public var progressBar:FlxBar;
	public var bf:FlxSprite;

	public var done:Bool = false;
	public var elapsedTime:Float = 0;
	public var lerpSpeed:Float = 0;
	public var overSound:FlxSound;

	public var generalProgress:FunkinText;
	public var partProgress:FunkinText;

	public var rainbowShader:CustomShader;

	public function new(check:UpdateCheckCallback) {
		super(false);
		updater = new AsyncUpdater(check.updates);
	}

	public override function create() {
		super.create();

		progressBar = new FlxBar(0, FlxG.height - 75, LEFT_TO_RIGHT, FlxG.width, 75);
		progressBar.createGradientBar([0xFF000000], [0xFF000000, 0xFF111111, 0xFF222222, 0xFF444444, 0xFF888888, -1], 1, 90);
		progressBar.setRange(0, 4);
		add(progressBar);

		bf = new FlxSprite();
		bf.antialiasing = true;
		bf.frames = Paths.getFrames("menus/update/bf");
		bf.animation.addByPrefix("loading", "", 0, false);
		bf.animation.addByPrefix("loading-anim", "", 24, false);
		bf.animation.play("loading");
		bf.screenCenter();
		add(bf);

		partProgress = new FunkinText(0, progressBar.y, FlxG.width, "-\n-", 20);
		partProgress.y -= partProgress.height;
		partProgress.alignment = CENTER;
		add(partProgress);

		generalProgress = new FunkinText(0, partProgress.y - 10, FlxG.width, "", 32);
		generalProgress.y -= generalProgress.height;
		generalProgress.alignment = CENTER;
		add(generalProgress);

		overSound = FlxG.sound.load(Paths.sound(Flags.DEFAULT_GAMEOVEREND_SOUND));

		updater.execute();

		FlxG.camera.addShader(rainbowShader = new CustomShader("engine/updaterShader"));

		DiscordUtil.call("onMenuLoaded", ["Update Screen"]);
	}


	public override function update(elapsed:Float) {
		super.update(elapsed);

		elapsedTime += elapsed;
		rainbowShader.hset("elapsed", elapsedTime / 3);
		rainbowShader.hset("strength", (elapsedTime >= 3) ? 1 : Math.sqrt(elapsedTime / 3));

		progressBar.y = FlxG.height - (65 + (Math.sin(elapsedTime * Math.PI / 2) * 10));

		if (done) return;

		var prog = updater.progress;
		lerpSpeed = lerp(lerpSpeed, prog.downloadSpeed, 0.0625);
		switch(prog.step) {
			case PREPARING:
				progressBar.value = 0;
				generalProgress.text = TU.translate("updateScreen.general-1") + " (1/4)";
				partProgress.text = TU.translate("updateScreen.part-1");
			case DOWNLOADING_ASSETS:
				progressBar.value = 1 + ((prog.curFile-1+(prog.bytesLoaded/prog.bytesTotal)) / prog.files);
				generalProgress.text = TU.translate("updateScreen.general-2") + " (2/4)";
				partProgress.text = TU.translate("updateScreen.part-2", [prog.curFileName]) + '\n(${prog.curFile+1}/${prog.files} | ${CoolUtil.getSizeString(prog.bytesLoaded)} / ${CoolUtil.getSizeString(prog.bytesTotal)} | ${CoolUtil.getSizeString(lerpSpeed)}/s)';
			case DOWNLOADING_EXECUTABLE:
				progressBar.value = 2 + (prog.bytesLoaded/prog.bytesTotal);
				generalProgress.text = TU.translate("updateScreen.general-3") + " (3/4)";
				partProgress.text = TU.translate("updateScreen.part-3", [prog.curFileName]) + '\n(${CoolUtil.getSizeString(prog.bytesLoaded)} / ${CoolUtil.getSizeString(prog.bytesTotal)} | ${CoolUtil.getSizeString(lerpSpeed)}/s)';
			case INSTALLING:
				progressBar.value = 3 + ((prog.curFile-1+(prog.curZipProgress.curFile/prog.curZipProgress.fileCount))/prog.files);
				generalProgress.text = TU.translate("updateScreen.general-4") + " (4/4)";
				partProgress.text = TU.translate("updateScreen.part-4", [prog.curFileName]) + '\n(${prog.curFile}/${prog.files})';
		}
		var rect = new FlxRect(0, (1 - (progressBar.value / 4)) * bf.frameHeight, bf.frameWidth, 0);
		rect.height = bf.frameHeight - rect.y;

		bf.clipRect = rect;
		bf.alpha = (progressBar.value / 4) * FlxG.random.float(0.70, 0.80);
		if (done = prog.done) {
			// update is done, play bf's anim
			FlxG.sound.music.stop();
			overSound.play();

			remove(generalProgress);
			remove(partProgress);
			generalProgress = FlxDestroyUtil.destroy(generalProgress);
			partProgress = FlxDestroyUtil.destroy(partProgress);

			bf.animation.curAnim.frameRate = 24;
			bf.animation.play("loading-anim", true, false, 1);
			bf.alpha = 1;

			FlxG.camera.fade(0xFF000000, overSound.length / 1000, false, function() {
				if (updater.executableReplaced) {
					#if windows
					// the executable has been replaced, restart the game entirely
					Sys.command('start /B ${AsyncUpdater.executableName}');
					#else
					// We have to make the new executable allowed to execute
					// before we can execute it!
					Sys.command('chmod +x ./${AsyncUpdater.executableName} && ./${AsyncUpdater.executableName}');
					#end
					openfl.system.System.exit(0);
				} else {
					// assets update, switch back to TitleState.
					FlxG.switchState(new TitleState());
				}
			});
			bf.clipRect = null;
		}
	}
}
