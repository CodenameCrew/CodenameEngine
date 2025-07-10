package lime._internal.backend.native;

import haxe.Timer;
import haxe.Int64;

import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import lime.media.vorbis.VorbisFile;

import lime.math.Vector4;
import lime.media.AudioBuffer;
import lime.media.AudioSource;
import lime.utils.ArrayBufferView;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.media.AudioBuffer)
@:access(lime.utils.ArrayBufferView)
@:access(lime.media.vorbis.VorbisFile)
class NativeAudioSource {
	public static var initBuffers:Array<NativeAudioSource> = [];

	private static final STREAM_BUFFER_SIZE:Int = 0x8000;
	private static final STREAM_NUM_BUFFERS:Int = 5;
	private static final STREAM_TIMER_FREQUENCY:Int = 100;

	//#if (lime >= "8.3.0")
	//private static var hasALSoftLatencyExt:Null<Bool>;
	//#end

	private var buffers:Array<ALBuffer>;
	private var bufferDatas:Array<ArrayBufferView>;
	private var bufferTimeBlocks:Array<Float>;
	private var bufferLoops:Int;
	private var queuedBuffers:Int;
	private var requestBuffers:Int;

	private var length:Null<Float>;
	private var loopTime:Null<Float>;
	private var playing:Bool;
	private var loops:Int;
	private var position:Vector4;

	private var bitsPerSample:Int;
	private var format:Int;
	private var dataLength:Int64;
	private var samples:Int64;
	private var completed:Bool;
	private var stream:Bool;

	private var handle:ALSource;
	private var parent:AudioSource;
	private var timer:Timer;
	private var streamTimer:Timer;
	private var disposed:Bool;
	private var safeEnd:Bool;

	public function new(parent:AudioSource) {
		this.parent = parent;
		position = new Vector4();
	}

	public function dispose():Void {
		disposed = true;
		stop();

		if (handle != null) {
			AL.sourcei(handle, AL.BUFFER, null);
			AL.deleteSource(handle);
		}
		handle = null;

		if (buffers != null) AL.deleteBuffers(buffers);
		buffers = null;

		initBuffers.remove(this);
	}

	public function init():Void {
		//#if (lime >= "8.3.0")
		//if (hasALSoftLatencyExt == null) hasALSoftLatencyExt = AL.isExtensionPresent("AL_SOFT_source_latency");
		//#end

		if (handle != null) return;

		var buffer = parent.buffer;
		if (disposed = (handle = AL.createSource()) == null) return;

		AL.sourcef(handle, AL.MAX_GAIN, 10);
		bufferLoops = 0;

		bitsPerSample = buffer.bitsPerSample;
		if (buffer.channels > 1) format = bitsPerSample == 8 ? AL.FORMAT_STEREO8 : AL.FORMAT_STEREO16;
		else format = bitsPerSample == 8 ? AL.FORMAT_MONO8 : AL.FORMAT_MONO16;

		var vorbisFile = buffer.__srcVorbisFile;
		if (stream = vorbisFile != null) {
			dataLength = (samples = vorbisFile.pcmTotal()) * buffer.channels * (Int64.ofInt(bitsPerSample) / 8);
			buffers = [];
			bufferDatas = [];
			bufferTimeBlocks = [];

			var constructor = bitsPerSample == 8 ? Int8 : Int16;
			for (i in 0...STREAM_NUM_BUFFERS) {
				buffers.push(AL.createBuffer());
				bufferDatas.push(new ArrayBufferView(STREAM_BUFFER_SIZE, constructor));
				bufferTimeBlocks.push(0);
			}
		}
		else {
			samples = ((dataLength = buffer.data.length) * 8) / (buffer.channels * bitsPerSample);

			if (buffer.__srcBuffer == null && (buffer.__srcBuffer = AL.createBuffer()) != null)
				AL.bufferData(buffer.__srcBuffer, format, buffer.data, buffer.data.length, buffer.sampleRate);

			AL.sourcei(handle, AL.BUFFER, buffer.__srcBuffer);
		}

		initBuffers.push(this);

		if (dataLength == 0) {
			trace('NativeAudioSource Bug! dataLength is 0');
			dispose();
		}
	}

	public function play():Void {
		if (playing || disposed) return;

		playing = true;
		if (completed) setCurrentTime(0);
		else setCurrentTime(getCurrentTime());
	}

	public function pause():Void {
		if (!(disposed = handle == null)) AL.sourcePause(handle);

		playing = false;
		stopStreamTimer();
		stopTimer();
	}

	public function stop():Void {
		if (!(disposed = handle == null)) {
			if (AL.getSourcei(handle, AL.SOURCE_STATE) != AL.STOPPED) AL.sourceStop(handle);
			if (stream) AL.sourceUnqueueBuffers(handle, AL.getSourcei(handle, AL.BUFFERS_QUEUED) + AL.getSourcei(handle, AL.BUFFERS_PROCESSED));
		}

		requestBuffers = queuedBuffers = bufferLoops = 0;
		playing = false;
		stopStreamTimer();
		stopTimer();
	}

	private function complete():Void {
		stop();

		completed = true;
		parent.onComplete.dispatch();
	}

	private function readVorbisFileBuffer(vorbisFile:VorbisFile, max:Int):ArrayBufferView {
		#if lime_vorbis
		var id = STREAM_NUM_BUFFERS - requestBuffers, read = STREAM_NUM_BUFFERS - 1, total = 0, readMax;
		var buffer = bufferDatas[id];

		for (i in id...read) {
			bufferTimeBlocks[i] = bufferTimeBlocks[i + 1];
			bufferDatas[i] = bufferDatas[i + 1];
		}
		bufferTimeBlocks[read] = vorbisFile.timeTell();
		bufferDatas[read] = buffer;
		queuedBuffers = requestBuffers;

		while (total < STREAM_BUFFER_SIZE) {
			if ((readMax = 4096) > (read = max - total)) readMax = read;
			if (vorbisFile.handle == null) break;
			if (readMax > 0 && (read = vorbisFile.read(buffer.buffer, total, readMax)) > 0) total += read;
			else if (safeEnd = (loops > bufferLoops)) {
				if (readMax == 4096) continue;
				bufferLoops++; vorbisFile.timeSeek((loopTime != null ? Math.max(0, loopTime / 1000) : 0) + parent.offset / 1000);
				if ((max = (dataLength - (vorbisFile.pcmTell() * (Int64.ofInt(bitsPerSample) / 8) * parent.buffer.channels)).low) > STREAM_BUFFER_SIZE)
					max = STREAM_BUFFER_SIZE;
			}
			else {
				buffer.buffer.fill(total, STREAM_BUFFER_SIZE - total - 1, 0);
				resetTimer((getLength() - getCurrentTime()) / getPitch());
				break;
			}
		}

		return buffer;
		#else
		return null;
		#end
	}

	private function fillBuffers(buffers:Array<ALBuffer>):Void {
		#if lime_vorbis
		if (parent == null || parent.buffer == null) return dispose();
		if (handle == null || buffers.length < 1) return;

		final buffer = parent.buffer, vorbisFile = buffer.__srcVorbisFile;
		final actualDataRate = (Int64.ofInt(bitsPerSample) / 8) * buffer.channels;
		var position = vorbisFile.pcmTell() * actualDataRate, length = getLengthSamples() * actualDataRate, trackLoops = bufferLoops;
		if (position >= length && safeEnd) return;

		var sampleRate = buffer.sampleRate, numBuffers = 0, data, size:Int64;
		for (buffer in buffers) {
			if ((size = length - position) > STREAM_BUFFER_SIZE) size = Int64.ofInt(STREAM_BUFFER_SIZE);
			data = readVorbisFileBuffer(vorbisFile, Int64.toInt(size));

			if (disposed) return;
			AL.bufferData(buffer, format, data, STREAM_BUFFER_SIZE, sampleRate);
			numBuffers++;

			if (safeEnd) break;
			else if (bufferLoops != trackLoops) {
				position = vorbisFile.pcmTell() * actualDataRate;
				trackLoops = bufferLoops;
			}
		}
		AL.sourceQueueBuffers(handle, numBuffers, buffers);

		if (AL.getSourcei(handle, AL.SOURCE_STATE) == AL.STOPPED) {
			if (bufferLoops > 0) { // TODO: remove this once buffer loop stutters fixed
				setCurrentTime(getCurrentTime());
				return;
			}
			AL.sourcePlay(handle);
			resetTimer(Std.int((getLength() - getCurrentTime()) / getPitch()));
		}
		#end
	}

	private function streamRun():Void {
		#if lime_vorbis
		if (disposed = (handle == null || buffers == null)) return dispose();

		var vorbisFile = parent.buffer.__srcVorbisFile;
		if (vorbisFile == null) return dispose();

		try {
			var processed = AL.getSourcei(handle, AL.BUFFERS_PROCESSED);
			if (processed > 0 && playing) {
				fillBuffers(AL.sourceUnqueueBuffers(handle, processed));
				if ((!safeEnd || loops > 0) && queuedBuffers < STREAM_NUM_BUFFERS && playing) {
					/*if (requestBuffers >= STREAM_NUM_BUFFERS) {
						AL.sourceUnqueueBuffers(handle, queuedBuffers);
						setCurrentTime((bufferTimeBlocks[STREAM_NUM_BUFFERS - queuedBuffers] +
							(STREAM_BUFFER_SIZE / ((bitsPerSample / 8) * parent.buffer.channels) / parent.buffer.sampleRate)
						) * 1000 - parent.offset);
					}
					else*/fillBuffers([buffers[++requestBuffers - 1]]);
				}
			}
		}
		catch(e) trace(e);
		#end
	}

	// Timers
	inline function stopStreamTimer():Void if (streamTimer != null) streamTimer.stop();

	private function resetStreamTimer():Void {
		stopStreamTimer();

		#if lime_vorbis
		streamTimer = new Timer(STREAM_TIMER_FREQUENCY);
		streamTimer.run = streamRun;
		#end
	}

	inline function stopTimer():Void if (timer != null) timer.stop();

	private function resetTimer(timeRemaining:Float):Void {
		stopTimer();

		/*if (timeRemaining <= 26) {
			timer_onRun();
			return;
		}*/
		timer = new Timer(timeRemaining);
		timer.run = timer_onRun;
	}

	private function timer_onRun():Void {
		if (!safeEnd && bufferLoops <= 0) {
			#if lime_vorbis
			var ranOut = false;
			if (stream) {
				var vorbisFile = parent.buffer.__srcVorbisFile;
				if (vorbisFile == null) return dispose();
				ranOut = vorbisFile.pcmTell() >= getLengthSamples() || queuedBuffers < 3;
			}

			if (!ranOut)
			#end
			{
				var timeRemaining = (getLength() - getCurrentTime()) / getPitch();
				if (timeRemaining > 100 && AL.getSourcei(handle, AL.SOURCE_STATE) == AL.PLAYING) {
					resetTimer(timeRemaining);
					return;
				}
			}
		}
		safeEnd = false;

		if (loops <= 0) {
			complete();
			return;
		}

		if (bufferLoops <= 0) {
			loops--;
			var loopTime = loopTime ?? 0;
			if (stream || loopTime > 0) setCurrentTime(loopTime);
			else if (!stream) {
				setLoops(loops);
				if (AL.getSourcei(handle, AL.SOURCE_STATE) != AL.PLAYING)
					setCurrentTime(0);
			}
		}
		else {
			loops -= bufferLoops;
			bufferLoops = 0;
		}
		parent.onLoop.dispatch();
	}

	// Get & Set Methods
	public function getCurrentTime():Float {
		if (completed) return getLength();
		else if (!disposed) {
			var time = AL.getSourcef(handle, AL.SEC_OFFSET);
			if (stream) time += bufferTimeBlocks[STREAM_NUM_BUFFERS - queuedBuffers];
			time = time * 1000 - parent.offset;
			if (loops > 0 && time > getLength()) {
				var start = loopTime != null ? Math.max(0, loopTime + parent.offset) : parent.offset;
				return ((time - start) % (getLength() - start)) + start;
			}
			if (time > 0) return time;
		}
		return 0;
	}

	public function setCurrentTime(value:Float):Float {
		if (disposed = (handle == null)) return value;

		var total = getRealLength();
		var time = Math.max(0, Math.min(total, value + parent.offset)), ratio = time / total;

		if (stream) {
			// TODO: smooth setCurrentTime for stream (dont refill buffers again)

			AL.sourceStop(handle);
			AL.sourceUnqueueBuffers(handle, AL.getSourcei(handle, AL.BUFFERS_QUEUED));

			#if lime_vorbis
			var vorbisFile = parent.buffer.__srcVorbisFile;
			if (vorbisFile != null) {
				// var chunk = Std.int(Math.floor(getFloat(samples) * ratio / STREAM_BUFFER_SIZE) * STREAM_BUFFER_SIZE);
				vorbisFile.pcmSeek(Int64.fromFloat(getFloat(samples) * ratio));
				fillBuffers(buffers.slice(0, requestBuffers = queuedBuffers = 3));
				// AL.sourcei(handle, AL.SAMPLE_OFFSET, Std.int((samples * ratio) - chunk));
				if (playing) resetStreamTimer();
			}
			#end
		}
		else {
			AL.sourceRewind(handle);
			AL.sourcei(handle, AL.BYTE_OFFSET, Int64.fromFloat(getFloat(dataLength) * ratio));
		}

		if (playing) {
			var timeRemaining = (getLength() - time) / getPitch();
			if (completed = timeRemaining <= 0) complete();
			else {
				AL.sourcePlay(handle);
				resetTimer(timeRemaining);
			}
		}

		return value;
	}

	inline private function getLengthSamples():Int64 {
		return if (length == null) samples;
		else Int64.fromFloat((length + parent.offset) / 1000 * parent.buffer.sampleRate);
	}
	
	inline private function getFloat(x:Int64):Float return x.high * 4294967296. + (x.low >>> 0);

	inline private function getRealLength():Float return getFloat(samples) / parent.buffer.sampleRate * 1000;

	public function getLength():Null<Float> {
		return if (length == null) getRealLength() - parent.offset;
		else length - parent.offset;
	}

	public function setLength(value:Null<Float>):Null<Float> {
		if (value == length) return value;
		length = value;

		if (playing) {
			var timeRemaining = ((getLength() - parent.offset) - getCurrentTime()) / getPitch();
			if (timeRemaining > 0) resetTimer(timeRemaining);
		}
		return value;
	}

	public function getPitch():Float {
		return if (disposed) 1;
		else AL.getSourcef(handle, AL.PITCH);
	}

	public function setPitch(value:Float):Float {
		if (disposed || value == AL.getSourcef(handle, AL.PITCH)) return value;
		if (playing) {
			var timeRemaining = (getLength() - getCurrentTime()) / value;
			if (timeRemaining > 0) resetTimer(timeRemaining);
		}
		AL.sourcef(handle, AL.PITCH, value);
		return value;
	}

	public function getGain():Float {
		if (disposed) return 1;
		return AL.getSourcef(handle, AL.GAIN);
	}

	public function setGain(value:Float):Float {
		if (!disposed) AL.sourcef(handle, AL.GAIN, value);
		return value;
	}

	inline public function getLoops():Int return loops;

	inline public function setLoops(value:Int):Int {
		if (!stream && !disposed) AL.sourcei(handle, AL.LOOPING, (loopTime <= 0 && value > 0) ? AL.TRUE : AL.FALSE);
		return loops = value;
	}

	inline public function getLoopTime():Float return loopTime;

	inline public function setLoopTime(value:Float):Float {
		if (!stream && !disposed) AL.sourcei(handle, AL.LOOPING, (value <= 0 && loops > 0) ? AL.TRUE : AL.FALSE);
		return loopTime = value;
	}

	public function getLatency():Float {
		/*#if (lime >= "8.3.0")
		if (hasALSoftLatencyExt) {
			final offsets = AL.getSourcedvSOFT(handle, AL.SEC_OFFSET_LATENCY_SOFT, 2);
			if (offsets != null) return offsets[1] * 1000;
		}
		#end*/
		return 0;
	}

	public function getPosition():Vector4 return position;

	public function setPosition(value:Vector4):Vector4 {
		position.x = value.x;
		position.y = value.y;
		position.z = value.z;
		position.w = value.w;

		if (!disposed) {
			AL.distanceModel(AL.NONE);
			AL.source3f(handle, AL.POSITION, position.x, position.y, position.z);
		}
		return position;
	}
}