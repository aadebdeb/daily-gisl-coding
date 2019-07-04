precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define foldingLimit 1.0
vec3 boxFold(vec3 z, float dz) {
    return clamp(z, -foldingLimit, foldingLimit) * 2.0 - z;
}

void sphereFold(inout vec3 z, inout float dz, float minRadius, float fixedRadius) {
    float m2 = minRadius * minRadius;
    float f2 = fixedRadius * fixedRadius;
    float r2 = dot(z, z);
    if (r2 < m2) {
        float temp = (f2 / m2);
        z *= temp;
        dz *= temp;
    } else if (r2 < f2) {
        float temp = (f2 / r2);
        z *= temp;
        dz *= temp;
    }
}

// ref: http://blog.hvidtfeldts.net/index.php/2011/11/distance-estimated-3d-fractals-vi-the-mandelbox/
#define ITERATIONS 12
float deMandelbox(vec3 p, float scale, float minRadius, float fixedRadius) {
    vec3 z = p;
    float dr = 1.0;
    for (int i = 0; i < ITERATIONS; i++) {
        z = boxFold(z, dr);
        sphereFold(z, dr, minRadius, fixedRadius);
        z = scale * z + p;
        dr = dr * abs(scale) + 1.0;
    }
    float r = length(z);
    return r / abs(dr);
}

float de(vec3 p) {
    return deMandelbox(p, 2.0, 0.5, 1.0);
}

vec3 calcNormal(vec3 p) {
    float d = 0.001;
    return normalize(vec3(
        de(p + vec3(d, 0.0, 0.0)) - de(p - vec3(d, 0.0, 0.0)),
        de(p + vec3(0.0, d, 0.0)) - de(p - vec3(0.0, d, 0.0)),
        de(p + vec3(0.0, 0.0, d)) - de(p - vec3(0.0, 0.0, d))
    ));
}

#define OCCLUSION_ITERATIONS 5
float ambientOcclusion(vec3 pos, vec3 nor) {
    float ao = 0.0;
    float amp = 0.5;
    float step = 0.02;
    for (int i = 1; i < OCCLUSION_ITERATIONS; i++) {
        vec3 p = pos + step * float(i) * nor;
        float d = de(p);
        ao += amp * ((step * float(i) - d) / (step * float(i)));
        amp *= 0.5;
    }
    return 1.0 - ao;
}

const vec3 LIGHT_DIR = normalize(vec3(0.5, 0.8, 1.0));
const vec3 DIFFUSE_COLOR = vec3(0.8);
const vec3 AMBIENT_COLOR = vec3(0.2);
vec3 shadeSurface(vec3 pos, vec3 nor) {
    float dotNL = max(0.0, dot(nor, LIGHT_DIR));
    vec3 dif = DIFFUSE_COLOR * dotNL;
    float ao = ambientOcclusion(pos, nor);
    vec3 amb = AMBIENT_COLOR * vec3(ao);
    return dif + amb;
}

bool raymarch(vec3 ro, vec3 rd, out float t) {
    vec3 p = ro;
    t = 0.0;
    for (int i = 0; i < 128; i++) {
        float d = de(p);
        p += d * rd;
        t += d;
        if (d < 0.002) {
            return true;
        }
    }
    return false;
}

vec3 background(vec2 st) {
    return mix(vec3(0.5), vec3(0.1), length(st) * 0.8);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(10.0, 10.0, 10.0);
    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c; 
    float t;
    if (raymarch(ro, rd, t)) {
        vec3 pos = ro + t * rd;
        vec3 nor = calcNormal(pos);
        c = shadeSurface(pos, nor);
    } else {
        c = background((2.0 * gl_FragCoord.xy - resolution) / resolution);
    }

    gl_FragColor = vec4(pow(c, vec3(1.0 / 2.2)), 1.0);
}