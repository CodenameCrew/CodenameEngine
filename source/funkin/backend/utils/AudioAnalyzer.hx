package funkin.backend.utils;

import flixel.sound.FlxSound;
import lime.media.AudioBuffer;

// Thank you yosh :DDD -lunar
// (https://github.com/CodenameCrew/YoshiCrafterEngine/blob/main/source/WaveformSprite.hx)
class AudioAnalyzer {
	public var buffer:AudioBuffer;
	var __peakByte:Float = 0;
	var __timeMulti:Float = 0;

	public function new(sound:FlxSound) {
		@:privateAccess buffer = sound._sound.__buffer;

		__peakByte = Math.pow(2, buffer.bitsPerSample-1)-1;

		__timeMulti = 1 / (1 / buffer.sampleRate);
		__timeMulti *= buffer.bitsPerSample;
		__timeMulti -= __timeMulti % buffer.bitsPerSample;
	}

	public function analyze(startPos:Float, endPos:Float):Float {
		var bytesStartPos:Int = Math.floor(startPos * __timeMulti / 4000 / buffer.bitsPerSample) * buffer.bitsPerSample;
		var bytesEndPos:Int = Math.floor(endPos * __timeMulti / 4000 / buffer.bitsPerSample) * buffer.bitsPerSample;

		bytesStartPos -= bytesStartPos % buffer.bitsPerSample;
		bytesEndPos -= bytesEndPos % buffer.bitsPerSample;

		var maxByte:Int = 0;
		for(i in 0...Math.floor((bytesEndPos - bytesStartPos) / buffer.bitsPerSample)) {
			var byte:Int = buffer.data.buffer.get(bytesStartPos + (i * buffer.bitsPerSample))
			| (buffer.data.buffer.get(bytesStartPos + (i * buffer.bitsPerSample) + 1) << 8);
			if (byte > 256 * 128) byte -= 256 * 256;
			if (maxByte < byte) maxByte = byte;
		}

		return maxByte/__peakByte;
	}
}