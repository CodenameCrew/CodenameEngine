package funkin.backend.utils;

import flixel.input.keyboard.FlxKey;
import lime.tools.imgui.ImGuiTypes.ImGuiKey;

class ImGuiUtil {

	public static function toImGuiKey(key:FlxKey) {
		switch(key) {
			case FlxKey.ANY: return ImGuiKey.None;
			case FlxKey.NONE: return ImGuiKey.None;
			case FlxKey.A: return ImGuiKey.A;
			case FlxKey.B: return ImGuiKey.B;
			case FlxKey.C: return ImGuiKey.C;
			case FlxKey.D: return ImGuiKey.D;
			case FlxKey.E: return ImGuiKey.E;
			case FlxKey.F: return ImGuiKey.F;
			case FlxKey.G: return ImGuiKey.G;
			case FlxKey.H: return ImGuiKey.H;
			case FlxKey.I: return ImGuiKey.I;
			case FlxKey.J: return ImGuiKey.J;
			case FlxKey.K: return ImGuiKey.K;
			case FlxKey.L: return ImGuiKey.L;
			case FlxKey.M: return ImGuiKey.M;
			case FlxKey.N: return ImGuiKey.N;
			case FlxKey.O: return ImGuiKey.O;
			case FlxKey.P: return ImGuiKey.P;
			case FlxKey.Q: return ImGuiKey.Q;
			case FlxKey.R: return ImGuiKey.R;
			case FlxKey.S: return ImGuiKey.S;
			case FlxKey.T: return ImGuiKey.T;
			case FlxKey.U: return ImGuiKey.U;
			case FlxKey.V: return ImGuiKey.V;
			case FlxKey.W: return ImGuiKey.W;
			case FlxKey.X: return ImGuiKey.X;
			case FlxKey.Y: return ImGuiKey.Y;
			case FlxKey.Z: return ImGuiKey.Z;
			case FlxKey.ZERO: return ImGuiKey._0;
			case FlxKey.ONE: return ImGuiKey._1;
			case FlxKey.TWO: return ImGuiKey._2;
			case FlxKey.THREE: return ImGuiKey._3;
			case FlxKey.FOUR: return ImGuiKey._4;
			case FlxKey.FIVE: return ImGuiKey._5;
			case FlxKey.SIX: return ImGuiKey._6;
			case FlxKey.SEVEN: return ImGuiKey._7;
			case FlxKey.EIGHT: return ImGuiKey._8;
			case FlxKey.NINE: return ImGuiKey._9;
			case FlxKey.PAGEUP: return ImGuiKey.PageUp;
			case FlxKey.PAGEDOWN: return ImGuiKey.PageDown;
			case FlxKey.HOME: return ImGuiKey.Home;
			case FlxKey.END: return ImGuiKey.End;
			case FlxKey.INSERT: return ImGuiKey.Insert;
			case FlxKey.ESCAPE: return ImGuiKey.Escape;
			case FlxKey.MINUS: return ImGuiKey.Minus;
			case FlxKey.PLUS: return ImGuiKey.Equal;
			case FlxKey.DELETE: return ImGuiKey.Delete;
			case FlxKey.BACKSPACE: return ImGuiKey.Backspace;
			case FlxKey.LBRACKET: return ImGuiKey.LeftBracket;
			case FlxKey.RBRACKET: return ImGuiKey.RightBracket;
			case FlxKey.BACKSLASH: return ImGuiKey.Backslash;
			case FlxKey.CAPSLOCK: return ImGuiKey.CapsLock;
			case FlxKey.SCROLL_LOCK: return ImGuiKey.ScrollLock;
			case FlxKey.NUMLOCK: return ImGuiKey.NumLock;
			case FlxKey.SEMICOLON: return ImGuiKey.Semicolon;
			case FlxKey.QUOTE: return ImGuiKey.Apostrophe;
			case FlxKey.ENTER: return ImGuiKey.Enter;
			case FlxKey.SHIFT: return ImGuiKey.LeftShift;
			case FlxKey.COMMA: return ImGuiKey.Comma;
			case FlxKey.PERIOD: return ImGuiKey.Period;
			case FlxKey.SLASH: return ImGuiKey.Slash;
			case FlxKey.GRAVEACCENT: return ImGuiKey.GraveAccent;
			case FlxKey.CONTROL: return ImGuiKey.LeftCtrl;
			case FlxKey.ALT: return ImGuiKey.LeftAlt;
			case FlxKey.SPACE: return ImGuiKey.Space;
			case FlxKey.UP: return ImGuiKey.UpArrow;
			case FlxKey.DOWN: return ImGuiKey.DownArrow;
			case FlxKey.LEFT: return ImGuiKey.LeftArrow;
			case FlxKey.RIGHT: return ImGuiKey.RightArrow;
			case FlxKey.TAB: return ImGuiKey.Tab;
			case FlxKey.WINDOWS: return ImGuiKey.None; //no windows key
			case FlxKey.MENU: return ImGuiKey.Menu;
			case FlxKey.PRINTSCREEN: return ImGuiKey.PrintScreen;
			case FlxKey.BREAK: return ImGuiKey.Pause;
			case FlxKey.F1: return ImGuiKey.F1;
			case FlxKey.F2: return ImGuiKey.F2;
			case FlxKey.F3: return ImGuiKey.F3;
			case FlxKey.F4: return ImGuiKey.F4;
			case FlxKey.F5: return ImGuiKey.F5;
			case FlxKey.F6: return ImGuiKey.F6;
			case FlxKey.F7: return ImGuiKey.F7;
			case FlxKey.F8: return ImGuiKey.F8;
			case FlxKey.F9: return ImGuiKey.F9;
			case FlxKey.F10: return ImGuiKey.F10;
			case FlxKey.F11: return ImGuiKey.F11;
			case FlxKey.F12: return ImGuiKey.F12;
			case FlxKey.NUMPADZERO: return ImGuiKey.Keypad0;
			case FlxKey.NUMPADONE: return ImGuiKey.Keypad1;
			case FlxKey.NUMPADTWO: return ImGuiKey.Keypad2;
			case FlxKey.NUMPADTHREE: return ImGuiKey.Keypad3;
			case FlxKey.NUMPADFOUR: return ImGuiKey.Keypad4;
			case FlxKey.NUMPADFIVE: return ImGuiKey.Keypad5;
			case FlxKey.NUMPADSIX: return ImGuiKey.Keypad6;
			case FlxKey.NUMPADSEVEN: return ImGuiKey.Keypad7;
			case FlxKey.NUMPADEIGHT: return ImGuiKey.Keypad8;
			case FlxKey.NUMPADNINE: return ImGuiKey.Keypad9;
			case FlxKey.NUMPADMINUS: return ImGuiKey.KeypadSubtract;
			case FlxKey.NUMPADPLUS: return ImGuiKey.KeypadAdd;
			case FlxKey.NUMPADPERIOD: return ImGuiKey.KeypadDecimal;
			case FlxKey.NUMPADMULTIPLY: return ImGuiKey.KeypadMultiply;
			case FlxKey.NUMPADSLASH: return ImGuiKey.KeypadDivide;
			default:
		}
		return ImGuiKey.None;
	}
}