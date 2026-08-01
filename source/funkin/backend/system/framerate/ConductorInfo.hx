package funkin.backend.system.framerate;

import funkin.backend.system.macros.StringMacro;

class ConductorInfo extends FramerateCategory {
	public function new() {
		super("Conductor Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		var buf = new StringBuf();
		StringMacro.addLine(buf, 'Current Song Position: ${Math.floor(Conductor.songPosition * 1000) / 1000}');
		StringMacro.addLine(buf, '\n - ${Conductor.curBeat} beats');
		StringMacro.addLine(buf, '\n - ${Conductor.curStep} steps');
		StringMacro.addLine(buf, '\n - ${Conductor.curMeasure} measures');
		StringMacro.addLine(buf, '\nCurrent BPM: ${Conductor.bpm}');
		StringMacro.addLine(buf, '\nTime Signature: ${Conductor.beatsPerMeasure}/${Conductor.denominator}');
		_text = buf.toString();

		this.text.text = _text;
		super.__enterFrame(t);
	}
}