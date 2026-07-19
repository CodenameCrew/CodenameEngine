package funkin.backend.system.framerate;

#if (gl_stats && !disable_cffi && (!html5 || !canvas))
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;

class StatsInfo extends FramerateCategory {
	public function new() {
		super("Asset Libraries Tree Info");
	}

	public override function __enterFrame(t:Float) {
		if (alpha <= 0.05) return;
		_text = "totalDC: " + Context3DStats.totalDrawCalls();
		_text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
		_text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);

		this.text.text = _text;
		super.__enterFrame(t);
	}
}
#end