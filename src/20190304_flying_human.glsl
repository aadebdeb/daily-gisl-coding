/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define PI 3.14159265359

float sdCapsule(vec3 p, float h, float r) {
    p.y -= clamp(p.y, 0.0, h);
    return length(p) - r;
}

float opUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s ,c);
}

float sdLeg1(vec3 p) {
    vec3 q = p;
    q.x = q.x + 0.1;
    q.xy *= rotate(max(0.0, p.y - 1.0) * 0.05);
    q.zy *= rotate(-max(0.0, p.y - 1.0) * 0.1);
    return sdCapsule(q, 3.0, 0.1);
}

float sdLeg2(vec3 p) {
    vec3 q = p;
    q.x = q.x - 0.1;
    q.xy *= rotate(-max(0.0, p.y - 1.0) * 0.05);
    q.zy *= rotate(-max(0.0, p.y - 1.0) * 0.1);
    return sdCapsule(q, 3.0, 0.1);
}

float sdLegs(vec3 p) {
    return opUnion(sdLeg1(p), sdLeg2(p), 0.25);
}

float sdArms(vec3 p) {
    p.xy *= rotate(PI / 2.0);
    vec3 q = p;
    q.y = abs(q.y);
    q.xy *= rotate(-max(0.0, q.y) * 1.5);
    q.zy *= rotate(-max(0.0, q.y) * 0.1);
    return sdCapsule(q, 1.5, 0.05);
}

float sdHead(vec3 p) {
    vec3 q = p;
    q.y += 0.4;
    q.yz *= rotate(-PI / 4.0);
    return sdCapsule(q, 0.1, 0.1);
}

float map(vec3 p) {
    p.x += sin(time * 1.12) * 0.4;
    p.y += sin(time * 0.68) * 0.8;
    p.z += sin(time * 1.21) * 0.32;
    p.xy *= rotate(sin(time * 0.34) * 0.3);
    p.yz *= rotate(-PI / 2.0);
    float dLegs = sdLegs(p);
    float dArms = sdArms(p);
    float dHead = sdHead(p);
    float dBody = opUnion(dLegs, dArms, 0.15);
    return opUnion(dBody, dHead, 0.2);
}

vec3 calcNormal(vec3 p) {
    float d = 0.05;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

vec3 LightDir = normalize(vec3(1.0, 1.0, -1.0));

vec2 hitCylinderZ(vec3 ro, vec3 rd, float r) {
    float a = rd.x * rd.x + rd.y * rd.y;
    float b = 2.0 * (rd.x * ro.x + rd.y * ro.y);
    float c = ro.x * ro.x + ro.y * ro.y - r * r;
    float d = sqrt(b * b - 4.0 * a * c);
    float t1 = (-b - d) / (2.0 * a);
    float t2 = (-b + d) / (2.0 * a);
    return vec2(t1, t2);
}

vec3 background(vec3 ro, vec3 rd) {
    vec2 res = hitCylinderZ(ro, rd, 3.0);
    float t = res.x > 0.0 && res.x < res.y ? res.x : res.y;
    vec3 pos = ro + t * rd;
    pos.xy *= rotate(pos.z);

    int idx = int(mod(abs(pos.z + time * 8.0), 5.0));
    vec3 c;
    if (idx == 0) {
        c = vec3(0.6, 0.5, 0.6);
    } else if (idx == 1) {
        c = vec3(0.5, 0.6, 0.6);
    } else if (idx == 2) {
        c = vec3(0.6, 0.6, 0.5);
    } else if (idx == 3) {
        c = vec3(0.5, 0.65, 0.5);
    } else if (idx == 4) {
        c = vec3(0.5, 0.5, 0.5);
    }
    return mix(c, vec3(0.5), 1.0 - exp(-max(0.0, pos.z) * 0.05));
}

float ambientOcculusion(vec3 o, vec3 n) {
    float step = 0.1;
    float sum = 0.0;
    float scale = 0.5;
    for (float i = 1.0; i <= 5.0; i += 1.0) {
        float d = step * i;
        vec3 p = o + d * n;
        sum += scale * (d - map(p));
        scale *= 0.5;
    }
    return 1.0 - sum;
}

vec3 raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;
    for (int i = 0; i < 64; i++) {
        float d = map(p) * 0.5;
        p += d * rd;
        if (d < 0.01) {
            vec3 n = calcNormal(p);
            float ao = ambientOcculusion(p, n);
            return vec3(ao) * 0.8;
        }
    }
    return background(ro, rd);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(-1.5, 2.0, -4.0);
    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = raymarch(ro, rd);

    c = pow(c, vec3(1.8));

    gl_FragColor = vec4(c, 1.0);
}