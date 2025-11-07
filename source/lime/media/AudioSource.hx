package lime.media;

import lime.app.Event;
import lime.math.Vector4;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
/**
	The `AudioSource` class provides a way to control audio playback in a Lime application. 
	It allows for playing, pausing, and stopping audio, as well as controlling various 
	audio properties such as gain, pitch, and looping.

	Depending on the platform, the audio backend may vary, but the API remains consistent.

	@see lime.media.AudioBuffer
**/
class AudioSource
{
	private static var activeSources:Array<AudioSource> = [];

	/**
		An event that is dispatched when the audio playback is complete.
	**/
	public var onComplete = new Event<Void->Void>();

	/**
		An event that is dispatched when the audio playback looped.
	**/
	public var onLoop = new Event<Void->Void>();

	/**
		The `AudioBuffer` associated with this `AudioSource`.
	**/
	public var buffer:AudioBuffer;

	/**
		An property if this 'AudioSource' is playing.
	**/
	public var playing(get, null):Bool;

	/**
		The current playback position of the audio, in milliseconds.
	**/
	public var currentTime(get, set):Float;

	/**
		The gain (volume) of the audio. A value of `1.0` represents the default volume.
	**/
	public var gain(get, set):Float;

	/**
		The length of the audio, in milliseconds.
	**/
	public var length(get, set):Null<Float>;

	/**
		The number of times the audio will loop. A value of `0` means the audio will not loop.
	**/
	public var loops(get, set):Int;

	/**
		In which audio playback time the audio will loop.
	**/
	public var loopTime(get, set):Float;

	/**
		The pitch of the audio. A value of `1.0` represents the default pitch.
	**/
	public var pitch(get, set):Float;

	/**
		The offset within the audio buffer to start playback, in samples.
	**/
	public var offset:Float;

	/**
		The 3D position of the audio source, represented as a `Vector4`.
	**/
	public var position(get, set):Vector4;

	/**
		The stereo pan of the audio source.
	**/
	public var pan(get, set):Float;

	/**
		The latency of the audio source.
	**/
	public var latency(get, never):Float;

	@:noCompletion private var __backend:AudioSourceBackend;

	/**
		Creates a new `AudioSource` instance.
		@param buffer The `AudioBuffer` to associate with this `AudioSource`.
		@param offset The starting offset within the audio buffer, in samples.
		@param length The length of the audio to play, in milliseconds. If `null`, the full buffer is used.
		@param loops The number of times to loop the audio. `0` means no looping.
	**/
	public function new(buffer:AudioBuffer = null, offset:Float = 0, length:Null<Float> = null, loops:Int = 0)
	{
		this.buffer = buffer;
		this.offset = offset;

		__backend = new AudioSourceBackend(this);

		if (length != null && length != 0)
		{
			this.length = length;
		}

		if (buffer != null)
		{
			init();
		}

		this.loops = loops;
	}

	/**
		Releases any resources used by this `AudioSource`.
	**/
	inline public function dispose():Void
	{
		__backend.dispose();
		activeSources.remove(this);
	}

	@:noCompletion inline private function init():Void
	{
		__backend.init();
		activeSources.push(this);
	}

	/**
		Starts or resumes audio playback.
	**/
	inline public function play():Void
	{
		__backend.play();
	}

	/**
		Pauses audio playback.
	**/
	inline public function pause():Void
	{
		__backend.pause();
	}

	/**
		Stops audio playback and resets the playback position to the beginning.
	**/
	inline public function stop():Void
	{
		__backend.stop();
	}

	// Get & Set Methods
	@:noCompletion inline private function get_playing():Bool
	{
		@:privateAccess return __backend.playing;
	}

	@:noCompletion inline private function get_currentTime():Float
	{
		return __backend.getCurrentTime();
	}

	@:noCompletion inline private function set_currentTime(value:Float):Float
	{
		return __backend.setCurrentTime(value);
	}

	@:noCompletion inline private function get_gain():Float
	{
		return __backend.getGain();
	}

	@:noCompletion inline private function set_gain(value:Float):Float
	{
		return __backend.setGain(value);
	}

	@:noCompletion inline private function get_length():Null<Float>
	{
		return __backend.getLength();
	}

	@:noCompletion inline private function set_length(value:Null<Float>):Null<Float>
	{
		return __backend.setLength(value);
	}

	@:noCompletion inline private function get_loops():Int
	{
		return __backend.getLoops();
	}

	@:noCompletion inline private function set_loops(value:Int):Int
	{
		return __backend.setLoops(value);
	}

	@:noCompletion inline private function get_loopTime():Float
	{
		return __backend.getLoopTime();
	}

	@:noCompletion inline private function set_loopTime(value:Float):Float
	{
		return __backend.setLoopTime(value);
	}

	@:noCompletion inline private function get_pitch():Float
	{
		return __backend.getPitch();
	}

	@:noCompletion inline private function set_pitch(value:Float):Float
	{
		return __backend.setPitch(value);
	}

	@:noCompletion inline private function get_position():Vector4
	{
		return __backend.getPosition();
	}

	@:noCompletion inline private function set_position(value:Vector4):Vector4
	{
		return __backend.setPosition(value);
	}

	@:noCompletion inline private function get_pan():Float
	{
		return __backend.getPan();
	}

	@:noCompletion inline private function set_pan(value:Float):Float
	{
		return __backend.setPan(value);
	}

	@:noCompletion inline private function get_latency():Float
	{
		return __backend.getLatency();
	}
}

#if (js && html5)
@:noCompletion private typedef AudioSourceBackend = lime._internal.backend.html5.HTML5AudioSource;
#else
@:noCompletion private typedef AudioSourceBackend = lime._internal.backend.native.NativeAudioSource;
#end
