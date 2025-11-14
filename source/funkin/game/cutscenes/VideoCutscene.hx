package funkin.game.cutscenes;

import flixel.tweens.FlxTween;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.backend.FunkinText;
import haxe.Int64;
import haxe.io.FPHelper;
import haxe.io.Path;
import haxe.xml.Access;
#if sys
import sys.io.File;
#end
#if VIDEO_CUTSCENES
import hxvlc.flixel.FlxVideoSprite;
#end

/**
 * Substate made for video cutscenes. To use it in a scripted cutscene, call `startVideo`.
 */
class VideoCutscene extends Cutscene {
	private static var curVideo:Int = 0; // internal for zip videos
	var path:String;
	var localPath:String;

	#if VIDEO_CUTSCENES
	var video:FlxVideoSprite;
	final mutex = new sys.thread.Mutex();

	var cutsceneCamera:FlxCamera;

	var text:FunkinText;
	var loadingBackdrop:FlxBackdrop;
	private var __loaded:Bool = false;

	var bg:FlxSprite;
	var subtitle:FunkinText;

	public var subtitles:Array<CutsceneSubtitle> = [];
	var curSubtitle:Int = 0;
	#end

	public function new(path:String, callback:Void->Void) {
		super(callback, false);
		localPath = Assets.getPath(this.path = path);
	}

	public override function create() {
		super.create();

		// TODO: get vlc to stop autoloading those goddamn subtitles (use different file ext??)

		#if VIDEO_CUTSCENES
		cutsceneCamera = new FlxCamera();
		cutsceneCamera.bgColor = 0;
		FlxG.cameras.add(cutsceneCamera, false);

		parseSubtitles();

		add(video = new FlxVideoSprite());
		video.antialiasing = true;
		#if (hxvlc < version("2.0.0"))
		video.autoPause = false;  // Imma handle it better inside this class, mainly because of the pause menu  - Nex
		#else
		video.bitmap.onOpening.add(function() @:privateAccess {
			#if (hxvlc < version("2.1.0"))
			final onFocusGained = video.onFocusGained;
			final onFocusLost = video.onFocusLost;
			#else
			final onFocusGained = video.bitmap.onFocusGained;
			final onFocusLost = video.bitmap.onFocusLost;
			#end

			if (FlxG.signals.focusGained.has(onFocusGained))
				FlxG.signals.focusGained.remove(onFocusGained);
			if (FlxG.signals.focusLost.has(onFocusLost))
				FlxG.signals.focusLost.remove(onFocusLost);
		});
		#end
		video.bitmap.onEndReached.add(close);
		video.bitmap.onFormatSetup.add(function() if (video.bitmap != null && video.bitmap.bitmapData != null) {
			final width = video.bitmap.bitmapData.width;
			final height = video.bitmap.bitmapData.height;
			final scale:Float = Math.min(FlxG.width / width, FlxG.height / height);
			video.setGraphicSize(Std.int(width * scale), Std.int(height * scale));
			video.updateHitbox();
			video.screenCenter();
		});

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

		text = new FunkinText(10, 10, Std.int(FlxG.width / 2), "Loading video...");
		text.cameras = [cutsceneCamera];
		text.visible = false;
		@:privateAccess
		text.regenGraphic();
		add(text);

		loadingBackdrop = new FlxBackdrop(text.graphic, X);
		loadingBackdrop.y = FlxG.height - 20 - loadingBackdrop.height;
		loadingBackdrop.velocity.x = 70;
		loadingBackdrop.cameras = [cutsceneCamera];
		add(loadingBackdrop);

		loadingBackdrop.alpha = 0;
		FlxTween.tween(loadingBackdrop, {alpha: 1}, 0.5, {ease: FlxEase.sineInOut});

		Main.execAsync(function() {
			if (localPath.startsWith("[ZIP]")) {
				// ZIP PATH: EXPORT
				// TODO: this but better and more ram friendly
				localPath = './.temp/video-${curVideo++}.mp4';
				File.saveBytes(localPath, Assets.getBytes(path));
			}

			if (video.load(localPath)) new FlxTimer().start(0.001, function(_) { mutex.acquire(); onReady(); mutex.release(); });
			else { mutex.acquire(); close(); mutex.release(); }
		});

		add(bg);
		add(subtitle);

		cameras = [cutsceneCamera];
		#else
		close();
		#end
	}

	#if VIDEO_CUTSCENES
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
				if (lastSub != null && lastSub.subtitle == "" && lastSub.time >= beginTime)
					subtitles.pop(); // remove last subtitle auto reset to prevent bugs
				subtitles.push({
					subtitle: subtitleText.join(""),
					time: beginTime * 1000
				});
				subtitles.push({
					subtitle: "",
					time: endTime * 1000
				});
			}
		}
	}

	public static function splitTime(str:String):Float {
		if (str == null || str.trim() == "") return -1;
		var multipliers:Array<Float> = [1, 60, 3600, 86400, 31536000]; // no way a cutscene will last longer than years
		var timeSplit:Array<Null<Float>> = [for(e in str.split(":")) Std.parseFloat(e.replace(",", "."))];
		var time:Float = 0;

		for(k=>i in timeSplit) {
			var mul = multipliers[timeSplit.length - 1 - k];
			if (i != null)
				time += i * mul;
		}
		return time;
	}

	public inline function onReady() {
		FlxTween.cancelTweensOf(loadingBackdrop);
		FlxTween.tween(loadingBackdrop, {alpha: 0}, 0.7, {ease: FlxEase.sineInOut, onComplete: function(_) {
			loadingBackdrop.destroy();
			text.destroy();
		}});

		pausable = __loaded = true;
		video.play();
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		if(loadingBackdrop != null) return;

		@:privateAccess
		var time:Int64 = video.bitmap.time;
		var time:Float = FPHelper.i64ToDouble(time.low, time.high);

		if(curSubtitle < subtitles.length && subtitles[curSubtitle].time < time) {
			setSubtitle(subtitles[curSubtitle]);
			curSubtitle++;
		}
	}

	@:dox(hide) override public function onFocus() {
		if(FlxG.autoPause && !paused) video.resume();
		super.onFocus();
	}

	@:dox(hide) override public function onFocusLost() {
		if(FlxG.autoPause && !paused) video.pause();
		super.onFocusLost();
	}

	public override function pauseCutscene() {
		video.pause();
		super.pauseCutscene();
	}

	public override function onResumeCutscene(event) {
		video.resume();
		super.onResumeCutscene(event);
	}

	public override function onRestartCutscene(event) {
		closeSubState();
		video.bitmap.position = curSubtitle = 0;
		setSubtitle({time: -1, subtitle: ""});
		video.resume();
	}

	public function setSubtitle(sub:CutsceneSubtitle) {
		if (bg.visible = subtitle.visible = (sub.subtitle.length > 0)) {
			subtitle.text = sub.subtitle;
			subtitle.screenCenter(X);
			bg.scale.set(subtitle.width + 8, subtitle.height + 8);
			bg.updateHitbox();
			bg.setPosition(subtitle.x - 4, subtitle.y - 4);
		}
	}

	public override function destroy() {
		FlxG.cameras.remove(cutsceneCamera, true);
		video.destroy();
		super.destroy();
	}
	#end
}

typedef CutsceneSubtitle = {
	var time:Float; // time in ms
	var subtitle:String; // subtitle text
}
