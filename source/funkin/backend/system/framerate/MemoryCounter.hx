package funkin.backend.system.framerate;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

class MemoryCounter extends Sprite {
	public var memoryText:TextField;
	public var memoryPeakText:TextField;

	public var gcMemory:Float = 0;
	public var processMemory:Float = 0;

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
			label.defaultTextFormat = new TextFormat(Framerate.fontName, 12, -1);
			label.selectable = false;
			addChild(label);
		}
		memoryPeakText.alpha = 0.5;
		#if !(cpp && (windows || mac || linux))
		memoryPeakText.visible = false;
		#end
	}

	public function reload() {}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		super.__enterFrame(t);

		#if (cpp && (windows || mac || linux))
		final gcMem = MemoryUtil.currentMemUsage();
		final osMem = MemoryUtil.currentProcessMemUsage();

		if (gcMem == gcMemory && osMem == processMemory) {
			updateLabelPosition();
			return;
		}

		gcMemory = gcMem;
		processMemory = osMem;

		memoryText.text = CoolUtil.getSizeString(gcMemory);
		memoryPeakText.text = ' / ${CoolUtil.getSizeString(osMem)}';
		#else
		final mem = MemoryUtil.currentMemUsage();

		if (mem == gcMemory) {
			updateLabelPosition();
			return;
		}

		gcMemory = mem;
		memoryText.text = CoolUtil.getSizeString(mem);
		#end

		updateLabelPosition();
	}

	private inline function updateLabelPosition():Void
		memoryPeakText.x = memoryText.x + memoryText.width;
}
