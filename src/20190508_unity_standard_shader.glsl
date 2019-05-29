/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define PI 3.14159265359
#define INV_PI 0.31830988618

#define SUN_DISK 2.0
#define SUN_SIZE 0.04
#define SUN_SIZE_CONVERGENCE 5.0
#define ATMOSPHERE_THICKNESS 1.0
#define SKY_TINT vec3(0.5, 0.5, 0.5)
#define GROUND_COLOR vec3(0.369, 0.349, 0.341)
#define EXPOSURE 1.3

#define COLOR_SPACE_DIELECTRIC_SPEC vec4(0.04, 0.04, 0.04, 0.96)
#define COLOR_SPACE_DOUBLE vec4(4.59479380, 4.59479380, 4.59479380, 2.0)

#define ALBEDO vec3(1.0)
#define METALLIC 0.1
#define SMOOTHNESS 0.8
#define LIGHT_COLOR vec3(1.0, 0.957, 0.839)
// #define saturate(x) clamp(x, 0.0, 1.0)

vec3 color2Gamma(vec3 color) {
    return COLOR_SPACE_DOUBLE.r > 2.0 ? pow(color, vec3(1.0 / 2.2)) : color;
}

const vec3 kDefaultScatteringWavelength = vec3(0.65, 0.57, 0.475);
const vec3 kVariableRangeForScatteringWavelength = vec3(0.15, 0.15, 0.15);


#define OUTER_RADIUS 1.025
const float kOuterRadius = OUTER_RADIUS;
const float kOuterRadius2 = OUTER_RADIUS * OUTER_RADIUS;
const float kInnerRadius = 1.0;
const float kInnerRadius2 = 1.0;

const float kCameraHeight = 0.0001;

const float kRAYLEIGH = mix(0.0, 0.0025, pow(ATMOSPHERE_THICKNESS, 2.5));
#define kMIE 0.001
#define kSUN_BRIGHTNESS 20.0

#define kMAX_SCATTER 50.0

const float kHDSundiskIntensityFactor = 15.0;

const float kSunScale = 400.0 * kSUN_BRIGHTNESS;
const float kKmESun = kMIE * kSUN_BRIGHTNESS;
const float kKm4PI = kMIE * 4.0 * PI;
const float kScale = 1.0 / (OUTER_RADIUS - 1.0);
const float kScaleDepth = 0.25;
const float kScaleOverScaleDepth = (1.0 / (OUTER_RADIUS - 1.0)) / 0.25;
const float kSamples = 2.0;

#define MIE_G (-0.990)
#define MIE_G2 0.9801

#define SKY_GROUND_THRESHOLD 0.01

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

float scale(float inCos) {
    float x = 1.0 - inCos;
    return 0.25 * exp(-0.0287 + x * (0.459 + x * (3.83 + x * (-6.80 + x * 5.25))));
}

float getRayleighPhase(float eyeCos2) {
    return 0.75 + 0.75 * eyeCos2;
}

float getRayleighPhase(vec3 light, vec3 ray) {
    float eyeCos = dot(light, ray);
    return getRayleighPhase(eyeCos * eyeCos);
}

#define WORLD_SPACE_LIGHT_POS normalize(vec3(0.0, 1.0, 0.0))

vec3 skybox(vec3 rd) {
    vec3 kSkyTintInGammaSpace = color2Gamma(SKY_TINT);
    vec3 kScatteringWavelength = mix(
        kDefaultScatteringWavelength - kVariableRangeForScatteringWavelength,
        kDefaultScatteringWavelength + kVariableRangeForScatteringWavelength,
        vec3(1.0) - kSkyTintInGammaSpace
    );
    vec3 kInvWavelength = 1.0 / pow(kScatteringWavelength, vec3(4.0));
    float kKrESun = kRAYLEIGH * kSUN_BRIGHTNESS;
    float kKr4PI = kRAYLEIGH * 4.0 * PI;

    vec3 cameraPos = vec3(0.0, kInnerRadius + kCameraHeight, 0.0);

    vec3 eyeRay = rd;
    float far = 0.0;
    vec3 cIn, cOut;
    if (eyeRay.y >= 0.0) {
        far = sqrt(kOuterRadius2 + kInnerRadius2 * eyeRay.y * eyeRay.y - kInnerRadius2) - kInnerRadius * eyeRay.y;
        vec3 pos = cameraPos + far * eyeRay;

        float height = kInnerRadius + kCameraHeight;
        float depth = exp(kScaleOverScaleDepth * (-kCameraHeight));
        float startAngle = dot(eyeRay, cameraPos) / height;
        float startOffset = depth * scale(startAngle);

        float sampleLength = far / kSamples;
        float scaledLength = sampleLength * kScale;
        vec3 sampleRay = eyeRay * sampleLength;
        vec3 samplePoint = cameraPos + sampleRay * 0.5;

        vec3 frontColor = vec3(0.0);

        for (int i = 0; i < 2; i++) {
            float height = length(samplePoint);
            float depth = exp(kScaleOverScaleDepth * (kInnerRadius - height));
            float lightAngle = dot(WORLD_SPACE_LIGHT_POS, samplePoint) / height;
            float cameraAngle = dot(eyeRay, samplePoint) / height;
            float scatter = (startOffset + depth * (scale(lightAngle) - scale(cameraAngle)));
            vec3 attenuate = exp(-clamp(scatter, 0.0, kMAX_SCATTER) * (kInvWavelength * kKr4PI + kKm4PI));
            frontColor += attenuate * (depth * scaledLength);
            samplePoint += sampleRay;
        }

        cIn = frontColor * (kInvWavelength * kKrESun);
        cOut = frontColor * kKmESun;
    } else {
        far = (-kCameraHeight) / min(-0.001, eyeRay.y);
        vec3 pos = cameraPos + far * eyeRay;
        float depth = exp((-kCameraHeight) * (1.0 / kScaleDepth));
        float cameraAngle = dot(-eyeRay, pos);
        float lightAngle = dot(WORLD_SPACE_LIGHT_POS, pos);
        float cameraScale = scale(cameraAngle);
        float lightScale = scale(lightAngle);
        float cameraOffset = depth * cameraScale;
        float temp = (lightScale + cameraScale);

        float sampleLength = far / kSamples;
        float scaledLength = sampleLength * kScale;
        vec3 sampleRay = eyeRay * sampleLength;
        vec3 samplePoint = cameraPos + sampleRay * 0.5;

        vec3 frontColor = vec3(0.0);
        vec3 attenuate;
        {
            float height = length(samplePoint);
            float depth = exp(kScaleOverScaleDepth * (kInnerRadius - height));
            float scatter = depth * temp - cameraOffset;
            attenuate = exp(-clamp(scatter, 0.0, kMAX_SCATTER) * (kInvWavelength * kKr4PI + kKm4PI));
            frontColor += attenuate * (depth * scaledLength);
            samplePoint += sampleRay;
        }

        cIn = frontColor * (kInvWavelength * kKrESun + kKmESun);
        cOut = clamp(attenuate, 0.0, 1.0);
    }

    vec3 groundColor = EXPOSURE * (cIn + GROUND_COLOR * cOut);
    vec3 skyColor = EXPOSURE * (cIn * getRayleighPhase(WORLD_SPACE_LIGHT_POS, -eyeRay));

    float y = rd.y / SKY_GROUND_THRESHOLD;

    return cIn + GROUND_COLOR * cOut * 0.2;
    // vec3 col = vec3(0.0);

    // vec3 col = skyColor;
    // return vec3(saturate(y));
    vec3 col = mix(groundColor, skyColor, saturate(y));

    return col;

}

float pow5(float x) {
    return x * x * x * x * x;
}

float perceptualRoughnessToRoughness(float perceptualRoughness) {
    return perceptualRoughness * perceptualRoughness;
}

float smoothnessToPerceptualRoughness(float smoothness) {
    return 1.0 - smoothness;
}

vec3 fresnelTerm(vec3 f0, float cosA) {
    float t = pow5(1.0 - cosA);
    return f0 + (1.0 - f0) * t;
}

vec3 fresnelLerp(vec3 f0, vec3 f90, float cosA) {
    float t = pow5(1.0 - cosA);
    return mix(f0, f90, t);
}

float disneyDiffuse(float dotNV, float dotNL, float dotLH, float perceptualRoughness) {
    float fd90 = 0.5 + 2.0 * dotLH * dotLH * perceptualRoughness;
    float lightScatter = (1.0 + (fd90 - 1.0) * pow5(1.0 - dotNL));
    float viewScatter = (1.0 + (fd90 - 1.0) * pow5(1.0 - dotNV));
    return lightScatter * viewScatter;
}

float smithJointVisibilityTerm(float dotNL, float dotNV, float roughness) {
    float a = roughness;
    float lambdaV = dotNL * (dotNV * (1.0 - a) + a);
    float lambdaL = dotNV * (dotNL * (1.0 - a) + a);
    return 0.5 / (lambdaV + lambdaL + 1e-5);
}

float ggxTerm(float dotNH, float roughness) {
    float a2 = roughness * roughness;
    float d = (dotNH * a2 - dotNH) * dotNH + 1.0;
    return INV_PI * a2 / (d * d + 1e-7);
}

float oneMinusReflectivityFromMetallic(float metallic) {
    float oneMinusDielectricSpec = COLOR_SPACE_DIELECTRIC_SPEC.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

vec3 diffuseAndSpecularFromMetallic(vec3 albedo, float metallic, out vec3 specColor, out float oneMinusReflectivity) {
    specColor = mix(COLOR_SPACE_DIELECTRIC_SPEC.rgb, albedo, metallic);
    oneMinusReflectivity = oneMinusReflectivityFromMetallic(metallic);
    return albedo * oneMinusReflectivity;
}

vec3 unityPBS(vec3 diffColor, vec3 specColor, float oneMinusReflectivity,
        float smoothness, vec3 normal, vec3 viewDir, vec3 lightDir, vec3 lightColor) {
    float perceptualRoughness = smoothnessToPerceptualRoughness(smoothness);
    vec3 halfDir = normalize(lightDir + viewDir);
    float dotNV = saturate(dot(normal, viewDir));
    float dotNL = saturate(dot(normal, lightDir));
    float dotNH = saturate(dot(normal, halfDir));
    float dotLV = saturate(dot(lightDir, viewDir));
    float dotLH = saturate(dot(lightDir, halfDir));

    float diffuseTerm = disneyDiffuse(dotNV, dotNL, dotLH, perceptualRoughness) * dotNL;

    float roughness = perceptualRoughnessToRoughness(perceptualRoughness);
    roughness = max(roughness, 0.002);
    float v = smithJointVisibilityTerm(dotNL, dotNV, roughness);
    float d = ggxTerm(dotNH, roughness);

    float specularTerm = v * d * PI;
    specularTerm = max(1e-4, specularTerm * dotNL);

    float surfaceReduction = 1.0 / (roughness * roughness + 1.0);

    float grazingTerm = saturate(smoothness + (1.0 - oneMinusReflectivity));
    return diffColor * lightColor * (vec3(0.15, 0.15, 0.25) + diffuseTerm)
         + specularTerm * lightColor * fresnelTerm(specColor, dotLH);
}

vec3 raytrace(vec3 ro, vec3 rd) {
    float tmin = 0.0;
    float tmax = 1e6;
    if (sphere(ro, rd, 2.0, tmin, tmax)) {
        vec3 pos = ro + tmin * rd;
        vec3 normal = sphereNormal(ro, rd, tmin);
        vec3 viewDir = normalize(ro - pos);
        vec3 lightDir = normalize(vec3(1.0));
        vec3 lightColor = vec3(1.0);

        vec3 specColor;
        float oneMinusReflectivity;
        vec3 diffColor = diffuseAndSpecularFromMetallic(ALBEDO, METALLIC, specColor, oneMinusReflectivity);

        vec3 c = unityPBS(diffColor, specColor, oneMinusReflectivity, SMOOTHNESS, normal, viewDir, lightDir, LIGHT_COLOR);
        return c;
    }
    return skybox(rd);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec2 m = mouse * 2.0 - 1.0;
    // vec3 ro = vec3(m.x * 10.0, m.y * 5.0, 5.0);
    // vec3 ro = vec3(5.0 * cos(time), 5.0 * sin(time * 0.5), 5.0 * sin(time));
    vec3 ro = vec3(0.0, 0.0, 5.0);
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