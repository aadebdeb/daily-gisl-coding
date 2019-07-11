/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

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
        p.xy *= rotate(1.0);
    }
    return res;
}

vec4 qmul(vec4 a, vec4 b) {
    return vec4(
        a.x * b.x - a.y * b.y - a.z * b.z - a.w * b.w,
        a.x * b.y + a.y * b.x - a.z * b.w + a.w * b.z,
        a.x * b.z + a.y * b.w + a.z * b.x - a.w * b.y,
        a.x * b.w - a.y * b.z + a.z * b.y + a.w * b.x
    );
}

#define ITERATIONS 12
float deQuaternionJuliaSet(vec4 p, vec4 c) {
    vec4 z = p;
    vec4 dz = vec4(1.0, 0.0, 0.0, 0.0);
    vec4 pz, pdz;
    float r = 0.0, dr = 1.0;
    for (int i = 0; i < ITERATIONS; i++) {
        pz = z;
        z = qmul(pz, pz) + c;
        pdz = dz;
        dz = 2.0 * qmul(pz, pdz);
        r = length(z);
        dr = length(dz);
        if (r > 4.0) break;
    }
    return 0.5 * log(r) * r / dr;
}

float map(vec3 p) {
    p.xy *= rotate(time * 0.45);
    p.xz *= rotate(time * 0.65);
    vec4 a = vec4(sin(time * 0.69) * 1.3, sin(time * 0.7) * 0.5, 0.0, 0.0);
    return deQuaternionJuliaSet(vec4(p, 0.0), a);
}

vec3 calcNormal(vec3 p) {
    float d = 0.001;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

float ambientOcclusion(vec3 pos, vec3 nor) {
    float ao = 0.0;
    float amp = 0.5;
    float step = 0.01;
    for (int i = 1; i <= 5; i++) {
        float dist = step * float(i);
        vec3 p = pos + dist * nor;
        float d = map(p);
        ao += amp * (dist - d) / dist;
        amp *= 0.5;
    }
    return 1.0 - ao;
}

float softshadow(vec3 ro, vec3 rd, float tmin, float k) {
    float res = 1.0;
    float t = tmin;
    vec3 p = ro + t * rd;
    for (int i = 0; i < 32; i++) {
        float d = map(p);
        if (d < 0.001) {
            return 0.0;
        }
        p += d * rd;
        t += d;
        res = min(res, k * d / t);
    }
    return res;
}

vec3 raymarchRef(vec3 ro, vec3 rd) {
    vec3 p = ro;

    float t = 0.0;
    for (int i = 0; i < 128; i++) {
        float d = 0.5 * map(p);
        t += d;
        p += d * rd;
        if (d < 0.002) {
            vec3 n = calcNormal(p);
            float ao = ambientOcclusion(p, n);

            vec3 lightDir = vec3(0.0, 1.0, 0.0);

            float dotNL = clamp(dot(n, lightDir), 0.0, 1.0);

            return vec3(1.0) * dotNL * (0.5 + 0.5 * ao) * (1.0 - min(1.0, t / 5.0));
        }
    }
    return vec3(0.0);
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
    float t = (h - ro.y) / rd.y;
    if (t > 0.0) {
        vec3 p = ro + t * rd;
        vec3 nor = mix(vec3(0.0, 1.0, 0.0), bumpmap(p.xz * 5.0), 
            sin(3.0 * p.x) * sin(3.0 * p.z) > 0.0 ? 0.0 : 0.05);
        float shadow = softshadow(p, vec3(0.0, 1.0, 0.0), 0.1, 128.0);

        vec3 refDir = reflect(rd, nor);
        vec3 ref = raymarchRef(p, refDir);

        vec3 albedo = sin(3.0 * p.x) * sin(3.0 * p.z) > 0.0 ? vec3(0.8) : vec3(0.5);

        float dotNL = clamp(dot(nor, -rd), 0.0, 1.0);
        return 0.5 * ref + (0.5 + 0.5 * shadow) * albedo * dotNL;
    }
    return vec3(0.0);
}

vec3 raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;

    float groundHeight =  -2.0;

    float tmax = (groundHeight - ro.y) / rd.y;
    if (tmax < 0.0) {
        tmax = 1e8;
    }

    float t = 0.0;
    for (int i = 0; i < 94; i++) {
        float d = 0.5 * map(p);
        t += d;
        if (t > tmax) {
            break;
        }
        p += d * rd;
        if (d < 0.002) {
            vec3 n = calcNormal(p);
            float ao = ambientOcclusion(p, n);

            vec3 lightDir = vec3(0.0, 1.0, 0.0);

            float dotNL = clamp(dot(n, lightDir), 0.0, 1.0);

            return vec3(1.0) * (0.8 * dotNL + 0.2) * (0.5 + 0.5 * ao);
        }
    }
    return ground(ro, rd, groundHeight);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(0.0, -0.5, 7.0);
    vec3 ta = vec3(0.0, 0.0, 0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = raymarch(ro, rd);

    gl_FragColor = vec4(c, 1.0);
}