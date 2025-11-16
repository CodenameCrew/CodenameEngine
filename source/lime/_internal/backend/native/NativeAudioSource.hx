package lime._internal.backend.native;

import haxe.Timer;
import haxe.Int64;

import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;

#if lime_vorbis
import lime.media.vorbis.Vorbis;
import lime.media.vorbis.VorbisFile;
import lime.media.vorbis.VorbisInfo;
#end

import lime.math.Vector2;
import lime.math.Vector4;
import lime.media.AudioBuffer;
import lime.media.AudioSource;
import lime.system.Endian;
import lime.system.System;
import lime.utils.ArrayBuffer;
import lime.utils.ArrayBufferView.TypedArrayType;
import lime.utils.ArrayBufferView;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(haxe.Timer)
@:access(lime.media.AudioBuffer)
@:access(lime.utils.ArrayBufferView)
class NativeAudioSource {
	// Can hold up to 3 hours 44100 sampleRate audio, if you are into that, theorically.

	public static var STREAM_BUFFER_SAMPLES:Int = 0x2000; // how much buffers will be generating every frequency (doesnt have to be pow of 2?).
	public static var STREAM_MIN_BUFFERS:Int = 2; // how much buffers can a stream hold on minimum or starting.
	public static var STREAM_MAX_BUFFERS:Int = 8; // how much limit of a buffers can be used for streamed audios, must be higher than minimum.
	public static var STREAM_PROCESS_BUFFERS:Int = 2; // how much buffers can be processed in a frequency tick.
	public static var STREAM_TIMER_CHECK_MS:Int = 100; // determines how milliseconds to update the buffers if available.
	public static var MAX_POOL_BUFFERS:Int = 32; // how much buffers for the pool to hold.

	public static var moreFormatsSupported:Null<Bool>;
	public static var loopPointsSupported:Null<Bool>;
	public static var stereoAnglesExtensionSupported:Null<Bool>;
	public static var latencyExtensionSupported:Null<Bool>;

	private static var bufferDataPool:Array<ArrayBufferView> = [];
	private static var isBigEndian:Bool = System.endianness == Endian.BIG_ENDIAN;

	public static function getALFormat(bitsPerSample:Int, channels:Int):Int {
		if (moreFormatsSupported == null) moreFormatsSupported = AL.isExtensionPresent("AL_EXT_MCFORMATS");

		// There was a code to also supports for X-Fi Renderer but, that kind of device is
		// rare nowadays and none of sounds should have more than 24 bitsPerSample.
		// https://github.com/kcat/openal-soft/issues/934

		if (channels > 2 && moreFormatsSupported) {
			if (channels == 3) return bitsPerSample == 32 ? 0x1209 : (bitsPerSample == 16 ? 0x1208 : 0x1207);
			else if (channels == 4) return bitsPerSample == 32 ? 0x1206 : (bitsPerSample == 16 ? 0x1205 : 0x1204);
			else if (channels == 6) return bitsPerSample == 32 ? 0x120C : (bitsPerSample == 16 ? 0x120B : 0x120A);
			else if (channels == 7) return bitsPerSample == 32 ? 0x120F : (bitsPerSample == 16 ? 0x120E : 0x120D);
			else if (channels == 8) return bitsPerSample == 32 ? 0x1212 : (bitsPerSample == 16 ? 0x1211 : 0x1210);
			else return AL.FORMAT_MONO8;
		}
		else if (bitsPerSample == 32 && moreFormatsSupported) return channels == 2 ? 0x1203 : 0x1202;
		else if (channels == 2) return bitsPerSample == 16 ? AL.FORMAT_STEREO16 : AL.FORMAT_STEREO8;
		else return bitsPerSample == 16 ? AL.FORMAT_MONO16 : AL.FORMAT_MONO8;
	}

	private static function resetTimer(timer:Timer, time:Float, callback:Void->Void):Timer {
		if (timer == null) (timer = new Timer(time)).run = callback;
		else {
			timer.mTime = time;
			timer.mFireAt = Timer.getMS() + time;
			timer.mRunning = true;
			timer.run = callback;

			if (!Timer.sRunningTimers.contains(timer)) Timer.sRunningTimers.push(timer);
		}
		return timer;
	}

	inline private static function getFloat(x:Int64):Float return x.high * 4294967296. + (x.low >> 0);

	// Backward Compatibility Variables
	var handle(get, set):ALSource; inline function get_handle() return source; inline function set_handle(v) return source = v;
	var timer(get, set):Timer; inline function get_timer() return completeTimer; inline function set_timer(v) return completeTimer = v;
	var length(get, set):Null<Float>; inline function get_length() return endTime; inline function set_length(v) return endTime = v;
	var toLoop(get, set):Int; inline function get_toLoop() return streamLoops; inline function set_toLoop(v) return streamLoops = v;
	var bufferSizes(get, set):Array<Int>; inline function get_bufferSizes() return bufferLengths; inline function set_bufferSizes(v) return bufferLengths = v;

	var parent:AudioSource;
	var disposed:Bool;
	var streamed:Bool;
	var playing:Bool;
	var completed:Bool;
	var lastTime:Float;

	var position:Vector4;
	var angles:Vector2;
	var anglesArray:Array<Float>;
	var endTime:Null<Float>;
	var loopTime:Float;
	var loops:Int;

	var channels:Int;
	var sampleRate:Int;
	var wordSize:Int; // is bitsPerSample >> 3, ex: 8 bits is 1, 16 bits is 2, 32 bits is 4, etc.
	var samples:Int;
	var dataLength:Int;
	var duration:Float;

	var streamTimer:Timer;
	var completeTimer:Timer;
	var source:ALSource;
	var buffer:ALBuffer;
	var standaloneBuffer:Bool;
	var format:Int; // AL.FORMAT_...
	var arrayType:TypedArrayType;
	var loopPoints:Array<Int>; // In Samples

	var bufferLength:Int; // Size in bytes for current streamed audio buffers.
	var requestBuffers:Int;
	var queuedBuffers:Int;
	var streamLoops:Int;
	var streamEnded:Bool;

	var buffers:Array<ALBuffer>;
	var unusedBuffers:Array<ALBuffer>;

	// ORDERING IS CURRENT TO NEXT, STARTS FROM THE LENGTH OF THE ARRAYS
	var bufferDatas:Array<ArrayBufferView>;
	var bufferTimes:Array<Float>;
	var bufferLengths:Array<Int>;
	var bufferTemps:Array<ALBuffer>;
	var buffersToQueue:Int = 0;

	public function new(parent:AudioSource) {
		this.parent = parent;

		if (loopPointsSupported == null) loopPointsSupported = AL.isExtensionPresent("AL_SOFT_loop_points");
		if (stereoAnglesExtensionSupported == null) stereoAnglesExtensionSupported = AL.isExtensionPresent("AL_EXT_STEREO_ANGLES");
		if (latencyExtensionSupported == null) latencyExtensionSupported = AL.isExtensionPresent("AL_SOFT_source_latency");
	}

	public function dispose() {
		stop();
		disposed = true;

		position = null;
		angles = null;
		anglesArray = null;

		if (source != null) {
			AL.sourcei(source, AL.BUFFER, AL.NONE);
			AL.deleteSource(source);
			source = null;
		}

		if (standaloneBuffer && buffer != null) {
			AL.bufferData(buffer, 0, null, 0, 0);
			AL.deleteBuffer(buffer);
			buffer = null;
		}
		loopPoints = null;

		if (buffers != null) {
			for (buffer in buffers) AL.bufferData(buffer, 0, null, 0, 0);
			AL.deleteBuffers(buffers);
			buffers = null;
		}

		if (bufferDatas != null) {
			for (data in bufferDatas) if (bufferDataPool.length < MAX_POOL_BUFFERS) bufferDataPool.push(data);
			bufferDatas = null;
		}

		bufferTemps = null;

		completeTimer = null;
		streamTimer = null;

		unusedBuffers = null;
		bufferTimes = null;
		bufferLengths = null;
	}

	public function init() {
		if (source != null || (disposed = parent == null || (source = AL.createSource()) == null)) return;
		AL.sourcef(source, AL.MAX_GAIN, 32);
		AL.distanceModel(AL.NONE);

		if (position == null) position = new Vector4();
		if (angles == null) angles = new Vector2(Math.PI / 6, -Math.PI / 6); // https://github.com/kcat/openal-soft/issues/1032
		if (loopPoints == null) loopPoints = [0, 0];
		if (stereoAnglesExtensionSupported && anglesArray == null) anglesArray = [0, 0];

		resetBuffer();
	}

	public function resetBuffer() {
		if (parent.buffer == null) return;
		stop();

		AL.sourcei(source, AL.BUFFER, AL.NONE);

		final audioBuffer = parent.buffer;
		channels = audioBuffer.channels;
		sampleRate = audioBuffer.sampleRate;
		wordSize = audioBuffer.bitsPerSample >> 3;
		format = getALFormat(audioBuffer.bitsPerSample, channels);
		arrayType = wordSize == 4 ? TypedArrayType.Uint32 : (wordSize == 2 ? TypedArrayType.Uint16 : TypedArrayType.Int8);
		standaloneBuffer = false;
		loopTime = 0;
		endTime = null;

		if (buffer != null) {
			if (standaloneBuffer) {
				AL.bufferData(buffer, 0, null, 0, 0);
				AL.deleteBuffer(buffer);
			}
			buffer = null;
		}

		if (audioBuffer.data != null) {
			streamed = false;
			samples = Std.int((dataLength = audioBuffer.data.byteLength) / wordSize / channels);
		}
		#if lime_vorbis
		else if (audioBuffer.__srcVorbisFile != null) {
			streamed = true;
			dataLength = Std.int(getFloat(samples = Int64.toInt(audioBuffer.__srcVorbisFile.pcmTotal())) * channels * wordSize);
		}
		#end
		else return;

		duration = getFloat(samples) / sampleRate * 1000;

		loopPoints[0] = 0;
		loopPoints[1] = samples - 1;

		if (streamed) {
			final length = STREAM_BUFFER_SAMPLES * channels;
			bufferLength = length * wordSize;

			if (buffers == null) buffers = AL.genBuffers(STREAM_MAX_BUFFERS);
			if (bufferDatas == null) {
				unusedBuffers = [];
				bufferDatas = [];
				bufferTimes = [];
				bufferLengths = [];
				bufferTemps = [];
			}
			else
				unusedBuffers.resize(0);

			for (i in 0...STREAM_MAX_BUFFERS) {
				bufferTimes[i] = 0.0;
				bufferLengths[i] = 0;

				var data = bufferDataPool.pop();
				if (data == null) data = new ArrayBufferView(length, arrayType);
				else {
					data.type = arrayType;
					data.bytesPerElement = wordSize;
					data.length = length;
					if (data.byteLength != bufferLength) {
						#if cpp
						data.buffer.getData().resize(bufferLength);
						data.buffer.fill(data.byteLength, bufferLength - data.byteLength, 0);
						@:privateAccess data.buffer.length = bufferLength;
						#else
						data.buffer = new ArrayBuffer(bufferLength);
						#end
					}
					data.byteLength = bufferLength;
				}
				bufferDatas[i] = data;
			}
		}
		else {
			if (buffers != null) {
				for (buffer in buffers) AL.bufferData(buffer, 0, null, 0, 0);
				AL.deleteBuffers(buffers);
				buffers = null;

				for (data in bufferDatas) if (bufferDataPool.length < MAX_POOL_BUFFERS) bufferDataPool.push(data);
				bufferDatas.resize(0);
			}

			if (audioBuffer.__srcBuffer != null) {
				if (AL.getBufferi(audioBuffer.__srcBuffer, AL.SIZE) != dataLength) {
					AL.bufferData(audioBuffer.__srcBuffer, 0, null, 0, 0);
					AL.deleteBuffer(audioBuffer.__srcBuffer);
					if ((buffer = audioBuffer.__srcBuffer = AL.createBuffer()) != null)
						AL.bufferData(buffer, format, audioBuffer.data, dataLength, sampleRate);
				}
				else
					buffer = audioBuffer.__srcBuffer;
			}
			else if ((buffer = audioBuffer.__srcBuffer = AL.createBuffer()) != null)
				AL.bufferData(buffer, format, audioBuffer.data, dataLength, sampleRate);

			AL.sourcei(source, AL.BUFFER, buffer);
		}

		updateLoopPoints();
	}

	function updateLoopPoints() {
		if (loops <= 0) return AL.sourcei(source, AL.LOOPING, AL.FALSE);

		var time = getCurrentTime() + parent.offset, length = getRealLength();
		final fixed = time >= length;
		if (fixed) time = loopTime;

		if (!streamed) {
			var internalLoop = AL.TRUE;
			if (length < duration - 1 && loopTime > 1) {
				if (!loopPointsSupported) internalLoop = AL.FALSE;
				else {
					AL.sourceStop(source);
					AL.sourcei(source, AL.BUFFER, AL.NONE);
					if (!standaloneBuffer) {
						if (standaloneBuffer = (buffer = AL.createBuffer()) != null)
							AL.bufferData(buffer, format, parent.buffer.data, dataLength, sampleRate);
						else {
							buffer = parent.buffer.__srcBuffer;
							internalLoop = AL.FALSE;
						}
					}
					if (internalLoop == AL.TRUE) AL.bufferiv(buffer, 0x2015/*AL.LOOP_POINTS_SOFT*/, loopPoints);
					AL.sourcei(source, AL.BUFFER, buffer);
				}
			}

			AL.sourcei(source, AL.LOOPING, internalLoop);
			if (playing) setCurrentTime(time - parent.offset);
			else updateCompleteTimer();
		}
		else if (playing && (fixed || streamLoops > 0)) {
			AL.sourcei(source, AL.LOOPING, AL.FALSE);
			AL.sourceStop(source);
			snapBuffersToTime(time, streamLoops > 0);
			AL.sourcePlay(source);
		}
	}

	// https://github.com/xiph/vorbis/blob/master/CHANGES#L39 bug in libvorbis <= 1.3.4
	inline function streamSeek(samples:Int64)
		if (samples <= 1) parent.buffer.__srcVorbisFile.rawSeek(0); else parent.buffer.__srcVorbisFile.pcmSeek(samples);

	inline function streamTell():Int64
		return parent.buffer.__srcVorbisFile.pcmTell();

	inline function streamRead(buffer:ArrayBuffer, position:Int, length:Int, wordSize:Int):Int
		return parent.buffer.__srcVorbisFile.read(buffer, position, length, isBigEndian, wordSize, true);

	function readToBufferData(data:ArrayBufferView, currentPCM:Int64):Int {
		var length = (Int64.ofInt(loopPoints[1]) - currentPCM) * channels * wordSize;
		var n = length < bufferLength ? length.low : bufferLength, total = 0, result = 0, wasEOF = false;
		while (total < bufferLength) {
			result = n > 0 ? streamRead(data.buffer, total, n, wordSize) : 0;

			if (result == Vorbis.HOLE) continue;
			else if (result <= Vorbis.EREAD) break;
			else if (result == 0) {
				if (streamEnded = wasEOF == (wasEOF = true) || loops <= streamLoops) break;

				streamSeek(Int64.ofInt(loopPoints[0]));
				streamLoops++;
				if ((length = Int64.ofInt(loopPoints[1] - loopPoints[0]) * channels * wordSize) < (n = bufferLength - total)) n = length.low;
			}
			else {
				total += result;
				n -= result;
				wasEOF = false;
			}
		}

		if (result < 0) {
			trace('NativeAudioSource readToBufferData Bug! reading result is $result, streamEnded: $streamEnded, total: $total, n: $n');
			return result;
		}
		return total;
	}

	function fillBuffer(buffer:ALBuffer):Int {
		var i = STREAM_MAX_BUFFERS - requestBuffers;
		var data = bufferDatas[i], currentPCM = streamTell();

		var decoded = readToBufferData(data, currentPCM);
		if (decoded > 0) {
			AL.bufferData(buffer, format, data, decoded, sampleRate);

			var n = STREAM_MAX_BUFFERS - 1, j = i;
			while (i < n) {
				bufferDatas[i] = bufferDatas[++j];
				bufferTimes[i] = bufferTimes[j];
				bufferLengths[i] = bufferLengths[j];
				i = j;
			}
			queuedBuffers = requestBuffers;
			bufferDatas[n] = data;
			bufferTimes[n] = getFloat(currentPCM) / sampleRate;
			bufferLengths[n] = decoded;
		}

		return decoded;
	}

	inline function queueBuffer(buffer:ALBuffer) bufferTemps[buffersToQueue++] = buffer;
	inline function flushBuffers() {
		AL.sourceQueueBuffers(source, buffersToQueue, bufferTemps);
		buffersToQueue = 0;
	}

	function skipBuffers(n:Int, fill:Int = 0) {
		for (buffer in AL.sourceUnqueueBuffers(source, n)) {
			if (!streamEnded && --fill > 0 && fillBuffer(buffer) > 0) queueBuffer(buffer);
			else {
				queuedBuffers = --requestBuffers;
				unusedBuffers.push(buffer);
			}
		}
	}

	function fillBuffers(n:Int) {
		var buffer:ALBuffer;
		while (n-- > 0 && queuedBuffers < STREAM_MAX_BUFFERS && !streamEnded) {
			if ((buffer = unusedBuffers.pop()) != null) {
				requestBuffers++;
				if (fillBuffer(buffer) > 0) queueBuffer(buffer);
				else {
					requestBuffers--;
					unusedBuffers.push(buffer);
				}
			}
			else if (fillBuffer(buffer = buffers[requestBuffers++]) > 0) queueBuffer(buffer);
			else requestBuffers--;
		}
	}

	function streamRun() {
		if (source == null || parent.buffer == null || parent.buffer.__srcVorbisFile == null || !streamed || !playing)
			return streamTimer.stop();

		final queued = AL.getSourcei(source, AL.BUFFERS_QUEUED);
		skipBuffers(AL.getSourcei(source, AL.BUFFERS_PROCESSED), STREAM_PROCESS_BUFFERS + (queued < STREAM_MIN_BUFFERS ? STREAM_MIN_BUFFERS - queued : 0));
		fillBuffers(STREAM_PROCESS_BUFFERS - buffersToQueue);
		flushBuffers();

		if (AL.getSourcei(source, AL.SOURCE_STATE) == AL.STOPPED) {
			AL.sourcePlay(source);
			updateCompleteTimer();
		}
	}

	function snapBuffersToTime(time:Float, force:Bool) {
		if (source == null || parent.buffer == null || parent.buffer.__srcVorbisFile == null) return;

		final sec = time / 1000;
		if (!force) {
			var bufferTime:Float;
			for (i in (STREAM_MAX_BUFFERS - queuedBuffers)...STREAM_MAX_BUFFERS)
				if (sec >= (bufferTime = bufferTimes[i]) && sec < bufferTime + (bufferLengths[i] / wordSize / channels / sampleRate))
			{
				skipBuffers(i - (STREAM_MAX_BUFFERS - queuedBuffers), STREAM_MIN_BUFFERS - STREAM_MAX_BUFFERS + i);
				AL.sourcei(source, AL.SAMPLE_OFFSET, Math.floor((sec - bufferTime) * sampleRate));
				return flushBuffers();
			}
		}

		AL.sourceUnqueueBuffers(source, AL.getSourcei(source, AL.BUFFERS_QUEUED));

		streamEnded = false;
		unusedBuffers.resize(0);
		streamSeek(Int64.fromFloat(sec * sampleRate));

		buffersToQueue = streamLoops = 0;
		for (i in 0...(requestBuffers = queuedBuffers = STREAM_MIN_BUFFERS)) {
			if (!streamEnded && fillBuffer(buffers[i]) > 0) queueBuffer(buffers[i]);
			else queuedBuffers = --requestBuffers;
		}
		flushBuffers();
	}

	function timer_onRun() {
		final pitch = getPitch();
		var timeRemaining = (getLength() - getCurrentTime()) / pitch;
		if (timeRemaining > 50 && AL.getSourcei(source, AL.SOURCE_STATE) == AL.PLAYING && (!streamed || !streamEnded && streamLoops <= 0)) {
			completeTimer = resetTimer(completeTimer, timeRemaining, timer_onRun);
			return;
		}

		completeTimer.stop();

		if (loops == 0) return complete();

		if (streamLoops > 0) {
			loops -= streamLoops;
			streamLoops = 0;
			completeTimer = resetTimer(completeTimer, (getLength() + parent.offset - loopTime) / pitch, timer_onRun);
		}
		else if (!loopPointsSupported || AL.getSourcei(source, AL.LOOPING) == AL.FALSE) {
			loops--;
			playing = true;
			setCurrentTime(loopTime - parent.offset);
		}

		if (loops <= 0) {
			loops = 0;
			AL.sourcei(source, AL.LOOPING, AL.FALSE);
		}

		parent.onLoop.dispatch();
	}

	function updateCompleteTimer() {
		if (playing) {
			var timeRemaining = (getLength() - getCurrentTime()) / getPitch();
			if (timeRemaining > 50) completeTimer = resetTimer(completeTimer, timeRemaining, timer_onRun);
			else {
				if (completeTimer != null) completeTimer.stop();
				if (loops > 0) play();
				else complete();
			}
		}
		else if (completeTimer != null) 
			completeTimer.stop();
	}

	function resetStreamTimer() {
		if (!streamEnded && (streamTimer == null || !streamTimer.mRunning))
			streamTimer = resetTimer(streamTimer, STREAM_TIMER_CHECK_MS, streamRun);
	}

	public function play() {
		if (playing || disposed) return;
		final time = completed ? 0 : getCurrentTime();
		playing = true;
		setCurrentTime(time);
	}

	public function pause() {
		if (!disposed) AL.sourcePause(source);
		lastTime = getCurrentTime();
		playing = false;
		if (completeTimer != null) completeTimer.stop();
		if (streamTimer != null) streamTimer.stop();
	}

	public function stop() {
		if (!disposed) AL.sourceStop(source);
		lastTime = 0;
		streamLoops = 0;
		playing = false;
		if (completeTimer != null) completeTimer.stop();
		if (streamTimer != null) streamTimer.stop();
	}

	public function complete() {
		if (!completed) parent.onComplete.dispatch();
		stop();
		completed = true;
	}

	public function getCurrentTime():Float {
		if (disposed) return 0.0;
		else if (completed) return getLength();
		else if (!playing) return lastTime - parent.offset;

		var time = AL.getSourcef(source, AL.SEC_OFFSET);
		if (streamed) {
			if (playing && streamEnded && AL.getSourcei(source, AL.SOURCE_STATE) == AL.STOPPED) {
				complete();
				return getLength();
			}
			else if (bufferTimes != null)
				time += bufferTimes[STREAM_MAX_BUFFERS - queuedBuffers];
		}
		time *= 1000;

		var length = getRealLength();
		return if (loops <= 0 || time <= length) time - parent.offset;
			else ((time - loopTime) % (length - loopTime)) + loopTime - parent.offset;
	}

	public function setCurrentTime(value:Float):Float {
		if (disposed) return 0.0;

		final length = getRealLength();
		value = Math.isFinite(value) ? Math.max(Math.min(value + parent.offset, length), parent.offset) : parent.offset;

		if (streamed) AL.sourceStop(source);
		else AL.sourcef(source, AL.SEC_OFFSET, value / 1000);

		final timeRemaining = (length - value) / getPitch();
		if (playing) {
			if (timeRemaining < 8 && value > 8) complete();
			else {
				completed = false;
				if (streamed) {
					snapBuffersToTime(value, false);
					resetStreamTimer();
				}
				if (AL.getSourcei(source, AL.SOURCE_STATE) != AL.PLAYING) AL.sourcePlay(source);
			}
		}
		else {
			completed = timeRemaining < 8;
			lastTime = value;
		}

		updateCompleteTimer();
		return value;
	}

	public function getPitch():Float {
		return if (disposed) 1;
			else AL.getSourcef(source, AL.PITCH);
	}

	public function setPitch(value:Float):Float {
		if (disposed || (value = Math.max(value, 0)) == AL.getSourcef(source, AL.PITCH)) return value;
		AL.sourcef(source, AL.PITCH, value);
		updateCompleteTimer();
		return value;
	}

	public function getGain():Float {
		return if (disposed) 1;
			else AL.getSourcef(source, AL.GAIN);
	}

	public function setGain(value:Float):Float {
		value = Math.max(value, 0);
		if (!disposed) AL.sourcef(source, AL.GAIN, value);
		return value;
	}

	public function getLoops():Int return loops;

	public function setLoops(value:Int):Int {
		if (loops == (loops = value < 0 ? 0 : value)) return loops;
		updateLoopPoints();
		return loops;
	}

	public function getLoopTime():Float return loopTime - parent.offset;

	public function setLoopTime(value:Float):Float {
		if (loopTime == (loopTime = Math.max(Math.min(value + parent.offset, duration), 0))) return loopTime - parent.offset;
		if ((loopPoints[0] = Std.int(value / 1000 * sampleRate)) >= samples) loopPoints[0] = samples - 1;
		updateLoopPoints();
		return loopTime - parent.offset;
	}

	public function getRealLength():Float return if (endTime == null) duration; else endTime;
	public function getLength():Float return if (disposed) 0; else (inline getRealLength()) - parent.offset;

	public function setLength(value:Null<Float>):Null<Float> {
		if (endTime == (endTime = (value == null ? value : Math.max(Math.min(value + parent.offset, duration), 0)))) return endTime - parent.offset;
		if ((loopPoints[1] = Std.int(getRealLength() / 1000 * sampleRate)) >= samples) loopPoints[1] = samples - 1;
		updateLoopPoints();
		return endTime - parent.offset;
	}

	public function getLatency():Float {
		//#if (lime >= "8.4.0")
		//if (latencyExtensionSupported) {
		//	final offsets = AL.getSourcedvSOFT(source, AL.SEC_OFFSET_LATENCY_SOFT, 2);
		//	if (offsets != null) return offsets[1] * 1000;
		//}
		//#end
		return 0;
	}

	public function getAngles():Vector2 {
		if (angles == null) angles = new Vector2(Math.PI / 6, -Math.PI / 6);
		return angles;
	}

	public function setAngles(left:Float, right:Float):Vector2 {
		if (angles == null) angles = new Vector2(left, right);
		else angles.setTo(left, right);

		if (!disposed && stereoAnglesExtensionSupported) {
			anglesArray[0] = angles.x;
			anglesArray[1] = angles.y;
			AL.sourcei(source, 0x1214/*AL.SOURCE_SPATIALIZE_SOFT*/, AL.FALSE);
			AL.sourcefv(source, 0x1030/*AL.STEREO_ANGLES*/, anglesArray);
			AL.source3f(source, AL.POSITION, 0, 0, 0);
		}
		return angles;
	}

	public function getPosition():Vector4 {
		if (position == null) position = new Vector4();
		return position;
	}

	public function setPosition(value:Vector4):Vector4 {
		position.x = value.x;
		position.y = value.y;
		position.z = value.z;
		position.w = value.w;

		// OpenAL Soft Positions doesn't seem to do anything but panning?
		if (!disposed) {
			if (stereoAnglesExtensionSupported) AL.sourcei(source, 0x1214/*AL.SOURCE_SPATIALIZE_SOFT*/, Math.abs(position.x) > 1e-04 ? AL.TRUE : AL.FALSE);
			AL.sourcei(source, AL.MAX_DISTANCE, 1);
			AL.source3f(source, AL.POSITION, position.x, position.y, position.z);
		}
		return position;
	}

	public function getPan():Float return getPosition().x;

	public function setPan(value:Float):Float {
		getPosition().setTo(value, 0, -Math.sqrt(1 - value * value));
		if (!disposed) {
			if (parent.buffer.channels > 1)
				setAngles(Math.PI * (Math.min(-value * 2 + 1, 1)) / 6, -Math.PI * Math.min(value * 2 + 1, 1) / 6);
			else
				setPosition(position);
		}
		return value;
	}
}