/*
 * Menger Sponge Repetition
 *
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 * 2018/12/18
 */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define PI 3.151519

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

float sdBox(vec3 p, vec3 b) {
    p = abs(p) - b;
    return length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0);
}

float mengerSponge(vec3 p) {
    float d = sdBox(p, vec3(1.0));

    float s = 1.0;
    for (int m = 0; m < 3; m++) {
        p.xy *= rotate(0.1 * time * float(m + 1));
        p.yz *= rotate(0.1 * time * 1.33 * float(m));
        p.zx *= rotate(0.1 * time * 2.15 * float(m));

        vec3 a = mod(p * s, 2.0) - 1.0;
        s *= 3.0;
        vec3 r = abs(1.0 - 3.0 * abs(a));

        float da = max(r.x, r.y);
        float db = max(r.y, r.z);
        float dc = max(r.z, r.x);
        float c = (min(da, min(db, dc)) - 1.0) / s;
        
        d = max(d, c);
    }

    return d;
}

float map(vec3 p) {
    float rep = 4.0;
    p.xy += 0.5 * rep;
    p = mod(p, rep) - 0.5 * rep;
    p *= 1.0;
    return mengerSponge(p);
}

vec3 normal(vec3 p, float d) {
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}


vec3 lightDir = normalize(vec3(1.0, 2.0, 1.5));
vec3 lightColor = vec3(0.9, 0.9, 0.95) * 3.0;
vec3 diffuseColor = vec3(0.15, 0.25, 0.4);
vec3 specularColor = vec3(0.5, 0.5, 0.5);
vec3 edgeColor = vec3(1.0, 0.4, 0.4);
float metallic = 0.5;

vec3 raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;
    float sumD = 0.0;
    float minD = 10000.0;
    for (int i = 0; i < 128; i++) {
        float d = map(p);
        p += d * rd;
        sumD += d;
        minD = min(d, minD);
        if (d < 0.01) {
            vec3 n = normal(p, 0.01);
            float edgeIntensity = smoothstep(0.0, 0.01, length(n - normal(p, 0.0101)));
            vec3 edge = edgeColor * edgeIntensity;
            vec3 dif = diffuseColor * lightColor * max(0.0, dot(n, lightDir)) / PI;
            vec3 ref = reflect(rd, n);
            float dotRL = dot(ref, lightDir);
            float smoothness = 8.0;
            vec3 spec = specularColor * lightColor * pow(max(0.0, dotRL), smoothness) * (smoothness + 2.0) / (2.0 * PI);
            vec3 c = (1.0 - metallic) * dif + metallic * spec + edge;
            float fog = exp(-sumD * 0.05);
            return c * fog;
        }
    }
    return vec3(0.0);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(0.0, 0.0, 5.0 - time * 2.0);
    vec3 ta = vec3(0.0, 0.0, 0.0 - time * 2.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(st.x * x + st.y * y + z);

    vec3 c = raymarch(ro, rd);

    gl_FragColor = vec4(c, 1.0);
}