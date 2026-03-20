package funkin.backend.system.framerate;

class ConductorInfo extends FramerateCategory {
	public function new() {
		super("Conductor Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		var buf = new StringBuf();
		addLineMacro(buf, 'Current Song Position: ', Math.floor(Conductor.songPosition * 1000) / 1000, 's');
		addLineMacro(buf, '\n - ', Conductor.curBeat, ' beats');
		addLineMacro(buf, '\n - ', Conductor.curStep, ' steps');
		addLineMacro(buf, '\n - ', Conductor.curMeasure, ' measures');
		addLineMacro(buf, '\nCurrent BPM: ', Conductor.bpm);
		addLineMacro(buf, '\nTime Signature: ', Conductor.beatsPerMeasure, '/', Conductor.denominator);
		_text = buf.toString();

		this.text.text = _text;
		super.__enterFrame(t);
	}
}