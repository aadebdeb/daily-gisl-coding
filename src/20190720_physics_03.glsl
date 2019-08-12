precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define HALF_PI 1.57079632679
#define PI 3.14159265359
#define TWO_PI 6.28318530718

#define MAX_DISTANCE 1e3
const vec3 LIGHT_UP = normalize(vec3(0.1, 1.0, 0.2));

#define SPHERE_RADIUS 2.5
#define GROUND_RADIUS 10.0

const float SPHERE_MAX_ROT = 0.8 * PI;
#define SPHERE_SPEED 1.5

#define SPHERE_NUM 3
vec3 SPHERE_SPECS[SPHERE_NUM];
void initConstants() {
    SPHERE_SPECS[0] = vec3(0.59, 0.52, 0.02);
    SPHERE_SPECS[1] = vec3(0.48, 0.52, 0.57);
    SPHERE_SPECS[2] = vec3(0.62, 0.18, 0.01);
}

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

float distSpheres(vec3 p, float r) {
    float d = MAX_DISTANCE;
    for (int i = 0; i < SPHERE_NUM; i++) {
        float angle = SPHERE_MAX_ROT * sin(SPHERE_SPEED * (time + 0.5 * float(i)));
        vec3 offset = vec3(
            (GROUND_RADIUS - SPHERE_RADIUS) * sin(angle),
            -(GROUND_RADIUS - SPHERE_RADIUS) * cos(angle),
            0.0
        );
        if (abs(angle) > HALF_PI) {
            offset.x = sign(angle) * (GROUND_RADIUS - SPHERE_RADIUS);
        }
        offset.xz *= rotate(0.2 * time + 2.0 * float(i));
        d = min(d, length(p - offset) - r);
    }
    return d;
}

float sdRect(vec2 p, vec2 r) {
    p = abs(p) - r;
    return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

float distGround(vec3 p) {
    return max(p.y, -length(p) + GROUND_RADIUS);
}

float map(vec3 p) {
    float ds = distSpheres(p, SPHERE_RADIUS);
    float dg = distGround(p);
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

void hitSpheres(vec3 ro, vec3 rd, float r, inout Surface surf) {
    for (int i = 0; i < SPHERE_NUM; i++) {
        float angle = SPHERE_MAX_ROT * sin(SPHERE_SPEED * (time + 0.5 * float(i)));
        vec3 offset = vec3(
            (GROUND_RADIUS - SPHERE_RADIUS) * sin(angle),
            -(GROUND_RADIUS - SPHERE_RADIUS) * cos(angle),
            0.0
        );
        if (abs(angle) > HALF_PI) {
            offset.x = sign(angle) * (GROUND_RADIUS - SPHERE_RADIUS);
        }
        offset.xz *= rotate(0.2 * time + 2.0 * float(i));
        if (hitSphere(ro, rd, r, offset, surf)) {
            surf.diffColor = vec3(1.0);
            surf.specColor = SPHERE_SPECS[i];
            surf.diff = 0.0;
            surf.spec = 1.0;
        }
    }
}

vec3 calcGroundNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        distGround(p + vec3(d, 0.0, 0.0)) - distGround(p - vec3(d, 0.0, 0.0)),
        distGround(p + vec3(0.0, d, 0.0)) - distGround(p - vec3(0.0, d, 0.0)),
        distGround(p + vec3(0.0, 0.0, d)) - distGround(p - vec3(0.0, 0.0, d))
    ));
}


void hitGround(vec3 ro, vec3 rd, inout Surface surf) {
    float t = max(0.0, -ro.y / rd.y);
    vec3 p = ro + t * rd;
    for (int i = 0; i < 48; i++) {
        float d = distGround(p);
        t += d;
        p += d * rd;
        if (t > surf.t) break;
        if (d < 0.01) {
            surf.t = t;
            surf.pos = p;
            surf.nor = calcGroundNormal(p);
            surf.diffColor = vec3(0.98, 0.82, 0.94);
            surf.specColor = vec3(0.5);
            surf.diff = 0.8;
            surf.spec = 0.2;
            break;
        }
    }
}

bool hitObjects(vec3 ro, vec3 rd, inout Surface surf) {
    surf.t = MAX_DISTANCE;
    hitSpheres(ro, rd, SPHERE_RADIUS, surf);
    hitGround(ro, rd, surf);
    return surf.t != MAX_DISTANCE;
}

vec3 background(vec3 rd) {
    return mix(vec3(0.1), vec3(0.8), rd.y * 0.5 + 0.5);
}

vec3 fresnelSchlick(vec3 f0, float cosine) {
    return f0 + (1.0 - f0) * pow(1.0 - cosine, 5.0);
}

vec3 getColor(vec3 ro, vec3 rd) {
    vec3 color = vec3(0.0);
    vec3 scale = vec3(1.0);
    Surface surf;
    for (int i = 0; i < 4; i++) {
        if (!hitObjects(ro, rd, surf)) {
            color += scale * background(rd);
            break;
        } else {
            vec3 diff = surf.diff * surf.diffColor * (dot(surf.nor, LIGHT_UP) * 0.5 + 0.5);
            float ao = ambientOcclusion(surf.pos, surf.nor, 0.15);
            color += scale * ao * diff;
        }

        if (surf.spec == 0.0) {
            break;
        }

        vec3 refDir = reflect(rd, surf.nor);
        float dotNR = clamp(dot(surf.nor, refDir), 0.0, 1.0);
        vec3 fresnel = fresnelSchlick(surf.specColor, dotNR);

        scale *= surf.spec * fresnel;

        ro = surf.pos + 0.02 * refDir;
        rd = refDir;
    }
    return color;
}

void main(void) {
    initConstants();

    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(0.0, 15.0, 20.0);
    vec3 ta = vec3(0.0, -0.2 * GROUND_RADIUS, 0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = getColor(ro, rd);

    gl_FragColor = vec4(pow(c, vec3(1.0 / 2.2)), 1.0);
}