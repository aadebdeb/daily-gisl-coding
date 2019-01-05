precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

float random(vec2 p){
    return fract(sin(dot(p,vec2(12.9898, 78.233))) * 43758.5453);
}

float valuenoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * f * (10.0 + f * (6.0 * f - 15.0));
    //vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(random(i), random(i + vec2(1.0, 0.0)), u.x),
        mix(random(i + vec2(0.0, 1.0)), random(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}


float fbm(vec2 p) {
    float res = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        res += amp * valuenoise(p);
        amp * 0.5;
        p *= rotate(0.03);
        p += vec2(34.43, 19.65);
        p *= 1.98;
    }
    return res;
}

float map(vec3 p) {
    p = mod(p, 4.0) - 2.0;
    return length(p) - 1.0;
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

float heightmap(vec2 uv) {
    return fbm(uv);
}

vec3 bumpmap(vec2 uv) {
    float d = 0.01;
    return normalize(vec3(
        heightmap(uv + vec2(d, 0.0)) - heightmap(uv - vec2(d, 0.0)),
        2.0 * d,
        heightmap(uv + vec2(0.0, d)) - heightmap(uv - vec2(0.0, d))
    ));
}

vec3 ground(vec3 ro, vec3 rd, float h) {
    if (rd.y >= 0.0 || ro.y <= h) {
        return vec3(0.0);
    }
    float d = (h - ro.y) / rd.y;
    vec2 xz = ro.xz + d * rd.xz;

    vec3 c = sin(xz.x) * sin(xz.y) > 0.0 ? vec3(1.0, 0.4, 0.8) : vec3(0.25, 0.4, 0.8);
    vec3 n = mix(vec3(0.0, 1.0, 0.0), bumpmap(xz * 1.5), 0.2);
    return c * max(0.0, dot(normalize(vec3(1.0)), n));
}

vec3 raymarch(vec3 ro, vec3 rd) {
    return ground(ro, rd, -5.0);
    vec3 p = ro;
    for (int i = 0; i < 64; i++) {
        float d = map(p);
        p += d * rd;
        if (d < 0.01) {
            vec3 n = calcNormal(p);
            return n * 0.5 + 0.5;
        }
    }
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec2 m = (2.0 * mouse - 1.0) * 10.0;

    vec3 ro = vec3(m.x, m.y, -5.0);
    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 2.0);

    vec3 c = raymarch(ro, rd);

    gl_FragColor = vec4(c, 1.0);
}