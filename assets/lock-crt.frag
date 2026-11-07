#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float seconds;
    float aspect;
    float pixelHeight;
    float heroX;
    float heroY;
    float heroScale;
};
layout(binding = 1) uniform sampler2D source;
const vec3 lime = vec3(0.749, 0.839, 0.188);
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float glyph(vec2 p) {
    vec2 uv = p / vec2(0.61, 0.52) + 0.5;
    if (any(lessThan(uv, vec2(0))) || any(greaterThan(uv, vec2(1)))) return 0.;
    vec4 c = texture(source, uv);
    return (1. - dot(c.rgb, vec3(.299,.587,.114))) * c.a;
}
float logo(vec2 p) {
    p.x /= 0.88 + 0.12 * cos(seconds * .35);
    p += vec2(sin(seconds*.23)*.055, cos(seconds*.31)*.025);
    float angle = .055*sin(seconds*.27);
    p = mat2(cos(angle),-sin(angle),sin(angle),cos(angle))*p;
    float band = exp(-pow((p.y - (fract(seconds*.13)*.7-.35)) / .018, 2.));
    p.x += band * sin(seconds * 11.) * .004;
    float core = glyph(p);
    float halo = glyph(p + vec2(.0025,0)) + glyph(p - vec2(.0025,0))
               + glyph(p + vec2(0,.0025)) + glyph(p - vec2(0,.0025));
    float glow = glyph(p + vec2(.007,.007)) + glyph(p - vec2(.007,.007));
    return core * .84 + halo * .13 + glow * .065;
}
void main() {
    vec2 uv = qt_TexCoord0;
    vec2 bend = uv * 2. - 1.;
    uv += bend * dot(bend,bend) * .009;
    vec2 p = (uv - .5) * vec2(aspect, 1.);
    vec3 color = vec3(.017,.026,.014);
    // Slowly drifting phosphor stars, sampled on a fixed cell lattice.
    vec2 starUV = vec2(p.x*24., (p.y+seconds*.006)*24.);
    vec2 cell = floor(starUV);
    vec2 center = vec2(hash(cell),hash(cell+17.));
    float star = exp(-length(fract(starUV)-center)*100.);
    color += lime * star * (.25+.15*sin(seconds+hash(cell)*16.));
    // Animated perspective floor: receding transverse lines and radial rays.
    float horizon = .665;
    if (uv.y > horizon) {
        float d = uv.y - horizon;
        float depth = .12 / (d + .025);
        float gx = p.x / (d + .05) * 2.2;
        float gy = depth + seconds*.65;
        float lineX = 1.-smoothstep(.015,.045,abs(fract(gx+.5)-.5));
        float lineY = 1.-smoothstep(.02,.065,abs(fract(gy+.5)-.5));
        color += lime * max(lineX,lineY) * .22 * smoothstep(0.,.12,d);
        vec2 reflected = vec2(p.x, -(uv.y-horizon)*1.6 + horizon-.5);
        color += lime * logo((reflected - vec2(heroX,heroY)) / heroScale) * .19 * exp(-d*8.);
    }
    color += lime * exp(-abs(uv.y-horizon)*210.) * .19;
    // Hero logo breathes and drifts to keep the phosphor pattern moving.
    vec2 hero = (p - vec2(heroX,heroY)) / heroScale;
    color += lime * logo(hero) * (.88 + .09*sin(seconds*1.2));
    // Faint rolling beam, noise, scanlines, edge vignette and rounded glass.
    float beam = exp(-pow((fract(uv.y-seconds*.065)-.5)/.065,2.));
    color += lime * beam * .018;
    color *= .88 + .12*sin(uv.y*pixelHeight*3.14159265);
    color += (hash(uv*1000.+fract(seconds))-.5)*.018;
    color *= .99 + .01*sin(seconds*41.);
    color *= 1.-.52*pow(length((uv-.5)*1.25),2.);
    vec2 edge = abs(uv-.5)*2.;
    float glass = 1.-smoothstep(.98,1.01,max(edge.x,edge.y));
    fragColor = vec4(max(color,vec3(0))*glass, 1.) * qt_Opacity;
}
