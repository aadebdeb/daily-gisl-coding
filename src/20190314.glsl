/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float displacement(vec3 p) {
    return sin(2.0 * sin(time * 0.95) * p.x) * sin(2.0 * sin(time * 1.2) * p.y) * sin(2.0 * sin(time * 1.35) * p.z);
}

float map(vec3 p) {
    p += 1.0;
    return sdSphere(p, 3.0) + 0.5 * displacement(p);
}


vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

float ambientOcculusion(vec3 o, vec3 n) {
    float step = 0.05;
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

bool raymarch(vec3 ro, vec3 rd, out vec3 color) {
    vec3 p = ro;
    for (int i = 0; i < 64; i++) {
        float d = 0.5 * map(p);
        p += d * rd;
        if (d < 0.01) {
            vec3 n = calcNormal(p);
            float dotNL = dot(n, vec3(0.0, 1.0, 0.0));
            float ao = ambientOcculusion(p, n);
            mat3 colMat = mat3(
                0.6, 0.2, 0.3,
                0.1, 0.8, 1.0,
                1.0, 0.4, 0.1
            );
            color = 0.8 * colMat * (0.5 * n + 0.5) * (0.5 + 0.5 * pow(ao, 0.8)) * smoothstep(-1.5, 1.0, dotNL);
            return true;
        }
    }
    return false;
}

float softshadow(vec3 ro, vec3 rd, float k) {
    vec3 p = ro;
    float res = 1.0;
    float d = 0.0;
    for (int i = 0; i < 32; i++) {
        float t = map(p);
        if (t < 0.0) return 0.0;
        res = min(res, k * t / d);
        d += t;
        p += t * rd;
    }
    return res;
}

vec4 planeX(vec3 ro, vec3 rd, float h) {
    float t = (h - ro.x) / rd.x;
    return vec4(ro + t * rd, t);
}

vec4 planeY(vec3 ro, vec3 rd, float h) {
    float t = (h - ro.y) / rd.y;
    return vec4(ro + t * rd, t);
}

vec4 planeZ(vec3 ro, vec3 rd, float h) {
    float t = (h - ro.z) / rd.z;
    return vec4(ro + t * rd, t);
}

vec3 room(vec3 ro, vec3 rd) {
    vec3 size = vec3(20.0, 5.0, 20.0);
    vec3 baseColor = vec3(0.8);
    vec3 c = baseColor;
    float t = 1e6;
    vec4 bottom  = planeY(ro, rd, -size.y);
    if (bottom.w > 0.0) {
        t = bottom.w;
    }
    vec4 top = planeY(ro, rd, size.y);
    if (top.w > 0.0 && top.w < t) {
        t = top.w;
    }
    vec4 far = planeZ(ro, rd, size.z);
    if (far.w > 0.0 && far.w < t) {
        t = far.w;
    }
    vec4 near = planeZ(ro, rd, -size.z);
    if (near.w > 0.0 && near.w < t) {
        t = near.w;
    }
    vec4 left = planeX(ro, rd, size.x);
    if (left.w > 0.0 && left.w < t) {
        t = left.w;
    }
    vec4 right = planeX(ro, rd, -size.x);
    if (right.w > 0.0 && right.w < t) {
        t = right.w;
    }
    vec3 p = ro + t * rd;

    if (abs(p.y - size.y) < 0.001) { // lights
        if (abs(abs(p.x) - 8.0) < 3.0 && abs(abs(p.z) - 8.0) < 1.0) {
            c = vec3(1.0);
        }
    }

    if (abs(p.y + size.y) < 0.001) {
        c *= 0.90 + 0.1 * softshadow(p, vec3(0.0, 1.0, 0.0), 3.0);
    }

    vec3 diff = abs(abs(p) - size);
    c *= 0.8 + 0.2 * min(pow(0.5 * (diff.x + diff.y), 0.5), 1.0);
    c *= 0.8 + 0.2 * min(pow(0.5 * (diff.y + diff.z), 0.5), 1.0);
    c *= 0.8 + 0.2 * min(pow(0.5 * (diff.z + diff.x), 0.5), 1.0);

    return c;
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    float rad = time * 0.2;
    vec3 ro = vec3(15.0 * sin(rad), 0.5, 15.0 * cos(rad));
    vec3 ta = vec3(0.0, -1.0, 0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c;
    if (raymarch(ro, rd, c)) {

    } else {
        c = room(ro, rd);
    }

    gl_FragColor = vec4(c, 1.0);
}