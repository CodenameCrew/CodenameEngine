package funkin.backend.system.framerate;

import funkin.backend.scripting.ModState;

class FlixelInfo extends FramerateCategory {
	public function new() {
		super("Flixel Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		@:privateAccess {
			var c:Int = Lambda.count(FlxG.bitmap._cache);
			var buf = new StringBuf();

			if((FlxG.state is ModState)) {
				var state:ModState = cast FlxG.state;
				buf.add("Mod State: ");
				buf.add(state.scriptName);
			} else {
				buf.add("State: ");
				buf.add(Type.getClassName(Type.getClass(FlxG.state)));
			}
			buf.add("\nObject Count: ");
			buf.add(FlxG.state.members.length);
			buf.add("\nCamera Count: ");
			buf.add(FlxG.cameras.list.length);
			buf.add("\nBitmaps Count: ");
			buf.add(c);
			buf.add("\nSounds Count: ");
			buf.add(FlxG.sound.list.length);
			buf.add("\nFlxG.game Childs Count: ");
			buf.add(FlxG.game.numChildren);
			if(FlxG.renderBlit) {
				buf.add("\nBlitting Render: true");
			}
			#if FLX_POINT_POOL
			//var points = flixel.math.FlxPoint.FlxBasePoint.pool;
			//buf.add('\nPoint Count: ${points._count} | +${points.made} | -${points.gotten} | ${points.balance} | >${points.putted}');
			//buf.add('\nPoint Count: ${points._count}');
			#end
			_text = buf.toString();
		}

		this.text.text = _text;
		super.__enterFrame(t);
	}
}