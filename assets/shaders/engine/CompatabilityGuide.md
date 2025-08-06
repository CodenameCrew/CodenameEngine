## Here are guides on common mistakes and advices for writing shaders for flixel and openfl.

It's important to follow this guide as most shader coders make these mistakes a lot and end up with shaders that only work on certain devices.

-------
### Common mistakes and how to avoid them
Avoid using `0.` or `.0` for floats, instead, use `0.0` (ending the float number with an `.0`)
(please note that despite half floats working on nVidia gpus, other gpus like AMD gpus don't support this feature)

Avoid using switch cases, and use if statements where possible.
(switch cases are not supported on macOS or miscellaneous platforms)

Ints are not recommended when initiating vectors. (ex, vec2(1, 1) is not supported on certain platforms).
And use floats where it's expected. Like mod(1.0, 2.0) instead of mod(1, 2)

Avoid using the following types:
- ivec2,3,4
- bvec2,3,4
- uvec2,3,4
- uint

as they are unsupported on certain platforms.

Avoid using `gl_` at the start of your variables (ex, `float gl_Number` can break your shaders).

Applying defaults to uniforms is not possible, so please set the defaults in your shader constructor or after initializing the shader.

Avoid using `<number>u` (ex, 8u)
Avoid initializing variables with the name `input` or `sample`, as those cause the shader to stop working on AMD gpus or other platforms.

Avoid using the % operator, instead use the mod function.

Avoid using arrays if possible.

### Guide to porting shaders from shadertoy.com
This is a sample shader that simply renders the texture of a sprite/camera.
```glsl
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Time varying pixel color
    vec4 col = texture(iChannel0, uv);

    // Output to screen
    fragColor = col;
}
```
We will show each step to converting this shader into an usable openfl/flixel shader

1. replace ``void mainImage( out vec4 fragColor, in vec2 fragCoord )`` with a simple ``void main()`` (flixel and openfl do not have any parameters since the coords are defined outside the function)
2. replace ``vec2 uv = fragCoord/iResolution.xy;`` with ``vec2 uv = openfl_TextureCoordv`` (or in some cases, add ``vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize.xy`` before it and replace `iResolution.xy` with ``openfl_TextureSize.xy`` (if the uv value is different than usual))
3. replace ``vec4 col = texture(iChannel0, uv);`` with ``vec4 col = texture2D(bitmap, uv);`` or ``vec4 col = flixel_texture2D(bitmap, uv);`` (keep in mind bitmap is the pixels of the camera/sprite the shader is applied to)
4. finally, replace ``fragColor = col;`` with ``gl_FragColor = col;``

###### Keep in mind that this covers the most basic on how to convert a shader from shadertoy.com, complex shaders will need more expertise with handling shaders before converting those.

-------

### Common Practice:

Use ``texture2D`` for camera shaders, and FlxGame shaders, and ``flixel_texture2D`` for sprite shaders.
``flixel_texture2D`` applies the .colorTransform, while ``texture2D`` doesn't.

-------

Extra:

Use tabs for indentation