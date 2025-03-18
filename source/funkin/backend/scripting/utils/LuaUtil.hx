package funkin.backend.scripting.utils;

#if ALLOW_LUASTATE
import Type.ValueType;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import funkin.backend.scripting.LuaScript;
import funkin.backend.MusicBeatState;
import funkin.backend.MusicBeatSubstate;
import funkin.backend.system.interfaces.IStateScript;
import flixel.FlxState;
import flixel.FlxSprite;
import hscript.IHScriptCustomBehaviour;

class LuaUtil {
	public inline static final Function_Stop:Int = 0;
	public inline static final Function_Continue:Int = 1;
	
	public static function reflectFunction(lua:LuaScript) {
		/**
		 * 获取此lua脚本的`scriptObject`中的变量值
		 * @param tag 选定变量
		 * @return 返回其变量值
		 */
		lua.set("getProperty", function(tag:String) {
			var split = tag.split(".");
			var first:String = split[0];
			
			if(lua._publicVariables.exists(first)) {
				if(split.length > 1) {
					return getVariableFromStr(lua._publicVariables.get(first), tag.substr(first.length + 1), lua, "getProperty");
				}else if(split.length == 1) {
					return lua._publicVariables.get(tag);
				}
			}
		
			if(lua.scriptObject != null) {
				if(lua.scriptObject is IStateScript) {
					var realState:IStateScript = cast lua.scriptObject;

					if(realState.scriptVariables.exists(first)) {
						if(split.length > 1) {
							return getVariableFromStr(realState.scriptVariables.get(first), tag.substr(first.length + 1), lua, "getProperty");
						}else {
							return realState.scriptVariables.get(first);
						}
					}
				}
			
				return getVariableFromStr(lua.scriptObject, tag, lua, "getProperty");
			}else {
				error('ScriptObject Was Null, So You Can\'t Use This Callback', "getProperty", lua);
			}
			
			return null;
		});
		
		/**
		 * 设置此脚本的`scriptObject`中选定变量的值
		 * @param tag 选定变量
		 * @param val 设置其变量的值
		 * @return 如果此回调运行正常，将会返回true，否则为false
		 */
		lua.set("setProperty", function(tag:String, val:Dynamic) {
			var split = tag.split(".");
			var first:String = split[0];
			
			if(lua._publicVariables.exists(first)) {
				if(split.length > 1) {
					return setVariableFromStr(lua._publicVariables.get(first), tag.substr(first.length + 1), val, lua, "setProperty");
				}else if(split.length == 1) {
					lua._publicVariables.set(tag, val);
					return true;
				}
			}
		
			if(lua.scriptObject != null) {
				if(lua.scriptObject is IStateScript) {
					var realState:IStateScript = cast lua.scriptObject;

					if(realState.scriptVariables.exists(first)) {
						if(split.length > 1) {
							return setVariableFromStr(realState.scriptVariables.get(first), tag.substr(first.length + 1), val, lua, "setProperty");
						}else {
							realState.scriptVariables.set(first, val);
							return true;
						}
					}
				}
			
				return setVariableFromStr(lua.scriptObject, tag, val, lua, "setProperty");
			}else {
				error('ScriptObject Was Null, So You Can\'t Use This Callback', "setProperty", lua);
			}
			
			return false;
		});
		
		/**
		 * 设置选定的类`Class`的静态变量的值
		 * @param cl 所选定的类
		 * @param tag 所选定其类中的静态变量
		 * @return 如果此回调运行正常，将会返回true，否则为false
		 */
		lua.set("setPropertyFromClass", function(cl:String, tag:String, val:Dynamic) {
			var cls:Class<Dynamic> = Type.resolveClass(cl);
			if(cls == null) {
				cls = Type.resolveClass('${cl}_HSC');
			}
			if(cls == null) {
				error('Not Found Class: $cl', "setPropertyFromClass", lua);
				return false;
			}
			
			return setVariableFromStr(cls, tag, val, lua, "setPropertyFromClass");
		});
		
		/**
		 * 获取选定的类`Class`的静态变量的值
		 * @param cl 所选定的类
		 * @param tag 所选定其类中的静态变量
		 * @return 将返回其类的静态变量的值
		 */
		lua.set("getPropertyFromClass", function(cl:String, tag:String) {
			var cls:Class<Dynamic> = Type.resolveClass(cl);
			if(cls == null) {
				cls = Type.resolveClass('${cl}_HSC');
			}
			if(cls == null) {
				error('Not Found Class: $cl', "setPropertyFromClass", lua);
				return false;
			}
			
			return getVariableFromStr(cls, tag, lua, "getPropertyFromClass");
		});
		
		/**
		 * 获取lua脚本中`scriptObject`中选定为`FlxGroup`或者`Array`类型的变量的变量值
		 * @param group 所选定的`FlxGroup`类型或者`Array`的变量
		 * @param index ......懒得说
		 * @param variable 其变量值
		 * @return 返回其所选的变量的值
		 */
		lua.set("getPropertyFromGroup", function(group:String, index:Int, variable:String) {
			
			
			var grp:Dynamic = null;
			var sureVar:Bool = false;
			
			var split = group.split(".");
			var first:String = split[0];
			
			if(lua._publicVariables.exists(first)) {
				if(split.length > 1) {
					grp =  getVariableFromStr(lua._publicVariables.get(first), group.substr(first.length + 1), lua, "getPropertyFromGroup");
				}else if(split.length == 1) {
					grp = lua._publicVariables.get(group);
				}
				sureVar = true;
			}
			
			if(!sureVar && (lua.scriptObject is IStateScript)) {
				var realState:IStateScript = cast lua.scriptObject;

				if(realState.scriptVariables.exists(first)) {
					if(split.length > 1) {
						grp = getVariableFromStr(realState.scriptVariables.get(first), group.substr(first.length + 1), lua, "getPropertyFromGroup");
					}else {
						grp = realState.scriptVariables.get(first);
					}
					sureVar = true;
				}
			}
			
			if(!sureVar)
				grp = getVariableFromStr(lua.scriptObject, group, lua, "getPropertyFromGroup");
			if(grp == null) {
				error('The Variable "$group" Was Null', "getPropertyFromGroup", lua);
				return null;
			}
			return (switch(Type.typeof(grp)) {
				case TClass(cls):
					if(cls == Array) {
						getVariableFromStr(grp[index], variable, lua, "getPropertyFromGroup");
					} else {
						if(Type.getInstanceFields(cls).contains("members") && (Reflect.getProperty(grp, "members") is Array)) {
							getVariableFromStr(grp.members[index], variable, lua, "getPropertyFromGroup");
						}else {
							error('The Variable "$group" Not Belonging To FlxGroup Or Array', "getPropertyFromGroup", lua);
							null;
						}
					}
				default:
					error('The Variable "$group" Not Belonging To FlxGroup Or Array', "getPropertyFromGroup", lua);
					null;
			});
		});
		
		/**
		 * 设置lua脚本中`scriptObject`中选定为`FlxGroup`或者`Array`类型的变量的变量值
		 * @param group 所选定的`FlxGroup`类型或者`Array`的变量
		 * @param index ......懒得说
		 * @param variable 其变量值
		 * @return 如果回调正常，将返回true，否则为false
		 */
		lua.set("setPropertyFromGroup", function(group:String, index:Int, variable:String, value:Dynamic) {
			var grp:Dynamic = null;
			var sureVar:Bool = false;
			var split = group.split(".");
			var first:String = split[0];
			
			if(lua._publicVariables.exists(first)) {
				if(split.length > 1) {
					grp = getVariableFromStr(lua._publicVariables.get(first), group.substr(first.length + 1), lua, "setPropertyFromGroup");
				}else if(split.length == 1) {
					return lua._publicVariables.get(group);
				}
				sureVar = true;
			}
			
			if(!sureVar && (lua.scriptObject is IStateScript)) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(realState.scriptVariables.exists(first)) {
					if(split.length > 1) {
						grp = getVariableFromStr(realState.scriptVariables.get(first), group.substr(first.length + 1), lua, "setPropertyFromGroup");
					}else {
						grp = realState.scriptVariables.get(first);
					}
					sureVar = true;
				}
			}
			
			if(!sureVar)
				grp = getVariableFromStr(lua.scriptObject, group, lua, "setPropertyFromGroup");
			if(grp == null) {
				error('The Variable "$group" Was Null', "setPropertyFromGroup", lua);
				return false;
			}
			
			switch(Type.typeof(grp)) {
				case TClass(cls):
					if(cls == Array) {
						return setVariableFromStr(grp[index], variable, value, lua, "setPropertyFromGroup");
					} else {
						if(Type.getInstanceFields(cls).contains("members") && (Reflect.getProperty(grp, "members") is Array)) {
							return setVariableFromStr(grp.members[index], variable, value, lua, "setPropertyFromGroup");
						}else {
							error('The Variable "$group" Not Belonging To FlxGroup Or Array', "setPropertyFromGroup", lua);
							return false;
						}
					}
				default:
					error('The Variable "$group" Not Belonging To FlxGroup Or Array', "setPropertyFromGroup", lua);
					return false;
			}
		});
		
		/**
		 * 回调
		 * @param func 选定的函数
		 * @paran args 选定的参数组
		 * @return 如果其函数拥有返回值，将会返回其值（否则为null）
		 */
		lua.set("callMethod", function(func:String, ?args:Array<Dynamic>) {
			var fs:Dynamic = null;
			var sureVar:Bool = false;
			var split = func.split(".");
			var first:String = split[0];
			
			if(lua._publicVariables.exists(first)) {
				if(split.length > 1) {
					fs = getVariableFromStr(lua._publicVariables.get(first), func.substr(first.length + 1), lua, "callMethod");
				}else if(split.length == 1) {
					fs = lua._publicVariables.get(func);
				}
				sureVar = true;
			}
			
			if(!sureVar && (lua.scriptObject is IStateScript)) {
				var realState:IStateScript = cast lua.scriptObject;

				if(realState.scriptVariables.exists(first)) {
					if(split.length > 1) {
						fs = getVariableFromStr(realState.scriptVariables.get(first), func.substr(first.length + 1), lua, "callMethod");
					}else {
						fs = realState.scriptVariables.get(first);
					}
					sureVar = true;
				}
			}
			
			if(!sureVar)
				fs = getVariableFromStr(lua.scriptObject, func, lua, "callMethod");
			if(fs == null) {
				error('The Variable "$func" Was Null', "callMethod", lua);
				return null;
			}
			if(Reflect.isFunction(fs)) {
				try {
					return Reflect.callMethod(null, fs, (args == null ? [] : args));
				} catch(e:Dynamic) {
					error('Expected variable "$func" In This Callback', "callMethod", lua);
				}
			}else {
				error('The Variable "$func" Was Not Function!', "callMethod", lua);
			}
			
			return null;
		});
		
		/**
		 * 选定类`Class`中的静态函数
		 * @param cl 选定的类
		 * @param func 选定其类中的静态函数
		 * @args 参数
		 * @return 你知道的，我懒得说
		 */
		lua.set("callMethodFromClass", function(cl:String, func:String, ?args:Array<Dynamic>) {
			var cls:Class<Dynamic> = Type.resolveClass(cl);
			if(cls == null) {
				cls = Type.resolveClass('${cl}_HSC');
			}
			if(cls == null) {
				error('Not Found Class: $cl', "setPropertyFromClass", lua);
				return null;
			}
			
			var fs:Dynamic = getVariableFromStr(cls, func, lua, "callMethodFromClass");
			if(fs == null) {
				error('The Variable "$func" Was Null', "callMethodFromClass", lua);
				return null;
			}
			if(Reflect.isFunction(fs)) {
				try {
					return Reflect.callMethod(null, fs, (args == null ? [] : args));
				} catch(e:Dynamic) {
					error('Expected variable "$func" In This Callback', "callMethodFromClass", lua);
				}
			}else {
				error('The Variable "$func" Was Not Function!', "callMethodFromClass", lua);
			}
			
			return null;
		});
		
		lua.set("setVar", function(name:String, value:Dynamic) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(name.contains(".") || name.contains("[") || name.contains("]")) {
					error('Expected Variable $name, Can\'t Contain "OP"(etc. "." or "[" )', "setVar", lua);
					return false;
				}
				
				if(lua._publicVariables.exists(name)) {
					error('The Variable "$name" Was Exist, If You Want to Setter. You can use "setProperty" Callback', "setVar", lua);
					return false;
				}
				
				if(!realState.scriptVariables.exists(name)) {
					realState.scriptVariables.set(name, value);
					return true;
				}else {
					error('The Variable "$name" Was Exist, If You Want to Setter. You can use "setProperty" Callback', "setVar", lua);
				}
			}
			
			return false;
		});
		
		lua.set("getVar", function(name:String) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				if(realState.scriptVariables.exists(name)) {
					return realState.scriptVariables.get(name);
				}else {
					error('The Variable "$name" was not exists', "getVar", lua);
				}
			}
			
			return null;
		});
	}
	
	public static function timerAndTweenFunction(lua:LuaScript) {
		lua.set("runTimer", function(tag:String, time:Float, loops:Int = 1) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(realState.scriptVariables.get("_timer_") == null) realState.scriptVariables.set("_timer_", new Map<String, FlxTimer>());
				
				final variables = realState.scriptVariables.get("_timer_");
				if(!variables.exists(tag)) {
					var tmr:FlxTimer = new FlxTimer().start(time, (fw) -> {
						lua.call("onTimerCompleted", [tag, fw.time, fw.loopsLeft]);
						if(fw.finished)
							cancelTimer(tag, "runTimer", lua);
					}, loops);
					variables.set(tag, tmr);
					return true;
				}else {
					error("The Timer's Tag Was Exists", "runTimer", lua);
				}
			}
			
			return false;
		});
			
		lua.set("cancelTimer", function(tag:String) {
			return cancelTimer(tag, "cancelTimer", lua, true);
		});
		
		lua.set("startTween", function(tag:String, obj:String, att:Dynamic, time:Float, ?options:Dynamic) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(realState.scriptVariables.get("_tween_") == null) {
					realState.scriptVariables.set("_tween_", new Map<String, FlxTween>());
				}
				
				if(realState.scriptVariables.get("_tween_").exists(tag)) {
					error('The Variable "$tag" was existed!', "startTween", lua);
					return false;
				}
				
				var split:Array<String> = obj.split(".");
				var first:String = split[0];

				if(lua._publicVariables.exists(first)) {
					if(split.length > 1) {
						var realObj:Dynamic = getVariableFromStr(lua._publicVariables.get(first), obj.substr(first.length + 1), lua, "startTween");
						if(realObj != null) {
							var tn:FlxTween = resolveLuaTween(tag, realObj, att, time, options, lua, "startTween");
							if(tn != null) {
								realState.scriptVariables.get("_tween_").set(tag, tn);
								return true;
							}
							return false;
						}
					}else if(split.length == 1) {
						var realObj:Dynamic = lua._publicVariables.get(obj);
						if(realObj != null) {
							var tn:FlxTween = resolveLuaTween(tag, realObj, att, time, options, lua, "startTween");
							if(tn != null) {
								realState.scriptVariables.get("_tween_").set(tag, tn);
								return true;
							}
							return false;
						}
					}
				}
			
				if(realState.scriptVariables.exists(first)) {
					if(split.length > 1) {
						var realObj:Dynamic = getVariableFromStr(realState.scriptVariables.get(first), obj.substr(first.length + 1), lua, "startTween");
						if(realObj != null) {
							var tn:FlxTween = resolveLuaTween(tag, realObj, att, time, options, lua, "startTween");
							if(tn != null) {
								realState.scriptVariables.get("_tween_").set(tag, tn);
								return true;
							}
							return false;
						}
					}else if(split.length == 1) {
						var realObj:Dynamic = realState.scriptVariables.get(obj);
						if(realObj != null) {
							var tn:FlxTween = resolveLuaTween(tag, realObj, att, time, options, lua, "startTween");
							if(tn != null) {
								realState.scriptVariables.get("_tween_").set(tag, tn);
								return true;
							}
							return false;
						}
					}
				}
				
				if(lua.scriptObject != null) {
					var realObj:Dynamic = getVariableFromStr(lua.scriptObject, obj, lua, "startTween");
					if(realObj != null) {
						var tn:FlxTween = resolveLuaTween(tag, realObj, att, time, options, lua, "startTween");
						if(tn != null) {
							realState.scriptVariables.get("_tween_").set(tag, tn);
							return true;
						}
					}else {
						error('The Variable "$obj" was Null!', "startTween", lua);
					}
				}
			}
			
			return false;
		});
		
		lua.set("doTweenNum", function(tag:String, fromValue:Float, toValue:Float, time:Float, ?options:Dynamic) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				if(realState.scriptVariables.get("_tween_") == null) {
					realState.scriptVariables.set("_tween_", new Map<String, FlxTween>());
				}
			
				if(realState.scriptVariables.get("_tween_").exists(tag)) {
					error('The Variable "$tag" was existed!', "doTweenNum", lua);
					return false;
				}
			
				var fn:FlxTween = resolveLuaNumTween(tag, fromValue, toValue, time, options, lua, "doTweenNum");
				if(fn != null) {
					realState.scriptVariables.get("_tween_").set(tag, fn);
					return true;
				}
			}
			return false;
		});
		
		lua.set("doTweenColor", function(tag:String, obj:String, time:Float, fromColor:String, toColor:String, ?options:Dynamic) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(realState.scriptVariables.get("_tween_") == null) {
					realState.scriptVariables.set("_tween_", new Map<String, FlxTween>());
				}
				
				if(realState.scriptVariables.get("_tween_").exists(tag)) {
					error('The Variable "$tag" was existed!', "doTweenColor", lua);
					return false;
				}
				
				var split:Array<String> = obj.split(".");
				var first:String = split[0];

				if(lua._publicVariables.exists(first)) {
					if(split.length > 1) {
						var realObj:Dynamic = getVariableFromStr(lua._publicVariables.get(first), obj.substr(first.length + 1), lua, "doTweenColor");
						if(realObj is FlxSprite) {
							var tn:FlxTween = resolveLuaColorTween(tag, realObj, time, FlxColor.fromString(fromColor), FlxColor.fromString(toColor), options, lua, "doTweenColor");
							if(tn != null) {
								realState.scriptVariables.get("_tween_").set(tag, tn);
								return true;
							}
							return false;
						}
					}else if(split.length == 1) {
						var realObj:Dynamic = lua._publicVariables.get(obj);
						if(realObj != null) {
							var tn:FlxTween = resolveLuaColorTween(tag, realObj, time, FlxColor.fromString(fromColor), FlxColor.fromString(toColor), options, lua, "doTweenColor");
							if(tn != null) {
								realState.scriptVariables.get("_tween_").set(tag, tn);
								return true;
							}
							return false;
						}
					}
				}
			
				if(realState.scriptVariables.exists(first)) {
					if(split.length > 1) {
						var realObj:Dynamic = getVariableFromStr(realState.scriptVariables.get(first), obj.substr(first.length + 1), lua, "doTweenColor");
						if(realObj is FlxSprite) {
							var tn:FlxTween = resolveLuaColorTween(tag, realObj, time, FlxColor.fromString(fromColor), FlxColor.fromString(toColor), options, lua, "doTweenColor");
							if(tn != null) {
								realState.scriptVariables.get("_tween_").set(tag, tn);
								return true;
							}
							return false;
						}
					}else if(split.length == 1) {
						var realObj:Dynamic = realState.scriptVariables.get(obj);
						if(realObj != null) {
							var tn:FlxTween = resolveLuaColorTween(tag, realObj, time, FlxColor.fromString(fromColor), FlxColor.fromString(toColor), options, lua, "doTweenColor");
							if(tn != null) {
								realState.scriptVariables.get("_tween_").set(tag, tn);
								return true;
							}
							return false;
						}
					}
				}
				
				if(lua.scriptObject != null) {
					var realObj:Dynamic = getVariableFromStr(lua.scriptObject, obj, lua, "doTweenColor");
					if(realObj == null) {
						error('The Variable "$obj" was Null!', "doTweenColor", lua);
						return false;
					}
					if(realObj is FlxSprite) {
						var tn:FlxTween = resolveLuaColorTween(tag, realObj, time, FlxColor.fromString(fromColor), FlxColor.fromString(toColor), options, lua, "doTweenColor");
						if(tn != null) {
							realState.scriptVariables.get("_tween_").set(tag, tn);
							return true;
						}
					}else {
						error('The Variable "$obj" was Not "FlxSprite" Type Or Ex', "doTweenColor", lua);
					}
				}
			}
			
			return false;
		});
		
		lua.set("cancelTween", function(tag:String) {
			cancelTween(tag, "cancelTween", lua, true);
		});
	}
	
	public static function spriteFunction(lua:LuaScript) {
		lua.set("makeLuaSprite", function(tag:String, x:Float = 0, y:Float = 0) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(realState.scriptVariables.exists(tag)) {
					error('The Variable "$tag" was Existed!', "makeLuaSprite", lua);
					return;
				}
				
				var spr:FunkinSprite = new FunkinSprite(x, y);
				realState.scriptVariables.set(tag, spr);
			}
		});
		
		lua.set("makeGraphic", function(tag:String, width:Float, height:Float, color:String) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(!realState.scriptVariables.exists(tag)) {
					error('The Variable "$tag" was not exists!', 'makeGraphic', lua);
					return;
				}
				
				var spr:Dynamic = realState.scriptVariables.get(tag);
				if(spr == null) {
					error('The Sprite Variable "$tag" Was Null!!', "makeGraphic", lua);
					return;
				}
				try {
					spr.makeGraphic(width, height, FlxColor.fromString(color));
				} catch(e:Dynamic) {
					error('Expected Variable "$tag", When Make Graphic', "makeGraphic", lua);
				}
			}
		});
		
		lua.set("loadGraphic", function(tag:String, path:String, animated:Bool = false, width:Float = 0, height:Float = 0) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(!realState.scriptVariables.exists(tag)) {
					error('The Variable "$tag" was not exists!', 'loadGraphic', lua);
					return;
				}
				
				var spr:Dynamic = realState.scriptVariables.get(tag);
				if(spr == null) {
					error('The Sprite Variable "$tag" Was Null!!', "loadGraphic", lua);
					return;
				}
				try {
					final imagePath = Paths.image(path);
					if(Assets.exists(imagePath))
						spr.loadGraphic(imagePath, animated, width, height);
					else error('The Image Path "$path" Was Not Exists!', "loadGraphic", lua);
				} catch(e:Dynamic) {
					error('Expected Variable "$tag", When Make Graphic', "loadGraphic", lua);
				}
			}
		});
		
		lua.set("loadFrames", function(tag:String, path:String) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(!realState.scriptVariables.exists(tag)) {
					error('The Variable "$tag" was not exists!', 'loadGraphic', lua);
					return;
				}
				
				var spr:Dynamic = realState.scriptVariables.get(tag);
				if(spr == null) {
					error('The Sprite Variable "$tag" Was Null!!', "loadFrames", lua);
					return;
				}
				try {
					if(spr is FunkinSprite) {
						cast(spr, FunkinSprite).loadSprite(Paths.image(path));
					}else if(spr is FlxSprite) {
						cast(spr, FlxSprite).frames = Paths.getFrames(Paths.image(path));
					}
				} catch(e:Dynamic) {
					error('Expected Variable "$tag", When Load Frames', "loadFrames", lua);
				}
			}
		});
	}
	
	public static function objectFunction(lua:LuaScript) {
		lua.set("addLuaObject", function(tag:String) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(!realState.scriptVariables.exists(tag)) {
					error('The Variable "$tag" was not exists!', 'addLuaObject', lua);
					return;
				}
				
				var obj:Dynamic = realState.scriptVariables.get(tag);
				if(obj == null) {
					error('The Object Variable "$tag" Was Null!', "addLuaObject", lua);
					return;
				}else if(!(obj is FlxBasic)) {
					error('The Object Variable "$tag" Can\'t Add To State, Because It Was Not FlxBasic Or Extended!', "addLuaObject", lua);
					return;
				}
				try {
					if(lua.scriptObject is FlxState) {
						cast(lua.scriptObject, FlxState).add(obj);
					}else {
						FlxG.state.add(obj);
					}
				} catch(e:Dynamic) {
					error('Expected Variable "$tag", When Add To State', "addLuaObject", lua);
				}
			}
		});
		
		lua.set("removeLuaObject", function(tag:String, isDestroy:Bool = false) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(!realState.scriptVariables.exists(tag)) {
					error('The Variable "$tag" was not exists!', 'removeLuaObject', lua);
					return;
				}
				
				var obj:Dynamic = realState.scriptVariables.get(tag);
				if(obj == null) {
					error('The Object Variable "$tag" Was Null!', "removeLuaObject", lua);
					return;
				}else if(!(obj is FlxBasic)) {
					error('The Object Variable "$tag" Can\'t Remove To State, Because It Was Not FlxBasic Or Extended!', "removeLuaObject", lua);
					return;
				}
				try {
					if(lua.scriptObject is FlxState) {
						cast(lua.scriptObject, FlxState).remove(obj);
					}else {
						FlxG.state.remove(obj);
					}
				} catch(e:Dynamic) {
					error('Expected Variable "$tag", When Remove To State', "removeLuaObject", lua);
				}
			}
		});
		
		lua.set("insertLuaObject", function(index:Int, tag:String) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(!realState.scriptVariables.exists(tag)) {
					error('The Variable "$tag" was not exists!', 'insertLuaObject', lua);
					return;
				}
				
				var obj:Dynamic = realState.scriptVariables.get(tag);
				if(obj == null) {
					error('The Object Variable "$tag" Was Null!', "insertLuaObject", lua);
					return;
				}else if(!(obj is FlxBasic)) {
					error('The Object Variable "$tag" Can\'t Inert To State, Because It Was Not FlxBasic Or Extended!', "insertLuaObject", lua);
					return;
				}
				try {
					if(lua.scriptObject is FlxState) {
						cast(lua.scriptObject, FlxState).insert(index, obj);
					}else {
						FlxG.state.insert(index, obj);
					}
				} catch(e:Dynamic) {
					error('Expected Variable "$tag", When Insert To State', "insertLuaObject", lua);
				}
			}
		});
		
		lua.set("setObjectCamera", function(tag:String, camera:String) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				var realCamera:Dynamic = null;
				
				var split:Array<Dynamic> = camera.split(".");
				var first:String = split[0];
				var sureVar:Bool = false;

				if(lua._publicVariables.exists(first)) {
					if(split.length > 1) {
						realCamera = getVariableFromStr(lua._publicVariables.get(first), camera.substr(first.length + 1), lua, "setObjectCamera");
					}else if(split.length == 1) {
						realCamera = lua._publicVariables.get(camera);
					}
					sureVar = true;
				}
				
				if(!sureVar)
					realCamera = getVariableFromStr(lua.scriptObject, camera, lua, "setObjectCamera");
				if(realCamera == null) {
					error('The Camera Variable "$camera" Was Null!', "setObjectCamera", lua);
					return;
				}
				else if(!(realCamera is FlxCamera)) {
					error('The Camera Variable "$camera" Was Not FlxCamera Type!', "setObjectCamera", lua);
					return;
				}
				
				
				if(realState.scriptVariables.exists(tag)) {
					var obj:Dynamic = realState.scriptVariables.get(tag);
					if(obj == null) {
						error('The Object Variable "$tag" Was Null!', "setObjectCamera", lua);
						return;
					}else if(!(obj is FlxBasic)) {
						error('The Object Variable "$tag" Can\'t Set Its Camera, Because It Was Not FlxBasic Or Extended!', "setObjectCamera", lua);
						return;
					}
					try {
						cast(obj, FlxBasic).camera = cast(realCamera, FlxCamera);
					} catch(e:Dynamic) {
						error('Expected Object Variable "$tag", When Set Camera', "setObjectCamera", lua);
					}
					return;
				}
				
				var obj:Dynamic = getVariableFromStr(lua.scriptObject, tag, lua, "setObjectCamera");
				if(obj == null) {
					error('The Object Variable "$tag" Was Null!', "setObjectCamera", lua);
					return;
				}else if(!(obj is FlxBasic)) {
					error('The Object Variable "$tag" Can\'t Set Its Camera, Because It Was Not FlxBasic Or Extended!', "setObjectCamera", lua);
					return;
				}
				try {
					cast(obj, FlxBasic).camera = cast(realCamera, FlxCamera);
				} catch(e:Dynamic) {
					error('Expected Object Variable "$tag", When Set Camera', "setObjectCamera", lua);
				}
			}
		});
		
		lua.set("scaleObject", function(tag:String, scaleX:Float, scaleY:Float, updateHitbox:Bool = false) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(realState.scriptVariables.exists(tag)) {
					var obj:Dynamic = realState.scriptVariables.get(tag);
					if(obj == null) {
						error('The Object Variable "$tag" Was Null!', "scaleObject", lua);
						return;
					}else if(!(Reflect.hasField(obj, "scale") || obj is FlxSprite)) {
						error('The Object Variable "$tag" Can\'t Set Scale, Because It Was Not FlxSprite Or Extended Or Has No Field "scale"!', "scaleObject", lua);
						return;
					}
					try {
						obj.scale.set(scaleX, scaleY);
						if(updateHitbox)
							obj.updateHitbox();
					} catch(e:Dynamic) {
						error('Expected Object Variable "$tag", When Set Scale', "scaleObject", lua);
					}
					return;
				}
				
				var obj:Dynamic = getVariableFromStr(lua.scriptObject, tag, lua, "scaleObject");
				if(obj == null) {
					error('The Object Variable "$tag" Was Null!', "scaleObject", lua);
					return;
				}else if(!(Reflect.hasField(obj, "scale") || obj is FlxSprite)) {
					error('The Object Variable "$tag" Can\'t Set Scale, Because It Was Not FlxSprite Or Extended Or Has No Field "scale"!', "scaleObject", lua);
					return;
				}
				try {
					obj.scale.set(scaleX, scaleY);
					if(updateHitbox)
						obj.updateHitbox();
				} catch(e:Dynamic) {
					error('Expected Object Variable "$tag", When Set Scale', "scaleObject", lua);
				}
			}
		});
		
		lua.set("updateHitbox", function(tag:String) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(realState.scriptVariables.exists(tag)) {
					var obj:Dynamic = realState.scriptVariables.get(tag);
					if(obj == null) {
						error('The Object Variable "$tag" Was Null!', "updateHitbox", lua);
						return;
					}else if(!(obj is FlxSprite)) {
						error('The Object Variable "$tag" Can\'t Update Hitbox, Because It Was Not FlxSprite Or Extended!', "scaleObject", lua);
						return;
					}
					try {
						obj.updateHtbox();
					} catch(e:Dynamic) {
						error('Expected Object Variable "$tag", When Update Its Hitbox', "updateHitbox", lua);
					}
					return;
				}
				
				var obj:Dynamic = getVariableFromStr(lua.scriptObject, tag, lua, "updateHitbox");
				if(obj == null) {
					error('The Object Variable "$tag" Was Null!', "updateHitbox", lua);
					return;
				}else if(!(obj is FlxSprite)) {
					error('The Object Variable "$tag" Can\'t Update Hitbox, Because It Was Not FlxSprite Or Extended!', "scaleObject", lua);
					return;
				}
				try {
					obj.updateHitbox();
				} catch(e:Dynamic) {
					error('Expected Object Variable "$tag", When Update Its Hitbox', "updateHitbox", lua);
				}
			}
		});
		
		lua.set("setScrollFactor", function(tag:String, x:Float, y:Float) {
			if(lua.scriptObject is IStateScript) {
				var realState:IStateScript = cast lua.scriptObject;
				
				if(realState.scriptVariables.exists(tag)) {
					var obj:Dynamic = realState.scriptVariables.get(tag);
					if(obj == null) {
						error('The Object Variable "$tag" Was Null!', "setScrollFactor", lua);
						return;
					}else if(!(obj is FlxSprite)) {
						error('The Object Variable "$tag" Can\'t Set ScrollFactor, Because It Was Not FlxSprite Or Extended!', "setScrollFactor", lua);
						return;
					}
					try {
						obj.scrollFactor.set(x, y);
					} catch(e:Dynamic) {
						error('Expected Object Variable "$tag", When Set Its Factor', "setScrollFactor", lua);
					}
					return;
				}
				
				var obj:Dynamic = getVariableFromStr(lua.scriptObject, tag, lua, "setScrollFactor");
				if(obj == null) {
					error('The Object Variable "$tag" Was Null!', "setScrollFactor", lua);
					return;
				}else if(!(obj is FlxSprite)) {
					error('The Object Variable "$tag" Can\'t Set ScrollFactor, Because It Was Not FlxSprite Or Extended!', "setScrollFactor", lua);
					return;
				}
				try {
					obj.scrollFactor.set(x, y);
				} catch(e:Dynamic) {
					error('Expected Object Variable "$tag", When Set Its Factor', "setScrollFactor", lua);
				}
			}
		});
	}
	
	public static function hscriptFunction(lua:LuaScript) {
		lua.set("addHaxeLibrary", function(className:String, ?packageName:String) {
			if(!lua._allowUseHScript) {
				error('Current Lua Script Was Not Allow Execute Haxe', "addHaxeLibrary", lua);
				return false;
			}
			
			var cp:String = null;
			if(packageName != null) {
				var realPN = packageName.trim();
				
				if(realPN != "") {
					cp = realPN + (realPN.endsWith(".") ? "" : ".") + className.trim();
				}else {
					cp = className.trim();
				}
			}else {
				cp = className.trim();
			}
			var cls:Dynamic = Type.resolveClass(cp);
			if(cls == null) {
				cls = Type.resolveEnum(cp);
				
				if(cls != null) {
					var precn = Type.getEnumName(cls);
					lua.interp.variables.set(precn.substr(precn.lastIndexOf(".") + 1), cls);
					return true;
				}
			}
			
			if(cls == null) {
				cls = Type.resolveClass('${cp}_HSC');
			}
			
			if(cls != null) {
				var precn = Type.getClassName(cls);
				lua.interp.variables.set(precn.substr(precn.lastIndexOf(".") + 1), cls);
				return true;
			}else {
				error('Not Found This Type $cp!', "addHaxeLibrary", lua);
			}
			
			return false;
		});
		
		lua.set("runHaxeCode", function(code:String) {
			if(!lua._allowUseHScript) {
				error('Current Lua Script Was Not Allow Execute Haxe', "runHaxeCode", lua);
				return null;
			}
			
			return lua.interp.execute(LuaScript.parser.parseString(code, '"${lua.fileName}" callback(runHaxeCode)'));
		});
	}
	
	public static function cancelTimer(tag:String, title:String, lua:LuaScript, isDestroy:Bool = false) {
		if(lua.scriptObject is IStateScript) {
			var realState:IStateScript = cast lua.scriptObject;
			final variables = realState.scriptVariables.get("_timer_");
			
			if(variables == null) {
				error('(cancelTimer)There are no performances on stage six', title, lua);
				return false;
			}
			
			if(variables.get(tag) != null) {
				var tmr:FlxTimer = variables.get(tag);
				variables.remove(tag);
				if(isDestroy && tmr.active) {
					tmr.cancel();
					tmr.destroy();
				}
				
				return true;
			}else {
				error('(cancelTimer)Not Exists This Timer Tag "$tag", You Can\'t Clear Its Timer', title, lua);
			}
		}
		
		return false;
	}
	
	private static function cancelTween(tag:String, title:String, lua:LuaScript, isDestroy:Bool = false) {
		if(lua.scriptObject is IStateScript) {
			var realState:IStateScript = cast lua.scriptObject;
			
			final variables = realState.scriptVariables.get("_tween_");
			
			if(variables == null) {
				error('(cancelTween)There are no performances on stage six', title, lua);
				return false;
			}
			
			if(variables.get(tag) != null) {
				var tn:FlxTween = variables.get(tag);
				variables.remove(tag);
				if(isDestroy && tn.active) {
					tn.cancel();
					tn.destroy();
				}
				
				return true;
			}else {
				error('(cancelTween)Not Exists This Timer Tag "$tag", You Can\'t Clear Its Tween', title, lua);
			}
		}
		
		return false;
	}
	
	private static function resolveLuaNumTween(tag:String, fv:Float, tv:Float, time:Float, options:Dynamic, lua:LuaScript, title:String) {
		var realOptions:Dynamic = {};
		
		Reflect.setField(realOptions, "onComplete", function(_:FlxTween) {
			lua.call("onTweenCompleted", [tag]);
			cancelTween(tag, title, lua);
		});
		if(options != null) {
			for(op in Reflect.fields(options)) {
				var value:Dynamic = Reflect.getProperty(options, op);
				switch(op) {
					case "startDelay" | "loopDelay":
						Reflect.setField(realOptions, op, value);
					case "ease":
						if(value is String)
							Reflect.setField(realOptions, op, Reflect.getProperty(FlxEase, value));
					default: {/*nothing*/}
				}
			}
		}
		
		try {
			return FlxTween.num(fv, tv, time, realOptions, function(val:Float) {
				lua.call("onGetTweenNum", [tag, val]);
			});
		} catch(e:haxe.Exception) {
			error('Expected The Tween "$tag", Content: \n"${e.message}"', title, lua);
		}
		
		return null;
	}
	
	private static function resolveLuaColorTween(tag:String, obj:FlxSprite, time:Float, fc:FlxColor, tc:FlxColor, options:Dynamic, lua:LuaScript, title:String) {
		var realOptions:Dynamic = {};
		
		Reflect.setField(realOptions, "onComplete", function(_:FlxTween) {
			lua.call("onTweenCompleted", [tag]);
			cancelTween(tag, title, lua);
		});
		if(options != null) {
			for(op in Reflect.fields(options)) {
				var value:Dynamic = Reflect.getProperty(options, op);
				switch(op) {
					case "startDelay" | "loopDelay":
						Reflect.setField(realOptions, op, value);
					case "ease":
						if(value is String)
							Reflect.setField(realOptions, op, Reflect.getProperty(FlxEase, value));
					default: {/*nothing*/}
				}
			}
		}
		
		try {
			return FlxTween.color(obj, time, fc, tc, realOptions);
		} catch(e:haxe.Exception) {
			error('Expected The Tween "$tag", Content: \n"${e.message}"', title, lua);
		}
		
		return null;
	}
	
	private static function resolveLuaTween(tag:String, obj:Dynamic, object:Dynamic, time:Float, options:Dynamic, lua:LuaScript, title:String):FlxTween {
		if(object == null) {
			error("The Att Was Null!!", title, lua);
			return null;
		}
		
		var realObject:Dynamic = {};
		var realOptions:Dynamic = {};
		
		for(ro in Reflect.fields(object)) {
			var value:Dynamic = Reflect.getProperty(object, ro);
			switch(ro) {
				case "color":
					if(value is String)
						Reflect.setField(realObject, ro, FlxColor.fromString(value));
					else Reflect.setField(realObject, ro, value);
				default:
					Reflect.setField(realObject, ro, value);
			}
		}
		
		Reflect.setField(realOptions, "onComplete", function(_:FlxTween) {
			lua.call("onTweenCompleted", [tag]);
			cancelTween(tag, title, lua);
		});
		if(options != null) {
			for(op in Reflect.fields(options)) {
				var value:Dynamic = Reflect.getProperty(options, op);
				switch(op) {
					case "startDelay" | "loopDelay":
						Reflect.setField(realOptions, op, value);
					case "ease":
						if(value is String)
							Reflect.setField(realOptions, op, Reflect.getProperty(FlxEase, value));
					default: {/*nothing*/}
				}
			}
		}
		try {
			return FlxTween.tween(obj, realObject, time, realOptions);
		} catch(e:haxe.Exception) {
			error('Expected The Tween "$tag", Content: \n"${e.message}"', title, lua);
		}
		
		return null;
	}
	
	public static function getVariableFromStr(scriptObject:Dynamic, variable:String, lua:LuaScript, title:String):Dynamic {
		var fuckyou = variable.split(".");
	
		if(fuckyou.length > 1) {
			var oldVar:Dynamic = scriptObject;
			for(shit=>fuck in fuckyou) {
				if(oldVar == null) {
					error('Invalid access to field "${fuck}"', title, lua);
					return null;
				}
			
				if(StringTools.contains(fuck, "[") && StringTools.contains(fuck, "]")) {
					var realShit = fuck.substr(0, fuck.indexOf("["));
					var preField = Reflect.getProperty(oldVar, realShit);
					if(!Std.isOfType(preField, Array)) {
						error('Expected "$realShit"!! Currently Only Supports Array In This Callback', title, lua);
						return null;
					}

					var preInt = fuck.substring(fuck.indexOf("[") + 1, fuck.indexOf("]"));
					oldVar = preField[Std.parseInt(preInt)];
					continue;
				}
				
				if(oldVar is IHScriptCustomBehaviour) {
					//检索自定义class里的field，因为我需要
					oldVar = cast(oldVar, IHScriptCustomBehaviour).hget(fuck);
					continue;
				}
		
				oldVar = Reflect.getProperty(oldVar, fuck);
			}
			return oldVar;
		}else if(fuckyou.length == 1) {
			var originFuck = fuckyou[0];
			
			if(scriptObject == null) {
				error('Invalid access to field "${originFuck}"', title, lua);
				return null;
			}
			
			if(StringTools.contains(originFuck, "[") && StringTools.contains(originFuck, "]")) {
				var preField = Reflect.getProperty(scriptObject, originFuck.substr(0, originFuck.indexOf("[")));
				if(!Std.isOfType(preField, Array)) return null;

				var preInt = originFuck.substring(originFuck.indexOf("[") + 1, originFuck.indexOf("]"));

				return preField[Std.parseInt(preInt)];
			}
			
			if(scriptObject is IHScriptCustomBehaviour) {
				//检索自定义class里的field，因为我需要
				return cast(scriptObject, IHScriptCustomBehaviour).hget(originFuck);
			}
		
			return Reflect.getProperty(scriptObject, originFuck);
		}
	
		return null;
	}

	public static function setVariableFromStr(scriptObject:Dynamic, variable:String, value:Dynamic, lua:LuaScript, title:String):Bool {
		var fuckyou = variable.split(".");
	
		if(fuckyou.length > 1) {
			var preVar:Dynamic = null;
			var oldVar:Dynamic = scriptObject;
			for(shit=>fuck in fuckyou) {
				if(oldVar == null) {
					error('Invalid access to field "${fuck}"', title, lua);
					return false;
				}
			
				if(shit < fuckyou.length - 1) {
					if(StringTools.contains(fuck, "[") && StringTools.contains(fuck, "]")) {
						var realShit = fuck.substr(0, fuck.indexOf("["));
						var preField = Reflect.getProperty(oldVar, realShit);
						if(!Std.isOfType(preField, Array)) {
							error('Expected Variable "$realShit"!! Currently Only Supports Array In This Callback', title, lua);
							return false;
						}

						var preInt = fuck.substring(fuck.indexOf("[") + 1, fuck.indexOf("]"));
					
						oldVar = preField[Std.parseInt(preInt)];
						continue;
					}
					
					if(oldVar is IHScriptCustomBehaviour) {
					//检索自定义class里的field，因为我需要
						oldVar = cast(oldVar, IHScriptCustomBehaviour).hget(fuck);
						continue;
					}
			
					oldVar = Reflect.getProperty(oldVar, fuck);
				}else {
					if(oldVar != null) {
						try {
							if((StringTools.contains(fuck, "[") && StringTools.contains(fuck, "]"))) {
								error('The final value cannot be Array', title, lua);
								return false;
							}else {
								if(oldVar is IHScriptCustomBehaviour) {
									cast(oldVar, IHScriptCustomBehaviour).hset(fuck, value);
									return true;
								}
							
								Reflect.setProperty(oldVar, fuck, value);
								return true;
							}
						} catch(e) {
							error('Expected Variable "$fuck" In This Callback', title, lua);
							return false;
						}
					}else error('Expected Variable "$fuck" In This Callback', title, lua);
				}
			}
		}else if(fuckyou.length == 1) {
			var originFuck = fuckyou[0];
			
			if(scriptObject == null) {
				error('Invalid access to field "${originFuck}"', title, lua);
				return false;
			}
			
			if(StringTools.contains(originFuck, "[") && StringTools.contains(originFuck, "]")) {
				error('The final value cannot be Array', title, lua);
				return false;
			}
			
			if(scriptObject is IHScriptCustomBehaviour) {
				//检索自定义class里的field，因为我需要
				cast(scriptObject, IHScriptCustomBehaviour).hset(originFuck, value);
				return true;
			}
			
			try {
				Reflect.setProperty(scriptObject, originFuck, value);
				return true;
			} catch(e) {
				error('Expected Variable "$originFuck" In This Callback', title, lua);
				return false;
			}
		}
	
		return false;
	}
	
	private static function error(text:String, title:String, lua:LuaScript) {
		lua.error('Null Pointer($title): $text');
	}
}
#end