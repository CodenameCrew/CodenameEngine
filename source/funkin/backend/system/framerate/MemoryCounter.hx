package funkin.backend.system.framerate;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

class MemoryCounter extends Sprite {
	public var memoryText:TextField;
	public var memoryPeakText:TextField;

	public var memory:Float = 0;
	public var memoryPeak:Float = 0;

	public function new() {
		super();

		memoryText = new TextField();
		memoryPeakText = new TextField();

		for(label in [memoryText, memoryPeakText]) {
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.text = "MEM";
			label.multiline = label.wordWrap = false;
			label.defaultTextFormat = Framerate.textFormat;
			label.selectable = false;
			addChild(label);
		}
		memoryPeakText.alpha = 0.5;
		#if !(cpp && (windows || mac || linux))
		memoryPeakText.visible = false;
		#end
	}

	public function reload() {
		for(label in [memoryText, memoryPeakText]) label.defaultTextFormat = Framerate.textFormat;
	}

	private var usingLegacy:Bool = false;

	public override function __enterFrame(t:Float) {
		if (alpha <= 0.05) return;
		super.__enterFrame(t);

		#if (cpp && (windows || mac || linux))
		var legacy = funkin.options.Options.legacyMemoryCounter;

		if (legacy) {
			if (legacy != usingLegacy) {
				usingLegacy = legacy;
				memoryPeak = 0;
			}

			final mem = MemoryUtil.currentMemUsage();
			if (memoryPeak < mem) memoryPeak = mem;
			if (mem == memory) {
				updateLabelPosition();
				return;
			}

			memory = mem;
			memoryPeakText.visible = true;
			memoryText.text = CoolUtil.getSizeString(memory);
			memoryPeakText.text = ' / ${CoolUtil.getSizeString(memoryPeak)}';
		} else {
			if (legacy != usingLegacy) usingLegacy = legacy;

			final gcMem = MemoryUtil.currentMemUsage();
			final osMem = MemoryUtil.currentProcessMemUsage();

			if (gcMem == memory && osMem == memoryPeak) {
				updateLabelPosition();
				return;
			}

			memory = gcMem;
			memoryPeak = osMem;
			memoryPeakText.visible = true;
			memoryText.text = CoolUtil.getSizeString(gcMem);
			memoryPeakText.text = ' / ${CoolUtil.getSizeString(osMem)}';
		}
		#else
		final mem = MemoryUtil.currentMemUsage();

		if (mem == memory) {
			updateLabelPosition();
			return;
		}

		memory = mem;
		memoryText.text = CoolUtil.getSizeString(mem);
		#end

		updateLabelPosition();
	}

	private inline function updateLabelPosition():Void
		memoryPeakText.x = memoryText.x + memoryText.width;
}
