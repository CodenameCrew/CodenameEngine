package funkin.backend.system.framerate;

import funkin.backend.scripting.ModState;
import funkin.backend.system.macros.StringMacro;

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
				StringMacro.addLine(buf, 'Mod State: ', state.scriptName);
			} else {
				StringMacro.addLine(buf, 'State: ', Type.getClassName(Type.getClass(FlxG.state)));
			}
			StringMacro.addLine(buf, '\nObject Count: ', FlxG.state.members.length);
			StringMacro.addLine(buf, '\nCamera Count: ', FlxG.cameras.list.length);
			StringMacro.addLine(buf, '\nBitmaps Count: ', c);
			StringMacro.addLine(buf, '\nSounds Count: ', FlxG.sound.list.length);
			StringMacro.addLine(buf, '\nFlxG.game Childs Count: ', FlxG.game.numChildren);
			if(FlxG.renderBlit) {
				StringMacro.addLine(buf, '\nBlitting Render: ', true);
			}
			#if FLX_POINT_POOL
			//var points = flixel.math.FlxPoint.FlxBasePoint.pool;
			//StringMacro.addLine(buf, '\nPoint Count: ', points._count, ' | +', points.made, ' | -', points.gotten, ' | ', points.balance, ' | >', points.putted);
			//StringMacro.addLine(buf, '\nPoint Count: ', points._count);
			#end
			_text = buf.toString();
		}

		this.text.text = _text;
		super.__enterFrame(t);
	}
}