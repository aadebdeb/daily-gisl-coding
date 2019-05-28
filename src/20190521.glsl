/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define PI 3.14159265359
#define TWO_PI 6.28318530718
#define HALF_PI 1.57079632679

#define CAMERA_POSITION vec3(0.0, time * 50.0, 0.0)

float random(float x){
    return fract(sin(x * 12.9898) * 43758.5453);
}

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdBox(vec2 p, vec2 b) {
    p = abs(p) - b;
    return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

float map(vec3 p) {
    vec3 q = mod(p, 20.0) - 10.0;
    float dx = sdBox(q.yz, vec2(0.5));
    float dy = sdBox(q.xz, vec2(0.5));
    float dz = sdBox(q.xy, vec2(0.5));
    float d = min(dx, min(dy, dz));
    for (float i = 1.0; i <= 5.0; i += 1.0) {
        vec3 sp = vec3(100.0 + 10.0 * sin(time + 10.0 * random(i * 43.32)), 0.0, 0.0);
        sp.xy *= rotate(time + 100.0 * random(i * 51.53));
        sp.xz *= rotate(time + 100.0 * random(i * 39.43));
        float ds = sdSphere(p - sp - CAMERA_POSITION, 50.0);
        d = max(-ds, d);
    }
    for (float i = 1.0; i <= 5.0; i += 1.0) {
        vec3 sp = vec3(100.0 + 10.0 * sin(time + 10.0 * random(i * 43.32)), 0.0, 0.0);
        sp.xy *= rotate(time + 100.0 * random(i * 51.53));
        sp.xz *= rotate(time + 100.0 * random(i * 39.43));
        float ds = sdSphere(p - sp - CAMERA_POSITION, 25.0);
        d = min(ds, d);
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

const vec3 LIGHT_DIR1 = normalize(vec3(0.5, 1.0, 0.7));
const vec3 LIGHT_DIR2 = normalize(vec3(-0.2, -1.0, -0.8));
const vec3 LIGHT_COLOR1 = vec3(1.0, 0.8, 0.2);
const vec3 LIGHT_COLOR2 = vec3(0.7, 0.95, 1.0);

vec3 raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;
    for (int i = 0; i < 64; i++) {
        float d = map(p);
        p += d * rd;
        if (d < 0.01) {
            vec3 n = calcNormal(p);
            return vec3(0.2)
                + LIGHT_COLOR1 * max(0.0, dot(n, LIGHT_DIR1))
                + LIGHT_COLOR2 * max(0.0, dot(n, LIGHT_DIR2));
        }
    }
    return vec3(1.0, 0.95, 0.98);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec2 uv = gl_FragCoord.xy / resolution;


    vec3 ro = CAMERA_POSITION;
    float theta = (1.0 - uv.y) * PI;
    float phi = (2.0 * uv.x - 1.0) * PI;
    vec3 rd = vec3(
        sin(theta) * sin(phi),
        cos(theta),
        sin(theta) * cos(phi)
    );

    rd.xz *= rotate(time * 0.45);
    rd.yz *= rotate(time * 0.34);

    vec3 c = raymarch(ro, rd);

    gl_FragColor = vec4(c, 1.0);
}