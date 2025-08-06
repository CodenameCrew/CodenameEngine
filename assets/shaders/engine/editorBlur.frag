#pragma header
#define PI 3.14159265359

// Used for editors

const int steps = 16;
const int stepsInside = 2;
const float strength = 0.0075;

vec4 getColor(vec2 pos) {
	pos = clamp(pos, vec2(0.0), vec2(1.0));//1.0 - (1.0 / openfl_TextureSize.xy));
	return flixel_texture2D(bitmap, pos);
}

void main() {
	vec2 camPos = openfl_TextureCoordv;

	vec4 color = getColor(camPos);
	float fsteps = float(steps);
	for(float inside = 1.0; inside < float(stepsInside)+1.0; inside++) {
		for(int i = 0; i < steps; i++) {
			float fi = float(i);
			color += getColor(camPos + vec2(
				strength * (inside / float(stepsInside)) * cos(fi / fsteps * (PI * 2.0)),
				strength * (inside / float(stepsInside)) * sin(fi / fsteps * (PI * 2.0))
			));
		}
	}

	color /= vec4(steps * stepsInside);
	gl_FragColor = color;
}
