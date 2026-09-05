package funkin.backend.shaders;

import openfl.Assets;

@:deprecated("Use funkin.backend.shaders.FunkinShader.fromFile instead.")
class CustomShader extends FunkinShader {
	@:isVar
	public var path(get, set):String;
	inline function get_path():String return path != null ? path : _fragmentFilePath + _vertexFilePath;
	inline function set_path(v:Null<String>):String return path = cast v;

	public function new(name:String, ?glslVersion:String) {
		super();
		loadShaderFile(Paths.fragShader(name), Paths.vertShader(name), glslVersion);
	}
}