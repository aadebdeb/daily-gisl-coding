precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

struct Surface {
    float t;
    vec3 pos;
    vec3 nor;
    vec3 diffColor;
    vec3 specColor;
    float diff;
    float spec;
};

#define GROUND_WIDTH 10.0

#define SPHERE_NUM 9
float SPHERE_RADIUSES[SPHERE_NUM];
vec3 SPHERE_POSITIONS[SPHERE_NUM];
void initConstants() {
    SPHERE_RADIUSES[0] = 3.0;
    SPHERE_RADIUSES[1] = 0.8;
    SPHERE_RADIUSES[2] = 1.2;
    SPHERE_RADIUSES[3] = 1.0;
    SPHERE_RADIUSES[4] = 0.7;
    SPHERE_RADIUSES[5] = 1.2;
    SPHERE_RADIUSES[6] = 0.6;
    SPHERE_RADIUSES[7] = 0.9;
    SPHERE_RADIUSES[8] = 1.0;
    SPHERE_POSITIONS[0] = vec3(0.0, SPHERE_RADIUSES[0], 0.0);
    SPHERE_POSITIONS[1] = vec3(3.2, SPHERE_RADIUSES[1], 2.8);
    SPHERE_POSITIONS[2] = vec3(-2.5, SPHERE_RADIUSES[2], 3.4);
    SPHERE_POSITIONS[3] = vec3(3.0, SPHERE_RADIUSES[3], -2.5);
    SPHERE_POSITIONS[4] = vec3(-3.0, SPHERE_RADIUSES[4], -2.5);
    SPHERE_POSITIONS[5] = vec3(1.0, 4.0, 4.3);
    SPHERE_POSITIONS[6] = vec3(-3.4, 5.2, 0.5);
    SPHERE_POSITIONS[7] = vec3(-0.9, 2.4, -4.5);
    SPHERE_POSITIONS[8] = vec3(4.7, 3.4, -0.9);
}

float mapSpheres(vec3 p) {
    float d = 1e8;
    for (int i = 0; i < SPHERE_NUM; i++) {
        d = min(d, length(p - SPHERE_POSITIONS[i]) - SPHERE_RADIUSES[i]);
    }
    return d;
}

float mapGround(vec3 p, float width) {
    p.xz = abs(p.xz) - 0.5 * width;
    return length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0);
}

float map(vec3 p) {
    float ds = mapSpheres(p);
    float dg = mapGround(p, GROUND_WIDTH);
    return min(ds, dg);
}

float ambientOcclusion(vec3 p, vec3 n, float step) {
    float ao = 1.0;
    float amp = 0.5;
    for (float i = 1.0; i <= 5.0; i += 1.0) {
        float t = i * step;
        float d = max(0.0, map(p + t * n));
        ao -= amp * (t - d) / t;
        amp *= 0.5;
    }
    return ao;
}

bool hitSphere(vec3 ro, vec3 rd, float r, vec3 offset, inout Surface surf) {
    ro -= offset;
    float a = dot(rd, rd);
    float b = 2.0 * dot(ro, rd);
    float c = dot(ro, ro) - r * r;

    float d = b * b - 4.0 * a * c;
    if (d < 0.0) {
        return false;
    }
    float sqrtD = sqrt(d);
    float t = (-b - sqrtD) / (2.0 * a);
    if (t > 0.0 && t < surf.t) {
        surf.t = t;
        surf.pos = ro + offset + t * rd;
        surf.nor = normalize(ro + t * rd);
        return true;
    }
    return false;
}

void hitGround(vec3 ro, vec3 rd, float width, inout Surface surf) {
    bool hit = false;
    float hw = 0.5 * width;
    float ty = -ro.y / rd.y;
    if (ty > 0.0 && ty < surf.t) {
        vec3 p = ro + ty * rd;
        if (abs(p.x) < hw && abs(p.z) < hw) {
            hit = true;
            surf.t = ty;
            surf.pos = p;
            surf.nor = vec3(0.0, 1.0, 0.0);
        }
    }
    float tpx = (hw - ro.x) / rd.x;
    if (tpx > 0.0 && tpx < surf.t) {
        vec3 p = ro + tpx * rd;
        if (p.y < 0.0 && abs(p.z) < hw) {
            hit = true;
            surf.t = tpx;
            surf.pos = p;
            surf.nor = vec3(1.0, 0.0, 0.0);
        }
    }
    float tmx = (-hw - ro.x) / rd.x;
    if (tmx > 0.0 && tmx < surf.t) {
        vec3 p = ro + tmx * rd;
        if (p.y < 0.0 && abs(p.z) < hw) {
            hit = true;
            surf.t = tmx;
            surf.pos = p;
            surf.nor = vec3(-1.0, 0.0, 0.0);
        }
    }
    float tpz = (hw - ro.z) / rd.z;
    if (tpz > 0.0 && tpz < surf.t) {
        vec3 p = ro + tpz * rd;
        if (p.y < 0.0 && abs(p.x) < hw) {
            hit = true;
            surf.t = tpz;
            surf.pos = p;
            surf.nor = vec3(0.0, 0.0, 1.0);
        }
    }
    float tmz = (-hw - ro.z) / rd.z;
    if (tmz > 0.0 && tmz < surf.t) {
        vec3 p = ro + tmz * rd;
        if (p.y < 0.0 && abs(p.x) < hw) {
            hit = true;
            surf.t = tmz;
            surf.pos = p;
            surf.nor = vec3(0.0, 0.0, -1.0);
        }
    }

    if (hit) {
        surf.diffColor = vec3(0.5);
        surf.specColor = vec3(0.1);
        surf.diff = 0.8;
        surf.spec = 1.0;
    }
}

#define MAX_DISTANCE 1e8
const vec3 LIGHT_UP = normalize(vec3(0.07, 1.0, 0.1));

bool hitObjects(vec3 ro, vec3 rd, inout Surface surf) {
    surf.t = MAX_DISTANCE;
    for (int i = 0; i < SPHERE_NUM; i++) {
        if (hitSphere(ro, rd, SPHERE_RADIUSES[i], SPHERE_POSITIONS[i], surf)) {
            surf.diffColor = vec3(0.5);
            surf.specColor = vec3(0.02);
            surf.diff = 1.0;
            surf.spec = 1.0;
        }
    }
    hitGround(ro, rd, GROUND_WIDTH, surf);
    return surf.t != MAX_DISTANCE;
}

vec3 fresnelSchlick(vec3 f0, float cosine) {
    return f0 + (1.0 - f0) * pow(1.0 - cosine, 5.0);
}

vec3 background(vec3 rd) {
    return mix(vec3(0.0, 0.0, 0.0), vec3(1.0, 0.15, 0.0), rd.y * 0.5 + 0.5);
}

vec3 getColor(vec3 ro, vec3 rd) {
    vec3 color = vec3(0.0);
    vec3 scale = vec3(1.0);
    Surface surf;
    for (int i = 0; i < 3; i++) {
        if (!hitObjects(ro, rd, surf)) {
            color += scale * background(rd);
            break;
        } else {
            vec3 diff = surf.diff * surf.diffColor * (dot(surf.nor, LIGHT_UP) * 0.5 + 0.5);
            float ao = ambientOcclusion(surf.pos, surf.nor, 0.1);
            color += scale * ao * diff;
        }

        if (surf.spec == 0.0) {
            break;
        }

        vec3 refDir = reflect(rd, surf.nor);
        float dotNR = clamp(dot(surf.nor, refDir), 0.0, 1.0);
        vec3 fresnel = fresnelSchlick(surf.specColor, dotNR);

        scale *= surf.spec * fresnel;

        ro = surf.pos + 0.01 * refDir;
        rd = refDir;
    }
    return color;
}

void main(void) {
    initConstants();

    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(
        20.0 * cos(-0.5 * time),
        5.0,
        8.0 * sin(-0.5 * time)
    );
    vec3 ta = vec3(0.0, 1.5, 0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = getColor(ro, rd);

    gl_FragColor = vec4(pow(c, vec3(1.0 / 2.2)), 1.0);
}