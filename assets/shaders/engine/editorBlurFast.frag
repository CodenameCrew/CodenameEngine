#pragma header

// Used for editors (faster)

const float uBlur = 0.015;
const float uBrightness = 0.6;

vec4 getColor(vec2 pos) {
	pos = clamp(pos, vec2(0.0), vec2(1.0));//1.0 - (1.0 / openfl_TextureSize.xy));
	return flixel_texture2D(bitmap, pos);
}

uniform sampler2D noiseTexture;
uniform vec2 noiseTextureSize;

vec2 random(vec2 p) {
	p *= openfl_TextureSize;
    return texture2D(noiseTexture, p / noiseTextureSize).rg - vec2(0.5);
}

void main() {
	vec2 camPos = openfl_TextureCoordv;
	vec2 blur = vec2(uBlur) * vec2(1.0, openfl_TextureSize.x / openfl_TextureSize.y);

	vec4 a =	getColor(camPos+random(camPos)*blur);
	a +=		getColor(camPos+random(camPos+0.1)*blur);
	//a +=		getColor(camPos+random(camPos+0.2)*blur);
	//a +=		getColor(camPos+random(camPos+0.3)*blur);
	gl_FragColor = (a / 2.0) * uBrightness;
}