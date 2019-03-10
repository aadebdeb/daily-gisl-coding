/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define PI 3.14159265359
#define MAX_DISTANCE 1000.0

float random(float x){
    return fract(sin(x * 12.9898) * 43758.5453);
}

float random(vec2 x){
    return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

float random(vec3 x){
    return fract(sin(dot(x,vec3(12.9898, 78.233, 39.425))) * 43758.5453);
}

float valuenoise(float x) {
    float i = floor(x);
    float f = fract(x);

    float u = f * f * (3.0 - 2.0 * f);

    return mix(random(i), random(i + 1.0), u);
}

float fbm(float x) {
    float sum = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        sum += valuenoise(x);
        amp *= 0.5;
        x *= 2.1;
    }
    return sum;
}

float sdTriangle(vec2 p) {
    float k = sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0 / k;
    if (p.x + k * p.y > 0.0) {
        p = vec2(p.x - k * p.y, -k * p.x - p.y) / 2.0;
    }
    p.x -= clamp(p.x, -2.0, 0.0);
    return -length(p) * sign(p.y);
}

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
    return mat2(c, s, -s, c);
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

float sdHuman(vec3 p) {
    p.y += (fbm(time * 0.03) * 2.0 - 1.0) * 0.2;
    p.yz *= rotate(PI / 2.0);
    p.xy *= rotate(-PI / 2.0);
    p.y += 1.0;
    float dLegs = sdLegs(p);
    float dArms = sdArms(p);
    float dHead = sdHead(p);
    float dBody = opUnion(dLegs, dArms, 0.15);
    return opUnion(dBody, dHead, 0.2);
}

float map(vec3 p) {
    return sdHuman(p);
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

float distTriangles(vec3 p) {
    p += vec3(2423.12, 0.0, 1230.219);
    p.y -= 10.0 * time;
    float spacing = 2.0;
    vec3 q = mod(p, spacing) - 0.5 * spacing;
    vec3 idx = floor(abs(p) / spacing);
    if (random(idx) < 0.8) {
        return 0.5 * spacing;
    }
    float r1 = random(idx + vec3(29.43, 19.27, 13.43));
    float r2 = random(idx + vec3(23.19, 11.43, 17.21));
    q.xy *= rotate(r1 + time);
    q.yz *= rotate(r2 + time);
    float d1 = abs(sdTriangle(q.xy * 4.0) / 4.0);
    float d2 = abs(q.z);
    return max(d1, d2);
}

vec3 triangleColor(vec3 p) {
    float t = mod(0.1 * time - 0.01 * p.y, 4.0);
    int idx = int(t);
    float f = smoothstep(0.9, 1.0, fract(t));
    vec3 c0 = vec3(1.2, 0.5, 0.8);
    vec3 c1 = vec3(1.2, 1.2, 0.5);
    vec3 c2 = vec3(1.2, 0.8, 0.5);
    vec3 c3 = vec3(0.5, 0.8, 1.2);
    if (idx == 0) {
        return mix(c0, c1, f);
    } else if (idx == 1) {
        return mix(c1, c2, f);
    } else if (idx == 2) {
        return mix(c2, c3, f);
    } else if (idx == 3)  {
        return mix(c3, c0, f);
    }

}

vec3 raymarchTriangles(vec3 ro, vec3 rd, float maxT) {
    vec3 c = vec3(0.0);
    vec3 p = ro;
    float t = 0.0;
    for (int i = 0; i < 32; i++) {
        float d = distTriangles(p);
        p += d * rd;
        t += d;
        vec3 pc = mix(vec3(1.0, 0.5, 0.5), vec3(1.0, 1.0, 0.5), smoothstep(0.9, 1.1, mod(time * 0.5 - p.y * 0.01, 2.0)));
        c += 0.0015 / max(d, 0.0001) * triangleColor(p);
        if (t > maxT) {
            break;
        }
    }
    return c; 
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

bool raymarch(vec3 ro, vec3 rd, out vec3 c, out float t) {
    t = 0.0;
    vec3 p = ro;
    for (int i = 0; i < 64; i++) {
        float d = 0.3 * map(p);
        p += d * rd;
        t += d;
        if (d < 0.005) {
            vec3 n = calcNormal(p);
            float ao = ambientOcculusion(p, n);
            c = vec3(pow(ao, 5.0) * 0.8);
            return true;
        }
        if (t >= MAX_DISTANCE) {
            break;
        }
    }
    t = MAX_DISTANCE;
    return false;
}

vec3 background(vec2 st) {
    vec3 sum = vec3(0.0);
    st += vec2(125.43, 191.09);
    st *= 80.0;
    for (int i = 0; i < 5; i++) {
        vec2 uv = mod(st, 2.0) - 1.0;
        vec2 idx = floor(st / 2.0);
        float r = random(idx);
        if (r < 0.001) {
            sum += smoothstep(0.55, 0.45, length(uv)) * vec3(0.8, 1.0, 1.5);
        }
        st *= 2.01;
    }
    return sum;
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(-2.0, -3.0, -2.0);
    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = vec3(0.0);
    float t;
    c += background(st);
    vec3 human;
    if(raymarch(ro, rd, human, t)) {
        c = human;
    }
    c += raymarchTriangles(ro, rd, t);

    gl_FragColor = vec4(c, 1.0);
}