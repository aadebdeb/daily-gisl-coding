precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

const float PI = acos(-1.0);

#define smin(a, b, k) (-log2(exp2(-k*a)+exp2(-k*b))/k)
#define sabs(p, k) (abs(p)-2.0*smin(0.0,abs(p),k))

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(2.0 * PI *(t * c + d));
}

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

vec2 pmod(vec2 p, float n) {
    float r = 2.0 * PI / n;
    float a = atan(p.x, p.y) + 0.5 * r;
    return p * rotate(-floor(a / r) * r);
}

float mapObj(vec3 p) {
    float s = 1.0;
    for (float i = 1.0; i < 5.0; i += 1.0) {
        p = sabs(p, 8.0);
        p.xyz -= 1.0;
        p.xy *= rotate(0.45 * time);
        p.yz *= rotate(0.56 * time);
        p *= 1.5;
        s *= 1.5;
    }
    return (length(p) - 1.0) / s;
}

float mapBg(vec3 p) {
    p.y -= time;
    vec3 rep = vec3(10.0, 1.5, 10.0);
    p.y = mod(p.y, 2.0) - 1.0;
    p.xz = pmod(p.xz, 16.0);
    p.z -= 7.0;
    return length(p) - 0.2;
}

float map(vec3 p) {
    float od= mapObj(p);
    float bd = mapBg(p);
    float fd = 4.0 - abs(p.y);
    return min(od, smin(bd, fd, 8.0));
}

vec3 calcNormal(vec3 p) {
    float d = 0.001;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

vec3 raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;
    for (int i = 0; i < 128; i++) {
        float d = map(p);
        p += d * rd;
        if (d < 0.01) {
            vec3 n = calcNormal(p);
            vec3 ld = normalize(ro - p);
            float dotNL = clamp(dot(n, ld), 0.0, 1.0);
            vec3 refDir = reflect(rd, n);
            float dotRL = clamp(dot(refDir, ld), 0.0, 1.0);
            vec3 c = palette(dotNL, vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.5, 0.8));
            vec3 diff = c * dotNL;
            vec3 spec = vec3(1.0) * pow(dotRL, 32.0);

            return diff + spec;
            return n * 0.5 + 0.5;
        }
    }
    return vec3(0.0);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(
        10.0 * sin(0.5 * time),
        -3.5,
        5.0 + 5.0 * (sin(0.5 * time) * 0.5 + 0.5)
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