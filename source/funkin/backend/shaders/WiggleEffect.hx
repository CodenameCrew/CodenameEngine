package funkin.backend.shaders;

// STOLEN FROM HAXEFLIXEL DEMO LOL
import flixel.system.FlxAssets.FlxShader;

@:dox(hide)
enum WiggleEffectType
{
	DREAMY;
	WAVY;
	HEAT_WAVE_HORIZONTAL;
	HEAT_WAVE_VERTICAL;
	FLAG;
}

@:dox(hide)
class WiggleEffect
{
	public var shader(default, null):WiggleShader = new WiggleShader();
	public var effectType(default, set):WiggleEffectType = DREAMY;
	public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;

	private var _time:Float = 0;

	public function new():Void
	{
		if (shader.uTime != null) shader.uTime.value = [0.0];
	}

	public function update(elapsed:Float):Void
	{
		_time += elapsed;
		if (shader.uTime != null)
		{
			shader.uTime.value = [_time];
		}
	}

	function set_effectType(v:WiggleEffectType):WiggleEffectType
	{
		effectType = v;
		if (shader.effectType != null)
		{
			var typeIndex:Float = WiggleEffectType.getConstructors().indexOf(Std.string(v));
			shader.effectType.value = [typeIndex];
		}
		return v;
	}

	function set_waveSpeed(v:Float):Float
	{
		waveSpeed = v;
		if (shader.uSpeed != null) shader.uSpeed.value = [waveSpeed];
		return v;
	}

	function set_waveFrequency(v:Float):Float
	{
		waveFrequency = v;
		if (shader.uFrequency != null) shader.uFrequency.value = [waveFrequency];
		return v;
	}

	function set_waveAmplitude(v:Float):Float
	{
		waveAmplitude = v;
		if (shader.uWaveAmplitude != null) shader.uWaveAmplitude.value = [waveAmplitude];
		return v;
	}
}

@:dox(hide)
class WiggleShader extends FlxShader
{
	@:glFragmentSource('
#pragma header
//uniform float tx, ty; // x,y waves phase
uniform float uTime;

const float EFFECT_TYPE_DREAMY = 0.0;
const float EFFECT_TYPE_WAVY = 1.0;
const float EFFECT_TYPE_HEAT_WAVE_HORIZONTAL = 2.0;
const float EFFECT_TYPE_HEAT_WAVE_VERTICAL = 3.0;
const float EFFECT_TYPE_FLAG = 4.0;

uniform float effectType;

/**
* How fast the waves move over time
*/
uniform float uSpeed;

/**
* Number of waves over time
*/
uniform float uFrequency;

/**
* How much the pixels are going to stretch over the waves
*/
uniform float uWaveAmplitude;

vec2 sineWave(vec2 pt)
{
	float x = 0.0;
	float y = 0.0;

	if (effectType == EFFECT_TYPE_DREAMY)
	{
		float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * uWaveAmplitude;
		pt.x += offsetX; // * (pt.y - 1.0); // <- Uncomment to stop bottom part of the screen from moving
	}
	else if (effectType == EFFECT_TYPE_WAVY)
	{
		float offsetY = sin(pt.x * uFrequency + uTime * uSpeed) * uWaveAmplitude;
		pt.y += offsetY; // * (pt.y - 1.0); // <- Uncomment to stop bottom part of the screen from moving
	}
	else if (effectType == EFFECT_TYPE_HEAT_WAVE_HORIZONTAL)
	{
		x = sin(pt.x * uFrequency + uTime * uSpeed) * uWaveAmplitude;
	}
	else if (effectType == EFFECT_TYPE_HEAT_WAVE_VERTICAL)
	{
		y = sin(pt.y * uFrequency + uTime * uSpeed) * uWaveAmplitude;
	}
	else if (effectType == EFFECT_TYPE_FLAG)
	{
		y = sin(pt.y * uFrequency + 10.0 * pt.x + uTime * uSpeed) * uWaveAmplitude;
		x = sin(pt.x * uFrequency + 5.0 * pt.y + uTime * uSpeed) * uWaveAmplitude;
	}

	return vec2(pt.x + x, pt.y + y);
}

void main()
{
	vec2 uv = sineWave(openfl_TextureCoordv);
	gl_FragColor = texture2D(bitmap, uv);
}')
	public function new()
	{
		super();
	}
}
