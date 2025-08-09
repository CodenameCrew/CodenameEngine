// ALL REWRITTEN FROM SCRATCH!!!! -raltyro
package lime._internal.backend.native;

import haxe.Timer;
import haxe.Int64;

import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;

#if lime_vorbis
import lime.media.vorbis.Vorbis;
import lime.media.vorbis.VorbisFile;
#end

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
class NativeAudioSource {
	private static var STREAM_BUFFER_SAMPLES:Int = 0x4000;
	private static var STREAM_MAX_BUFFERS:Int = 8;
	private static var STREAM_TIMER_FREQUENCY:Int = 100;
	private static var STREAM_BUFFER_FREQUENCY:Int = 3;

	private var parent:AudioSource;
	private var disposed:Bool;
	private var streamed:Bool;
	private var playing:Bool;
	private var completed:Bool;

	private var handle:ALSource;
	private var buffers:Array<ALBuffer>;
	private var unusedBuffers:Array<ALBuffer>;
	private var timer:Timer;
	private var format:Int;
	private var samples:Float;

	private var streamTimer:Timer;
	private var bufferDatas:Array<ArrayBufferView>;
	private var bufferTimes:Array<Float>;
	private var bufferSizes:Array<Int>;
	private var bufferSize:Int;
	private var requestBuffers:Int;
	private var queuedBuffers:Int;
	private var toLoop:Int;
	private var streamEnded:Bool;
	private var dataLength:Float;

	private var position:Vector4 = new Vector4();
	private var length:Null<Float>;
	private var loopTime:Null<Float>;
	private var loops:Int;

	public function new(parent:AudioSource) this.parent = parent;

	public function dispose() {
		disposed = true;
		stop();

		if (handle != null) {
			AL.sourcei(handle, AL.BUFFER, AL.NONE);
			AL.deleteSource(handle);
		}
		handle = null;

		if (buffers != null) AL.deleteBuffers(buffers);
		buffers = null;
		bufferDatas = null;
		bufferTimes = null;
		bufferSizes = null;
		unusedBuffers = null;
	}

	public function init() {
		if (handle != null) return;

		if (disposed = (handle = AL.createSource()) == null) return;
		AL.sourcef(handle, AL.MAX_GAIN, 10);

		var buffer = parent.buffer;
		var channels = buffer.channels, bitsPerSample = buffer.bitsPerSample;

		// Default is just AL.FORMAT_MONO8 if it doesn't match any to avoid yo ears getting blasted
		var isCreativeXFi = AL.getString(AL.RENDERER) == "X-Fi";
		if (channels > 2 && (isCreativeXFi || AL.isExtensionPresent("AL_EXT_MCFORMATS"))) { // https://github.com/openalext/openalext/blob/master/AL_EXT_MCFORMATS.txt
			if (channels == 3) format = bitsPerSample == 32 ? 0x1209 : (bitsPerSample == 16 ? 0x1208 : 0x1207);
			else if (channels == 4) format = bitsPerSample == 32 ? 0x1206 : (bitsPerSample == 16 ? 0x1205 : 0x1204);
			else if (channels == 6) format = bitsPerSample == 32 ? 0x120C : (bitsPerSample == 16 ? 0x120B : 0x120A);
			else if (channels == 7) format = bitsPerSample == 32 ? 0x120F : (bitsPerSample == 16 ? 0x120E : 0x120D);
			else if (channels == 8) format = bitsPerSample == 32 ? 0x1212 : (bitsPerSample == 16 ? 0x1211 : 0x1210);
		}
		// The 32 bit for STEREO and MONO are undocumented? https://github.com/kcat/openal-soft/issues/934, though it only works in X-Fi OpenAL??
		else if (bitsPerSample == 32 && isCreativeXFi) format = channels == 2 ? 0x1203 : 0x1202;
		else if (channels == 2) format = bitsPerSample == 16 ? AL.FORMAT_STEREO16 : AL.FORMAT_STEREO8;
		else format = bitsPerSample == 16 ? AL.FORMAT_MONO16 : AL.FORMAT_MONO8;

		if (buffer.data != null) {
			streamed = false;
			samples = (dataLength = (buffer.data.length >> 0)) / buffer.channels / (buffer.bitsPerSample >> 3);

			if ((buffer.__srcBuffer == null || (AL.getBufferi(buffer.__srcBuffer, AL.SIZE) >> 0) != dataLength) && (buffer.__srcBuffer = AL.createBuffer()) != null)
				AL.bufferData(buffer.__srcBuffer, format, buffer.data, buffer.data.length, buffer.sampleRate);

			AL.sourcei(handle, AL.BUFFER, buffer.__srcBuffer);
		}
		#if lime_vorbis
		else if (buffer.__srcVorbisFile != null) {
			streamed = true;
			dataLength = (samples = getFloat(buffer.__srcVorbisFile.pcmTotal())) * buffer.channels * (buffer.bitsPerSample >> 3);

			var constructor = buffer.bitsPerSample == 32 ? Int32 : buffer.bitsPerSample == 16 ? Int16 : Int8;
			bufferSize = STREAM_BUFFER_SAMPLES * buffer.channels * (constructor == Int8 ? buffer.bitsPerSample >> 3 : 1);
			buffers = AL.genBuffers(STREAM_MAX_BUFFERS);
			bufferDatas = [for (i in 0...STREAM_MAX_BUFFERS) new ArrayBufferView(bufferSize, constructor)];
			bufferTimes = [for (i in 0...STREAM_MAX_BUFFERS) 0];
			bufferSizes = [for (i in 0...STREAM_MAX_BUFFERS) 0];
			unusedBuffers = [];
			bufferSize *= constructor == Int8 ? 1 : buffer.bitsPerSample >> 3;
		}
		#end

		if (dataLength == 0) {
			trace('NativeAudioSource Bug! dataLength is 0');
			dispose();
		}
	}

	public function play() {
		if (playing || disposed) return;

		var t = completed ? 0 : getCurrentTime();
		playing = true;
		setCurrentTime(t);
	}

	public function pause() {
		if (!disposed) AL.sourcePause(handle);

		playing = false;
		stopStreamTimer();
		stopTimer();
	}

	public function stop() {
		if (!disposed) {
			AL.sourceStop(handle);
			toLoop = 0;
		}

		playing = false;
		stopStreamTimer();
		stopTimer();
	}

	private function complete() {
		completed = true;
		stop();
		parent.onComplete.dispatch();
	}

	// Streaming, atleast for vorbis for now.
	// just incase if we support more than 1 in the future?? which i doubt
	private function streamTell():Float {
		#if lime_vorbis
		return parent.buffer.__srcVorbisFile.timeTell();
		#else
		return 0;
		#end
	}

	private function streamSeek(samples:Int64) {
		#if lime_vorbis
		// There's apparently a bug in libvorbis <= 1.3.4, hhttps://github.com/xiph/vorbis/blob/master/CHANGES#L39
		// But it seems to also happen in this lime libvorbis version which is 1.3.7...? -ralty
		if (samples < 4) parent.buffer.__srcVorbisFile.rawSeek(0); else parent.buffer.__srcVorbisFile.pcmSeek(samples);
		#end
	}

	private function readToBufferData(data:ArrayBufferView):Int {
		#if lime_vorbis
		var isBigEndian = lime.system.System.endianness == lime.system.Endian.BIG_ENDIAN, wordSize = parent.buffer.bitsPerSample >> 3;
		var size = dataLength - (streamTell() * parent.buffer.sampleRate * parent.buffer.channels * wordSize);
		var n:Int = size < bufferSize ? Math.floor(size) : bufferSize;
		n -= n % (parent.buffer.channels * wordSize);

		var total = 0, result = 0, wasEOF = false;
		while (total < bufferSize) {
			result = n > 0 ? parent.buffer.__srcVorbisFile.read(data.buffer, total, n, isBigEndian, wordSize, true) : 0;

			if (result == Vorbis.HOLE) continue;
			else if (result <= Vorbis.EREAD) break;
			else if (result == 0) {
				if (wasEOF || (streamEnded = loops <= toLoop)) break;
				else {
					wasEOF = true;
					toLoop++;

					var samples = getSamples(loopTime != null ? loopTime + parent.offset : parent.offset);
					streamSeek(samples);
					if ((size = dataLength - (getFloat(samples) * parent.buffer.channels * wordSize)) < (n = bufferSize - total)) n = Math.floor(size);
					n -= n % (parent.buffer.channels * wordSize);
				}
			}
			else {
				total += result;
				n -= result;
				wasEOF = false;
			}
		}

		if (total < bufferSize) data.buffer.fill(total, n, 0);
		if (result < 0) {
			trace('NativeAudioSource Streaming Bug! reading result is $result, streamEnded: $streamEnded, total: $total, n: $n');
			return result;
		}
		return total;
		#else
		return 0;
		#end
	}

	private function fillBuffer(buffer:ALBuffer):Int {
		var i = STREAM_MAX_BUFFERS - requestBuffers;
		var data = bufferDatas[i], time = streamTell();
		var decoded = readToBufferData(data);

		if (decoded > 0) {
			AL.bufferData(buffer, format, data, decoded, parent.buffer.sampleRate);

			var n = STREAM_MAX_BUFFERS - 1;
			while (i < n) {
				bufferDatas[i] = bufferDatas[i + 1];
				bufferTimes[i] = bufferTimes[i + 1];
				bufferSizes[i] = bufferSizes[++i];
			}
			queuedBuffers = requestBuffers;
			bufferDatas[n] = data;
			bufferTimes[n] = time;
			bufferSizes[n] = decoded;
		}

		return decoded;
	}

	private function streamRun() {
		if (parent == null || parent.buffer == null || handle == null) return dispose();
		if (!playing || disposed) return stopStreamTimer();

		try {
			var processed = AL.getSourcei(handle, AL.BUFFERS_PROCESSED), n = STREAM_BUFFER_FREQUENCY, buffer;
			while (processed-- > 0) {
				buffer = AL.sourceUnqueueBuffer(handle);
				if (!streamEnded && --n > 0 && fillBuffer(buffer) > 0) AL.sourceQueueBuffer(handle, buffer);
				else {
					queuedBuffers = --requestBuffers;
					unusedBuffers.push(buffer);
				}
			}

			if (!streamEnded) {
				if (unusedBuffers.length != 0) {
					requestBuffers++;
					if (fillBuffer(buffer = unusedBuffers.pop()) > 0) {
						queuedBuffers = requestBuffers;
						AL.sourceQueueBuffer(handle, buffer);
					}
					else {
						requestBuffers--;
						unusedBuffers.push(buffer);
					}
				}
				else if (queuedBuffers < STREAM_MAX_BUFFERS) {
					if (fillBuffer(buffer = buffers[requestBuffers++]) > 0) AL.sourceQueueBuffer(handle, buffer);
					else requestBuffers--;
				}
			}
		}
		catch(e) trace('NativeAudioSource Bug! in streamRun $e');

		if (AL.getSourcei(handle, AL.SOURCE_STATE) == AL.STOPPED) {
			AL.sourcePlay(handle);
			resetTimer((getLength() - getCurrentTime()) / getPitch());
		}
	}

	// Timers
	inline function stopStreamTimer() {
		if (streamTimer != null) streamTimer.stop();
		streamTimer = null;
	}

	private function resetStreamTimer() {
		stopStreamTimer();
		if (streamed) (streamTimer = new Timer(STREAM_TIMER_FREQUENCY)).run = streamRun;
	}

	inline function stopTimer() {
		if (timer != null) timer.stop();
		timer = null;
	}

	private function resetTimer(timeRemaining:Float) {
		stopTimer();
		(timer = new Timer(timeRemaining)).run = timer_onRun;
	}

	private function timer_onRun() {
		var timeRemaining = (getLength() - getCurrentTime()) / getPitch();
		if (timeRemaining > 100 && AL.getSourcei(handle, AL.SOURCE_STATE) == AL.PLAYING && (!streamed || !streamEnded)) {
			resetTimer(timeRemaining);
			return;
		}

		if (loops == 0) {
			complete();
			return;
		}

		var start = loopTime != null ? loopTime : 0;
		if (toLoop <= 0) {
			setLoops(--loops);
			if (start > 0 || AL.getSourcei(handle, AL.SOURCE_STATE) != AL.PLAYING) setCurrentTime(start);
			else resetTimer((getLength() - start) / getPitch());
		}
		else {
			if ((loops -= toLoop) < 0) loops = 0;
			toLoop = 0;
			resetTimer((getLength() - start) / getPitch());
		}

		parent.onLoop.dispatch();
	}

	// Get & Set Methods
	public function getCurrentTime():Float {
		if (disposed) return 0;
		else if (completed) return getLength();

		var time = AL.getSourcef(handle, AL.SAMPLE_OFFSET) / parent.buffer.sampleRate;
		if (streamed) {
			if (playing && streamEnded && AL.getSourcei(handle, AL.SOURCE_STATE) == AL.STOPPED) {
				complete();
				return getLength();
			}
			else
				time += bufferTimes[STREAM_MAX_BUFFERS - queuedBuffers];
		}
		time *= 1000;

		var length = if (length == null) getRealLength(); else length;
		if (loops > 0 && time > length) {
			var start = loopTime != null ? Math.max(0, loopTime) : 0;
			return ((time - start) % (length - start)) + start - parent.offset;
		}

		return time - parent.offset;
	}

	public function setCurrentTime(value:Float):Float {
		if (disposed) return value;

		if (streamed) AL.sourceStop(handle);
		else AL.sourcei(handle, AL.SAMPLE_OFFSET, getSamples(value + parent.offset));

		if (playing) {
			var timeRemaining = (getLength() - value) / getPitch();
			if (timeRemaining < 8 && value > 8) complete();
			else {
				completed = streamEnded = false;
				if (streamed) {
					AL.sourceUnqueueBuffers(handle, AL.getSourcei(handle, AL.BUFFERS_QUEUED));

					unusedBuffers.resize(0);
					streamSeek(getSamples(value + parent.offset));

					requestBuffers = queuedBuffers = STREAM_BUFFER_FREQUENCY;
					for (i in 0...queuedBuffers) {
						if (!streamEnded && fillBuffer(buffers[i]) > 0) AL.sourceQueueBuffer(handle, buffers[i]);
						else queuedBuffers = --requestBuffers;
					}

					if (!streamEnded) resetStreamTimer();
				}

				resetTimer(timeRemaining);
				AL.sourcePlay(handle);
			}
		}
		else
			completed = false;

		if (!playing && streamed) bufferTimes[STREAM_MAX_BUFFERS - (requestBuffers = queuedBuffers = 1)] = value / 1000;

		return value;
	}

	inline private function getRealLength():Float return samples / parent.buffer.sampleRate * 1000;
	public function getLength():Null<Float>
		return if (disposed) 0; else if (length == null) getRealLength() - parent.offset; else length - parent.offset;

	public function setLength(value:Null<Float>):Null<Float> {
		if (value == length || disposed) return length = value;

		var buffer = parent.buffer, wordSize = buffer.bitsPerSample >> 3;
		if ((length = value) == null) dataLength = streamed ? samples * buffer.channels * wordSize : getFloat(Int64.make(0, buffer.data.length));
		else dataLength = Math.ffloor(Math.max(0, Math.min(value, getRealLength())) / 1000 * buffer.sampleRate) * buffer.channels * wordSize;

		if (playing) {
			if (streamed && (streamEnded || toLoop > 0)) setCurrentTime(getCurrentTime());
			else {
				var timeRemaining = ((getLength() - parent.offset) - getCurrentTime()) / getPitch();
				if (timeRemaining > 0) resetTimer(timeRemaining);
			}
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
		if (!streamed && !disposed) AL.sourcei(handle, AL.LOOPING, (loopTime <= 0 && value > 0) ? AL.TRUE : AL.FALSE);
		else if (loops == 0 && value > 0) setCurrentTime(getCurrentTime());
		if (value < 0) return loops = 0;
		return loops = value;
	}

	inline public function getLoopTime():Float return loopTime;

	inline public function setLoopTime(value:Float):Float {
		if (!streamed && !disposed) AL.sourcei(handle, AL.LOOPING, (value <= 0 && loops > 0) ? AL.TRUE : AL.FALSE);
		return loopTime = value;
	}

	public function getLatency():Float {
		/*#if (lime >= "8.3.0")
		if (AL.isExtensionPresent("AL_SOFT_source_latency")) {
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

	inline private function getFloat(x:Int64):Float return x.high * 4294967296. + (x.low >> 0);
	inline private function getSamples(ms:Float):Int64 return Int64.fromFloat(Math.max(0, Math.min(ms / 1000 * parent.buffer.sampleRate, samples)));
}