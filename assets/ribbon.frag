#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 ink;
    float tiles;
    float phase;
    float contentFraction;
};
layout(binding = 1) uniform sampler2D source;
void main() {
    float x = fract(qt_TexCoord0.x * tiles + phase);
    vec4 pixel = texture(source, vec2(clamp(x / contentFraction, 0.0, 1.0), qt_TexCoord0.y));
    float coverage = (1.0 - dot(pixel.rgb, vec3(0.299, 0.587, 0.114))) * pixel.a;
    coverage *= 1.0 - step(contentFraction, x);
    float a = coverage * ink.a * qt_Opacity;
    fragColor = vec4(ink.rgb * a, a);
}
