package funkin.backend.scripting;

#if ALLOW_LUASTATE
import llua.State;
import llua.LuaL;
import llua.Lua;
import llua.Convert;

import flixel.util.FlxStringUtil;
import flixel.util.FlxColor;
import funkin.backend.scripting.utils.LuaUtil;
import funkin.backend.system.interfaces.IStateScript;
import funkin.backend.MusicBeatState;
import hscript.Interp;
import hscript.Expr;
import hscript.Parser;

/**
 * 第一次搞，懂？
 * ...
 * 从目前lua的局限性来看，我认为不可能将他应用在多方面身上的，那很废，而且也不友好
 */
@:allow(funkin.backend.scripting.utils.LuaUtil)
class LuaScript extends Script {
	private static var parser:Parser = initParser();
	private static function initParser():Parser {
		var pr = new Parser();
		pr.allowMetadata = pr.allowTypes = pr.allowJSON = true;
		return pr;
	}

	public var heart:State;
	public var code:String = "";
	//666，代码要是是空的直接报错闪退了，你这是在让我填充啊
	private var templateCode:String = "return Function_Stop";
	
	//用于锁定setProperty和getProperty的指定用途（你懂的
	public var scriptObject(default, set):Dynamic = null;
	@:noCompletion private function set_scriptObject(val:Dynamic):Dynamic {
		scriptObject = val;
		if(_allowUseHScript) {
			interp.scriptObject = val;
			if(val is IStateScript) {
				interp.variables.set("setLuaVar", (tag:String, val:Dynamic) -> val.scriptVariables.set(tag, val));
				interp.variables.set("getLuaVar", (tag:String) -> return val.scriptVariables.get(tag));
			}
		}
		return val;
	}
	private var interp:Interp = new Interp();
	
	public var closed:Bool = false;
	private var _variables:Map<String, Dynamic> = new Map();
	private var _publicVariables:Map<String, Dynamic> = new Map();
	
	private var _allowUseHScript:Bool = false;
	private var defaultVariables:Map<String, Dynamic> = [
		//测试的
		"debugPrint" => (text:String, delayTime:Float = 1, ?style:String) -> {
			Main.instance.debugPrintLog.debugPrint(text, {delayTime: delayTime, style: (style != null ? (cast FlxColor.fromString(style)) : 0xFFFFFFFF)});
		},
		"windowAlert" => lime.app.Application.current.window.alert,
			
		//决定call的生死时刻！
		"Function_Stop" => LuaUtil.Function_Stop,
		"Function_Continue" => LuaUtil.Function_Continue,
			
		//部分FlxMath的大宝贝
		"mathBound" => flixel.math.FlxMath.bound,
		"mathLerp" => (FlxG.state is MusicBeatState ? cast(FlxG.state, MusicBeatState).lerp ? flixel.math.FlxMath.lerp),
	];
	
	public function new(path:String, allowUseHScript:Bool = true) {
		_allowUseHScript = allowUseHScript;
		isLua = true;
		super(path);
	}

	public override function onCreate(path:String) {
		super.onCreate(path);
		
		heart = LuaL.newstate();
		loadLibs();
		
		try {
			if(Assets.exists(rawPath)) code = Assets.getText(rawPath);
			if(code == "" || code == null) code = templateCode;
		} catch(e) {
			Logs.trace('Error while reading $path: ${Std.string(e)}', ERROR);
			_close();
		}
		
		#if GLOBAL_SCRIPT
		funkin.backend.scripting.GlobalScript.call("onScriptCreated", [this, "lua"]);
		#end
		
		if(_allowUseHScript) {
			for(k=>v in Script.getDefaultVariables()) {
				interp.variables.set(k, v);
			}
			interp.variables.set("parent_lua", this);
			interp.errorHandler = _hscriptErrorHandler;
		}

		for(k=>v in defaultVariables) {
			set(k, v);
		}
		LuaUtil.reflectFunction(this);
		LuaUtil.hscriptFunction(this);
		LuaUtil.timerAndTweenFunction(this);
		LuaUtil.objectFunction(this);
		LuaUtil.spriteFunction(this);
	}
	
	override function onLoad() {
		if(heart == null || closed) return;
	
		//我一直在想加载是否需要返回值😅
		try {
			if(LuaL.dostring(heart, code) != Lua.LUA_OK) {
				var output:Dynamic = null;
				if((output = Lua.tostring(heart, -1)) != null) {
					error(output);
					_close();
				}
			}
		} catch(e:Dynamic) {
			trace(e);
			_close();
			
			return;
		}
		trace("loading Successully");
		call("new");
	}
	
	override function reload() {
		if(!closed)
			load();
	}
	
	override function onCall(key:String, args:Array<Dynamic>) {
		var result:Dynamic = null;
		
		if(heart == null || closed) return result;

		try {
			var oldTop:Int = Lua.gettop(heart);
	
			Lua.getglobal(heart, key);
			var funcType:Int = Lua.type(heart, -1);
		
			//不加这个一大堆文字占满你屏幕，密密麻麻的！密集恐惧症都犯了唉
			if(funcType != Lua.LUA_TFUNCTION) {
				if(funcType > Lua.LUA_TNIL) {
					error('Attempt To Call other Type Variable: $key!!');
				}
			
				Lua.pop(heart, 1);
				return result;
			}
		
			if(args.length < 1) {
				if(Lua.pcall(heart, 0, Lua.LUA_MULTRET, 1) != Lua.LUA_OK) {
					error('On Call "$key" ${Lua.tostring(heart, -1)}');
				}else {
					result = retReturn(heart, oldTop);
				}
			}else {
				//实际被撅了的数量（确信
				var ifLength:Int = 0;
				for(arg in args) {
					if(Convert.toLua(heart, arg))
						ifLength++;
				}
			
				if(Lua.pcall(heart, ifLength, Lua.LUA_MULTRET, 1) != Lua.LUA_OK) {
					error('On Call "$key" ${Lua.tostring(heart, -1)}');
				}else {
					result = retReturn(heart, oldTop);
				}
			}
		
			Lua.settop(heart, oldTop);
			return result;
		} catch(e:Dynamic) {
			trace(e);
		}
		
		return result;
	}
	
	public override function set(key:String, val:Dynamic) {
		if(heart == null || closed) return;
	
		if(!Reflect.isFunction(val)) {
			if(Convert.toLua(heart, val)) {
				Lua.setglobal(heart, key);
				if(!_variables.exists(key))
					_variables.set(key, val);
			}
		}else {
			Lua_helper.add_callback(heart, key, val);
			if(!_variables.exists(key))
				_variables.set(key, val);
		}
	}
	
	public override function get(key:String):Dynamic {
		if(heart == null || closed) return null;
	
		Lua.getglobal(heart, key);
		var ret:Dynamic = Convert.fromLua(heart, -1);
		if(ret != null) Lua.pop(heart, 1);
		
		return ret;
	}
	
	public override function setParent(sc:Dynamic) {
		scriptObject = sc;
	}
	
	public override function setPublicMap(map:Map<String, Dynamic>) {
		_publicVariables = map;
		if(_allowUseHScript)
			this.interp.publicVariables = map;
	}
	
	public override function error(text:String, ?additionInfo:Dynamic) {
		var fileName = this.fileName;
		if(remappedNames.exists(fileName))
			fileName = remappedNames.get(fileName);
		Logs.traceColored([
			Logs.logText(fileName, RED),
			Logs.logText(text)
		], ERROR);
		#if mobile
		final debugPrint = Main.instance.debugPrintLog.debugPrint;
		debugPrint('Error On $fileName!!!', {style: 0xFF00FF00, delayTime: 3.5});
		debugPrint('$fileName: $text', {style: 0xFFFF0000, delayTime: 3.5});
		#end
	}
	
	private function _hscriptErrorHandler(error:Error) {
		var fileName = error.origin;

		var fn = '$fileName:${error.line}: ';
		var err = error.toString();
		if (err.startsWith(fn)) err = err.substr(fn.length);

		Logs.traceColored([
			Logs.logText(fn, GREEN),
			Logs.logText(err, RED)
		], ERROR);

		#if mobile
		Main.instance.debugPrintLog.debugPrint(fn, {delayTime: 3.5, style: 0x00ff00});
		Main.instance.debugPrintLog.debugPrint(err, {delayTime: 3.5, style: 0xff0000});
		#end
	}
	
	public override function destroy():Void {
		super.destroy();
		
		_close();
	}
	
	override function toString():String {
		return FlxStringUtil.getDebugString(didLoad ? [
			LabelValuePair.weak("path", path),
			LabelValuePair.weak("active", active),
			LabelValuePair.weak("closed", closed),
		] : [
			LabelValuePair.weak("path", path),
			LabelValuePair.weak("active", active),
			LabelValuePair.weak("loaded", didLoad),
			LabelValuePair.weak("closed", closed),
		]);
	}
	
	private function retReturn(sb:State, oldTop:Int):Dynamic {
		if(Lua.gettop(sb) - oldTop > 1) {
			var arr:Array<Dynamic> = [];
			var top:Int;
			var i:Int;

			while(Lua.gettop(sb) != Lua.LUA_OK) {
				top = Lua.gettop(sb);
					
				i = top - 1;
				arr[i] = Convert.fromLua(sb, top);
				Lua.pop(sb, 1);
			}
				
			return arr;
		}else {
			return Convert.fromLua(sb, -1);
		}
	}
	
	private function _close() {
		if(closed || heart == null) return;
		
		Lua.close(heart);
		_variables = null;
		heart = null;
		
		closed = true;
	}
	
	private function loadLibs():Void {
		LuaL.openlibs(heart);
		Lua.init_callbacks(heart);
		Lua_helper.register_hxtrace(heart);
	}
}
#end
