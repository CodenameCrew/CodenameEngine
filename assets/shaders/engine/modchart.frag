#pragma opengl
#define BASIC_LIGHTING_FRAG
#include "foxlite/inc/templates/basic.glsl"

varying vec4 glowv;

void main(void) {
	mainFrag();
	gl_FragData[0].rgb *= foxlite_Colorv.a;
	gl_FragData[0].rgb = mix(gl_FragData[0].rgb, glowv.rgb * gl_FragData[0].a, glowv.a);
}