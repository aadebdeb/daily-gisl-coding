precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define INV_PI 0.31830988618

float linearstep(float edge0, float edge1, float x) {
    return min(1.0, max(0.0, (x - edge0) / (edge1 - edge0)));
}

float box(vec3 p, vec3 r) {
    p = abs(p) - r;
    return length(max(p, 0.0)) + min(0.0, max(p.x, max(p.y, p.z)));
}

float sphere(vec3 p, float r) {
    return length(p) - r;
}

float torus(vec3 p, vec2 r) {
    vec2 q = vec2(length(p.xz) - r.x, p.y);
    return length(q) - r.y;
}

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

float map(vec3 p) {
    p.x += sin(p.y * 3.0 + time) * 0.2;
    p.y += sin(p.x * 2.0 + time) * 0.5;
    p.z += sin(p.z * 2.5 + time) * 0.2;
    p.xz *= rotate(time * 0.5);
    p.xy *= rotate(time * 0.3);
    return box(p, vec3(2.0 + 1.0 * sin(time * 0.7), 1.0 + 0.5 * sin(time * 0.45), 0.5 + 0.2 * sin(time * 0.25)));
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

bool raymarch(vec3 ro, vec3 rd, out float t) {
    vec3 p = ro;
    t = 0.0;
    for (int i = 0; i < 64; i++) {
        float d = map(p);
        t = t + d;
        p =  ro + t * rd;
        if (d < 0.01) {
            return true;
        }
    }
    return false;
}

vec3 backLightDir = normalize(vec3(0.0, 0.0, 1.0));
vec3 backLightColor = vec3(1.0) * 3.0;
vec3 frontLightDir = normalize(vec3(0.5, 0.5, -0.7));
vec3 frontLightColor = vec3(0.8, 0.8, 0.4) * 1.5;
vec3 substanceColor = vec3(0.15, 0.4, 0.2);

vec3 color(vec3 ro, vec3 rd) {
    float t;
    if (raymarch(ro, rd, t)) {
        vec3 p = ro + t * rd;
        float lt;
        vec3 lro = p + backLightDir * 1000.0;
        raymarch(lro, -backLightDir, lt);
        vec3 lp = lro - backLightDir * lt;
        float thick = length(p - lp);
        float trans = 1.0 - linearstep(0.0, 5.0, thick);
        vec3 n = calcNormal(p);
        vec3 dif = frontLightColor * max(0.0, dot(n, frontLightDir)) * INV_PI;
        vec3 ss = trans * backLightColor * max(0.0, dot(n, -backLightDir));
        return substanceColor * (ss + dif);
    }
    return vec3(0.0);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(0.0, 0.0, -5.0);
    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = color(ro, rd);

    gl_FragColor = vec4(c, 1.0);
}