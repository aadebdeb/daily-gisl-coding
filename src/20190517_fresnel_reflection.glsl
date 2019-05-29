/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define INV_PI 0.31830988618
// #define saturate(x) clamp(x, 0.0, 1.0)

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float map(vec3 p) {
    p.y -= time * 5.0;
    p = mod(p, 10.0) - 5.0;
    return length(p) - 0.3;
}

vec3 fresnelSchlick(vec3 f0, vec3 f90, float cosine) {
    return f0 + (f90 - f0) * pow(1.0 - cosine, 5.0);
}

const vec3 LIGHT_DIR = normalize(vec3(0.0, 1.0, 0.0));
const vec3 LIGHT_COLOR = vec3(1.0) * 3.0;

vec3 getSkyColor(vec3 rd) {
    return mix(vec3(0.5, 0.5, 1.0), vec3(1.0, 0.8, 0.5), rd.y * 0.5 + 0.5);
}

bool raymarch(vec3 ro, vec3 rd, float tmax) {
    vec3 p = ro;
    float t = 0.0;
    for (int i = 0; i < 64; i++) {
        float d = map(p);
        p += d * rd;
        t += d;
        if (t > tmax) {
            return false;
        }
        if (d < 0.01) {
            return true;
        }
    }
    return false;
}


bool raymarch(vec3 ro, vec3 rd) {
    return raymarch(ro, rd, 1e6);
}

vec3 getRaymarchColor(bool hit, vec3 rd) {
    return hit ? vec3(2.0) : getSkyColor(rd);
}

vec3 getRaymarchColor(vec3 ro, vec3 rd) {
    return getRaymarchColor(raymarch(ro, rd), rd);
}

#define DIFFUSE_COLOR vec3(0.0, 0.045, 0.065)
#define SPECULAR_COLOR vec3(0.8, 0.8, 1.0)

vec3 shadeSurface(vec3 pos, vec3 normal, vec3 viewDir, vec3 lightDir) {
    vec3 refDir = reflect(-viewDir, normal);
    float dotNV = saturate(dot(normal, viewDir));
    float dotNL = saturate(dot(normal, lightDir));
    float dotNR = saturate(dot(normal, refDir));

    vec3 f0 = vec3(0.0);
    vec3 f90 = vec3(0.5);

    vec3 fresnelLight = fresnelSchlick(f0, f90, dotNL);
    vec3 fresnelRef = fresnelSchlick(f0, f90, dotNV);

    vec3 diffColor = (1.0 - fresnelLight) * DIFFUSE_COLOR;
    vec3 specColor = SPECULAR_COLOR * fresnelRef;

    vec3 diffuse = diffColor * INV_PI * dotNL * LIGHT_COLOR;
    vec3 specular = specColor * getRaymarchColor(pos, refDir);

    return diffuse + specular;
}

bool hitSphere(vec3 ro, vec3 rd, float r, inout float t) {
    float a = dot(rd, rd);
    float b = 2.0 * dot(ro, rd);
    float c = dot(ro, ro) - r * r;

    float d = b * b - 4.0 * a * c;
    if (d < 0.0) {
        return false;
    }
    float sqrtD = sqrt(d);
    float tmin = (-b - sqrtD) / (2.0 * a);
    if (t > tmin) {
        t = tmin;
        return true;
    }
    return false;
}

bool hitPlane(vec3 ro, vec3 rd, float y, inout float t) {
    if (rd.y == 0.0) {
        return false;
    }
    float pt = (y - ro.y) / rd.y;
    if (pt > 0.0 && pt < t) {
        t = pt;
        return true;
    }
    return false;
}

#define MAX_RAYTRACE_DISTNACE 1e6
#define SPHERE_RADIUS 5.0

float raytraceDist(vec3 p) {
    float sd = length(p - vec3(0.0, SPHERE_RADIUS, 0.0)) - SPHERE_RADIUS;
    float pd = p.y;
    return min(sd, pd);
}

float ambientocclusion(vec3 ro, vec3 rd) {
    float res = 1.0;
    float sd = 1.0;
    float amp = 0.5;
    for (int i = 1; i <= 5; i++) {
        float d = sd * float(i);
        float s = max(0.0, raytraceDist(ro + d * rd));
        res -= amp * (d - s) / d;
        amp *= 0.5;
    }
    return res;
}

vec3 raytrace(vec3 ro, vec3 rd) {
    float t = MAX_RAYTRACE_DISTNACE;
    vec3 sphereOffset = vec3(0.0, SPHERE_RADIUS, 0.0);
    vec3 position;
    vec3 normal;
    if (hitSphere(ro - sphereOffset, rd, SPHERE_RADIUS, t)) {
        position = ro + t * rd;
        normal = normalize(position);
    }
    if (hitPlane(ro, rd, 0.0, t)) {
        position = ro + t * rd;
        normal = vec3(0.0, 1.0, 0.0);
    }

    bool hit = raymarch(ro, rd, t);
    if (hit) {
        return vec3(2.0);
    }
    if (t != MAX_RAYTRACE_DISTNACE) {
        return shadeSurface(position, normal, -rd, LIGHT_DIR) * ambientocclusion(position, normal);
    }
    return getRaymarchColor(hit, rd);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    float camDist = 30.0 + 20.0 * sin(time * 0.3);
    float camAng = -time * 0.5;
    float camH = 20.0 + 19.0 * sin(time * 0.2);

    vec3 ro = vec3(camDist * cos(camAng), camH, camDist * sin(camAng));
    vec3 ta = vec3(0.0, SPHERE_RADIUS, 0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = raytrace(ro, rd);

    gl_FragColor = vec4(pow(c, vec3(1.0 / 2.2)), 1.0);
}