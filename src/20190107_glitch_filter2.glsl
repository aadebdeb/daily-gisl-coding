precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float random(float x){
    return fract(sin(x * 12.9898) * 43758.5453);
}

float random(vec2 x){
    return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 random4(float x) {
    return fract(sin(x * vec4(12.9898, 51.431, 29.964, 86.432)) * vec4(43758.5453, 71932.1354, 39215.4221, 67915.8743));
}

float square(vec2 p, float s) {
    p = abs(p) - s;
    return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

float distG(vec2 p, float s) {
    s /= 5.0;
    float t = s * 0.5;
    float d = 10000.0;
    d = min(d, square(p - vec2(1.0 * s, 2.0 * s), t));
    d = min(d, square(p - vec2(0.0 * s, 2.0 * s), t));
    d = min(d, square(p - vec2(-1.0 * s, 2.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, 1.0 * s), t));
    d = min(d, square(p - vec2(-2.0 * s, 1.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, 0.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, -1.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, -1.0 * s), t));
    d = min(d, square(p - vec2(-1.0 * s, -1.0 * s), t));
    d = min(d, square(p - vec2(-2.0 * s, -1.0 * s), t));
    d = min(d, square(p - vec2(1.0 * s, -2.0 * s), t));
    d = min(d, square(p - vec2(0.0 * s, -2.0 * s), t));
    d = min(d, square(p - vec2(-1.0 * s, -2.0 * s), t));
    d = min(d, square(p - vec2(-2.0 * s, -2.0 * s), t));
    return d;
}

float distL(vec2 p, float s) {
    s /= 5.0;
    float t = s * 0.5;
    float d = 10000.0;
    d = min(d, square(p - vec2(2.0 * s, 2.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, 1.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, 0.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, -1.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, -2.0 * s), t));
    d = min(d, square(p - vec2(1.0 * s, -2.0 * s), t));
    d = min(d, square(p - vec2(0.0 * s, -2.0 * s), t));
    d = min(d, square(p - vec2(-1.0 * s, -2.0 * s), t));
    d = min(d, square(p - vec2(-2.0 * s, -2.0 * s), t));
    return d;
}

float distI(vec2 p, float s) {
    s /= 5.0;
    float t = s * 0.5;
    float d = 10000.0;
    d = min(d, square(p - vec2(0.0, 2.0 * s), t));
    d = min(d, square(p - vec2(0.0, 1.0 * s), t));
    d = min(d, square(p, t));
    d = min(d, square(p - vec2(0.0, -1.0 * s), t));
    d = min(d, square(p - vec2(0.0, -2.0 * s), t));
    return d;
}

float distT(vec2 p, float s) {
    s /= 5.0;
    float t = s * 0.5;
    float d = 10000.0;
    d = min(d, square(p - vec2(2.0 * s, 2.0 * s), t));
    d = min(d, square(p - vec2(1.0 * s, 2.0 * s), t));
    d = min(d, square(p - vec2(0.0 * s, 2.0 * s), t));
    d = min(d, square(p - vec2(-1.0 * s, 2.0 * s), t));
    d = min(d, square(p - vec2(-2.0 * s, 2.0 * s), t));
    d = min(d, square(p - vec2(0.0, 1.0 * s), t));
    d = min(d, square(p, t));
    d = min(d, square(p - vec2(0.0, -1.0 * s), t));
    d = min(d, square(p - vec2(0.0, -2.0 * s), t));
    return d;
}

float distC(vec2 p, float s) {
    s /= 5.0;
    float t = s * 0.5;
    float d = 10000.0;
    d = min(d, square(p - vec2(1.0 * s, 2.0 * s), t));
    d = min(d, square(p - vec2(0.0 * s, 2.0 * s), t));
    d = min(d, square(p - vec2(-1.0 * s, 2.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, 1.0 * s), t));
    d = min(d, square(p - vec2(-2.0 * s, 1.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, 0.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, -1.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, -1.0 * s), t));
    d = min(d, square(p - vec2(-2.0 * s, -1.0 * s), t));
    d = min(d, square(p - vec2(1.0 * s, -2.0 * s), t));
    d = min(d, square(p - vec2(0.0 * s, -2.0 * s), t));
    d = min(d, square(p - vec2(-1.0 * s, -2.0 * s), t));
    return d;
}

float distH(vec2 p, float s) {
    s /= 5.0;
    float t = s * 0.5;
    float d = 10000.0;
    d = min(d, square(p - vec2(2.0 * s, 2.0 * s), t));
    d = min(d, square(p - vec2(-2.0 * s, 2.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, 1.0 * s), t));
    d = min(d, square(p - vec2(-2.0 * s, 1.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, 0.0 * s), t));
    d = min(d, square(p - vec2(1.0 * s, 0.0 * s), t));
    d = min(d, square(p - vec2(0.0 * s, 0.0 * s), t));
    d = min(d, square(p - vec2(-1.0 * s, 0.0 * s), t));
    d = min(d, square(p - vec2(-2.0 * s, 0.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, -1.0 * s), t));
    d = min(d, square(p - vec2(-2.0 * s, -1.0 * s), t));
    d = min(d, square(p - vec2(2.0 * s, -2.0 * s), t));
    d = min(d, square(p - vec2(-2.0 * s, -2.0 * s), t));
    return d;
}


float distGlitch2D(vec2 p, float s) {
    float d = 10000.0;
    float gap = 1.5;
    d = min(d, distG(p - vec2(2.5 * gap * s, 0.0), s));
    d = min(d, distL(p - vec2(1.5 * gap * s, 0.0), s));
    d = min(d, distI(p - vec2(0.5 * gap * s, 0.0), s));
    d = min(d, distT(p - vec2(-0.5 * gap * s, 0.0), s));
    d = min(d, distC(p - vec2(-1.5 * gap * s, 0.0), s));
    d = min(d, distH(p - vec2(-2.5 * gap * s, 0.0), s));
    return d;
}

float distGlitch3D(vec3 p, float t, float s) {
    float d1 = distGlitch2D(p.xy, s);
    float d2 = abs(p.z) - t;
    return min(max(d1, d2), 0.0) + length(max(vec2(d1, d2), 0.0));
}

float sdBox(vec3 p, vec3 b) {
    p = abs(p) - b;
    return length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0);
}

float distBuildings(vec3 p, float s) {
    float w = s * 0.5 * 0.8;
    vec3 p1 = p;
    p1.xz = mod(p.xz, s * 2.0) - s;
    vec2 id1 = floor(p.xz / (s * 2.0));
    float h1 = random(id1 * 32.123 + 129.43) * 4.5 + 0.5;
    float d1 = sdBox(p1 - vec3(0.0, h1 * 0.5, 0.0), vec3(w, h1, w));
    vec3 p2 = p;
    p2.xz = mod(p.xz + s, s * 2.0) - s;
    vec2 id2 = floor((p.xz + s) / (s * 2.0));
    float h2 = random(id2 * 43.123 + 214.10) * 4.5 + 0.5;
    float d2 = sdBox(p2 - vec3(0.0, h2 * 0.5, 0.0), vec3(w, h2, w));

    return min(d1, d2);
}

vec4 map(vec3 p) {
    float dw = distGlitch3D(p - vec3(0.0, 15.0, 0.0), 3.0, 5.0);
    float db = distBuildings(p, 5.0);
    if (dw < db) {
        return vec4(vec3(0.1, 0.3, 0.6), dw);
    } else {
        return vec4(vec3(0.7, 0.9, 0.2), db);
    }
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)).w - map(p - vec3(d, 0.0, 0.0)).w,
        map(p + vec3(0.0, d, 0.0)).w - map(p - vec3(0.0, d, 0.0)).w,
        map(p + vec3(0.0, 0.0, d)).w - map(p - vec3(0.0, 0.0, d)).w
    ));
}

bool raymarch(vec3 ro, vec3 rd, out vec3 c) {
    vec3 p = ro;
    for (int i = 0; i < 96; i++) {
        vec4 m = map(p);
        float d = map(p).w;
        p += d * rd;
        if (d < 0.01) {
            vec3 n = calcNormal(p);
            vec3 dif = m.rgb * (max(0.0, dot(n, normalize(vec3(0.2, 0.5, -0.5)))) + 0.2);
            c = dif;
            return true;
        }
    }
    return false;
}


float noiseoffset(float y) {
    float sum = 0.0;
    float amp = 0.5;
    float o = 453.43;
    float s = 1.0;
    for (int i = 0; i < 5; i++) {
        sum += amp * sin(s * y + o);

        o += 123.342;
        s *= 2.14;
        amp *= 0.5;
    }
    return sum;
}

vec2 noisedCoord(vec2 st) {
    float intensity = (exp(2.0 * sin(time * 0.7)) / exp(2.0))* noiseoffset(st.y * 2.42 + time * 14.43 + 1354.614);

    st.x += noiseoffset(st.y - time) * intensity * 5.0;

    return st;
}

vec3 background(vec3 rd) {
    return mix(vec3(0.3), vec3(0.7), rd.y * 0.5 + 0.5);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    st = noisedCoord(st);

    vec3 ro = vec3(15.0 * sin(time * 0.5), 5.0 * cos(time * 1.2) + 20.0, -25.0 + 5.0 * sin(time * 0.7));
    vec3 ta = vec3(0.0, 13.0, 0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c;
    if(!raymarch(ro, rd, c)) {
        c = background(rd);
    }

    gl_FragColor = vec4(c, 1.0);
}