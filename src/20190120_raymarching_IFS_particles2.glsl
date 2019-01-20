/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define PI 3.14159265359

float sphere(vec3 p, float r) {
    return length(p) - r;
}

float box(vec3 p, vec3 b) {
    p = abs(p) - b;
    return length(max(p, 0.0)) + min(0.0, max(p.x, max(p.y, p.z)));
}

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

float map(vec3 p) {
    float d = box(p, vec3(1.0));
    float s = 1.0;
    vec3 size = fract(vec3(0.85, 0.43, 0.64) + time);
    for (int i = 0; i < 6; i++) {
        p = abs(p);
        p *= 1.4;
        s *= 1.4;
        p -= 7.0;
        p.xy *= rotate(time * 0.84);
        p.yz *= rotate(time * 0.54);
        d = min(d, box(p, size) / s);
        size = 0.5 + 0.5 * fract(size * 2.12);
    }
    return d;
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

vec3 raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;
    for (int i = 0; i < 64; i++) {
        float d = map(p);
        p += d * rd;
        if (d < 0.01) {
            vec3 n = calcNormal(p);
            float edge = smoothstep(0.0, 0.01, length(n - calcNormal(p + 0.01)));
            return mix(vec3(0.1, 0.8, 0.7), vec3(1.0), edge);
        }
    }
    return vec3(0.9, 0.6, 0.7);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(
        10.0 * cos(time * 0.85),
        8.0 * sin(time * 0.55),
        10.0 * sin(time * 0.85)
    );
    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = raymarch(ro, rd);

    gl_FragColor = vec4(c, 1.0);
}