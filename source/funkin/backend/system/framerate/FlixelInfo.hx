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
				addLineMacro(buf, 'Mod State: ', state.scriptName);
			} else {
				addLineMacro(buf, 'State: ', Type.getClassName(Type.getClass(FlxG.state)));
			}
			addLineMacro(buf, '\nObject Count: ', FlxG.state.members.length);
			addLineMacro(buf, '\nCamera Count: ', FlxG.cameras.list.length);
			addLineMacro(buf, '\nBitmaps Count: ', c);
			addLineMacro(buf, '\nSounds Count: ', FlxG.sound.list.length);
			addLineMacro(buf, '\nFlxG.game Childs Count: ', FlxG.game.numChildren);
			if(FlxG.renderBlit) {
				addLineMacro(buf, '\nBlitting Render: ', true);
			}
			#if FLX_POINT_POOL
			//var points = flixel.math.FlxPoint.FlxBasePoint.pool;
			//addLineMacro(buf, '\nPoint Count: ', points._count, ' | +', points.made, ' | -', points.gotten, ' | ', points.balance, ' | >', points.putted);
			//addLineMacro(buf, '\nPoint Count: ', points._count);
			#end
			_text = buf.toString();
		}

		this.text.text = _text;
		super.__enterFrame(t);
	}
}