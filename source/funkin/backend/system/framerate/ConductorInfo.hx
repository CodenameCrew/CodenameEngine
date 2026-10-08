package funkin.backend.system.framerate;

import funkin.backend.system.macros.StringMacro;

class ConductorInfo extends FramerateCategory
{
	public function new()
	{
		super("Conductor Info");
		visible = Options.fpsCounterConductor;
	}

	public override function __enterFrame(t:Float) {
		if (alpha <= 0.05 || !visible) return;

		var buf = new StringBuf();
		StringMacro.addLine(buf, 'Current Song Position: ${Math.floor(Conductor.instance.songPosition * 1000) / 1000}');
		StringMacro.addLine(buf, '\n - ${Conductor.instance.curBeat} beats');
		StringMacro.addLine(buf, '\n - ${Conductor.instance.curStep} steps');
		StringMacro.addLine(buf, '\n - ${Conductor.instance.curMeasure} measures');
		StringMacro.addLine(buf, '\nCurrent BPM: ${Conductor.instance.bpm}');
		StringMacro.addLine(buf, '\nTime Signature: ${Conductor.instance.beatsPerMeasure}/${Conductor.instance.denominator}');
		_text = buf.toString();

		this.text.text = _text;
		super.__enterFrame(t);
	}
}
