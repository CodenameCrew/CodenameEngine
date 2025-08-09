#pragma header

// Used in difficulty screen

uniform vec4 clipRect;

bool boxCollision(vec2 pixel, vec4 rect) {
	return (pixel.x >= rect.x) && (pixel.x < rect.x + rect.z) && (pixel.y >= rect.y) && (pixel.y < rect.y + rect.w);
}

void main()
{
	vec2 pixel = gl_FragCoord.xy;

	if (boxCollision(pixel, clipRect)) gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv.xy);
	else gl_FragColor = vec4(0.0);
}