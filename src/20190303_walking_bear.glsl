/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define PI 3.14159265359

float MAT_BODY = 1.0;
float MAT_ACCENT = 2.0;
float MAT_EYE = 3.0;

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdCapsule(vec3 p, float h, float r) {
    p.y -= clamp(p.y, 0.0, h);
    return length(p) - r;
}

float sdCylinderZ(vec3 p, float h, float r) {
    vec2 d = abs(vec2(length(p.xy), p.z)) - vec2(r, h);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdRoundedCylinderZ(vec3 p, float h, float ra, float rb) {
    vec2 d = vec2(length(p.xy) - 2.0 * ra + rb, abs(p.z) - h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - rb;
}

float sdRoundedConeY(vec3 p, float h, float r1, float r2) {
    vec2 q = vec2(length(p.xz), p.y);
    float b = (r1 - r2) / h;
    float a = sqrt(1.0 - b * b);
    float k = dot(q, vec2(-b, a));
    if (k < 0.0) return length(q) - r1;
    if (k > a * h) return length(q - vec2(0.0, h)) - r2;
    return dot(q, vec2(a, b)) - r1;
}

float sdRoundedConeX(vec3 p, float h, float r1, float r2) {
    vec2 q = vec2(length(p.yz), p.x);
    float b = (r1 - r2) / h;
    float a = sqrt(1.0 - b * b);
    float k = dot(q, vec2(-b, a));
    if (k < 0.0) return length(q) - r1;
    if (k > a * h) return length(q - vec2(0.0, h)) - r2;
    return dot(q, vec2(a, b)) - r1;
}


float opUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

vec2 sdEyes(vec3 p) {
    float r = 0.06;
    p.x = abs(p.x) - 0.4;
    p.y -= 0.3;
    p.z += 0.85;
    return vec2(sdSphere(p, r), MAT_EYE);
}

vec2 sdEars(vec3 p) {
    p.x = abs(p.x) - 0.6;
    p.y -= 0.8;
    float mat = length(p.xy) < 0.13 && p.z < 0.0 ? MAT_ACCENT : MAT_BODY; 
    return vec2(sdRoundedCylinderZ(p, 0.05, 0.15, 0.05), mat);
}

vec2 sdNose(vec3 p) {
    p.y += 0.1;
    p.z += 0.7;
    return vec2(sdSphere(p, 0.4), MAT_ACCENT);
}

vec2 sdHead(vec3 p) {
    float r = 1.0;
    p.y -= 2.6 + 0.5 * r;
    vec2 dHead = vec2(sdSphere(p, r), MAT_BODY);
    vec2 res = dHead;
    vec2 dNose = sdNose(p);
    if (dNose.x < res.x) res = dNose;
    vec2 dEyes = sdEyes(p);
    if (dEyes.x < res.x) res = dEyes;
    vec2 dEars = sdEars(p);
    if (dEars.x < res.x) res = dEars;
    return res;
}

vec2 sdBody(vec3 p) {
    float h = 1.0;
    p.y -= 0.5 * h + 0.8;
    return vec2(sdRoundedConeY(p, h, 0.8, 0.5), MAT_BODY);
}

vec2 sdLegs(vec3 p) {
    float h = 1.0;
    p.y -= h;
    p.yz *= rotate(sign(p.x) * sin(time * 7.0) * PI * 0.15);
    p.y += h;
    p.x = abs(p.x) - 0.3;
    return vec2(sdRoundedConeY(p, h, 0.25, 0.15), MAT_BODY);
}

vec2 sdArms(vec3 p) {
    p.y -= 1.8;
    float h = 0.3;
    p.x += h;
    p.xz *= rotate(sin(time * 7.0) * PI * 0.15);
    p.x -= h;
    p.x = abs(p.x) - 0.3;
    return vec2(sdRoundedConeX(p, 0.7, 0.2, 0.1), MAT_BODY);
}

vec2 map(vec3 p) {
    vec2 dHead = sdHead(p);
    vec2 res = dHead;
    vec2 dBody = sdBody(p);
    if (dBody.x < res.x) res = dBody;
    vec2 dLegs = sdLegs(p);
    if (dLegs.x < res.x) res = dLegs;
    vec2 dArms = sdArms(p);
    if (dArms.x < res.x) res = dArms;
    float d = opUnion(opUnion(opUnion(dHead.x, dBody.x, 0.2), dLegs.x, 0.2), dArms.x, 0.2);
    return vec2(d, res.y);
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)).x - map(p - vec3(d, 0.0, 0.0)).x,
        map(p + vec3(0.0, d, 0.0)).x - map(p - vec3(0.0, d, 0.0)).x,
        map(p + vec3(0.0, 0.0, d)).x - map(p - vec3(0.0, 0.0, d)).x
    ));
}

vec3 material(float mat) {
    if (mat == MAT_BODY) {
        return vec3(0.5, 0.3, 0.2);
    } else if (mat == MAT_ACCENT) {
        return vec3(0.8, 0.6, 0.4);
    } else if (mat == MAT_EYE) {
        return vec3(0.0);
    } else {
        return vec3(0.0);
    }
}

vec3 LightDir = normalize(vec3(-0.5, 1.0, -1.0));

float expFog(float d, float density) {
    return exp(-d * density);
}

float softshadow(vec3 ro, vec3 rd, float k) {
    vec3 p = ro;
    float res = 1.0;
    float d = 0.0;
    for (int i = 0; i < 32; i++) {
        float t = map(p).x;
        if (t < 0.0) return 0.0;
        res = min(res, k * t / d);
        d += t;
        p += t * rd;
    }
    return res;
}

vec3 background(vec3 ro, vec3 rd, float h) {
    vec3 fog = vec3(0.8);
    if (rd.y >= 0.0) {
        return fog;
    }
    float d = (h - ro.y) / rd.y;
    vec3 p = ro + d * rd;
    float shadow = softshadow(p, LightDir, 16.0);

    vec3 c = vec3(0.2, 0.7, 0.3) * (0.5 + 0.5 * shadow);

    return mix(fog, c, expFog(d, 0.05));
}

vec3 raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;
    for (int i = 0; i < 128; i++) {
        vec2 res = map(p);
        float d = 0.5 * res.x;
        p += d * rd;
        if (d < 0.01) {
            vec3 n = calcNormal(p);
            vec3 c = material(res.y);
            return c * max(smoothstep(-1.0, 1.0, dot(n, LightDir)), 0.5);
            return n * 0.5 + 0.5;
        }
    }
    return background(ro, rd, 0.0);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(3.0, 4.0, -5.0);
    vec3 ta = vec3(0.0, 2.0, 0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = raymarch(ro, rd);

    gl_FragColor = vec4(c, 1.0);
}