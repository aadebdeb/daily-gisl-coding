#define PI 3.14159265359
#define INV_PI 0.31830988618
#define TAU 6.28318530718
#define INV_GAMMA 0.45454545454

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

struct Surface {
  vec3 position;
  vec3 normal;
  vec3 diffuse;
  vec3 specular;
  vec3 emissive;
  float roughness;
  float metallic;
};

mat2 rotate(float r) {
  float c = cos(r);
  float s = sin(r);
  return mat2(c, s, -s, c);
}

float sdRoundBox(vec3 p, vec3 b, float r) {
  p.xy *= rotate(time * 0.15);
  p.xz *= rotate(time * 0.2);
  p = abs(p) - b;
  return length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0) - r;
}

float map(vec3 p) {
  return sdRoundBox(p, vec3(2.0), 0.5);
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

const vec3 LightColor = vec3(1.0) * 4.0;

float diffuseLambertNormalized(float dotNL) {
    return max(0.0, dotNL) * INV_PI;
}

float specularBlinnPhongNormalized(float dotNH, float m) {
    float n = (m + 2.0) / TAU;
    return n * pow(max(0.0, dotNH), m);
}

vec3 lightSurface(vec3 rd, Surface s) {
  vec3 lightPos = vec3(8.0 * cos(time * 3.0), 3.0 * sin(time * 1.5), 8.0 * sin(time * 3.0));
  vec3 lightDir = normalize(lightPos - s.position);
  float dotNL = dot(s.normal, lightDir);
  vec3 h = normalize(-rd + lightDir);
  float dotNH = dot(s.normal, h);
  vec3 dif = s.diffuse * LightColor * diffuseLambertNormalized(dotNL);
  vec3 spe = s.specular * LightColor * specularBlinnPhongNormalized(dotNL, 1.0 / (s.roughness * 0.99 + 0.01));
  return (1.0 - s.metallic) * dif + s.metallic * spe + s.emissive;
}

vec3 ground(vec3 ro, vec3 rd, float h) {
  if (ro.y < 0.0 || rd.y > 0.0) {
    return vec3(0.0);
  }
  float d = (h - ro.y) / rd.y;
  vec2 xz = ro.xz + d * rd.xz;

  vec3 p = vec3(xz.x, h, xz.y);

  Surface surf1;
  surf1.position = p;
  surf1.normal = vec3(0.0, 1.0, 0.0);
  surf1.diffuse = vec3(0.05, 0.07, 0.1);
  surf1.specular = vec3(0.2);
  surf1.emissive = vec3(0.0);
  surf1.roughness = 0.8;
  surf1.metallic = 0.1;

  Surface surf2;
  surf2.position = p;
  surf2.normal = vec3(0.0, 1.0, 0.0);
  surf2.diffuse = vec3(0.5);
  surf2.specular = vec3(0.45, 0.35, 0.2);
  surf2.emissive = vec3(0.0);
  surf2.roughness = 0.2;
  surf2.metallic = 0.8;

  return sin(xz.x * 5.0) * sin(xz.y * 5.0) > 0.0 ? 
    lightSurface(rd, surf1) :
    lightSurface(rd, surf2);
}

vec3 raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;
    for (int i = 0; i < 64; i++) {
        float d = map(p);
        p += d * rd;
        if (d < 0.01) {
            vec3 n = calcNormal(p);

            Surface surf;
            float t = sin(p.y * 10.0);
            if (t < 0.8) {
              surf.position = p;
              surf.normal = n;
              surf.diffuse = vec3(0.2);
              surf.specular = vec3(0.5);
              surf.roughness = 0.1;
              surf.metallic = 0.9;
              surf.emissive = vec3(0.0);
            } else {
              surf.position = p;
              surf.normal = n;
              surf.diffuse = vec3(0.0);
              surf.specular = vec3(0.0);
              surf.roughness = 0.5;
              surf.metallic = 0.5;
              surf.emissive = mix(
                vec3(0.2, 0.1, 0.15),
                vec3(1.0, 0.8, 0.85),
                smoothstep(0.82, 0.95, t)
              );
            }
            return lightSurface(rd, surf);
        }
    }
    return ground(ro, rd, -5.0);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(0.0, 0.0, -12.0);
    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = raymarch(ro, rd);

    c = pow(c, vec3(INV_GAMMA));

    gl_FragColor = vec4(c, 1.0);
}