package funkin.backend.utils;

import flixel.sound.FlxSound;
import lime.media.AudioBuffer;
import lime.utils.ArrayBufferView.ArrayBufferIO;
import lime.utils.ArrayBuffer;

#if (lime_cffi && lime_vorbis)
import lime.media.vorbis.Vorbis;
import lime.media.vorbis.VorbisFile;
#end

#if (target.threaded)
import sys.thread.Mutex;
#end

typedef AudioAnalyzerCallback = Int->Int->Void;

/**
 * An utility that analyze FlxSounds,
 * can be used to make waveform or real-time audio visualizer.
 * 
 * FlxSound.amplitude does work in CNE so if any case if your only checking for peak of current
 * time, use that instead.
 */
final class AudioAnalyzer {
	/**
	 * Get bytes from an audio buffer with specified position and wordSize
	 * @param buffer The audio buffer to get byte from.
	 * @param position The specified position to get the byte from the audio buffer.
	 * @param wordSize How many bytes to get with to one byte (Usually it's bitsPerSample / 8 or bitsPerSample >> 3).
	 * @return Byte from the audio buffer with specified position.
	 */
	public static function getByte(buffer:ArrayBuffer, position:Int, wordSize:Int):Int {
		if (wordSize == 2) return inline ArrayBufferIO.getInt16(buffer, position);
		else if (wordSize == 3) {
			var b = inline ArrayBufferIO.getUint16(buffer, position) | (buffer.get(position + 2) << 16);
			if (b & 0x800000 != 0) return b - 0x1000000;
			else return b;
		}
		else if (wordSize == 4) return inline ArrayBufferIO.getInt32(buffer, position);
		else return inline ArrayBufferIO.getUint8(buffer, position) - 128;
	}

	/**
	 * Gets levels from the frequencies with specified sample rate.
	 * @param frequencies Frequencies input.
	 * @param sampleRate Sample Rate input.
	 * @param barCount How much bars to get.
	 * @param levels The output for getting the values, to avoid memory leaks (Optional).
	 * @param ratio How much ratio for smoothen the values from the previous levels values (Optional, use CoolUtil.getFPSRatio(1 - ratio) to simulate web AnalyserNode.smoothingTimeConstant, 0.35 of smoothingTime works most of the time).
	 * @param minDb The minimum decibels to cap (Optional, default -63.0, -120 is pure silence).
	 * @param maxDb The maximum decibels to cap (Optional, default -10.0, Above 0 is not recommended).
	 * @param minFreq The minimum frequency to cap (Optional, default 20.0, Below 8.0 is not recommended).
	 * @param maxFreq The maximum frequency to cap (Optional, default 22000.0, Above 23000.0 is not recommended).
	 * @return Output of levels/bars that ranges from 0 to 1.
	 */
	public static function getLevelsFromFrequencies(frequencies:Array<Float>, sampleRate:Int, barCount:Int, ?levels:Array<Float>, ratio = 0.0, minDb = -63.0, maxDb = -10.0, minFreq = 20.0, maxFreq = 22000.0):Array<Float> {
		if (levels == null) levels = [];
		levels.resize(barCount);

		var logMin = Math.log(minFreq), logMax = Math.log(maxFreq);
		var logRange = logMax - logMin, dbRange = maxDb - minDb, n = frequencies.length;
		inline function calculateScale(i:Int)
			return CoolUtil.bound(Math.exp(logMin + (logRange * i / (barCount + 1))) * n * 2 / sampleRate, 0, n - 1);

		var s1 = calculateScale(0), s2;
		var i1 = Math.floor(s1), i2;
		var v, range;
		for (i in 0...barCount) {
			if ((range = (s2 = calculateScale(i + 1)) - s1) < 1) {
				i2 = Math.ceil(s2);
				if (i2 == i1) v = frequencies[i1] * range;
				else v = (frequencies[i1] + (frequencies[i2] - frequencies[i1]) * (s1 - i1)) * range;
			}
			else {
				v = frequencies[i1] * (Math.ceil(s1) - i1);
				if (i1 != (i2 = Math.floor(s2))) {
					while (++i1 < i2) v += frequencies[i1];
					v += frequencies[i2] * (s2 - Math.floor(s2));
				}
			}
			i1 = Math.floor(s1 = s2);

			v = CoolUtil.bound(((20 * Math.log(v) / 2.302585092994046) - minDb) / dbRange, 0, 1);
			if (ratio > 0 && ratio < 1 && v < levels[i]) levels[i] -= (levels[i] - v) * ratio;
			else levels[i] = v;
		}

		return levels;
	}

	static var __reverseIndices:Array<Array<Int>> = [];
	static var __windows:Array<Array<Float>> = [];
	static var __twiddleReals:Array<Array<Float>> = [];
	static var __twiddleImags:Array<Array<Float>> = [];
	static var __freqReals:Array<Array<Float>> = [];
	static var __freqImags:Array<Array<Float>> = [];
	#if (target.threaded)
	static var __mutex:Mutex = new Mutex();
	static var __freqCalculating:Int = 0;
	#end

	/**
	 * Gets frequencies from the samples.
	 * @param samples The samples (can be from AudioAnalyzer.getSamples).
	 * @param fftN How much samples for the fft to get, Has to be power of two, or it won't work.
	 * @param useWindowing Should fft related stuff use blackman windowing? (Web AnalyzerNode windowing), Most of the time it's not worth it.
	 * @param frequencies The output for getting the frequencies, to avoid memory leaks (Optional).
	 * @return Output of frequencies.
	 */
	public static function getFrequenciesFromSamples(samples:Array<Float>, fftN = 2048, useWindowing = false, ?frequencies:Array<Float>):Array<Float> {
		var log = Math.floor(Math.log(fftN) / 0.6931471805599453);
		if (log == 0) throw "AudioAnalyzer.getFrequenciesFromSamples: Cannot insert a fftN of 1";

		var i = log - 1;
		fftN = 1 << log;

		#if (target.threaded) __mutex.acquire(); #end
		var reals:Array<Float> = __freqReals[__freqCalculating], imags:Array<Float> = __freqImags[__freqCalculating];
		if (reals == null) {
			__freqReals.push(reals = []);
			__freqImags.push(imags = []);
		}
		__freqCalculating++;

		var reverseIndices:Array<Int> = __reverseIndices[i];
		var windows:Array<Float> = __windows[i];
		var twiddleReals:Array<Float> = __twiddleReals[i];
		var twiddleImags:Array<Float> = __twiddleImags[i];

		if (reverseIndices == null) {
			__reverseIndices.resize(log);
			__windows.resize(log);
			__twiddleReals.resize(log);
			__twiddleImags.resize(log);

			(reverseIndices = []).resize(fftN);
			(windows = []).resize(fftN);
			(twiddleReals = []).resize(fftN);
			(twiddleImags = []).resize(fftN);

			var f;
			for (i in 0...fftN) {
				f = 2 * Math.PI * (i / fftN);
				windows[i] = 0.42 - 0.5 * Math.cos(f) + 0.08 * Math.cos(2 * f);
				reverseIndices[i] = __bitReverse(i, log);
				twiddleReals[i] = Math.cos(-f);
				twiddleImags[i] = Math.sin(-f);
			}

			__reverseIndices[i] = reverseIndices;
			__windows[i] = windows;
			__twiddleReals[i] = twiddleReals;
			__twiddleImags[i] = twiddleImags;
		}

		#if (target.threaded) __mutex.release(); #end

		if (fftN > reals.length) {
			reals.resize(fftN);
			imags.resize(fftN);
		}

		if (frequencies == null) frequencies = [];
		frequencies.resize(1 << i);

		i = samples.length;
		while (i > 0) {
			i--;
			if (useWindowing) reals[reverseIndices[i]] = samples[i] * windows[i];
			else reals[reverseIndices[i]] = samples[i];
			imags[i] = 0;
		}

		var size = 1, n = fftN, half = 1, k, i0, i1, t, tr:Float, ti:Float;
		while ((size <<= 1) < fftN) {
			n >>= 1;
			i = 0;
			while (i < fftN) {
				k = 0;
				while (k < half) {
					i1 = (i0 = i + k) + half;
					t = (k * n) % fftN;

					tr = reals[i1] * twiddleReals[t] - imags[i1] * twiddleImags[t];
					ti = reals[i1] * twiddleImags[t] + imags[i1] * twiddleReals[t];
					reals[i1] = reals[i0] - tr;
					imags[i1] = imags[i0] - ti;
					reals[i0] += tr;
					imags[i0] += ti;

					k++;
				}
				i += size;
			}
			half = size;
		}

		tr = 1.0 / fftN;
		i = 1 << (log - 1);
		while (i > 1) {
			i--;
			frequencies[i] = 2 * Math.sqrt(reals[i] * reals[i] + imags[i] * imags[i]) * tr;
		}
		frequencies[0] = Math.sqrt(reals[0] * reals[0] + imags[0] * imags[0]) * tr;

		#if (target.threaded) __mutex.acquire(); #end
		__freqCalculating--;
		#if (target.threaded) __mutex.release(); #end

		return frequencies;
	}

	static function __bitReverse(x:Int, log:Int):Int {
		var y = 0, i = log;
		while (i > 0) {
			y = (y << 1) | (x & 1);
			x >>= 1;
			i--;
		}
		return y;
	}

	/**
	 * The current sound to analyze.
	 */
	public var sound:FlxSound;

	/**
	 * How much samples for the fft to get.
	 * Usually for getting the levels or frequencies of the sound.
	 * 
	 * Has to be power of two, or it won't work.
	 */
	public var fftN:Int;

	/**
	 * Should fft related stuff use blackman windowing? (Web AnalyzerNode windowing).
	 * Most of the time looks bad with this.
	 */
	public var useWindowingFFT:Bool;

	/**
	 * The current buffer from sound.
	 */
	public var buffer(default, null):AudioBuffer;

	/**
	 * The current byteSize from buffer.
	 * Example the byteSize of 16 BitsPerSample is 32768 (1 << 16-1)
	 */
	public var byteSize(default, null):Int;

	var __toBits:Float;
	var __wordSize:Int;
	var __sampleSize:Int;

	#if (lime_cffi && lime_vorbis)
	var __vorbis:VorbisFile;
	var __buffer:ArrayBuffer;
	var __bufferSize:Int;
	var __bufferLastSize:Int;
	var __bufferTime:Float;
	var __bufferLastTime:Float;
	#end

	// analyze
	var __min:Array<Int> = [];
	var __max:Array<Int> = [];
	var __minByte:Int;
	var __maxByte:Int;

	// samples
	var __sampleIndex:Int;
	var __sampleChannel:Int;
	var __sampleToValue:Float;
	var __sampleOutputMerge:Bool;
	var __sampleOutputLength:Int;
	var __sampleOutput:Array<Float>;

	// frequencies
	var __freqSamples:Array<Float>;
	var __frequencies:Array<Float>;

	/**
	 * Creates an analyzer for specified FlxSound
	 * @param sound An FlxSound to analyze.
	 * @param fftN How much samples for fft to get (Optional, default 2048, 4096 is recommended for highest quality).
	 * @param useWindowingFFT Should fft related stuff use blackman windowing? (Web AnalyzerNode windowing).
	 */
	public function new(sound:FlxSound, fftN = 2048, useWindowingFFT = false) {
		this.sound = sound;
		this.fftN = fftN;
		this.useWindowingFFT = useWindowingFFT;
		__check();
	}

	function __check() if (sound.buffer != buffer) {
		byteSize = 1 << ((buffer = sound.buffer).bitsPerSample - 1);

		#if (lime_cffi && lime_vorbis)
		__vorbis = null;
		__bufferLastSize = 0;
		__bufferTime = Math.NaN;
		__bufferLastTime = Math.NaN;
		#end

		__toBits = buffer.sampleRate / 1000 * (__sampleSize = buffer.channels * (__wordSize = buffer.bitsPerSample >> 3));
		__min.resize(buffer.channels);
		__max.resize(buffer.channels);
	}

	/**
	 * Gets levels from an attached FlxSound from startPos, basically a minimized of frequencies.
	 * @param startPos Start Position to get from sound in milliseconds.
	 * @param volume How much volume multiplier will it affect the output. (Optional, default 1.0).
	 * @param barCount How much bars to get.
	 * @param levels The output for getting the values, to avoid memory leaks (Optional).
	 * @param ratio How much ratio for smoothen the values from the previous levels values (Optional, use CoolUtil.getFPSRatio(1 - ratio) to simulate web AnalyserNode.smoothingTimeConstant, 0.35 of smoothingTime works most of the time).
	 * @param minDb The minimum decibels to cap (Optional, default -63.0, -120 is pure silence).
	 * @param maxDb The maximum decibels to cap (Optional, default -10.0, Above 0 is not recommended).
	 * @param minFreq The minimum frequency to cap (Optional, default 20.0, Below 8.0 is not recommended).
	 * @param maxFreq The maximum frequency to cap (Optional, default 22000.0, Above 23000.0 is not recommended).
	 * @return Output of levels/bars that ranges from 0 to 1.
	 */
	public function getLevels(startPos:Float, ?volume:Float, barCount:Int, ?levels:Array<Float>, ?ratio:Float, ?minDb:Float, ?maxDb:Float, ?minFreq:Float, ?maxFreq:Float):Array<Float>
		return inline getLevelsFromFrequencies(__frequencies = getFrequencies(startPos, volume, __frequencies), buffer.sampleRate, barCount, levels, ratio, minDb, maxDb, minFreq, maxFreq);

	/**
	 * Gets frequencies from an attached FlxSound from startPos.
	 * @param startPos Start Position to get from sound in milliseconds.
	 * @param volume How much volume multiplier will it affect the output. (Optional, default 1.0).
	 * @param frequencies The output for getting the frequencies, to avoid memory leaks (Optional).
	 * @return Output of frequencies.
	 */
	public function getFrequencies(startPos:Float, ?volume:Float, ?frequencies:Array<Float>):Array<Float>
		return inline getFrequenciesFromSamples(__freqSamples = getSamples(startPos, fftN, true, -1, volume, __freqSamples), fftN, useWindowingFFT, frequencies);

	/**
	 * Analyzes an attached FlxSound from startPos to endPos in milliseconds to get the amplitudes.
	 * @param startPos Start Position to get from sound in milliseconds.
	 * @param endPos End Position to get from sound in milliseconds.
	 * @param outOrOutMin The output minimum value from the analyzer, indices is in channels (0 to -0.5 -> 0 to 0.5) (Optional, if outMax doesn't get passed in, it will be [min, max] with all channels combined instead).
	 * @param outMax The output maximum value from the analyzer, indices is in channels (Optional).
	 * @return Output of amplitude from given position.
	 */
	public function analyze(startPos:Float, endPos:Float, ?outOrOutMin:Array<Float>, ?outMax:Array<Float>):Float {
		var hasOut = outOrOutMin != null;
		var hasTwoOut = hasOut && outMax != null;

		if (hasTwoOut) for (i in 0...buffer.channels) __min[i] = __max[i] = 0;
		__minByte = __maxByte = 0;

		__check();
		__read(startPos, endPos, hasTwoOut ? __analyzeCallback : __analyzeCallbackSimple);

		if (hasOut) {
			var f:Float;
			if (hasTwoOut) for (i in 0...buffer.channels) {
				if (outOrOutMin[i] < (f = __min[i] / byteSize)) outOrOutMin[i] = f;
				if (outMax[i] < (f = __max[i] / byteSize)) outMax[i] = f;
			}
			else {
				outOrOutMin.resize(2);
				if (outOrOutMin[0] < (f = __minByte / byteSize)) outOrOutMin[0] = f;
				if (outOrOutMin[1] < (f = __maxByte / byteSize)) outOrOutMin[1] = f;
			}
		}

		return (__maxByte + __minByte) / byteSize;
	}

	function __analyzeCallback(b:Int, c:Int):Void
		((b > __max[c]) ? (if ((__max[c] = b) > __maxByte) (__maxByte = b)) : (if (-b > __min[c]) (if ((__min[c] = -b) > __minByte) (__minByte = __min[c]))));

	function __analyzeCallbackSimple(b:Int, c:Int):Void
		((b > __maxByte) ? (__maxByte = b) : (if (-b > __minByte) (__minByte = -b)));

	/**
	 * Gets samples from startPos with given length of samples.
	 * @param startPos Start Position to get from sound in milliseconds.
	 * @param length Length of Samples.
	 * @param mono Merge all of the byte channels of samples in one channel instead (Optional).
	 * @param channel What channels to get from? (-1 == All Channels, Optional, this will be ignored if mono is enabled).
	 * @param volume How much volume multiplier will it affect the output. (Optional, default 1.0).
	 * @param output An Output that gets passed into this function, usually for to avoid memory leaks (Optional).
	 * @param outputMerge Merge with previous values (Optional, default false).
	 * @return Output of samples.
	 */
	public function getSamples(startPos:Float, length:Int, mono = true, channel = -1, volume = 1.0, ?output:Array<Float>, ?outputMerge = false):Array<Float> {
		((!mono && (__sampleChannel = channel) == -1) ? (__sampleOutputLength = length * buffer.channels) : (__sampleOutputLength = length));
		((output == null) ? (__sampleOutput = output = []) : (__sampleOutput = output)).resize(__sampleOutputLength);
		((mono) ? (__sampleToValue = volume / (byteSize * buffer.channels)) : (__sampleToValue = 1.0 / byteSize));
		__sampleOutputMerge = outputMerge;
		__sampleIndex = 0;

		__check();
		__read(startPos, startPos + (length / __toBits * buffer.channels), mono ? __getSamplesCallbackMono : (channel == -1 ? __getSamplesCallback : __getSamplesCallbackChannel));

		__sampleOutput = null;
		return output;
	}

	function __getSamplesCallbackMono(b:Int, c:Int):Void if (__sampleIndex < __sampleOutputLength) {
		if (c == 0) {
			if (__sampleOutputMerge) __sampleOutput[__sampleIndex] += b * __sampleToValue;
			else __sampleOutput[__sampleIndex] = b * __sampleToValue;
		}
		else if (c == buffer.channels) {
			__sampleOutput[__sampleIndex] += b * __sampleToValue;
			__sampleIndex++;
		}
		else
			__sampleOutput[__sampleIndex] += b * __sampleToValue;
	}

	function __getSamplesCallbackChannel(b:Int, c:Int):Void if (__sampleIndex < __sampleOutputLength) {
		if (c == __sampleChannel) {
			if (__sampleOutputMerge) __sampleOutput[__sampleIndex] += b * __sampleToValue;
			else __sampleOutput[__sampleIndex] = b * __sampleToValue;
			__sampleIndex++;
		}
	}

	function __getSamplesCallback(b:Int, c:Int):Void if (__sampleIndex < __sampleOutputLength) {
		if (__sampleOutputMerge) __sampleOutput[__sampleIndex] += b * __sampleToValue;
		else __sampleOutput[__sampleIndex] = b * __sampleToValue;
		__sampleIndex++;
	}

	/**
	 * Read an attached FlxSound from startPos to endPos in milliseconds with a callback.
	 * @param startPos Start Position to get from sound in milliseconds.
	 * @param endPos End Position to get from sound in milliseconds.
	 * @param callback Int->Int->Void Byte->Channels->Void Callback to get the byte of a sample.
	 */
	public function read(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback) {
		__check();
		__read(startPos, endPos, callback);
	}

	inline function __read(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback) {
		if (buffer.data != null) __readData(startPos, endPos, callback);
		#if lime_cffi
		else if (__canReadStream() && (startPos += __readStream(startPos, endPos, callback)) >= endPos) {}
		#if lime_vorbis
		else if (__prepareDecoder()) __readDecoder(startPos, endPos, callback);
		#end
		#end
	}

	inline function __readData(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback) {
		var pos = Math.floor(startPos * __toBits), end = Math.min(Math.floor(endPos * __toBits), buffer.data.buffer.length), c = 0;
		pos -= pos % __sampleSize;
		end -= end % __sampleSize;

		while (pos < end) {
			callback(getByte(buffer.data.buffer, pos, __wordSize), c);
			if (++c > buffer.channels) c = 0;
			pos += __wordSize;
		}
	}

	#if lime_cffi
	inline function __canReadStream():Bool
		@:privateAccess return sound._source != null && sound._source.__backend != null && sound._source.__backend.playing;

	inline function __readStream(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback):Float @:privateAccess {
		var backend = sound._source.__backend;
		var i = backend.bufferSizes.length - backend.queuedBuffers;
		var time = backend.bufferTimes[i] * 1000;

		var n = Math.floor((endPos - startPos) * __toBits);
		if (startPos >= time && startPos < backend.bufferTimes[backend.bufferSizes.length - 1] * 1000) {
			var pos = Math.floor((startPos - time) * __toBits), buf = backend.bufferDatas[i].buffer, size = backend.bufferSizes[i], c = 0;
			while (pos >= size) {
				if (++i >= backend.bufferSizes.length) {
					n = 0;
					break;
				}
				pos -= size;
				buf = backend.bufferDatas[i].buffer;
				size = backend.bufferSizes[i];
			}
			pos -= pos % __sampleSize;
			n -= pos % __sampleSize;

			while (n > 0) {
				callback(getByte(buf, pos, __wordSize), c);
				if (++c > buffer.channels) c = 0;
				if ((pos += __wordSize) >= size) {
					if (++i >= backend.bufferSizes.length) break;
					pos = 0;
					buf = backend.bufferDatas[i].buffer;
					size = backend.bufferSizes[i];
				}
				n -= __wordSize;
			}
		}

		return endPos - (n / __toBits);
	}

	#if lime_vorbis
	inline function __prepareDecoder():Bool @:privateAccess {
		if (buffer.__srcVorbisFile == null) return __vorbis != null;
		if (__vorbis != null) return true;
		if ((__vorbis = buffer.__srcVorbisFile.clone()) != null) { // IM HOPING IT HAVE A GC CLOSURE.
			__buffer = new ArrayBuffer(__bufferSize = (buffer.sampleRate >> 1) * __sampleSize); // 0.5 seconds of buffers.
			return true;
		}
		return false;
	}

	inline function __readDecoder(startPos:Float, endPos:Float, callback:AudioAnalyzerCallback) {
		var n = Math.floor((endPos - startPos) * __toBits);
		if ((n -= n % __sampleSize) > 0) {
			var pos = Math.floor((startPos - __bufferTime * 1000) * __toBits);
			pos -= pos % __sampleSize;

			var doRead = __bufferLastSize == 0 || (pos < 0 && pos >= __bufferSize);
			if (doRead) {
				if (startPos < 1) {
					__vorbis.rawSeek(0);
					__bufferTime = 0;
				}
				else
					__vorbis.timeSeek(__bufferTime = startPos / 1000);

				__bufferLastSize = pos = 0;
			}

			var isBigEndian = lime.system.System.endianness == lime.system.Endian.BIG_ENDIAN, ranOut = false, c = 0, result;
			while (true) {
				if (doRead) {
					result = __vorbis.read(__buffer, pos, __bufferSize - pos, isBigEndian, __wordSize, true);
					if (result == Vorbis.HOLE) continue;
					else if (result < 0) break;
					else if (!(ranOut = result == 0)) {
						__bufferLastTime = __vorbis.timeTell();
						__bufferLastSize += result;
						while (pos < __bufferLastSize) {
							callback(getByte(__buffer, pos, __wordSize), c);
							if (++c > buffer.channels) c = 0;
							pos += __wordSize;
							if ((n -= __wordSize) <= 0) break;
						}
					}
				}
				else {
					while (pos < __bufferLastSize) {
						callback(getByte(__buffer, pos, __wordSize), c);
						if (++c > buffer.channels) c = 0;
						pos += __wordSize;
						if ((n -= __wordSize) <= 0) break;
					}
					doRead = true;
					ranOut = pos >= __bufferSize;
				}

				if (n <= 0) break;
				else if (doRead && ranOut) {
					__bufferLastSize = pos = 0;
					__bufferTime = __bufferLastTime;
				}
			}
		}
	}
	#end
	#end
}