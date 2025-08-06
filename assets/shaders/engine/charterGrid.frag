#pragma header

#define GRID_SIZE 40.0
#define GRID_HEIGHT 4.0

uniform int segments;

vec4 colorA = vec4(0.329, 0.329, 0.329, 1.0);
vec4 colorB = vec4(0.153, 0.153, 0.153, 1.0);
vec4 colorOutline = vec4(0.867, 0.867, 0.867, 1.0);

void main()
{
	vec2 pixelSize = (1.0 / openfl_TextureSize) / (GRID_SIZE * float(segments));
	vec2 uv = openfl_TextureCoordv.xy;
	vec2 pixelUV = vec2(uv.x * GRID_SIZE * float(segments), uv.y * GRID_SIZE * GRID_HEIGHT);
	if (uv.x < pixelSize.x || uv.x > 1.0 - pixelSize.x) { //edges
		gl_FragColor = colorOutline;
		return;
	}
	vec4 col = colorA;
	bool flip = false;
	
	//horizontal
	if (mod(pixelUV.x, GRID_SIZE * 2.0) < GRID_SIZE)
		flip = !flip;
	//vertical
	if (mod(pixelUV.y, GRID_SIZE * 2.0) < GRID_SIZE)
		flip = !flip;

	if (flip)
		col = colorB;

	gl_FragColor = col * flixel_texture2D(bitmap, uv);
}