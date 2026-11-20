#pragma header
void main() {
    vec4 bleh = texture2D(bitmap, openfl_TextureCoordv);
    float dude = dot(bleh.rgb / vec3(bleh.a), vec3(0.20, 0.72, 0.07));
    float factor = smoothstep(0.1, 0.5, pow(1.0 - dude, 32.0));
    bleh = vec4(vec3(0.3 + factor * 0.7) * bleh.a, (bleh.a - (factor * 0.4)));
    bleh.a = pow(bleh.a, 3.0) * 0.5;
    gl_FragColor = bleh * openfl_ColorMultiplierv * openfl_Alphav;
}