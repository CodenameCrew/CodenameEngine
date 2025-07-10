package flixel.sound;

import lime.media.AudioBuffer;
import lime.media.AudioSource;
import lime.media.openal.AL;
#if lime_vorbis
import lime.media.vorbis.VorbisFile;
#end

import openfl.Assets;
import openfl.events.IEventDispatcher;
import openfl.events.Event;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.media.SoundMixer;
import openfl.net.URLRequest;
import openfl.utils.AssetType;
#if flash11
import openfl.utils.ByteArray;
#end

import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal;
import flixel.util.FlxStringUtil;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxG;

@:access(flixel.FlxGame)
class FlxSound extends FlxBasic {
	/**
	 * The x position of this sound in world coordinates.
	 * Only really matters if you are doing proximity/panning stuff.
	 */
	public var x:Float;

	/**
	 * The y position of this sound in world coordinates.
	 * Only really matters if you are doing proximity/panning stuff.
	 */
	public var y:Float;

	/**
	 * Whether or not this sound should be automatically destroyed when you switch states.
	 */
	public var persist:Bool;

	/**
	 * Whether or not the sound is currently playing.
	 */
	public var playing(get, never):Bool;

	/**
	 * Set volume to a value between 0 and 1 to change how this sound is.
	 */
	public var volume(get, set):Float;

	/**
	 * Whether to make this sound muted or not.
	 */
	public var muted(default, set):Bool;

	#if FLX_PITCH
	/**
	 * Set pitch, which also alters the playback speed. Default is 1.
	 * @since 5.0.0
	 */
	public var pitch(get, set):Float;

	/**
	 * Alters the pitch of the sound depends on the current FlxG.timeScale. Default is true.
	 * @since raltyMod
	 */
	public var timeScaleBased:Bool;
	#end

	/**
	 * Pan amount. -1 = full left, 1 = full right. Proximity based panning overrides this.
	 */
	public var pan(get, set):Float;

	/**
	 * The position in runtime of the music playback in milliseconds.
	 * If set while paused, changes only come into effect after a `resume()` call.
	 */
	public var time(get, set):Float;

	/**
	 * The offset for this FlxSound.
	 * Useful for just generally offsetting this sound without affecting time.
	 * @since raltyMod
	 */
	public var offset(get, set):Float;

	/**
	 * The length of the sound in milliseconds.
	 * @since 4.2.0
	 */
	public var length(get, never):Float;

	/**
	 * The latency of the sound in milliseconds.
	 * @since raltyMod
	 */
	//public var latency(get, never):Float;

	/**
	 * Whether or not this sound should loop.
	 */
	public var looped(default, set):Bool;

	/**
	 * In case of looping, the point (in milliseconds) from where to restart the sound when it loops back
	 * @since 4.1.0
	 */
	public var loopTime(default, set):Float;

	/**
	 * At which point to stop playing the sound, in milliseconds.
	 * If not set / `null`, the sound completes normally.
	 * @since 4.2.0
	 */
	public var endTime(default, set):Null<Float>;

	/**
	 * The sound's "target" (for proximity and panning).
	 * @since raltyMod
	 */
	public var target:Null<FlxObject>;

	/**
	 * The maximum effective radius of this sound (for proximity and panning).
	 * @since raltyMod
	 */
	public var radius:Float;

	/**
	 * Whether the proximity alters the pan or not
	 * @since raltyMod
	 */
	public var proximityPan:Bool;

	/**
	 * Stores for how much channels are in the loaded sound.
	 * @since raltyMod
	 */
	public var channels(get, never):Int;

	/**
	 * Whether or not this sound is stereo instead of mono.
	 * @since raltyMod
	 */
	public var stereo(get, never):Bool;

	/**
	 * Whether or not this sound is loaded yet.
	 * @since raltyMod
	 */
	public var loaded(get, never):Bool;

	/**
	 * Whether or not this sound is streamed, only vorbis though.
	 * @since raltyMod
	 */
	public var streamed(get, never):Bool;

	/**
	 * Stores the average wave amplitude of both stereo channels.
	 * @since raltyMod
	 */
	public var amplitude(get, never):Float;

	/**
	 * Just the amplitude of the left stereo channel
	 * @since raltyMod
	 */
	public var amplitudeLeft(get, never):Float;

	/**
	 * Just the amplitude of the right stereo channel
	 * @since raltyMod
	 */
	public var amplitudeRight(get, never):Float;

	/**
	 * The ID3 song name. Defaults to null. Currently only works for MP3 streamed sounds.
	 */
	public var name(default, null):String;

	/**
	 * The ID3 artist name. Defaults to null. Currently only works for MP3 streamed sounds.
	 */
	public var artist(default, null):String;

	/**
	 * Whether to call `destroy()` when the sound has finished playing.
	 */
	public var autoDestroy:Bool;

	/**
	 * Signal that is dispatched on sound complete.
	 */
	public final onFinish:FlxSignal;

	/**
	 * Tracker for sound complete callback. If assigned, will be called
	 * each time when sound reaches its end.
	 */
	//@:deprecated("`FlxSound.onComplete` is deprecated! Use `FlxSound.onFinish` instead.")
	public var onComplete:Void->Void;

	/**
	 * The sound group this sound belongs to
	 */
	public var group(default, set):FlxSoundGroup;

	/**
	 * Stores the sound lime AudioBuffer if exists.
	 * @since raltyMod
	 */
	public var buffer(get, never):AudioBuffer;

	#if lime_vorbis
	/**
	 * Stores the sound VorbisFile if exists.
	 * @since raltyMod
	 */
	public var vorbis(get, never):VorbisFile;
	#end

	/**
	 * The tween used to fade this sound's volume in and out (set via `fadeIn()` and `fadeOut()`)
	 * @since 4.1.0
	 */
	public var fadeTween:FlxTween;

	@:allow(flixel.system.frontEnds.SoundFrontEnd.load) var _sound:Sound;
	var _transform:SoundTransform;
	var _channel:SoundChannel;
	var _source:AudioSource;
	var _paused:Bool;
	var _volume:Float;
	var _volumeAdjust:Float;
	var _time:Float;
	var _offset:Float;
	var _timeInterpolation:Float;
	var _lastTime:Null<Float>; // FlxG.game.getTicks(), in MS
	var _length:Float;
	#if FLX_PITCH
	var _pitch:Float;
	var _timeScaleAdjust:Float;
	var _realPitch:Float;
	#end
	var _amplitudeLeft:Float;
	var _amplitudeRight:Float;
	var _amplitudeUpdate:Bool;
	var _amplitudeTime:Float;
	var _alreadyPaused:Null<Bool>;

	public function new() {
		super();
		onFinish = new FlxSignal();
		revive();
	}

	/**
	 * Resets this FlxSound properties.
	 *
	 * @param	clean	Whether if this FlxSound also needs to be cleaned up too.
	 */
	public function reset():Void {
		if (_source != null) stop();
		x = y = 0;

		muted = false;
		looped = false;
		loopTime = 0;
		endTime = null;
		autoDestroy = false;
		visible = false;
		target = null;
		radius = 0;
		proximityPan = true;
		onComplete = null;
		timeScaleBased = true;

		_alreadyPaused = null;
		_cameras = null;
		_lastTime = null;
		_paused = false;
		_length = _time = 0;
		_volume = _volumeAdjust = 1;
		_amplitudeLeft = _amplitudeRight = 0;
		_amplitudeUpdate = true;
		#if FLX_PITCH _pitch = _realPitch = _timeScaleAdjust = 1; #end
	}

	/**
	 * Internal cleanup function for cleaning up this FlxSound.
	 * @since raltyMod
	 */
	function cleanup(destroySound:Bool, resetPosition:Bool = true) @:privateAccess {
		active = false;
		_lastTime = null;

		if (_channel != null) {
			_channel.removeEventListener(Event.SOUND_COMPLETE, stopped);
		}

		if (destroySound) {
			onFinish.removeAll();

			if (group != null) group.remove(this);

			if (_channel != null) {
				_channel.stop();
				_channel = null;
			}
			if (_source != null) _source.dispose();
			_source = null;
			_sound = null;

			reset();
		}
		else if (_channel != null && _channel.__isValid) {
			if (resetPosition) {
				_source.stop();

				_time = 0;
				_paused = false;
			}
			else if (!_paused) {
				get_time();
				_source.pause();
			}
		}
	}

	/**
	 * Handles fade out, fade in, panning, proximity, and amplitude operations each frame.
	 */
	override function update(elapsed:Float):Void {
		if (!playing) return;

		var timeScaleTarget = timeScaleBased ? FlxG.timeScale : 1.0;
		if (_timeScaleAdjust != timeScaleTarget) {
			_timeScaleAdjust = timeScaleTarget;
			pitch = _pitch;
			if (_channel == null) return;
		}

		_amplitudeUpdate = true;

		var radialMultiplier = 1.0;

		// Distance-based volume control (TODO for Ralty: REDO THIS)
		if (target != null) {
			var targetPosition = target.getPosition();
			radialMultiplier = targetPosition.distanceTo(FlxPoint.weak(x, y)) / radius;
			targetPosition.put();
			radialMultiplier = 1 - FlxMath.bound(radialMultiplier, 0, 1);

			if (proximityPan && _transform != null) {
				var d:Float = (x - target.x) / radius;
				_transform.pan = FlxMath.bound(d, -1, 1);
			}
		}

		_volumeAdjust = radialMultiplier;
		updateTransform();
	}

	override function revive() {
		reset();
		super.revive();
	}

	override function kill() {
		super.kill();
		reset();
	}

	override function destroy() {
		super.destroy();
		cleanup(true);
	}

	/**
	 * One of the main setup functions for sounds, this function loads a sound from an embedded MP3.
	 *
	 * @param	embeddedSound	An embedded Class object representing an MP3 file.
	 * @param	looped			Whether or not this sound should loop endlessly.
	 * @param	autoDestroy		Whether or not this FlxSound instance should be destroyed when the sound finishes playing.
	 * 							Default value is false, but `FlxG.sound.play()` and `FlxG.sound.stream()` will set it to true by default.
	 * @param	onComplete		Called when the sound finished playing
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadEmbedded(embeddedSound:FlxSoundAsset, looped = false, autoDestroy = false, ?onComplete:Void->Void):FlxSound {
		if (!exists || embeddedSound == null) return this;
		cleanup(true);

		if ((embeddedSound is Sound)) _sound = embeddedSound;
		else if ((embeddedSound is Class)) _sound = Type.createInstance(embeddedSound, []);
		else if ((embeddedSound is String)) {
			if (Assets.exists(embeddedSound, AssetType.MUSIC) && this == FlxG.sound.music)
				_sound = Assets.getMusic(embeddedSound);
			else if (Assets.exists(embeddedSound, AssetType.SOUND))
				_sound = Assets.getSound(embeddedSound);
			else
				FlxG.log.error('Could not find a Sound asset with an ID of \'$embeddedSound\'.');
		}

		return init(looped, autoDestroy, onComplete);
	}

	/**
	 * One of the main setup functions for sounds, this function loads a sound from a URL.
	 *
	 * @param	soundURL		A string representing the URL of the MP3 file you want to play.
	 * @param	looped			Whether or not this sound should loop endlessly.
	 * @param	autoDestroy		Whether or not this FlxSound instance should be destroyed when the sound finishes playing.
	 * 							Default value is false, but `FlxG.sound.play()` and `FlxG.sound.stream()` will set it to true by default.
	 * @param	onComplete		Called when the sound finished playing
	 * @param	onLoad			Called when the sound finished loading.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadStream(soundURL:String, looped = false, autoDestroy = false, ?onComplete:Void->Void, ?onLoad:Void->Void):FlxSound {
		if (!exists) return this;
		cleanup(true);

		_sound = new Sound();
		_sound.addEventListener(Event.ID3, gotID3);
		var loadCallback:Event->Void = null;
		loadCallback = function(e:Event)
		{
			(e.target : IEventDispatcher).removeEventListener(e.type, loadCallback);
			// Check if the sound was destroyed before calling. Weak ref doesn't guarantee GC.
			if (_sound == e.target)
			{
				_length = _sound.length;
				if (onLoad != null)
					onLoad();
			}
		}
		// Use a weak reference so this can be garbage collected if destroyed before loading.
		_sound.addEventListener(Event.COMPLETE, loadCallback, false, 0, true);
		_sound.load(new URLRequest(soundURL));

		return init(looped, autoDestroy, onComplete);
	}

	#if flash11
	/**
	 * One of the main setup functions for sounds, this function loads a sound from a ByteArray.
	 *
	 * @param	bytes 			A ByteArray object.
	 * @param	looped			Whether or not this sound should loop endlessly.
	 * @param	autoDestroy		Whether or not this FlxSound instance should be destroyed when the sound finishes playing.
	 * 							Default value is false, but `FlxG.sound.play()` and `FlxG.sound.stream()` will set it to true by default.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadByteArray(bytes:ByteArray, looped = false, autoDestroy = false, ?onComplete:Void->Void):FlxSound {
		if (!exists) return this;
		cleanup(true);

		_sound = new Sound();
		_sound.addEventListener(Event.ID3, gotID3);
		_sound.loadCompressedDataFromByteArray(bytes, bytes.length);

		return init(looped, autoDestroy, onComplete);
	}
	#end

	function init(?looped:Null<Bool>, ?autoDestroy:Null<Bool>, ?onComplete:Null<Void->Void>):FlxSound {
		if (looped != null) this.looped = looped;
		if (autoDestroy != null) this.autoDestroy = autoDestroy;
		if (onComplete != null) this.onComplete = onComplete; // DEPRECATED

		if (_sound != null) makeChannel();
		else _length = 0;

		endTime = null;

		return this;
	}

	/**
	 * Call inbetween init function if a sound asset does exists.
	 * @since raltyMod
	 */
	function makeChannel() @:privateAccess {
		if (_source != null) _source.dispose();

		if (_channel == null) (_source = (_channel = new SoundChannel(null)).__source = new AudioSource(_sound.__buffer)).gain = 0;
		else {
			(_source = new AudioSource(_sound.__buffer)).gain = 0;
			_channel.__dispose();
			_channel.__source = _source;
			SoundMixer.__registerSoundChannel(_channel);
		}
		if (_transform == null) _transform = new SoundTransform();
		_transform.pan = 0;
		_length = _source.length;

		_source.onComplete.add(_channel.source_onComplete);
		_source.onLoop.add(_channel.source_onLoop);
		_channel.__soundTransform = _transform;
		_channel.__isValid = true;
	}

	/**
	 * Call after adjusting the volume to update the sound channel's settings.
	 */
	@:allow(flixel.sound.FlxSoundGroup)
	function updateTransform() {
		if (_transform == null) {
			_transform = new SoundTransform();
			pan = pan;
		}
		_transform.volume = #if FLX_SOUND_SYSTEM ((FlxG.sound.muted || muted) ? 0 : 1) * FlxG.sound.volume * #end
			(group != null ? group.volume : 1) * _volume * _volumeAdjust;

		if (_channel != null) _channel.soundTransform = _transform;
	}

	/**
	 * Call this function if you want this sound's volume to change
	 * based on distance from a particular FlxObject.
	 *
	 * @param	X			The X position of the sound.
	 * @param	Y			The Y position of the sound.
	 * @param	TargetObject		The object you want to track.
	 * @param	Radius			The maximum distance this sound can travel.
	 * @param	Pan			Whether panning should be used in addition to the volume changes.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function proximity(x = 0.0, y = 0.0, ?targetObject:FlxObject, ?radius:Float, pan = true):FlxSound {
		setPosition(x, y);
		if (targetObject != null) this.target = targetObject;
		if (radius != null) this.radius = radius;
		proximityPan = pan;

		return this;
	}

	/**
	 * Helper function to set the coordinates of this object.
	 * Sound positioning is used in conjunction with proximity/panning.
	 *
	 * @param        x        The new x position
	 * @param        y        The new y position
	 */
	public inline function setPosition(x = 0.0, y = 0.0):Void {
		this.x = x;
		this.y = y;
	}

	/**
	 * Call this function to play the sound - also works on paused sounds.
	 *
	 * @param   forceRestart   Whether to start the sound over or not.
	 *                         Default value is false, meaning if the sound is already playing or was
	 *                         paused when you call play(), it will continue playing from its current
	 *                         position, NOT start again from the beginning.
	 * @param   startTime      At which point to start playing the sound, in milliseconds.
	 * @param   endTime        At which point to stop playing the sound, in milliseconds.
	 *                         If not set / `null`, the sound completes normally.
	 */
	public function play(forceRestart = false, startTime = 0.0, ?endTime:Null<Float>):FlxSound {
		if (!exists) return this;

		if (forceRestart) cleanup(false, true);
		else if (playing) return this;

		if (endTime != null) this.endTime = endTime;
		if (_paused) resume();
		else startSound(startTime);

		return this;
	}

	/**
	 * Unpause a sound. Only works on sounds that have been paused.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function resume():FlxSound {
		if (_paused) startSound(_time);
		return this;
	}

	/**
	 * Call this function to pause this sound.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function pause():FlxSound {
		if (!playing) return this;

		cleanup(false, false);
		_paused = true;
		return this;
	}

	/**
	 * Call this function to stop this sound.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function stop():FlxSound {
		cleanup(autoDestroy, true);
		return this;
	}

	/**
	 * Helper function that tweens this sound's volume.
	 *
	 * @param	duration	The amount of time the fade-out operation should take.
	 * @param	to			The volume to tween to, 0 by default.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function fadeOut(duration = 1.0, to = 0.0, ?onComplete:FlxTween->Void):FlxSound {
		if (fadeTween != null) fadeTween.cancel();
		fadeTween = FlxTween.num(volume, to, duration, {onComplete: onComplete}, volumeTween);

		return this;
	}

	/**
	 * Helper function that tweens this sound's volume.
	 * If the sound wasn't playing at all, it'll play before the tween starts.
	 *
	 * @param	duration	The amount of time the fade-in operation should take.
	 * @param	from		The volume to tween from, 0 by default.
	 * @param	to			The volume to tween to, 1 by default.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function fadeIn(duration = 1.0, from = 0.0, to = 1.0, ?onComplete:FlxTween->Void):FlxSound {
		if (!playing) play();
		if (fadeTween != null) fadeTween.cancel();
		fadeTween = FlxTween.num(from, to, duration, {onComplete: onComplete}, volumeTween);

		return this;
	}

	function volumeTween(f:Float) volume = f;

	/**
	 * Returns the currently selected "real" volume of the sound (takes fades and proximity into account).
	 *
	 * @return	The adjusted volume of the sound.
	 */
	public inline function getActualVolume():Float
		return _volume * _volumeAdjust;

	#if FLX_PITCH
	/**
	 * Returns the currently selected "real" pitch of the sound.
	 *
	 * @return	The adjusted pitch of the sound.
	 */
	public inline function getActualPitch():Float
		return _realPitch;
	#end

	/**
	 * Returns the actual time coming from the internal, can be used for detecting sync error.
	 * 
	 * @return The actual time of the sound.
	 */
	public inline function getActualTime():Float {
		get_time();
		return _time;
	}

	/**
	 * An internal helper function used to attempt to start playing
	 * the sound and populate the _channel variable.
	 */
	var _tries = 0;
	function startSound(StartTime:Float) @:privateAccess {
		if (_sound == null) return;

		_paused = false;
		_time = StartTime;
		_lastTime = FlxG.game.getTicks();
		if (_channel == null || !_channel.__isValid || _source.__backend == null || _source.__backend.disposed #if lime_openal || _source.__backend.handle == null #end)
			makeChannel();

		if (_channel != null) {
			#if FLX_PITCH
			_timeScaleAdjust = timeScaleBased ? FlxG.timeScale : 1.0;
			_realPitch = -1.0;
			pitch = _pitch;
			#end

			// TODO: fix the buffer loud beep for streaming sounds...
			#if lime_openal
			_source.__backend.setGain(0);
			#end

			_channel.soundTransform = _transform;
			_channel.__lastPeakTime = 0;
			_channel.__leftPeak = 0;
			_channel.__rightPeak = 0;
			_channel.addEventListener(Event.SOUND_COMPLETE, stopped);
			_source.__backend.playing = true;
			_source.offset = 0;
			_source.currentTime = _time;

			#if lime_openal
			if (_source.__backend.handle == null) return destroy();

			var s = false;
			try {s = AL.getSourcei(_source.__backend.handle, AL.SOURCE_STATE) == AL.PLAYING;} catch(e) {}
			if (s) updateTransform();
			else {
				if (++_tries > 10) return;
				makeChannel();
				return startSound(StartTime);
			}

			_tries = 0;
			#end

			looped = looped;
			loopTime = loopTime;
			endTime = endTime;
			_amplitudeTime = -1;

			active = true;
		}
		else {
			exists = false;
			active = false;
		}
	}

	function stopped(?_) {
		onFinish.dispatch();

		if (onComplete != null) onComplete();

		if (looped) {
			cleanup(false);
			play(false, loopTime - _offset, endTime - _offset);
		}
		else cleanup(autoDestroy);
	}

	/**
	 * Internal event handler for ID3 info (i.e. fetching the song name).
	 */
	function gotID3(_) {
		name = _sound.id3.songName;
		artist = _sound.id3.artist;
		_sound.removeEventListener(Event.ID3, gotID3);
	}

	#if FLX_SOUND_SYSTEM
	@:allow(flixel.system.frontEnds.SoundFrontEnd)
	function onFocus() if (!_alreadyPaused) {
		resume();
		_alreadyPaused = null;
	}

	@:allow(flixel.system.frontEnds.SoundFrontEnd)
	function onFocusLost() if (_alreadyPaused == null && !(_alreadyPaused = _paused)) pause();
	#end

	#if (flixel > "5.6.2")
	@:deprecated("sound.group = myGroup is deprecated, use myGroup.add(sound)") // 5.7.0
	#end
	function set_group(value:FlxSoundGroup):FlxSoundGroup {
		#if (flixel > "5.6.2")
		if (value != null) value.add(this);
		else group.remove(this);
		#else
		if (group != value) {
			var oldGroup = group;
			group = value; // New group must be set before removing sound to prevent infinite recursion

			if (oldGroup != null) oldGroup.remove(this);
			if (group != null) group.add(this);

			updateTransform();
		}
		#end
		return group;
	}

	inline function get_playing():Bool @:privateAccess
		return _channel != null && _channel.__isValid && _source.playing;

	inline function get_volume():Float
		return _volume;

	inline function set_volume(Volume:Float):Float {
		_volume = FlxMath.bound(Volume, 0, 4);
		updateTransform();
		return _volume;
	}

	inline function set_muted(Muted:Bool):Bool {
		muted = Muted;
		updateTransform();
		return muted;
	}

	inline function get_loaded():Bool
		return buffer != null;

	inline function get_streamed():Bool
		return #if lime_vorbis vorbis != null #else false #end;

	inline function get_buffer():AudioBuffer
		@:privateAccess return _sound != null ? _sound.__buffer : null;

	#if lime_vorbis
	inline function get_vorbis():VorbisFile
		@:privateAccess return _sound != null ? _sound.__buffer.__srcVorbisFile : null;
	#end

	function update_amplitude():Void @:privateAccess {
		if (_channel == null || _time == _amplitudeTime || !_amplitudeUpdate) return;
		_channel.__updatePeaks();

		_amplitudeUpdate = false;
		_amplitudeLeft = _channel.__leftPeak;
		_amplitudeRight = _channel.__rightPeak;
		_amplitudeTime = _time;
	}

	inline function get_amplitudeLeft():Float {
		update_amplitude();
		return _amplitudeLeft;
	}

	inline function get_amplitudeRight():Float {
		update_amplitude();
		return _amplitudeRight;
	}

	inline function get_amplitude():Float {
		update_amplitude();
		return if (stereo) (_amplitudeLeft + _amplitudeRight) * 0.5; else _amplitudeLeft;
	}

	inline function get_channels():Int
		@:privateAccess return (buffer != null) ? buffer.channels : 0;

	inline function get_stereo():Bool
		return channels > 1;

	#if FLX_PITCH
	inline function get_pitch():Float
		return _pitch;

	function set_pitch(v:Float):Float {
		var adjusted:Float = FlxMath.bound(v * _timeScaleAdjust, 0);
		if (_channel != null && _realPitch != adjusted) {
			if ((_channel.pitch = adjusted) > 0 && _realPitch <= 0) {
				_realPitch = adjusted;
				time = _time;
			}
			else {
				get_time();
				_realPitch = adjusted;
			}
		}
		return _pitch = FlxMath.bound(v, 0);
	}
	#end

	function set_looped(v:Bool):Bool {
		if (playing) {
			if (v) _channel.loops = 999;
			else _channel.loops = 0;
		}
		return looped = v;
	}

	function set_loopTime(v:Float):Float {
		if (playing) _channel.loopTime = v;
		return loopTime = v;
	}

	function set_endTime(v:Null<Float>):Null<Float> {
		if (playing) {
			if (v != null && v > 0 && v < length) _channel.endTime = v;
			else _channel.endTime = null;
		}
		return endTime = v;
	}

	inline function get_pan():Float return _transform.pan;
	inline function set_pan(pan:Float):Float return _transform.pan = pan;

	inline function getFakeTime():Float {
		if (@:privateAccess _channel.__isValid && _source.playing && _realPitch > 0 && _lastTime != null)
			return _time + (FlxG.game.getTicks() - _lastTime) * _realPitch * _timeInterpolation;
		else
			return _time;
	}
	function get_time():Float {
		if (_channel == null) return _time;

		final pos = _channel.position - _offset;
		if (!playing || _realPitch <= 0) {
			_lastTime = null;
			return _time = pos;
		}

		final fakeTime = getFakeTime();
		if (pos != _time) {
			_lastTime = FlxG.game.getTicks();
			if ((_timeInterpolation = 1 - Math.min(fakeTime - pos, 1000) * 0.001) < 1 && _timeInterpolation > .9)
				return _time = fakeTime;
			else {
				_timeInterpolation = 1;
				return _time = pos;
			}
		}
		else
			return fakeTime;
	}

	function set_time(time:Float):Float @:privateAccess {
		time = FlxMath.bound(time, 0, length - 1);
		if (_channel != null && _realPitch > 0) {
			if (!_channel.__isValid) {
				cleanup(false, true);
				startSound(time);
			}
			else if (playing) {
				_source.offset = 0;
				_source.currentTime = time + _offset;
			}
		}

		_lastTime = null;
		return _time = time;
	}

	function get_offset():Float return _offset;
	function set_offset(offset:Float):Float {
		if (offset == _offset) return offset;
		_offset = offset;
		time = time;
		return offset;
	}

	inline function get_length():Float return _length - _offset;

	/*function get_latency():Float {
		if (_channel != null) return _source.latency;
		return 0;
	}*/

	override function toString():String {
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("playing", playing),
			LabelValuePair.weak("time", _time),
			LabelValuePair.weak("length", length),
			LabelValuePair.weak("volume", volume),
			LabelValuePair.weak("pitch", pitch)
		]);
	}
}