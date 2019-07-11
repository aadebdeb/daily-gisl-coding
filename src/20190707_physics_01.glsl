precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define TWO_PI 6.28318530718

const float GRAVITY = -9.8 * 2.5;

#define MAX_DISTANCE 1e8
const vec3 LIGHT_UP = normalize(vec3(0.1, 1.0, 0.2));

#define PATHWAY_WIDTH 3.0
#define SPHERE_RADIUS 2.0

#define SPHERE_NUM 16.0
#define HORIZONTAL_SPEED 8.0
#define NON_FALL_TIME 15.0
#define FALL_TIME 3.0
const float SIM_TIME = NON_FALL_TIME + FALL_TIME;

struct Surface {
    float t;
    vec3 pos;
    vec3 nor;
    vec3 diffColor;
    vec3 specColor;
    float diff;
    float spec;
};

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

float getFreeFallPosition(float t, float v0) {
    return 0.5 * GRAVITY * t * t + v0 * t + 0.0;
}

float distSpheres(vec3 p, float r) {
    float d = MAX_DISTANCE;
    for (float i = 0.0; i < SPHERE_NUM; i += 1.0) {
        float tm = mod(time + i * SIM_TIME / SPHERE_NUM, SIM_TIME);
        vec3 offset = vec3(
            HORIZONTAL_SPEED * (tm - NON_FALL_TIME),
            (tm < NON_FALL_TIME ? 0.0 : getFreeFallPosition(tm - NON_FALL_TIME, 0.0)) + r,
            0.0
        );
        d = min(d, length(p - offset) - r);
    }
    return d;
}

float distPathway(vec3 p, float width) {
    p.z = abs(p.z) - 0.5 * width;
    float d1 = length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0);
    return d1;
}

float map(vec3 p) {
    float ds = distSpheres(p, SPHERE_RADIUS);
    float dp = distPathway(p, PATHWAY_WIDTH);
    return min(ds, dp);
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

void hitSpheres(vec3 ro, vec3 rd, float r, inout Surface surf) {
    for (float i = 0.0; i < SPHERE_NUM; i += 1.0) {
        float tm = mod(time + i * SIM_TIME / SPHERE_NUM, SIM_TIME);
        vec3 offset = vec3(
            HORIZONTAL_SPEED * (tm - NON_FALL_TIME),
            (tm < NON_FALL_TIME ? 0.0 : getFreeFallPosition(tm - NON_FALL_TIME, 0.0)) + r,
            0.0
        );
        if (hitSphere(ro, rd, SPHERE_RADIUS, offset, surf)) {
            vec3 objectPos = surf.pos - offset;
            objectPos.xy *= rotate(-2.0 * TWO_PI * SPHERE_RADIUS / HORIZONTAL_SPEED * time);
            if (sin(objectPos.y * 5.0) > 0.0) {
                surf.diffColor = vec3(0.8);
                surf.specColor = vec3(0.04);
                surf.diff = 1.0;
                surf.spec = 0.5;
            } else {
                surf.diffColor = vec3(0.1);
                surf.specColor = vec3(0.08);
                surf.diff = 0.5;
                surf.spec = 0.5;
            }
        }
    }
}

void hitPathway(vec3 ro, vec3 rd, float width, inout Surface surf) {
    float hw = 0.5 * width;
    bool hit = false;
    float ty = -ro.y / rd.y;
    if (ty > 0.0 && ty < surf.t) {
        vec3 p = ro + ty * rd;
        if (p.x < 0.0 && p.z < hw && p.z > -hw) {
            hit = true;
            surf.t = ty;
            surf.pos = p;
            surf.nor = vec3(0.0, 1.0, 0.0);
        }
    }
    float tx = -ro.x / rd.x;
    if (tx > 0.0 && tx < surf.t) {
        vec3 p = ro + tx * rd;
        if (p.y < 0.0 && p.z < hw && p.z > -hw) {
            hit = true;
            surf.t = tx;
            surf.pos = p;
            surf.nor = vec3(1.0, 0.0, 0.0);
        }
    }
    float tpz = (hw - ro.z) / rd.z;
    if (tpz > 0.0 && tpz < surf.t) {
        vec3 p = ro + tpz * rd;
        if (p.x < 0.0 && p.y < 0.0) {
            hit = true;
            surf.t = tpz;
            surf.pos = p;
            surf.nor = vec3(0.0, 0.0, 1.0);
        }
    }
    float tmz = (-hw - ro.z) / rd.z;
    if (tmz > 0.0 && tmz < surf.t) {
        vec3 p = ro + tmz * rd;
        if (p.x < 0.0 && p.y < 0.0) {
            hit = true;
            surf.t = tmz;
            surf.pos = p;
            surf.nor = vec3(0.0, 0.0, -1.0);
        }
    }

    if (hit) {
        surf.diffColor = vec3(0.8);
        surf.specColor = vec3(0.2);
        surf.diff = 1.0;
        surf.spec = 0.5;
    }
}

bool hitObjects(vec3 ro, vec3 rd, inout Surface surf) {
    surf.t = MAX_DISTANCE;
    hitSpheres(ro, rd, SPHERE_RADIUS, surf);
    hitPathway(ro, rd, PATHWAY_WIDTH, surf);
    return surf.t != MAX_DISTANCE;
}

vec3 background(vec3 rd) {
    return mix(vec3(0.0), vec3(0.05, 0.65, 0.8), rd.y * 0.5 + 0.5);
}

vec3 fresnelSchlick(vec3 f0, float cosine) {
    return f0 + (1.0 - f0) * pow(1.0 - cosine, 5.0);
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
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(10.0, 10.0, 20.0);
    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 2.0);

    vec3 c = getColor(ro, rd);

    gl_FragColor = vec4(pow(c, vec3(1.0 / 2.2)), 1.0);
}