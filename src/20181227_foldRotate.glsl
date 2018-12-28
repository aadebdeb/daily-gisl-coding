/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define PI 3.14159265359
#define INV_PI 0.31830988618
#define TAU 6.28318530718

mat2 rotate(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

/*
vec2 foldRotate(vec2 p, float s) {
    float a = PI / s - atan(p.x, p.y);
    float n = TAU / s;
    a = floor(a / n) * n;
    p *= rotate(a);
    return p;
}
*/

vec2 foldRotate(vec2 p, int n) {
    float nf = float(n);
    vec2 q = -p;
    float ang = atan(q.y, q.x) + PI;
    float step = TAU / nf;
    float idx = floor(ang / step);
    p *= rotate(idx * step);
    return p;
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    int n = 5;

    st = foldRotate(st, n);
    gl_FragColor = vec4(st, 0.0, 1.0);
}