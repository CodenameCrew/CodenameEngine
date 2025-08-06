package funkin.backend.shaders;

import hscript.IHScriptCustomBehaviour;
import funkin.backend.scripting.events.shader.ShaderProcessEvent;
import funkin.backend.scripting.ScriptPack;
import funkin.backend.scripting.Script;

@:structInit
class FieldInfo {
	public var get:Void->Dynamic;
	public var set:Dynamic->Dynamic;
}

@:access(funkin.backend.shaders.FunkinShader)
class ScriptableShader extends FlxBasic implements IHScriptCustomBehaviour {
	private static var __instanceFields = Type.getInstanceFields(ScriptableShader);

	public var shader:FunkinShader;
	public var script:Script;

	var fields:Map<String, FieldInfo> = [];

	public function new(shader:FunkinShader, ?scriptName:String, ?parentScriptPack:ScriptPack) {
		super();

		if(parentScriptPack == null && PlayState.instance != null)
			parentScriptPack = PlayState.instance.scripts;

		if(scriptName == null)
			if((shader is CustomShader)) scriptName = cast(shader, CustomShader).fileName;
			else throw "Missing name for shader script, please provide a scriptName, or use CustomShader";

		script = Script.create(Paths.script('shaders/$scriptName'));
		script.setParent(shader);
		script.set("shader", shader);
		script.set("registerParameter", shader.registerParameter);
		script.set("registerField", (name:String, get: Void->Dynamic, set: Dynamic->Dynamic) -> {
			registerField(name, get, set);
		});
		script.set("registerShaderField", (name:String, shaderField:String) -> {
			var get = () -> shader.hget(shaderField);
			var set = (value:Dynamic) -> {
				var val = shader.hset(shaderField, value);
				script.set(name, val);
				return val;
			};
			registerField(name, get, set);
			var gg = script.get(name);
			if(gg != null) {
				shader.hset(shaderField, gg);
			}
		});
		if(parentScriptPack != null)
			script.setPublicMap(parentScriptPack.publicVariables);
		script.load();
		script.call("create");

		shader.onGLUpdate.add(updateGL);
		shader.onProcessGLData.add(processGLData);
	}

	function registerField(name:String, get: Void->Dynamic, set: Dynamic->Dynamic) {
		fields.set(name, {
			get: get,
			set: set
		});
		script.set("get_"+name, get);
		script.set("set_"+name, set);
	}

	public override function update(elapsed:Float) script.call("update", [elapsed]);
	public override function draw() script.call("draw", []);
	public function updateGL() script.call("updateGL", []);
	public function processGLData(source:String, storageType:String) {
		var event = EventManager.get(ShaderProcessEvent).recycle(source, storageType);
		script.call("processGLData", [event]);
		if(event.cancelled)
			shader.__cancelNextProcessGLData = true;
		script.call("processGLDataPost", [event]);
	}

	public override function destroy() {
		shader.onGLUpdate.remove(updateGL);
		shader.onProcessGLData.remove(processGLData);
		if(script != null) {
			script.call("destroy");
			script.destroy();
		}
		fields = null;
		super.destroy();
	}

	public function hget(name:String):Dynamic {
		if(fields.exists(name))
			return fields.get(name).get();
		if (__instanceFields.contains(name) || __instanceFields.contains('get_${name}'))
			return Reflect.getProperty(this, name);
		return shader.hget(name);
	}

	public function hset(name:String, val:Dynamic):Dynamic {
		if (fields.exists(name)) {
			return fields.get(name).set(val);
		}
		if (__instanceFields.contains(name) || __instanceFields.contains('set_${name}')) {
			Reflect.setProperty(this, name, val);
			return val;
		}
		return shader.hset(name, val);
	}
}