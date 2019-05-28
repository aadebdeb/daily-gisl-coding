precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define PI 3.14159265359
#define INV_PI 0.31830988618
#define INV_TWO_PI 0.15915494309
// #define saturate(x) clamp(x, 0.0, 1.0)

#define ALBEDO vec3(0.2, 0.5, 0.7)
#define ROUGHNESS mouse.x
#define METALLIC mouse.y

// 0: normalized lambert
// 1: difuse disney
// 2: normalized diffuse disney
// 3: oren nayar
// others: no diffuse
#define DIFFUSE_BRDF 2

// 0: noramlized phong
// 1: normalized blinn-phong
// 2: cook-torrance
// others: no specular
#define SPECULAR_BRDF 2

#define NORMALIZED_PHONG_POWER ROUGHNESS * 128.0
#define NORMALIZED_BLINN_PHONG_POWER ROUGHNESS * 1000.0

// 0: smith masking shadowing function
// 1: smith joint masking shadowing function
#define COOK_TORRANCE_MASKING_SHADOWING_FUNCITON 0

#define BACKGROUND_COLOR vec3(0.3)
const vec3 LIGHT_DIR = normalize(vec3(1.0));
const vec3 LIGHT_COLOR = vec3(1.0) * PI;

// #define CAMERA_MOVEMENT

vec3 diffuseMormalizedLambertBrdf(vec3 reflectance) {
    return reflectance * INV_PI;
}

float fresnelSchlick(float f0, float f90, float cosine) {
    return f0 + (f90 - f0) * pow(1.0 - cosine, 5.0);
}

//ref: https://qiita.com/mebiusbox2/items/1cd65993ffb546822213
vec3 diffuseDisneyBrdf(vec3 reflectance, float dotNV, float dotNL, float dotLH, float roughness) {
    float fd90 = 0.5 + 2.0 * dotLH * dotLH * roughness;
    float fl = fresnelSchlick(1.0, fd90, dotNL);
    float fv = fresnelSchlick(1.0, fd90, dotNV);
    return reflectance * INV_PI * fl * fv;
}

//ref: https://qiita.com/mebiusbox2/items/1cd65993ffb546822213
vec3 diffuseNormalizedDisneyBrdf(vec3 reflectance, float dotNV, float dotNL, float dotLH, float roughness) {
    float bias = mix(0.0, 0.5, roughness);
    float factor = mix(1.0, 1.0 / 1.51, roughness);
    float fd90 = bias + 2.0 * dotLH * dotLH * roughness;
    float fl = fresnelSchlick(1.0, fd90, dotNL);
    float fv = fresnelSchlick(1.0, fd90, dotNV);
    return reflectance * INV_PI * fl * fv * factor;
}

// https://ja.wikipedia.org/wiki/%E3%82%AA%E3%83%BC%E3%83%AC%E3%83%B3%E3%83%BB%E3%83%8D%E3%82%A4%E3%83%A4%E3%83%BC%E5%8F%8D%E5%B0%84
// https://t-pot.com/program/80_OrenNayer/index.html
vec3 diffuseOrenNayarBrdf(vec3 reflectance, vec3 normal, vec3 viewDir, vec3 lightDir, float roughness) {
    float dotNV = saturate(dot(normal, viewDir));
    float dotNL = saturate(dot(normal, lightDir));
    float roughness2 = roughness * roughness;
    float a = 1.0 - 0.5 * roughness2 / (roughness2 + 0.33);
    float b = 0.45 * roughness2 / (roughness2 + 0.09);
    float cosPhi = dot(normalize(viewDir - dotNV * normal), normalize(lightDir - dotNL * normal)); // cos(phi_v, phi_l)
    float sinNV = sqrt(1.0 - dotNV * dotNV);
    float sinNL = sqrt(1.0 - dotNL * dotNL);
    float s = dotNV < dotNL ? sinNV : sinNL; // sin(max(theta_v, theta_l))
    float t = dotNV > dotNL ? sinNV / dotNV : sinNL / dotNL; // tan(min(theta_v, theta_l))
    return reflectance * INV_PI * (a + b * cosPhi * s * t);
}

// ref: http://www.project-asura.com/program/d3d11/d3d11_006.html
vec3 specularNormalizedPhongBrdf(vec3 reflectance, float dotRL, float power) {
    float norm = (power + 1.0) * INV_TWO_PI;
    return reflectance * pow(dotRL, power) * norm;
}

// ref http://d.hatena.ne.jp/hanecci/20130505/p2
vec3 specularNormalizedBlinnPhongBrdf(vec3 reflectance, float dotNH, float power) {
    float norm = (power + 2.0) * INV_TWO_PI;
    return reflectance * pow(dotNH, power) * norm;
}

float normalDistributionGgx(vec3 normal, vec3 halfDir, float roughness) {
    float roughness2 = roughness * roughness;
    float dotNH = saturate(dot(normal, halfDir));
    float a = (1.0 - (1.0 - roughness2) * dotNH * dotNH);
    return roughness2 * INV_PI / (a * a);
}

// https://qiita.com/_Pheema_/items/f1ffb2e38cc766e6e668
// also called Height-Correlated Masking-Shadowing Function
float maskingShadowingSmith(vec3 normal, vec3 viewDir, vec3 lightDir, float roughness) {
    float roughness2 = roughness * roughness;
    float dotNV = saturate(dot(normal, viewDir));
    float dotNL = saturate(dot(normal, lightDir));
    float lv = 0.5 * (-1.0 + sqrt(1.0 + roughness2 * (1.0 / (dotNV * dotNV) - 1.0)));
    float ll = 0.5 * (-1.0 + sqrt(1.0 + roughness2 * (1.0 / (dotNL * dotNL) - 1.0)));
    return (1.0 / (1.0 + lv)) * (1.0 / (1.0 + ll));
}

// https://qiita.com/_Pheema_/items/f1ffb2e38cc766e6e668
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
    #if COOK_TORRANCE_MASKING_SHADOWING_FUNCITON == 0
    float g = maskingShadowingSmith(normal, viewDir, lightDir, roughness);
    #else 
    float g = maskingShadowingSmithJoint(normal, viewDir, lightDir, roughness);
    #endif
    vec3 f = fresnelSchlick(reflectance, dotVH);
    return d  * g * f / (4.0 * dotNV * dotNL);
}

bool sphere(vec3 ro, vec3 rd, float r, inout float tmin, inout float tmax) {
    float a = dot(rd, rd);
    float b = 2.0 * dot(ro, rd);
    float c = dot(ro, ro) - r * r;

    float d = b * b - 4.0 * a * c;
    if (d < 0.0) {
        return false;
    }
    float sqrtD = sqrt(d);
    tmin = max(tmin, (-b - sqrtD) / (2.0 * a));
    tmax = min(tmax, (-b + sqrtD) / (2.0 * a));
    if (tmin > tmax) {
        return false;
    }
    return true;
}

vec3 sphereNormal(vec3 ro, vec3 rd, float t) {
    vec3 p = ro + t * rd;
    return normalize(p);
}

vec3 physicallyBasedShading(vec3 normal, vec3 viewDir, vec3 lightDir, vec3 reflectDir) {
    vec3 halfDir = normalize(viewDir + lightDir);

    float dotNV = saturate(dot(normal, viewDir));
    float dotNL = saturate(dot(normal, lightDir));
    float dotNH = saturate(dot(normal, halfDir));
    float dotLH = saturate(dot(lightDir, halfDir));
    float dotRL = saturate(dot(reflectDir, lightDir));

    vec3 diffuseBrdf = vec3(0.0);
    #if DIFFUSE_BRDF == 0
    diffuseBrdf = diffuseMormalizedLambertBrdf(ALBEDO);
    #elif DIFFUSE_BRDF == 1
    diffuseBrdf = diffuseDisneyBrdf(ALBEDO, dotNV, dotNL, dotLH, ROUGHNESS);
    #elif DIFFUSE_BRDF == 2
    diffuseBrdf = diffuseNormalizedDisneyBrdf(ALBEDO, dotNV, dotNL, dotLH, ROUGHNESS);
    #elif DIFFUSE_BRDF == 3
    diffuseBrdf = diffuseOrenNayarBrdf(ALBEDO, normal, viewDir, lightDir, ROUGHNESS);
    #endif

    vec3 specularBrdf = vec3(0.0);
    #if SPECULAR_BRDF == 0
    specularBrdf = specularNormalizedPhongBrdf(ALBEDO, dotRL, NORMALIZED_PHONG_POWER);
    #elif SPECULAR_BRDF == 1
    specularBrdf = specularNormalizedBlinnPhongBrdf(ALBEDO, dotNH, NORMALIZED_BLINN_PHONG_POWER);
    #elif SPECULAR_BRDF == 2
    specularBrdf = specularCookTorranceBrdf(ALBEDO, normal, viewDir, lightDir, ROUGHNESS);
    #endif

    vec3 brdf = (1.0 - METALLIC) * diffuseBrdf + METALLIC * specularBrdf;
    return brdf * dotNL * LIGHT_COLOR;
}

vec3 raytrace(vec3 ro, vec3 rd) {
    float tmin = 0.0;
    float tmax = 1e6;
    if (sphere(ro, rd, 2.0, tmin, tmax)) {
        vec3 pos = ro + tmin * rd;
        vec3 normal = sphereNormal(ro, rd, tmin);
        vec3 viewDir = -normalize(rd);
        vec3 lightDir = LIGHT_DIR;
        vec3 reflectDir = reflect(-viewDir, normal);
        return physicallyBasedShading(normal, viewDir, lightDir, reflectDir);
    }
    return BACKGROUND_COLOR;
}


void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec2 m = mouse * 2.0 - 1.0;
    #ifdef CAMERA_MOVEMENT
    vec3 ro = vec3(5.0 * cos(time * 0.5), 0.0, 5.0 * sin(time * 0.5));
    #else
    vec3 ro = vec3(0.0, 0.0, 5.0);
    #endif
    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = raytrace(ro, rd);

    c = pow(c, vec3(1.0 / 2.2));

    gl_FragColor = vec4(c, 1.0);
}