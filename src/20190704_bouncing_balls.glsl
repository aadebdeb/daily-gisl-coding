precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define PI 3.14159265359
#define INV_PI 0.31830988618
#define TWO_PI 6.28318530718
// #define saturate(x) clamp(x, 0.0, 1.0)

const float GRAVITY = -9.81 * 5.0;
const float V0 = 50.0;
const float SPACING = 30.0;
const float HORIZONTAL_SPEED = -50.0;

struct Surface {
    vec3 albedo;
    float metallic;
    float roughness;
    vec3 pos;
    vec3 nor;
    vec3 viewDir;
};

float random(vec2 x){
    return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

// a(t) = g
// v(t) = g * t + v0
// x(t) = 0.5 * g * t^2 + v0 * t + x0
float getFreeFallPosition(float t, float v0) {
    return 0.5 * GRAVITY * t * t + v0 * t + 0.0;
}

float getBouncingTime(float v0) {
    float a = 0.5 * GRAVITY;
    float b = v0;
    float c = 0.0;
    return 0.5 * (-b - sqrt(b * b - 4.0 * a * c)) / a;
}

float map(vec3 p) {
    p.z += HORIZONTAL_SPEED * time;
    vec2 idx = floor(p.xz / SPACING);
    p.xz = mod(p.xz, SPACING) - 0.5 * SPACING;
    float randTime = random(0.15 * idx) * 100.0;
    float randSize = random(0.32 * idx) * 2.0 + 1.0;
    float bounceTime = getBouncingTime(V0);
    p.y -= getFreeFallPosition(mod(time + randTime, bounceTime), V0);
    return length(p) - randSize;
}

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(TWO_PI * (c * t + d));
}

vec3 rainbowPalette(float t) {
    return palette(t, vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.37, 0.67));
}

vec3 getAlbedo(vec3 p) {
    p.z += HORIZONTAL_SPEED * time;
    vec2 idx = floor(p.xz / SPACING);
    return rainbowPalette(random(0.19 * idx) * 100.0);
}

vec3 calcNormal(vec3 p) {
    float d = 0.001;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

float softshadow(vec3 ro, vec3 rd, float tmin, float k) {
    float res = 1.0;
    float t = tmin;
    vec3 p = ro + t * rd;
    for (int i = 0; i < 32; i++) {
        float d = map(p);
        if (d < 0.002) {
            return 0.0;
        }
        p += d * rd;
        t += d;
        res = min(res, k * d / t);
    }
    return res;
}

bool raymarch(vec3 ro, vec3 rd, out Surface surf) {
    vec3 p = ro;
    for (int i = 0; i < 192; i++) {
        float d = 0.5 * map(p);
        p += d * rd;
        if (d < 0.002) {
            surf.albedo = getAlbedo(p);
            surf.metallic = 0.0;
            surf.roughness = 0.8;
            surf.pos = p;
            surf.nor = calcNormal(p);
            return true;
        }
    }
    return false;
}

bool hitFloor(vec3 ro, vec3 rd, out Surface surf) {
    float t = -ro.y / rd.y;
    if (t > 0.0) {
        surf.albedo = vec3(0.01, 0.05, 0.1);
        surf.metallic = 1.0;
        surf.roughness = 0.5;
        surf.pos = ro + t * rd;
        surf.nor = vec3(0.0, 1.0, 0.0);
        return true;
    }
    return false;
}

vec3 background(vec3 rd) {
    return mix(vec3(0.3, 0.5, 0.95), vec3(0.95, 0.65, 0.5), rd.y * 0.5 + 0.5);
}

vec3 ambientlight(vec3 rd) {
    return 0.2 * mix(0.8, 1.0, rd.y * 0.5 + 0.5) * background(vec3(rd.x, abs(rd.y), rd.z));
}

const vec3 LIGHT_DIR = normalize(vec3(0.05, 1.0, 0.05));
const vec3 LIGHT_COLOR = 1.0 * vec3(1.0);

vec3 schlickFresnel(vec3 f0, float cosine) {
    return f0 + (1.0 - f0) * pow(1.0 - cosine, 5.0);
}

float schlickFresnel(float f0, float f90, float cosine) {
    return f0 + (f90 - f0) * pow(1.0 - cosine, 5.0);
}


vec3 diffuseNormalizedDisneyBrdf(vec3 reflectance, float dotNV, float dotNL, float dotLH, float roughness) {
    float bias = mix(0.0, 0.5, roughness);
    float factor = mix(1.0, 1.0 / 1.51, roughness);
    float fd90 = bias + 2.0 * dotLH * dotLH * roughness;
    float fl = schlickFresnel(1.0, fd90, dotNL);
    float fv = schlickFresnel(1.0, fd90, dotNV);
    return reflectance * INV_PI * fl * fv * factor;
}

float normalDistributionGgx(vec3 normal, vec3 halfDir, float roughness) {
    float roughness2 = roughness * roughness;
    float dotNH = saturate(dot(normal, halfDir));
    float a = (1.0 - (1.0 - roughness2) * dotNH * dotNH);
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

vec3 specularCookTorranceBrdf(vec3 reflectance, vec3 normal, vec3 viewDir, vec3 lightDir, float roughness) {
    vec3 halfDir = normalize(viewDir + lightDir);
    float dotNV = saturate(dot(normal, viewDir));
    float dotNL = saturate(dot(normal, lightDir));
    float dotVH = saturate(dot(viewDir, halfDir));
    float d = normalDistributionGgx(normal, halfDir, roughness);
    float g = maskingShadowingSmithJoint(normal, viewDir, lightDir, roughness);
    vec3 f = schlickFresnel(reflectance, dotVH);
    return max(d  * g * f / (4.0 * dotNV * dotNL), 0.0);
}

vec3 shadeSurface(Surface surf, vec3 lightDir) {
    vec3 diffColor = mix(vec3(0.0), surf.albedo, 1.0 - surf.metallic);
    vec3 specColor = mix(vec3(0.04), surf.albedo, surf.metallic);
    vec3 halfDir = normalize(surf.viewDir + lightDir);
    float dotNL = clamp(dot(surf.nor, lightDir), 0.0, 1.0);
    float dotNV = clamp(dot(surf.nor, surf.viewDir), 0.0, 1.0);
    float dotLH = clamp(dot(lightDir, halfDir), 0.0, 1.0);
    vec3 dif = diffuseNormalizedDisneyBrdf(diffColor, dotNV, dotNL, dotLH, surf.roughness);
    vec3 spec = specularCookTorranceBrdf(specColor, surf.nor, surf.viewDir, LIGHT_DIR, surf.roughness);
    vec3 amb = diffColor * ambientlight(surf.nor);
    return LIGHT_COLOR * (dif + spec) + amb; 
}

vec3 getSurfaceColor(vec3 rd, Surface surf) {
    vec3 color = shadeSurface(surf, LIGHT_DIR);
    float shadow = softshadow(surf.pos, LIGHT_DIR, 0.2, 8.0);
    float shadowIntensity = 0.7;
    return ((1.0 - shadowIntensity) + shadowIntensity * shadow) * color;
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    float timeRep = 40.0;
    float seq = mod(time, timeRep) / timeRep;

    vec3 ro = vec3(
        100.0 * cos(2.0 * TWO_PI * seq),
        30.0 + 500.0 * smoothstep(0.3, 0.02, abs(seq - 0.5)),
        100.0 * sin(2.0 * TWO_PI * seq)
    );

    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    float t = 0.0;
    vec3 c = vec3(0.0);
    Surface surf;
    surf.viewDir = -rd;
    vec3 bg = background(rd);
    if (raymarch(ro, rd, surf) || hitFloor(ro, rd, surf)) {
        c = getSurfaceColor(rd, surf);
        float dd = length(surf.pos.xz) * 0.0005;
        float fog = exp(-dd * dd);
        c = mix(bg, c, fog);
    } else {
        c = bg;
    }

    gl_FragColor = vec4(pow(c, vec3(1.0 / 2.2)), 1.0);
}