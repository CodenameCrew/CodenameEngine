package funkin.editors.ui;

import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import openfl.media.Sound;

using flixel.util.FlxSpriteUtil;

class UIAudioPlayer extends UIButton {
	public var sound:FlxSound;
	public var bytes:Bytes;

	public var playingSprite:FlxSprite;
	public var timeText:UIText;

	public var timeBar:FlxBar;
	public var timeBarPlayer:FlxSprite;
	public var timeBarSpr:UISprite;

	public var volumeIcon:FlxSprite;
	public var volumeBar:FlxBar;
	public var volumeBarSpr:UISprite;

	public function new(x:Float, y:Float, bytes:Bytes) {
		sound = FlxG.sound.load(Sound.fromAudioBuffer(AudioBuffer.fromBytes(bytes)));

		super(x, y, null, () -> {
			if (sound.playing) sound.pause();
			else sound.play(sound.time + 1 >= sound.length ? 0 : sound.time);
		}, 58 - 16, 58 - 16);

		playingSprite = new FlxSprite(x + ((58 - 16)/2) - 8, y + ((58 - 16)/2) - 8).loadGraphic(Paths.image('editors/ui/audio-buttons'), true, 16, 16);
		playingSprite.animation.add("paused", [0]);
		playingSprite.animation.add("playing", [1]);
		playingSprite.antialiasing = false;
		playingSprite.updateHitbox();
		members.push(playingSprite);

		timeText = new UIText(x + bWidth + 8, y + 4, 0, "", 12);
		timeText.alignment = RIGHT;
		members.push(timeText);

		timeBar = new FlxBar(x + bWidth + 8, y + (58 - 16) - ((58 - 16)/3) - 4, LEFT_TO_RIGHT, 202, Std.int((58 - 16)/3), sound, "time", 0, sound.length);
		timeBar.createImageBar(Paths.image('editors/ui/audio-time-empty'), Paths.image('editors/ui/audio-time-full'));
		timeBar.numDivisions = timeBar.barWidth;
		timeBar.unbounded = true;
		members.push(timeBar);

		timeBarPlayer = new FlxSprite(timeBar.x, timeBar.y).loadGraphic(Paths.image('editors/ui/audio-time-empty'));
		timeBarPlayer.colorTransform.color = 0x440364;
		timeBarPlayer.scale.y = (timeBarPlayer.frameHeight + 2) / timeBarPlayer.frameHeight;
		timeBarPlayer.pixelPerfectRender = true;
		members.push(timeBarPlayer);

		timeBarSpr = cast new UISprite(timeBar.x, timeBar.y).makeSolid(timeBar.barWidth, timeBar.barHeight, 0x00FFFFFF);
		timeBarSpr.cursor = CLICK;
		members.push(timeBarSpr);

		volumeBar = new FlxBar(timeBar.x + timeBar.barWidth - 56, y + 6, LEFT_TO_RIGHT, 56, 10, sound, "volume", 0, 1);
		volumeBar.createImageBar(Paths.image('editors/ui/audio-volume-empty'), Paths.image('editors/ui/audio-volume-full'));
		volumeBar.numDivisions = volumeBar.barWidth;
		volumeBar.unbounded = true;
		members.push(volumeBar);

		volumeBarSpr = cast new UISprite(volumeBar.x, volumeBar.y).makeSolid(volumeBar.barWidth, volumeBar.barHeight, 0x00FFFFFF);
		volumeBarSpr.cursor = CLICK;
		members.push(volumeBarSpr);

		volumeIcon = new FlxSprite(volumeBar.x - 12 - 8, volumeBar.y-1).loadGraphic(Paths.image('editors/ui/audio-icon'));
		volumeIcon.antialiasing = false;
		members.push(volumeIcon);
	}

	public var draggingObj:FlxBar = null;
	public var wasPlaying:Bool = false;

	public var nextPlayerColor:FlxColor = 0x440364;

	public override function update(elapsed:Float) {
		super.update(elapsed);

		if (sound != null) {
			playingSprite.animation.play(sound.playing ? "playing" : "paused");
			timeText.text = '${FlxStringUtil.formatTime(sound.time/1000, true)} / ${FlxStringUtil.formatTime(sound.length/1000)}';

			if(timeBarPlayer.rawClipRect == null)
				timeBarPlayer.rawClipRect = new FlxRect(0, 0, timeBarPlayer.frameWidth, timeBarPlayer.frameHeight);

			timeBarPlayer.rawClipRect.x = timeBarPlayer.frameWidth * (sound.time/sound.length);
			timeBarPlayer.rawClipRect.width = 2;

			timeBarPlayer.rawClipRect = timeBarPlayer.rawClipRect;

			nextPlayerColor = sound.playing ? 0x732D95 : 0x440364;
			timeBarPlayer.colorTransform.color = FlxColor.interpolate(timeBarPlayer.colorTransform.color, nextPlayerColor, 1/14);
		}

		var mousePos = FlxG.mouse.getScreenPosition(__lastDrawCameras[0], FlxPoint.get());

		for (sprite in [timeBar, volumeBar]) {
			if (!selectable) continue;

			var spritePos:FlxPoint = sprite.getScreenPosition(FlxPoint.get(), __lastDrawCameras[0]);

			if (((mousePos.x > spritePos.x) && (mousePos.x < spritePos.x + sprite.barWidth))
				&& ((mousePos.y > spritePos.y) && (mousePos.y < spritePos.y + sprite.barHeight))) {

				if (FlxG.mouse.justPressed) {
					if ((draggingObj = sprite) == timeBar && (wasPlaying = sound.playing)) sound.pause();
				}
				if (FlxG.mouse.pressed) {
					if (draggingObj == timeBar)
						sound.time = FlxMath.remapToRange(mousePos.x - spritePos.x, 0, timeBar.barWidth, 0, sound.length);
					else if (draggingObj == volumeBar)
						sound.volume = FlxMath.remapToRange(mousePos.x - spritePos.x, 0, volumeBar.barWidth, 0, 1);
				}
			}
			spritePos.put();
		}
		mousePos.put();

		if (FlxG.mouse.released) {
			if (draggingObj == timeBar && wasPlaying) {
				sound.play();
				wasPlaying = false;
			}
			draggingObj = null;
		}
	}

	public override function destroy() {
		super.destroy();

		sound.stop();
		@:privateAccess sound.reset();
		bytes = null;
	}
}