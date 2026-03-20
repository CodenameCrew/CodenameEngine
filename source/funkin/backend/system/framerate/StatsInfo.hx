package funkin.backend.system.framerate;

#if (gl_stats && !disable_cffi && (!html5 || !canvas))
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
import funkin.backend.system.macros.StringMacro;

class StatsInfo extends FramerateCategory {
	public function new() {
		super("Asset Libraries Tree Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		var buf = new StringBuf();
		StringMacro.addLine(buf, 'totalDC: ', Context3DStats.totalDrawCalls());
		StringMacro.addLine(buf, '\nstageDC: ', Context3DStats.contextDrawCalls(DrawCallContext.STAGE));
		StringMacro.addLine(buf, '\nstage3DDC: ', Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D));
		_text = buf.toString();

		this.text.text = _text;
		super.__enterFrame(t);
	}
}
#end