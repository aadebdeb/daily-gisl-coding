precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define PI 3.14159265359
// #define saturate(a) clamp(a, 0.0, 1.0)

#define RAYMARCH_ITERATIONS 48
#define SHADOW_LENGTH 3.0
#define SHADOW_ITERATIONS 8
#define DENSITY_INTENSITY 2.0
#define AMBIENT_INTENSITY 10.0
#define BACKGROUND_COLOR vec3(0.35, 0.5, 0.75)
#define BOUNDING_BOX_SIZE 6.0
#define BOUNDING_BOX_OFFSET vec3(0.0)

// 0: box, 1: sphere: 2: torus
#define DENSITY_BASIC_SHAPE 1

#define WITH_DIRECTIONAL_LIGHT
#define WITH_AMBIENT_LIGTHT

const vec3 DENSITY_COLOR = vec3(0.8, 0.9, 1.0);
const vec3 ABSORPTION_INTENSITY = vec3(0.5, 0.8, 0.7) * 0.5;
const vec3 DIRECTIONAL_LIGHT_DIR = normalize(vec3(0.5, 1.0, 0.5));
const vec3 DIRECTIONAL_LIGHT_COLOR = vec3(1.0, 1.0, 0.8) * 1.0;
const vec3 AMBIENT_LIGHT_DIR = normalize(vec3(0.0, -1.0, 0.0));
const vec3 AMBIENT_LIGHT_COLOR = vec3(0.5, 0.7, 1.0) * 0.2;

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

float random(vec4 x){
    return fract(sin(dot(x,vec4(12.9898, 78.233, 39.425, 27.196))) * 43758.5453);
}

float valuenoise(vec4 x) {
  vec4 i = floor(x);
  vec4 f = fract(x);

  vec4 u = f * f * (3.0 - 2.0 * f);

  return mix(
    mix(
      mix(
          mix(random(i + vec4(0.0, 0.0, 0.0, 0.0)), random(i + vec4(1.0, 0.0, 0.0, 0.0)), u.x),
          mix(random(i + vec4(0.0, 1.0, 0.0, 0.0)), random(i + vec4(1.0, 1.0, 0.0, 0.0)), u.x),
          u.y
      ),
      mix(
          mix(random(i + vec4(0.0, 0.0, 1.0, 0.0)), random(i + vec4(1.0, 0.0, 1.0, 0.0)), u.x),
          mix(random(i + vec4(0.0, 1.0, 1.0, 0.0)), random(i + vec4(1.0, 1.0, 1.0, 0.0)), u.x),
          u.y
      ),
      u.z
    ),
    mix(
      mix(
          mix(random(i + vec4(0.0, 0.0, 0.0, 1.0)), random(i + vec4(1.0, 0.0, 0.0, 1.0)), u.x),
          mix(random(i + vec4(0.0, 1.0, 0.0, 1.0)), random(i + vec4(1.0, 1.0, 0.0, 1.0)), u.x),
          u.y
      ),
      mix(
          mix(random(i + vec4(0.0, 0.0, 1.0, 1.0)), random(i + vec4(1.0, 0.0, 1.0, 1.0)), u.x),
          mix(random(i + vec4(0.0, 1.0, 1.0, 1.0)), random(i + vec4(1.0, 1.0, 1.0, 1.0)), u.x),
          u.y
      ),
      u.z
    ),
    u.w
  );
}

float fbm(vec4 x) {
    float sum = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        sum += amp * valuenoise(x);
        amp *= 0.5;
        x *= 2.01;
        x.xy *= rotate(0.65);
    }
    return sum;
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

float sampleDensity(vec3 p) {
    #if DENSITY_BASIC_SHAPE == 0
    float d = sdBox(p, vec3(2.5));
    #elif DENSITY_BASIC_SHAPE == 1
    float d= sdSphere(p, 3.0);
    #else
    float d = sdTorus(p, vec2(2.0, 1.5));
    #endif
    float n = fbm(vec4(p * 2.0 + 1000.0, time * 0.3)) * 1.5;
    d += n;
    return saturate(-d * 5.0);
}

vec4 raymarch(vec3 rayOrigin, vec3 rayDirection, float tmin, float tmax) {
    float raymarchSize = sqrt(3.0) * BOUNDING_BOX_SIZE / float(RAYMARCH_ITERATIONS);
    float shadowSize = SHADOW_LENGTH / float(SHADOW_ITERATIONS);
    float densityScale = DENSITY_INTENSITY * raymarchSize;
    vec3 shadowScale = ABSORPTION_INTENSITY * shadowSize;
    int maxRaymarchIteration = int((tmax - tmin) / raymarchSize) + 1;
    vec3 position = rayOrigin + tmin * rayDirection - BOUNDING_BOX_OFFSET;
    vec3 rayStep = rayDirection * raymarchSize;
    vec3 shadowStep = DIRECTIONAL_LIGHT_DIR * shadowSize;
    vec3 color = vec3(0.0);
    float transmittance = 1.0;
    for (int ri = 0; ri < RAYMARCH_ITERATIONS; ri++) {
        if (ri >= maxRaymarchIteration) {
            break;
        }
        float density = sampleDensity(position);
        if (density > 0.001) {
            density = saturate(density * densityScale);
            #ifdef WITH_DIRECTIONAL_LIGHT
            vec3 shadowPosition = position;
            float shadowDensity = 0.0;
            for (int si = 0; si < SHADOW_ITERATIONS; si++) {
                shadowPosition += shadowStep;
                shadowDensity +=  sampleDensity(shadowPosition);
            }
            vec3 attenuation = exp(-shadowDensity * shadowScale); // attenuated by absorption
            vec3 attenuatedLight = DIRECTIONAL_LIGHT_COLOR * attenuation;
            color += DENSITY_COLOR * attenuatedLight * transmittance * density; // out-scattering
            #endif
            #ifdef WITH_AMBIENT_LIGTHT
            {
                float shadowDensity = 0.0;
                vec3 shadowPosition = position + AMBIENT_LIGHT_DIR * 0.05;
                shadowDensity += sampleDensity(shadowPosition) * 0.05;
                shadowPosition = position + AMBIENT_LIGHT_DIR * 0.1;
                shadowDensity += sampleDensity(shadowPosition) * 0.05;
                shadowPosition = position + AMBIENT_LIGHT_DIR * 0.2;
                shadowDensity += sampleDensity(shadowPosition) * 0.1;
                float attenuation = exp(-shadowDensity * AMBIENT_INTENSITY); // attenuated by absorption
                vec3 attenuatedLight = AMBIENT_LIGHT_COLOR * attenuation;
                color += DENSITY_COLOR * attenuatedLight * transmittance * density; // out-scattering
            }
            #endif
            transmittance *= 1.0 - density;
        }
        if (transmittance < 0.001) {
            break;
        }
        position += rayStep;
    }
    return vec4(color, 1.0 - transmittance);
}

bool aabb(vec3 ro, vec3 rd, vec3 corner0, vec3 corner1, inout float tmin, inout float tmax) {
    for (int i = 0; i < 3; i++) {
        float t0 = (corner0[i] - ro[i]) / rd[i];
        float t1 = (corner1[i] - ro[i]) / rd[i];
        tmin = max(tmin, min(t0, t1));
        tmax = min(tmax, max(t0, t1));
        if (tmax <= tmin) {
            return false;
        }
    }
    return true;
}

vec3 background(vec3 rd) {
    float d = max(0.0, dot(rd, DIRECTIONAL_LIGHT_DIR));
    return mix(BACKGROUND_COLOR, DIRECTIONAL_LIGHT_COLOR, pow(d, 20.0));
}

vec3 cameraDir(vec3 ro, out vec3 ta, vec2 st) {
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);
    return rd;
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec2 m = mouse * 2.0 - 1.0;
    vec3 ro = vec3(7.0 * cos(m.x * PI), m.y * 5.0, 7.0 * sin(m.x * PI));

    vec3 ta = vec3(0.0);
    vec3 rd = cameraDir(ro, ta, st);

    vec3 color = background(rd);
    vec3 corner0 = vec3(-0.5 * BOUNDING_BOX_SIZE + BOUNDING_BOX_OFFSET);
    vec3 corner1 = vec3(0.5 * BOUNDING_BOX_SIZE + BOUNDING_BOX_OFFSET);
    float tmin = 0.0;
    float tmax = 1e6;
    if (aabb(ro, rd, corner0, corner1, tmin, tmax)) {
        vec4 res = raymarch(ro, rd, tmin, tmax);
        color = res.xyz + (1.0 - res.w) * color;
    }

    color = pow(color, vec3(1.0 / 2.2));
    gl_FragColor = vec4(color, 1.0);
}