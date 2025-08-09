package funkin.backend.system.framerate;

class ConductorInfo extends FramerateCategory {
	public function new() {
		super("Conductor Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		_text = 'Current Song Position: ${Math.floor(Conductor.songPosition * 1000) / 1000}';
		_text += '\n - ${Conductor.curBeat} beats';
		_text += '\n - ${Conductor.curStep} steps';
		_text += '\n - ${Conductor.curMeasure} measures';
		_text += '\nCurrent BPM: ${Conductor.bpm}';
		_text += '\nTime Signature: ${Conductor.beatsPerMeasure}/${Conductor.denominator}';

		this.text.text = _text;
		super.__enterFrame(t);
	}
}