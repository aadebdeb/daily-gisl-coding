precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define INV_PI 0.31830988618
#define INV_TWO_PI 0.15915494309

#define GROUND_COLOR vec3(0.01, 0.01, 0.01)
#define OBJECT_COLOR vec3(0.1, 0.05, 0.2)
#define CYLINDER_LIGHT1 vec3(1.5, 0.7, 0.95)
#define CYLINDER_LIGHT2 vec3(0.6, 1.5, 0.8)

vec3 kCameraPos;
vec3 kLightColor = vec3(1.0) * 300.0;
vec3 kLightPos;

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

vec3 schlickFresnel(vec3 f90, float cosine) {
    return f90 + (1.0 - f90) * pow(1.0 - cosine, 5.0);
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

vec3 specularNormalizedBlinnPhongBrdf(vec3 reflectance, float dotNH, float power) {
    float norm = (power + 2.0) * INV_TWO_PI;
    return reflectance * pow(dotNH, power) * norm;
}

float sdCylinder(vec3 p, vec2 h) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - h;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

vec4 mapLight(vec3 p) {
    float d1 = sdCylinder(p - vec3(-6.0, 3.0 + 2.0, -3.0), vec2(1.0, 3.0));
    float d2 = sdCylinder(p - vec3(3.0, 3.0 + 1.0, -10.0), vec2(1.0, 3.0));
    return d1 < d2 ? vec4(CYLINDER_LIGHT1, d1) : vec4(CYLINDER_LIGHT2, d2);
}

float map(vec3 p) {
    return length(p - vec3(0.0, 3.0, 0.0)) - 3.0;
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

vec3 raymarchLight(vec3 ro, vec3 rd, float tmax) {
    vec3 p = ro;
    float t = 0.0;
    vec4 minRes;
    float minD = 1e6;
    for (int i = 0; i < 32; i++) {
        vec4 res = mapLight(p);
        float d = res.w;
        p += d * rd;
        if (d < minD) {
            minRes = res;
        }
        minD = min(minD, d);
        t += d;
        if (d < 0.01) {
            return res.rgb;
        }
        if (t > tmax) {
            break;
        }
    }
    return minRes.rgb * exp(-10.0 * minD);
}

bool raymarch(vec3 ro, vec3 rd, float tmax, out float t) {
    vec3 p = ro;
    t = 0.0;
    for (int i = 0; i < 32; i++) {
        float d = map(p);
        p += d * rd;
        t += d;
        if (d < 0.01) {
            return true;
        }
        if (t >= tmax) {
            return false;
        }
    }
    return false;
}

vec4 raymarchMaterial(vec3 pos) {
    pos.xy *= rotate(-0.2);
    float v = pos.y * 2.0;
    vec4 m1 = vec4(vec3(0.8), 0.0);
    vec4 m2 =  vec4(vec3(0.7, 0.6, 0.3), 0.8);
    float t = smoothstep(0.95, 1.0, fract(v));
    return mod(v, 2.0) < 1.0 ? mix(m1, m2, t) : mix(m2, m1, t);
}

vec3 raymarchColor(vec3 pos) {
    vec3 nor = calcNormal(pos);
    vec3 ldir = normalize(kLightPos - pos);
    float d = length(kLightPos - pos);
    float atten = 1.0 / (d * d);

    vec3 viewDir = normalize(kCameraPos - pos);
    vec3 halfDir = normalize(viewDir + ldir);

    float dotNV = max(0.0, dot(nor, viewDir));
    float dotNL = max(0.0, dot(nor, ldir));
    float dotLH = max(0.0, dot(ldir, halfDir));

    vec4 mat = raymarchMaterial(pos);

    float metallic = 0.5;
    vec3 specColor = mix(vec3(0.04), mat.rgb, mat.w);
    vec3 difColor = mix(mat.rgb, vec3(0.0), mat.w);

    vec3 diffuse = diffuseNormalizedDisneyBrdf(difColor, dotNV, dotNL, dotLH, 0.3);
    vec3 specular = specularNormalizedBlinnPhongBrdf(specColor, dotNL, 64.0);

    return (diffuse + specular) * dotNL * atten * kLightColor;
}

float sampleGroundHeight(vec2 uv) {
    uv.y *= 2.0;
    uv.x += mod(uv.y, 2.0) < 1.0 ? 0.0 : 0.5;
    vec2 f = fract(uv);
    return smoothstep(0.5, 0.48, abs(f.x - 0.5)) * smoothstep(0.5, 0.48, abs(f.y - 0.5));
}

vec3 groundNormal(vec3 pos) {
    vec2 eps = vec2(0.005, 0.0);
    vec2 uv = pos.xz * 1.0;
    vec3 du = vec3(eps.x, sampleGroundHeight(uv + eps.xy) - sampleGroundHeight(uv), 0.0);
    vec3 dv = vec3(0.0, sampleGroundHeight(uv + eps.yx) - sampleGroundHeight(uv), eps.x);
    return normalize(mix(vec3(0.0, 1.0, 0.0), normalize(cross(dv, du)), 0.5));
}

float ground(vec3 ro, vec3 rd, float y) {
    return (y - ro.y) / rd.y;
}

vec3 groundColor(vec3 pos) {
    vec3 nor = groundNormal(pos);
    vec3 lightDir = normalize(kLightPos - pos);
    float d = length(kLightPos - pos);
    float atten = 1.0 / (d * d);
    vec3 viewDir = normalize(kCameraPos - pos);
    vec3 refDir = reflect(-viewDir, nor);
    vec3 halfDir = normalize(viewDir + lightDir);
    float dotNR = max(0.0, dot(nor, refDir));
    float dotNV = max(0.0, dot(nor, viewDir));
    float dotNL = max(0.0, dot(nor, lightDir));
    float dotLH = max(0.0, dot(lightDir, halfDir));
    vec3 diffuse = diffuseNormalizedDisneyBrdf(GROUND_COLOR, dotNV, dotNL, dotLH, 1.0);
    vec3 fresnel = schlickFresnel(vec3(0.0), dotNR);
    vec3 spec = 0.5 * raymarchLight(pos, refDir, 1e6) * fresnel;

    return spec + diffuse * dotNL * atten * kLightColor;
}

vec3 scene(vec3 ro, vec3 rd) {
    float gt = ground(ro, rd, 0.0);
    vec3 gc = gt > 0.0 ? groundColor(ro + gt * rd) : vec3(0.0);
    float rt;
    if (raymarch(ro, rd, gt > 0.0 ? gt : 1e6, rt)) {
        return raymarchColor(ro + rt * rd);
    }
    return raymarchLight(ro, rd, gt > 0.0 ? gt : 1e6) + gc;
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3((mouse.x * 2.0 - 1.0) * 10.0, mouse.y * 10.0 + 2.0, 10.0);

    kCameraPos = ro;
    kLightPos = ro;

    vec3 ta = vec3(0.0, 5.0, 0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = scene(ro, rd);

    gl_FragColor = vec4(pow(c, vec3(1.0 / 2.2)), 1.0);
}