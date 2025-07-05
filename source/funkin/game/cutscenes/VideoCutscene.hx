package funkin.game.cutscenes;

import flixel.util.FlxColor;
import haxe.io.Path;
import flixel.addons.display.FlxBackdrop;
#if sys
import sys.io.File;
#end
import funkin.backend.FunkinText;
import haxe.io.FPHelper;
import haxe.xml.Access;
import haxe.Int64;
import flixel.util.FlxTimer;
#if VIDEO_CUTSCENES
import hxvlc.flixel.FlxVideo;
#end

/**
 * Substate made for video cutscenes. To use it in a scripted cutscene, call `startVideo`.
 */
class VideoCutscene extends Cutscene {
	private static var curVideo:Int = 0; // internal for zip videos
	var path:String;
	var localPath:String;

	#if VIDEO_CUTSCENES
	var video:FlxVideo;
	public var skippable:Bool = true;
	#end
	var cutsceneCamera:FlxCamera;

	var text:FunkinText;
	var loadingBackdrop:FlxBackdrop;
	var videoReady:Bool = false;

	var bg:FlxSprite;
	var subtitle:FunkinText;

	public var subtitles:Array<CutsceneSubtitle> = [];

	public function new(path:String, callback:Void->Void) {
		super(callback);
		localPath = Assets.getPath(this.path = path);
	}

	public override function create() {
		super.create();

		// TODO: get vlc to stop autoloading those goddamn subtitles (use different file ext??)

		cutsceneCamera = new FlxCamera();
		cutsceneCamera.bgColor = 0;
		FlxG.cameras.add(cutsceneCamera, false);

		#if VIDEO_CUTSCENES
		parseSubtitles();

		video = new FlxVideo();
		video.onEndReached.add(function()
		{
			video.dispose();
			FlxG.removeChild(video);
		});
		video.onEndReached.add(close);
		FlxG.addChildBelowMouse(video);

		//cover = new FlxSprite(0, FlxG.height * 0.85).makeSolid(FlxG.width + 50, FlxG.height + 50, 0xFF000000);
		//cover.scrollFactor.set(0, 0);
		//cover.screenCenter();
		//add(cover);

		bg = new FlxSprite(0, FlxG.height * 0.85).makeGraphic(1, 1, 0xFF000000);
		bg.alpha = 0.5;
		bg.visible = false;

		subtitle = new FunkinText(0, FlxG.height * 0.875, 0, "", 20);
		subtitle.alignment = CENTER;
		subtitle.visible = false;

		if (localPath.startsWith("[ZIP]")) {
			text = new FunkinText(10, 10, Std.int(FlxG.width / 2), "Loading video...");
			text.cameras = [cutsceneCamera];
			text.visible = false;
			@:privateAccess
			text.regenGraphic();
			add(text);

			loadingBackdrop = new FlxBackdrop(text.graphic, X);
			loadingBackdrop.y = FlxG.height - 20 - loadingBackdrop.height;
			loadingBackdrop.cameras = [cutsceneCamera];
			add(loadingBackdrop);

			// ZIP PATH: EXPORT
			// TODO: this but better and more ram friendly
			localPath = './.temp/video-${curVideo++}.mp4';
			Main.execAsync(function() {
				File.saveBytes(localPath, Assets.getBytes(path));
				videoReady = true;
			});
		} else {
			if (video.load(localPath))
				new FlxTimer().start(0.001, function(tmr:FlxTimer) {
					video.play();
				});
			else
				close();
		}
		add(bg);
		add(subtitle);
		#end

		cameras = [cutsceneCamera];
	}

	public function parseSubtitles() {
		var subtitlesPath = '${Path.withoutExtension(path)}.srt';

		if (Assets.exists(subtitlesPath)) {
			var text = Assets.getText('$subtitlesPath').split("\n");
			while(text.length > 0) {
				var head = text.shift();
				if (head == null || head.trim() == "")
					continue; // no head (EOF or empty line), skipping
				if (Std.parseInt(head) == null)
					continue; // invalid index, skipping

				var id = head;
				var time = text.shift();
				if (time == null) continue; // no time (EOF), skipping
				var arrowIndex = time.indexOf('-->');
				if (arrowIndex < 0) continue; // no -->, skipping
				var beginTime = splitTime(time.substr(0, arrowIndex).trim());
				var endTime = splitTime(time.substr(arrowIndex + 3).trim());
				if (beginTime < 0 || endTime < 0) continue; // invalid timestamps

				var subtitleText:Array<String> = [];
				var t:String = text.shift();
				while(t != null && t.trim() != "") {
					subtitleText.push(t);
					t = text.shift();
				}
				if (subtitleText.length <= 0) continue; // empty subtitle, skipping
				var lastSub = subtitles.last();
				if (lastSub != null && lastSub.subtitle == "" && lastSub.time > beginTime)
					subtitles.pop(); // remove last subtitle auto reset to prevent bugs
				subtitles.push({
					subtitle: subtitleText.join("."),
					time: beginTime * 1000,
					color: 0xFFFFFFFF // todo
				});
				subtitles.push({
					subtitle: "",
					time: endTime * 1000,
					color: 0xFFFFFFFF
				});
			}
		}

		trace(subtitles);
	}

	public static function splitTime(str:String):Float {
		if (str == null || str.trim() == "") return -1;
		var multipliers:Array<Float> = [1, 60, 3600, 86400]; // no way a cutscene will last longer than days
		var timeSplit:Array<Null<Float>> = [for(e in str.split(":")) Std.parseFloat(e.replace(",", "."))];
		var time:Float = 0;

		for(k=>i in timeSplit) {
			var mul = multipliers[timeSplit.length - 1 - k];
			if (i != null)
				time += i * mul;
		}
		return time;
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		#if VIDEO_CUTSCENES
		if (videoReady) {
			videoReady = false;

			if (video.load(localPath))
				new FlxTimer().start(0.001, function(tmr:FlxTimer) {
					video.play();
				});
			else
			{
				close();

				if (loadingBackdrop != null)
					loadingBackdrop.visible = false;

				return;
			}

			if (loadingBackdrop != null)
				loadingBackdrop.visible = false;
		}
		@:privateAccess
		var time:Int64 = video.time;

		while (subtitles.length > 0 && subtitles[0].time < Math.round(FPHelper.i64ToDouble(time.low, time.high)))
			setSubtitle(subtitles.shift());

		if (loadingBackdrop != null) {
			loadingBackdrop.x -= elapsed * FlxG.width * 0.5;
		}
		if (skippable && video.isPlaying && controls.ACCEPT) {
			video.onEndReached.dispatch();
		}
		#else
		close();
		#end
	}

	public function setSubtitle(sub:CutsceneSubtitle) {
		if (bg.visible = subtitle.visible = (sub.subtitle.length > 0)) {
			subtitle.text = sub.subtitle;
			subtitle.color = sub.color;
			subtitle.screenCenter(X);
			bg.scale.set(subtitle.width + 8, subtitle.height + 8);
			bg.updateHitbox();
			bg.setPosition(subtitle.x - 4, subtitle.y - 4);
		}
	}

	public override function destroy() {
		FlxG.cameras.remove(cutsceneCamera, true);
		super.destroy();
	}
}

typedef CutsceneSubtitle = {
	var time:Float; // time in ms
	var subtitle:String; // subtitle text
	var color:FlxColor;
}
