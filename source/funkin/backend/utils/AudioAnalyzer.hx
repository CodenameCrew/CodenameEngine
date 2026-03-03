package funkin.backend.utils;

#if lime_openal
import sys.thread.Mutex;

import lime.utils.ArrayBufferView.ArrayBufferIO;
import lime.utils.ArrayBuffer;

import flixel.sound.FlxSound;
import flixel.sound.FlxSoundData;

typedef ReadCallback = Int->Int->Void;
typedef WindowFunction = Float->Float;

final class WindowFunctions {
	static inline final TWO_PI:Float = 6.283185307179586;
	static inline final FOUR_PI:Float = 12.566370614359172;
	static inline final SIX_PI:Float = 18.84955592153876;
	static inline final EIGHT_PI:Float = 25.132741228718345;

	public static inline function triangular(x:Float):Float
		return 1.0 - Math.abs(x - 0.5) * 2.0;

	public static inline function hann(x:Float):Float
		return 0.5 - 0.5 * FlxMath.fastCos(TWO_PI * x);

	public static inline function hamming(x:Float):Float
		return 0.53836 - 0.46164 * FlxMath.fastCos(TWO_PI * x);

	public static inline function blackmanNuttall(x:Float):Float
		return 0.3635819 - 0.4891775 * FlxMath.fastCos(TWO_PI * x) + 0.1365995 * FlxMath.fastCos(FOUR_PI * x)
			- 0.0106411 * FlxMath.fastCos(SIX_PI * x);

	public static inline function blackmanHarris(x:Float):Float
		return 0.4243801 - 0.4973406 * FlxMath.fastCos(TWO_PI * x) + 0.0782793 * FlxMath.fastCos(FOUR_PI * x);

	public static inline function flatTop(x:Float):Float
		return 0.21557895 - 0.41663158 * FlxMath.fastCos(TWO_PI * x) + 0.277263158 * FlxMath.fastCos(FOUR_PI * x)
			+ 0.083578947 * FlxMath.fastCos(SIX_PI * x) + 0.006947368 * FlxMath.fastCos(EIGHT_PI * x);
}

enum abstract TimeUnit(Int) from Int to Int {
	var MILLISECOND = 0;
	var SECOND = 1;
	var SAMPLE = 2;
}

/**
 * An utility that analyze FlxSound,
 * can be used to make waveform or real-time audio visualizer.
 */
final class AudioAnalyzer {
	/**
	 * Get bytes from an audio buffer with specified position and wordSize
	 * @param	buffer The audio buffer to get byte from.
	 * @param	position The specified position to get the byte from the audio buffer.
	 * @param	wordSize How many bytes to get with to one byte (Usually it's bitsPerSample / 8 or bitsPerSample >> 3).
	 * @return Byte from the audio buffer with specified position.
	 */
	public static function getByte(buffer:ArrayBuffer, position:Int, wordSize:Int):Int {
		if (wordSize == 2) return ArrayBufferIO.getInt16(buffer, position);
		else if (wordSize == 3) {
			wordSize = ArrayBufferIO.getUint16(buffer, position) | (buffer.get(position + 2) << 16);
			if (wordSize & 0x800000 != 0) return wordSize - 0x1000000;
			else return wordSize;
		}
		else if (wordSize == 4) return ArrayBufferIO.getInt32(buffer, position);
		else return ArrayBufferIO.getInt8(buffer, position);
	}

	/**
	 * Gets spectrum from the frequencies with specified sample rate.
	 * @param	frequencies	Frequencies input.
	 * @param	sampleRate	Sample Rate input.
	 * @param	barCount	How much bars to get.
	 * @param	spectrum	The output for getting the values, to avoid memory leaks (Optional).
	 * @param	ratio		How much ratio for smoothen the values from the previous spectrum values (Optional, use FlxMath.getElapsedLerp(1 - ratio) to simulate web AnalyserNode.smoothingTimeConstant, 0.35 of smoothingTime works most of the time).
	 * @param	minDb		The minimum decibels to cap (Optional, default -63.0, -120 is pure silence).
	 * @param	maxDb		The maximum decibels to cap (Optional, default -10.0, Above 0 is not recommended).
	 * @param	minFreq		The minimum frequency to cap (Optional, default 20.0, Below 8.0 is not recommended).
	 * @param	maxFreq		The maximum frequency to cap (Optional, default 20000.0, Above 23000.0 is not recommended).
	 * @return	Output of spectrum/bars that ranges from 0 to 1.
	 */
	public static function getSpectrumFromFrequencies(frequencies:Array<Float>, sampleRate:Int, barCount:Int, ?spectrum:Array<Float>, ratio = 0.0, minDb = -63.0, maxDb = -10.0, minFreq = 20.0, maxFreq = 20000.0):Array<Float> {
		if (spectrum == null) spectrum = [];
		if (spectrum.length != barCount) spectrum.resize(barCount);

		var logMin = Math.log(minFreq), n = frequencies.length - 1;
		var logRange = Math.log(maxFreq) - logMin, dbRangeRate = 1 / (maxDb - minDb), rate = frequencies.length * 2 / sampleRate;
		inline function calculateScale(i:Int)
			return FlxMath.bound(Math.exp(logMin + (logRange * i / (barCount + 1))) * rate, 0, n);

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

			v = FlxMath.bound((Math.log(v) * 8.685889638065035 - minDb) * dbRangeRate, 0, 1);
			if (ratio > 0 && ratio < 1 && v < spectrum[i]) spectrum[i] -= (spectrum[i] - v) * ratio;
			else spectrum[i] = v;
		}

		return spectrum;
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
	 * 
	 * deprecated, use getSpectrumFromFrequencies instead.
	 */
	@:deprecated("Use getSpectrumFromFrequencies instead of getLevelsFromFrequencies.")
	public static function getLevelsFromFrequencies(frequencies:Array<Float>, sampleRate:Int, barCount:Int, ?levels:Array<Float>, ratio = 0.0, minDb = -63.0, maxDb = -10.0, minFreq = 20.0, maxFreq = 22000.0):Array<Float>
		return inline getSpectrumFromFrequencies(frequencies, sampleRate, barCount, levels, ratio, minDb, maxDb, minFreq, maxFreq);

	static final _permutations:Map<Int, Array<Int>> = [];
	static final _twiddleReals:Map<Int, Array<Float>> = [];
	static final _twiddleImags:Map<Int, Array<Float>> = [];
	static final _reals:Array<Array<Float>> = [];
	static final _imags:Array<Array<Float>> = [];
	static var _freqCalculating:Int = 0;
	static final _mutex = new Mutex();

	/**
	 * Gets frequencies from the samples.
	 * @param	samples		The samples (can be from FunkinAudioAnalyzer.getSamples).
	 * @param	window		The windowing function to use when passed.
	 * @param	frequencies	The output for getting the frequencies, to avoid memory leaks (Optional).
	 * @return	Output of frequencies.
	 */
	public static function getFrequenciesFromSamples(samples:Array<Float>, ?window:WindowFunction, ?frequencies:Array<Float>, ?fftN:Int):Array<Float> {
		if (fftN == null) fftN = samples.length;

		var bits = 0;
		while ((fftN >>= 1) > 0) bits++;
		if (bits == 0) throw "FunkinAudioAnalyzer.getFrequenciesFromSamples: Cannot insert a sample length or fftN of 1";

		fftN = 1 << bits;
		var fftN2 = fftN >> 1, n = fftN - 1;

		var permutation:Array<Int>, twiddleReal:Array<Float>, twiddleImag:Array<Float>;
		_mutex.acquire();

		var real:Array<Float> = _reals[_freqCalculating], imag:Array<Float> = _imags[_freqCalculating];
		if (real == null) {
			_reals.push(real = []);
			_imags.push(imag = []);
		}
		_freqCalculating++;

		if (_permutations.exists(bits)) {
			permutation = _permutations.get(bits);
			twiddleReal = _twiddleReals.get(bits);
			twiddleImag = _twiddleImags.get(bits);
		}
		else {
			(permutation = []).resize(fftN);
			(twiddleReal = []).resize(fftN2);
			(twiddleImag = []).resize(fftN2);

			var ang:Float;
			for (i in 0...fftN) {
				permutation[i] = _bitReverse(i, bits);
				if (i < fftN2) {
					twiddleReal[i] = Math.cos((ang = -6.283185307179586 * i / n));
					twiddleImag[i] = Math.sin(ang);
				}
			}

			_permutations.set(bits, permutation);
			_twiddleReals.set(bits, twiddleReal);
			_twiddleImags.set(bits, twiddleImag);
		}

		_mutex.release();

		if (fftN > real.length) {
			real.resize(fftN);
			imag.resize(fftN);
		}

		if (frequencies == null) frequencies = [];
		if (frequencies.length != fftN2) frequencies.resize(fftN2);

		var tr = 1 / n;
		for (i in 0...fftN) {
			real[permutation[i]] = samples[i];
			if (window != null) real[permutation[i]] *= window(i * tr);
			imag[i] = 0;
		}

		var half = 1, g:Int, b:Int, r:Int, i0:Int, i1:Int, ti:Float;
		while (fftN2 > 0) {
			g = 0;
			while (g < fftN) {
				b = r = 0;
				while (b < half) {
					i1 = (i0 = g + b) + half;
					tr = real[i1] * twiddleReal[r] - imag[i1] * twiddleImag[r];
					ti = real[i1] * twiddleImag[r] + imag[i1] * twiddleReal[r];
					real[i1] = real[i0] - tr;
					imag[i1] = imag[i0] - ti;
					real[i0] += tr;
					imag[i0] += ti;
					b++;
					r += fftN2;
				}
				g += half << 1;
			}
			half <<= 1;
			fftN2 >>= 1;
		}

		tr = 1.0 / fftN;
		i0 = frequencies.length - 1;
		for (i in 1...i0) frequencies[i] = 2 * Math.sqrt(real[i] * real[i] + imag[i] * imag[i]) * tr;
		frequencies[0] = Math.sqrt(real[0] * real[0] + imag[0] * imag[0]) * tr;
		frequencies[i0] = Math.sqrt(real[i0] * real[i0] + imag[i0] * imag[i0]) * tr;

		_mutex.acquire();
		_freqCalculating--;
		_mutex.release();

		return frequencies;
	}

	static function _bitReverse(x:Int, bits:Int):Int {
		var y = 0, i = bits;
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
	 * The current data from sound.
	 */
	public var data(default, null):FlxSoundData;

	/**
	 * How much samples for the fourier transform to get.
	 * Has to be power of two, or it won't work.
	 */
	public var fftN:Int;

	/**
	 * The current byteSize from buffer.
	 * Example the byteSize of 16 BitsPerSample is 32768 (1 << (16 - 1))
	 */
	public var byteSize(default, null):Int;

	var _sampleSize:Int;
	var _mins:Array<Int> = [];
	var _maxs:Array<Int> = [];
	//var _decoder:FunkinAudioDecoder;
	//var _buffer:ArrayBuffer;
	//var _bufferLen:Int;
	//var _bufferLastSize:Int;
	//var _bufferLastSample:Int;
	var _sampleIndex:Int;
	var _sampleChannel:Int;
	var _sampleValue:Int;
	var _sampleValueGain:Float;
	var _sampleOutputMerge:Bool;
	var _sampleOutputLength:Int;
	var _sampleOutput:Array<Float>;
	var _freqSamples:Array<Float>;
	var _frequencies:Array<Float>;

	public function new(sound:FlxSound, fftN = 4096) {
		this.sound = sound;
		this.fftN = fftN;
		_check();
	}

	function _check() {
		if (sound != null && !sound.data.isDestroyed) {
			if (sound.data != data)
			{
				byteSize = 1 << ((data = sound.data).bitsPerSample - 1);
				_sampleSize = data.channels * (data.bitsPerSample >> 3);
				_mins.resize(data.channels);
				_maxs.resize(data.channels);
				//_decoder?.destroy();
			}
		}
		else data = null;
	}

	/**
	 * Gets spectrum from an attached sound from position.
	 * @param	pos			Position to get (Optional).
	 * @param	timeUnit	TimeUnit to use for positions (Optional).
	 * @param	gain		How much gain multiplier will it affect the output. (Optional, default 1.0).
	 * @param	barCount	How much bars to get.
	 * @param	spectrum	The output for getting the values, to avoid memory leaks (Optional).
	 * @param	ratio		How much ratio for smoothen the values from the previous spectrum values (Optional, use FlxMath.getElapsedLerp(1 - ratio) to simulate web AnalyserNode.smoothingTimeConstant, 0.35 of smoothingTime works most of the time).
	 * @param	minDb		The minimum decibels to cap (Optional, default -63.0, -120 is pure silence).
	 * @param	maxDb		The maximum decibels to cap (Optional, default -10.0, Above 0 is not recommended).
	 * @param	minFreq		The minimum frequency to cap (Optional, default 20.0, Below 8.0 is not recommended).
	 * @param	maxFreq		The maximum frequency to cap (Optional, default 20000.0, Above 23000.0 is not recommended).
	 * @return	Output of spectrum/bars that ranges from 0 to 1.
	 */
	public function getSpectrum(?pos:Float, ?timeUnit:TimeUnit, ?gain:Float, ?window:WindowFunction, barCount:Int, ?spectrum:Array<Float>, ?ratio:Float, ?minDb:Float, ?maxDb:Float, ?minFreq:Float, ?maxFreq:Float):Array<Float> {
		return getSpectrumFromFrequencies(_frequencies = getFrequencies(pos, timeUnit, gain, window, _frequencies), data.sampleRate, barCount, spectrum, ratio, minDb, maxDb, minFreq, maxFreq);
	}

	/**
	 * Gets levels from an attached FlxSound from startPos, basically a minimized of frequencies.
	 * @param	startPos	Start Position to get from sound in milliseconds.
	 * @param	volume		How much volume multiplier will it affect the output. (Optional, default 1.0).
	 * @param	barCount	How much bars to get.
	 * @param	levels		The output for getting the values, to avoid memory leaks (Optional).
	 * @param	ratio		How much ratio for smoothen the values from the previous levels values (Optional, use CoolUtil.getFPSRatio(1 - ratio) to simulate web AnalyserNode.smoothingTimeConstant, 0.35 of smoothingTime works most of the time).
	 * @param	minDb		The minimum decibels to cap (Optional, default -63.0, -120 is pure silence).
	 * @param	maxDb		The maximum decibels to cap (Optional, default -10.0, Above 0 is not recommended).
	 * @param	minFreq		The minimum frequency to cap (Optional, default 20.0, Below 8.0 is not recommended).
	 * @param	maxFreq		The maximum frequency to cap (Optional, default 22000.0, Above 23000.0 is not recommended).
	 * @return	Output of levels/bars that ranges from 0 to 1.
	 * 
	 * deprecated, use getLevels instead.
	 */
	@:deprecated("Use getSpectrum instead of getLevels.")
	public function getLevels(?startPos:Float, ?volume:Float, barCount:Int, ?levels:Array<Float>, ?ratio:Float, ?minDb:Float, ?maxDb:Float, ?minFreq:Float, ?maxFreq:Float):Array<Float>
		return inline getSpectrum(startPos, MILLISECOND, volume, null, barCount, levels, ratio, minDb, maxDb, minFreq, maxFreq);

	/**
	 * Gets frequencies from an attached sound from position.
	 * @param	pos			Position to get. (Optional).
	 * @param	timeUnit	TimeUnit to use for positions. (Optional).
	 * @param	gain		How much gain multiplier will it affect the output. (Optional, default 1.0).
	 * @param	window		The windowing function to use when passed.
	 * @param	frequencies	The output for getting the frequencies, to avoid memory leaks (Optional).
	 * @return	Output of frequencies.
	 */
	public function getFrequencies(?pos:Float, ?timeUnit:TimeUnit, ?gain:Float, ?window:WindowFunction, ?frequencies:Array<Float>):Array<Float> {
		if (pos == null) {
			if (sound == null) return frequencies;
			_check();
			if ((pos = sound.time / 1000 * data.sampleRate - fftN) < 0) pos = 0;
			timeUnit = SAMPLE;
		}
		return getFrequenciesFromSamples(_freqSamples = getSamples(pos, timeUnit, fftN, true, -1, gain, _freqSamples), window, frequencies);
	}

	/**
	 * Analyzes an attached sound from startPos to endPos in milliseconds to get the amplitudes.
	 * @param	startPos		Start Position to get.
	 * @param	endPos			End Position to get.
	 * @param	timeUnit		TimeUnit to use for positions.
	 * @param	outOrOutMins	The output minimum value from the analyzer, indices is in channels (0 to -0.5 -> 0 to 0.5) (Optional, if outMax doesn't get passed in, it will be [min, max] with all channels combined instead).
	 * @param	outMaxs			The output maximum value from the analyzer, indices is in channels (Optional).
	 * @return	Output			of amplitude from given position.
	 */
	public function analyze(startPos:Float, endPos:Float, ?timeUnit:TimeUnit, ?outOrOutMins:Array<Float>, ?outMaxs:Array<Float>):Float {
		var hasOut = outOrOutMins != null;
		var hasTwoOut = hasOut && outMaxs != null;

		_check();
		var conversion:Float = switch (timeUnit) {
			case SAMPLE: 1;
			case SECOND: data.sampleRate;
			default: data.sampleRate / 1000;
		}
		for (i in 0...data.channels) _mins[i] = _maxs[i] = -0x7FFFFFFF;
		if (startPos > endPos) _read(Math.floor(startPos * conversion), Math.floor(endPos * conversion), _analyzeRead);

		var min = -0x7FFFFFFF, max = -0x7FFFFFFF, v = 1 / byteSize, f:Float;
		for (i in 0...data.channels) {
			if (hasTwoOut) {
				if ((f = _mins[i] * v) > outOrOutMins[i]) outOrOutMins[i] = f;
				if ((f = _maxs[i] * v) > outMaxs[i]) outMaxs[i] = f;
			}
			if (_maxs[i] > max) max = _maxs[i];
			if (_mins[i] > min) min = _mins[i];
		}

		if (hasOut && outMaxs == null) {
			if ((f = min * v) > outOrOutMins[0]) outOrOutMins[0] = f;
			if ((f = max * v) > outOrOutMins[1]) outOrOutMins[1] = f;
		}
		return (max + min) * v;
	}

	function _analyzeRead(b:Int, c:Int) ((b > _maxs[c]) ? (_maxs[c] = b) : (if (-b > _mins[c]) (_mins[c] = -b)));

	/**
	 * Gets samples from startPos with given length of samples.
	 * @param	startPos		Start Position to get.
	 * @param	timeUnit		TimeUnit to use for positions.
	 * @param	length			Length of Samples.
	 * @param	mono 			Merge all of the byte channels of samples in one channel instead (Optional).
	 * @param	channel			What channels to get from? (-1 == All Channels, Optional, this will be ignored if mono is enabled).
	 * @param	gain			How much gain multiplier will it affect the output. (Optional, default 1.0).
	 * @param	output			An Output that gets passed into this function, usually for to avoid memory leaks (Optional).
	 * @param	outputMerge		Merge with previous values (Optional, default false).
	 * @return	Output of samples.
	 */
	public function getSamples(startPos:Float, ?timeUnit:TimeUnit, length:Int, mono = true, channel = -1, gain = 1.0, ?output:Array<Float>, ?outputMerge = false):Array<Float> {
		_check();
		((!mono && channel == -1) ? (_sampleOutputLength = length * data.channels) : (_sampleOutputLength = length));
		if (((output == null) ? (_sampleOutput = output = []) : (_sampleOutput = output)).length != _sampleOutputLength) output.resize(_sampleOutputLength);
		_sampleValueGain = gain;
		_sampleOutputMerge = outputMerge;
		_sampleIndex = 0;
		_sampleValue = 0;

		final samplePos = Math.floor(switch (timeUnit) {
			case SAMPLE: startPos;
			case SECOND: startPos * data.sampleRate;
			default: startPos * data.sampleRate / 1000;
		});
		_sampleChannel = mono ? data.channels - 1 : channel;
		if (length > 0) _read(samplePos, samplePos + length, mono ? _getSamplesCallbackMono : (channel == -1 ? _getSamplesCallback : _getSamplesCallbackChannel));

		_sampleOutput = null;
		return output;
	}

	function _getSamplesCallbackMono(b:Int, c:Int):Void if (_sampleIndex < _sampleOutputLength) {
		if (c == 0) _sampleValue = idiv(b, data.channels);
		else _sampleValue += idiv(b, data.channels);

		if (c == _sampleChannel) {
			if (_sampleOutputMerge) _sampleOutput[_sampleIndex] += _sampleValue / byteSize;
			else _sampleOutput[_sampleIndex] = _sampleValue / byteSize;
			_sampleIndex++;
		}
	}

	function _getSamplesCallbackChannel(b:Int, c:Int):Void if (_sampleIndex < _sampleOutputLength) {
		if (c == _sampleChannel) {
			if (_sampleOutputMerge) _sampleOutput[_sampleIndex] += b / byteSize;
			else _sampleOutput[_sampleIndex] = b / byteSize;
			_sampleIndex++;
		}
	}

	function _getSamplesCallback(b:Int, c:Int):Void if (_sampleIndex < _sampleOutputLength) {
		if (_sampleOutputMerge) _sampleOutput[_sampleIndex] += b / byteSize;
		else _sampleOutput[_sampleIndex] = b / byteSize;
		_sampleIndex++;
	}

	/**
	 * Read an attached sound from startPos to endPos in milliseconds with a callback.
	 * @param	startPos	Start Position to get.
	 * @param	endPos		End Position to get.
	 * @param	timeUnitTimeUnit to use for positions.
	 * @param	callback	Byte:Int->Channels:Int->Void Callback to get the byte of a sample.
	 */
	public function read(startPos:Float, endPos:Float, ?timeUnit:TimeUnit, callback:ReadCallback) {
		_check();
		var conversion:Float = switch (timeUnit) {
			case SAMPLE: 1;
			case SECOND: data.sampleRate;
			default: data.sampleRate / 1000;
		}
		if (startPos > endPos) _read(Math.floor(startPos * conversion), Math.floor(endPos * conversion), callback);
	}

	function _read(startSample:Int, endSample:Int, callback:ReadCallback) {
		// use data in ram if available
		if (data.buffer.data != null) _readData(startSample * _sampleSize, endSample * _sampleSize, callback);
		// use decoded datas that have been used in streaming sound to reduce jumping disk seeking
		// if not use decoder and use seeking instead*
		else if (sound.loaded) _readStream(startSample, endSample, callback);

		// TODO
		//else if ((!sound.loaded || (startSample = _readStream(startSample, endSample, callback)) < endSample) && _prepareDecoder())
		//	_readDecoder(startSample, endSample, callback);
	}

	inline function _readData(startIndex:Int, endIndex:Int, callback:ReadCallback) {
		if (endIndex > data.buffer.data.byteLength) endIndex = data.buffer.data.byteLength;
		var buffer = data.buffer.data.buffer, byteRate = data.bitsPerSample >> 3, c = 0;
		while (startIndex < endIndex) {
			callback(getByte(buffer, startIndex, byteRate), c);
			startIndex += byteRate;
			if (++c == data.channels) c = 0;
		}
	}

	function _readStream(startSample:Int, endSample:Int, callback:ReadCallback):Int @:privateAccess {
		final backend = sound.source.__backend;
		if (backend.filledBuffers == 0) return startSample;

		backend.mutex.acquire();

		final max = backend.bufferViews.length;
		var byteRate = data.bitsPerSample >> 3, i = max - backend.queuedBuffers, buffer:ArrayBuffer, bufferLen:Int, bufferSample:Int, pos:Int, c:Int;

		while (i < max && startSample < endSample) {
			if (startSample >= (bufferSample = backend.bufferCurs[i])) {
				if ((pos = (startSample - bufferSample) * _sampleSize) < (bufferLen = backend.bufferLens[i])) {
					buffer = backend.bufferViews[i].buffer;
					c = 0;
					while (startSample < endSample) {
						callback(getByte(buffer, pos, byteRate), c);
						if ((pos += byteRate) >= bufferLen) {
							startSample++;
							break;
						}
						else if (++c == data.channels) {
							c = 0;
							startSample++;
						}
					}
				}
			}
			i++;
		}

		backend.mutex.release();

		return startSample;
	}

	// TODO: Fix this and _readDecoder in the future.
	inline function _prepareDecoder():Bool {
		return false;
		/*
		if (_decoder != null) return true;
		if (data.decoder != null && (_decoder = data.decoder.clone()) != null) {
			_bufferLen = (data.sampleRate >> 2) * _sampleSize;
			#if cpp
			if (_buffer != null) {
				if (_buffer.length < _bufferLen) {
					_buffer.getData().resize(_bufferLen);
					_buffer.fill(_buffer.length, _bufferLen - _buffer.length, 0);
					@:privateAccess _buffer.length = _bufferLen;
				}
			}
			else
			#end
				_buffer = new ArrayBuffer(_bufferLen);
			return true;
		}
		return false;
		*/
	}

	/*
	function _readDecoder(startSample:Int, endSample:Int, callback:ReadCallback) {
		var pos = (startSample - _bufferLastSample) * _sampleSize, n = endSample - startSample, c = 0;

		var doDecode = _bufferLastSize == 0 || (pos < 0 && pos >= _bufferLastSize);
		if (doDecode) {
			_decoder.seek(startSample);
			_bufferLastSize = pos = 0;
			doDecode = true;
		}

		var result:Int;
		while (n > 0) {
			if (doDecode) {
				_bufferLastSample = _decoder.tell();
				result = _decoder.decode(_buffer, pos, _bufferLen - pos);
				if (result == 0) break;

				_bufferLastSize += result;
				while (n > 0) {
					callback(getByte(_buffer, pos, data.byteRate), c);
					if (++c == data.channels) {
						c = 0;
						n--;
					}
					if ((pos += data.byteRate) >= _bufferLastSize) break;
				}
			}
			else {
				while (n > 0) {
					callback(getByte(_buffer, pos, data.byteRate), c);
					if (++c == data.channels) {
						c = 0;
						n--;
					}
					if ((pos += data.byteRate) >= _bufferLastSize) break;
				}
				doDecode = true;
				_bufferLastSize = pos = 0;
			}
		}
	}
	*/

	static inline function idiv(num:Int, denom:Int):Int return #if (cpp && !cppia) cpp.NativeMath.idiv(num, denom) #else Std.int(num / denom) #end;
}
#end