#pragma opengl
#define BASIC_LIGHTING_VERT
#include "foxlite/inc/templates/basic.glsl"

attribute vec4 glow;
varying vec4 glowv;

void main(void) {
	mainVert();
	glowv = glow;
}