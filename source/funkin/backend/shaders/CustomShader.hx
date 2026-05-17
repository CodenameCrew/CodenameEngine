package funkin.backend.shaders;

import openfl.Assets;

/**
 * Class for custom shaders.
 *
 * To create one, create a `shaders` folder in your assets/mod folder, then add a file named `my-shader.frag` or/and `my-shader.vert`.
 *
 * Non-existent shaders will only load the default one, and throw a warning in the console.
 *
 * To access the shader's uniform variables, use `shader.variable`
 */
class CustomShader extends FunkinShader {
	public var path:String = "";

	/**
	 * Creates a new custom shader
	 * @param name Name of the frag and vert files.
	 */
	public function new(name:String) {
		var fragShaderPath = Paths.fragShader(name);
		var vertShaderPath = Paths.vertShader(name);
		
		var hasFrag = Assets.exists(fragShaderPath);
		var hasVert = Assets.exists(vertShaderPath);
		
		var fragCode = hasFrag ? Assets.getText(fragShaderPath) : null;
		var vertCode = hasVert ? Assets.getText(vertShaderPath) : null;

		this.fileName = name;
		this.fragFileName = fragShaderPath;
		this.vertFileName = vertShaderPath;

		this.path = name;

		if (fragCode == null && vertCode == null) {
			Logs.trace('Shader "$name" assets were not found. Falling back to default.', WARNING);
		}

		super(fragCode, vertCode);
	}
}
