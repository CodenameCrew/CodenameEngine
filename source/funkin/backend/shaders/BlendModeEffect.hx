package funkin.backend.shaders;

import flixel.util.FlxColor;
import openfl.display.ShaderParameter;

@:dox(hide)
typedef BlendModeShader =
{
	var uBlendColor:ShaderParameter<Float>;
}

@:dox(hide)
class BlendModeEffect
{
	public var shader(default, null):BlendModeShader;

	@:isVar
	public var color(default, set):FlxColor;

	public function new(shader:BlendModeShader, color:FlxColor):Void
	{
		this.shader = shader;
		
		if (this.shader?.uBlendColor != null)
		{
			this.shader.uBlendColor.value = [0.0, 0.0, 0.0, 0.0];
		}
		
		this.color = color;
	}

	function set_color(value:FlxColor):FlxColor
	{
		if (this.color == value && shader?.uBlendColor?.value != null) 
			return this.color = value;

		this.color = value;

		if (shader?.uBlendColor != null)
		{
			shader.uBlendColor.value = [
				color.redFloat,
				color.greenFloat,
				color.blueFloat,
				color.alphaFloat
			];
		}

		return this.color;
	}
}
