package funkin.backend.system.framerate;

class ConductorInfo extends FramerateCategory {
	public function new() {
		super("Conductor Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		var buf = new StringBuf();
		buf.add("Current Song Position: ");
		buf.add(Math.floor(Conductor.songPosition * 1000) / 1000);
		buf.add("\n - ");
		buf.add(Conductor.curBeat);
		buf.add(" beats");
		buf.add("\n - ");
		buf.add(Conductor.curStep);
		buf.add(" steps");
		buf.add("\n - ");
		buf.add(Conductor.curMeasure);
		buf.add(" measures");
		buf.add("\nCurrent BPM: ");
		buf.add(Conductor.bpm);
		buf.add("\nTime Signature: ");
		buf.add(Conductor.beatsPerMeasure);
		buf.add("/");
		buf.add(Conductor.denominator);
		_text = buf.toString();

		this.text.text = _text;
		super.__enterFrame(t);
	}
}