#pragma header

// Used in charter by waveforms

#define HEIGHT      0.05   // Height of the Bar
#define BACKLIGHT   0.6    // Backlight
#define BRIGHTNESS  0.33   // overall Brightness
#define GLOW        1.25   // Glow intensity of the Bar

const vec3 gradient1 = vec3(114.0/255.0, 81.0/255.0, 135.0/255.0);
const vec3 gradient2 = vec3(144.0/255.0, 80.0/255.0, 186.0/255.0);

const vec4 outlinecolor = vec4(0.1);
const vec3 lowdetailcol = vec3(0.0, 0.0, 1.0);

uniform vec2 textureRes;
uniform float pixelOffset;

uniform float playerPosition;

uniform sampler2D waveformTexture;
uniform ivec2 waveformSize;

uniform bool lowDetail;

uniform float time;

float getAmplitude(vec2 pixel) {
	float pixelID = floor((pixel.y+pixelOffset)/3.0);

	// TODO: INVESTIGATE THE 1.+ AND WHY IT WORKS (SRSLY I GOT NO CLUE) -lunar
	vec2 wavePixel = vec2(mod(pixelID,waveformSize.x), 1.0+floor(pixelID/waveformSize.x));
	vec4 waveData = texture2D(waveformTexture, wavePixel / waveformSize);

	int id = int(mod(wavePixel.x, 3.0));
	if(id == 0) return waveData.r;
	if(id == 1) return waveData.g;
	if(id == 2) return waveData.b;
	return 0.0;
}

float getAmpWidth(float amplitude) {
	return (1.0-amplitude) * textureRes.x;
}

bool inWaveForm(vec2 pixel, float width) {
	float widthdiv2 = width/2.0;
	return pixel.x > widthdiv2 && pixel.x < textureRes.x-widthdiv2;
}

float getHightlight(float ampwidth) {
	float remapCoord = (ampwidth/textureRes.x)/2.0;
	float mappedCoord = map(openfl_TextureCoordv.x, remapCoord, 1.0-remapCoord, 0.0, 1.0);
	return 1.0-(abs(mappedCoord-0.5)*2.0);
}

void outlineWaveform(vec2 pixel, vec2 offset) {
	float amplitude = getAmplitude(pixel - offset);
	float ampwidth = (1.0-amplitude) * textureRes.x;

	if (!inWaveForm(pixel, ampwidth))
		gl_FragColor = vec4(vec3(0.), 1.);
}

void main()
{
	vec2 pixel = openfl_TextureCoordv * textureRes;
	float amplitude = getAmplitude(pixel);
	float ampwidth = getAmpWidth(amplitude);

	gl_FragColor = vec4(vec3(0.0), .1);

	vec2 uv = openfl_TextureCoordv.xy - 0.5;

	float c = BACKLIGHT;
	float a = abs(uv.x);
	float s = 1.0 - smoothstep(0.0, ampwidth/textureRes.x, a);
	c *= 1.33 - smoothstep(0.0, 0.5, a);
	c*=c*c;
	c += s*.5;

	if (inWaveForm(pixel, ampwidth))
		c += s;
	
	gl_FragColor = vec4((cos(6.283 * (uv.y + time + vec3(0.0,.33,0.66)))*map(getHightlight(amplitude), 0.0, 1.0, 0.5, 1.0)) + GLOW, 1.0) * c * BRIGHTNESS;
	gl_FragColor.xyz *= map(getHightlight(amplitude), 0.0, 1.0, 0.5, 1.0);
	gl_FragColor.xyz *= pixel.y+pixelOffset>playerPosition ? 0.6 : 1.0;
}