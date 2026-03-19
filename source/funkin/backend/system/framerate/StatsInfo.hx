package funkin.backend.system.framerate;

#if (gl_stats && !disable_cffi && (!html5 || !canvas))
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;

class StatsInfo extends FramerateCategory {
	public function new() {
		super("Asset Libraries Tree Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		var buf = new StringBuf();
		buf.add("totalDC: ");
		buf.add(Context3DStats.totalDrawCalls());
		buf.add("\nstageDC: ");
		buf.add(Context3DStats.contextDrawCalls(DrawCallContext.STAGE));
		buf.add("\nstage3DDC: ");
		buf.add(Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D));
		_text = buf.toString();

		this.text.text = _text;
		super.__enterFrame(t);
	}
}
#end