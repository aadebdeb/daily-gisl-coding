precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define PI 3.14159265359
#define INV_PI 0.31830988618
#define TWO_PI 6.28318530718
// #define saturate(x) clamp(x, 0.0, 1.0)

vec2 random2(float x) {
    return fract(sin(x * vec2(12.9898, 51.431)) * vec2(43758.5453, 71932.1354));
}

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
    p = abs(p) - b;
    return length(max(p, 0.0)) + min(0.0, max(p.x, max(p.y, p.z)));
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}


float plane(vec3 ro, vec3 rd, float y) {
    float t = (y - ro.y) / rd.y;
    return t;
}

float map(vec3 p) {
    p.xy *= rotate(time * 0.5);
    p.xz *= rotate(time * 0.8);

    float db = sdBox(p, vec3(3.0));
    float dt = sdTorus(p, vec2(4.0, 1.0));
    float ds = sdSphere(p, 2.0) + sin(10.0 * p.x) * sin(10.0 * p.y) * sin(10.0 * p.z);

    float t = time * 0.8;
    float idx = mod(t, 2.0);
    float f = fract(t);
    float l = smoothstep(0.7, 1.0, f);
    if (idx < 1.0) {
        float v = l < 0.5 ? mix(db, ds, smoothstep(0.0, 1.0, l * 2.0)) : mix(ds, dt, smoothstep(0.0, 1.0, (l - 0.5) * 2.0));
        return mix(db, v, l);
    } else {
        float v = l < 0.5 ? mix(dt, ds, smoothstep(0.0, 1.0, l * 2.0)) : mix(ds, db, smoothstep(0.0, 1.0, (l - 0.5) * 2.0));
        return mix(dt, v, l);
    }
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

bool raymarch(vec3 ro, vec3 rd, float tmin, out float t) {
    vec3 p = ro;
    t = tmin;
    for (int i = 0; i < 32; i++) {
        float d = map(p);
        t += d;
        p += d * rd;
        if (d < 0.01) {
            return true;
        }
    }
    return false;
}

bool raymarchShort(vec3 ro, vec3 rd, float tmin, float near, out float t) {
    vec3 p = ro;
    t = tmin;
    for (int i = 0; i < 8; i++) {
        float d = map(p);
        t += d;
        p += d * rd;
        if (d < near) {
            return true;
        }
    }
    return false;
}

const vec3 LIGHT_COLOR = vec3(1.0) * 3.0;
const vec3 OBJECT_COLOR = vec3(0.9, 0.2, 0.45);
const vec3 FLOOR_COLOR = vec3(0.35, 0.4, 0.45);
const vec3 AMBINET_LGIHT_COLOR = vec3(0.05);
const float FLOOR_Y = -5.0;
const vec3 LIGHT_POS = vec3(60.0, 15.0, -30.0);

mat3 orthonormal(vec3 orthoY) {
    vec3 a = orthoY.x < 0.9 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
    vec3 orthoX = normalize(cross(orthoY, a));
    vec3 orthoZ = cross(orthoX, orthoY);
    return mat3(orthoX, orthoY, orthoZ);
}

vec3 createSampleDir(mat3 ortho, float theta, float phi) {
    vec3 v = vec3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi));
    return ortho * v;
}

vec3 orthonormal(vec3 normal, float theta, float phi) {
    vec3 orthoY = normal;
    vec3 a = normal.x < 0.9 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
    vec3 orthoX = normalize(cross(orthoY, a));
    vec3 orthoZ = cross(orthoX, orthoY);

    vec3 n;
    n.x = sin(theta) * cos(phi);
    n.y = cos(theta);
    n.z = sin(theta) * sin(phi);

    return normalize(vec3(dot(vec3(orthoX.x, orthoY.x, orthoZ.x), n),
    dot(vec3(orthoX.y, orthoY.y, orthoZ.y), n),
    dot(vec3(orthoX.z, orthoY.z, orthoZ.z), n)));

}

vec3 skyColor() {
    return vec3(0.0);
}

float fresnelSchlick(float f0, float f90, float cosine) {
    return f0 + (f90 - f0) * pow(1.0 - cosine, 5.0);
}

vec3 diffuseNormalizedDisneyBrdf(vec3 reflectance, float dotNV, float dotNL, float dotLH, float roughness) {
    float bias = mix(0.0, 0.5, roughness);
    float factor = mix(1.0, 1.0 / 1.51, roughness);
    float fd90 = bias + 2.0 * dotLH * dotLH * roughness;
    float fl = fresnelSchlick(1.0, fd90, dotNL);
    float fv = fresnelSchlick(1.0, fd90, dotNV);
    return reflectance * INV_PI * fl * fv * factor;
}

float normalDistributionGgx(vec3 normal, vec3 halfDir, float roughness) {
    float roughness2 = roughness * roughness;
    float dotNH = saturate(dot(normal, halfDir));
    float a = (1.0 + (roughness2 - 1.0) * dotNH * dotNH);
    return roughness2 * INV_PI / (a * a);
}

float maskingShadowingSmithJoint(vec3 normal, vec3 viewDir, vec3 lightDir, float roughness) {
    float roughness2 = roughness * roughness;
    float dotNV = saturate(dot(normal, viewDir));
    float dotNL = saturate(dot(normal, lightDir));
    float lv = 0.5 * (-1.0 + sqrt(1.0 + roughness2 * (1.0 / (dotNV * dotNV) - 1.0)));
    float ll = 0.5 * (-1.0 + sqrt(1.0 + roughness2 * (1.0 / (dotNL * dotNL) - 1.0)));
    return 1.0 / (1.0 + lv + ll);
}

vec3 fresnelSchlick(vec3 f0, float cosine) {
    return f0 + (1.0 - f0) * pow(1.0 - cosine, 5.0);
}

vec3 specularCookTorranceBrdf(vec3 reflectance, vec3 normal, vec3 viewDir, vec3 lightDir, float roughness) {
    vec3 halfDir = normalize(viewDir + lightDir);
    float dotNV = saturate(dot(normal, viewDir));
    float dotNL = saturate(dot(normal, lightDir));
    float dotVH = saturate(dot(viewDir, halfDir));
    float d = normalDistributionGgx(normal, halfDir, roughness);
    float g = maskingShadowingSmithJoint(normal, viewDir, lightDir, roughness);
    vec3 f = fresnelSchlick(reflectance, dotVH);
    return d * g * f / (4.0 * dotNV * dotNL + 1e-5);
}

vec3 getObjectColor(vec3 normal, vec3 viewDir, vec3 lightDir) {
    vec3 halfDir = normalize(viewDir + lightDir);
    float dotNV = saturate(dot(normal, viewDir));
    float dotNL = saturate(dot(normal, lightDir));
    float dotLH = saturate(dot(lightDir, halfDir));
    vec3 brdf = diffuseNormalizedDisneyBrdf(OBJECT_COLOR, dotNV, dotNL, dotLH, 0.5);
    return brdf * LIGHT_COLOR * dotNL + AMBINET_LGIHT_COLOR * OBJECT_COLOR;
}

const float FLOOR_ROUGHNESS = 0.2;

float softShadow(vec3 ro, vec3 rd, float tmin, float k) {
    float res = 1.0;
    vec3 p = ro + tmin * rd;
    float t = tmin;
    for (int i = 0; i < 32; i++) {
        float d = map(p);
        p += d * rd;
        t += d;
        if (d < 0.02) {
            return 0.0;
        }
        res = min(res, k * d / t);
    } 
    return res;
}

vec3 getFloorColor(vec3 normal, vec3 viewDir, vec3 lightDir, vec3 lightColor) {
    float dotNL = saturate(dot(normal, lightDir));
    vec3 brdf = specularCookTorranceBrdf(FLOOR_COLOR, normal, viewDir, lightDir, FLOOR_ROUGHNESS);
    return brdf * lightColor * dotNL;
}

vec3 getLightDir(vec3 pos) {
    return normalize(LIGHT_POS - pos);
}

vec3 getColor(vec3 ro, vec3 rd) {
    float t;
    if (raymarch(ro, rd, 0.0, t)) {
        vec3 pos = ro + t * rd;
        vec3 normal = calcNormal(pos);
        return getObjectColor(normal, -rd, getLightDir(pos));
    } else {
        float t = plane(ro, rd, FLOOR_Y);
        if (t < 0.0) {
            return skyColor();
        }
        vec3 floorPos = ro + t * rd;
        vec3 floorNormal = vec3(0.0, 1.0, 0.0);
        vec3 refDir = reflect(rd, floorNormal);
        float shadow = softShadow(floorPos, getLightDir(floorPos), 0.01, 16.0);
        vec3 lightDir = getLightDir(floorPos);
        vec3 lightSpec = (0.5 + 0.5 * shadow) * getFloorColor(floorNormal, -rd, lightDir, LIGHT_COLOR);
        vec3 sum = vec3(0.0);
        mat3 ortho = orthonormal(refDir);
        for (int i = 0; i < 16; i++) {
            vec2 r = random2(float(i) + floorPos.x + floorPos.z);
            vec3 sampleDir = createSampleDir(ortho, FLOOR_ROUGHNESS * r.x * PI / 8.0, r.y * TWO_PI);
            if (dot(sampleDir, floorNormal) <= 0.0) {
                continue;
            }
            if (raymarchShort(floorPos, sampleDir, 0.01, 0.05, t)) {
                vec3 objPos = floorPos + t * sampleDir;
                vec3 objNormal = calcNormal(objPos);
                vec3 objColor = getObjectColor(objNormal, -sampleDir, getLightDir(objPos));
                sum += FLOOR_COLOR * objColor;
            } else {
                sum += FLOOR_COLOR * skyColor();
            }
        }
        return lightSpec + sum / 16.0;
    }
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec2 m = (2.0 * mouse - 1.0);

    vec3 ro = vec3(10.0, 5.0, 10.0);
    // vec3 ro = vec3(m.x * 50.0, m.y * 20.0, 20.0);
    vec3 ta = vec3(0.0, -3.0, 0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = getColor(ro, rd);

    gl_FragColor = vec4(pow(c, vec3(1.0 / 2.2)), 1.0);
}