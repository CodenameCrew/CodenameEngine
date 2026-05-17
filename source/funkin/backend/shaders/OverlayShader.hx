package funkin.backend.shaders;

import flixel.system.FlxAssets.FlxShader;

@:dox(hide)
class OverlayShader extends FlxShader
{
	@:glFragmentSource('
	#pragma header

	uniform vec4 uBlendColor;

	vec3 overlay(vec3 base, vec3 blend)
	{
		return mix(
			2.0 * base * blend,
			1.0 - 2.0 * (1.0 - base) * (1.0 - blend),
			step(0.5, base)
		);
	}

	void main()
	{
		vec4 tex = flixel_texture2D(bitmap, openfl_TextureCoordv);

		vec3 color = overlay(tex.rgb, uBlendColor.rgb);

		color = mix(tex.rgb, color, uBlendColor.a);

		gl_FragColor = vec4(color, tex.a);
	}
	')
	public function new()
	{
		super();
	}
}
