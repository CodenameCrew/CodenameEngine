#pragma header

// Used for editors (faster)

//#define iResolution _camSize
#define getTexture textureCam

#define iResolution openfl_TextureSize
//#define getTexture flixel_texture2D

float uBlur = 0.015;
float uBrightness = 0.6;

vec4 getColor(vec2 pos) {
	vec2 ps = (pos);
	ps = clamp(ps, vec2(0.0), vec2(1.0));//1.0 - (1.0 / iResolution.xy));
	return flixel_texture2D(bitmap, (ps));
}

uniform sampler2D noiseTexture;
uniform vec2 noiseTextureSize;

vec2 random(vec2 p) {
	p *= openfl_TextureSize;
    return texture2D(noiseTexture, p/noiseTextureSize).rg;
}

void main() {
	vec2 camPos = (openfl_TextureCoordv);
	//vec2 camPos = openfl_TextureCoordv;
	if (camPos.x < 0.0 || camPos.x > 1.0 || camPos.y < 0.0 || camPos.y > 1.0)
		return;

	vec2 blur = vec2(uBlur) * vec2(1.0, iResolution.x / iResolution.y);

	vec4 a = getColor(camPos+(random(camPos)*blur - blur / 2.0)) * uBrightness;
	a += getColor(camPos+(random(camPos+0.1)*blur - blur / 2.0)) * uBrightness;
	//a += getColor(camPos+(random(camPos+0.2)*blur - blur / 2.0)) * uBrightness;
	//a += getColor(camPos+(random(camPos+0.3)*blur - blur / 2.0)) * uBrightness;
	gl_FragColor = a / 2.0;
}