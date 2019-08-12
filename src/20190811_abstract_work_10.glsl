precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

const float PI = acos(-1.0);

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(2.0 * PI * (t * c + d));
}

float random(float x){
    return fract(sin(x * 12.9898) * 43758.5453);
}

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

float map(vec3 p) {
    p.x += sin(2.0 * p.y + 2.0 * time) * 2.0 * exp(-10.0 * fract(time));
    for (float i = 0.0; i < 5.0; i++) {
        p.xy *= rotate(10.0 * sin(i * 134.23));
        p.zy *= rotate(10.0 * sin(i * 432.13));
        p += (i + 1.0) * 0.1 * sin(0.5 * vec3(5.21, 4.32, -4.32) * p + 2.0 * time);
        p = p.yzx;
    }
    return length(p) - 3.0;
}

vec3 calcNormal(vec3 p) {
    float d = 0.002;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

vec3 lightDir = normalize(vec3(0.0, 1.0, 0.0));

vec3 schlickFresnel(vec3 f90, float cosine) {
    return f90 + (1.0 - f90) * pow(1.0 - cosine, 5.0);
}

vec3 raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;
    for (int i = 0; i < 96; i++) {
        float d = map(p);
        p += d * rd;
        if (d < 0.001) {
            vec3 n = calcNormal(p);
            float dotNL = dot(n, lightDir);
            float dotNE = dot(n, -rd);
            vec3 fresnel =schlickFresnel(vec3(0.0), clamp(dotNE, 0.0, 1.0));
            vec3 diffuse = vec3(1.0) * (0.5 * dotNL + 0.5);
            return mix(
                diffuse,
                palette(3.0 * (2.0 * dotNL + 2.0 * dotNE), vec3(0.0), vec3(1.0), vec3(1.0, 1.7, 2.1), vec3(0.0, 0.33, 0.67)),
                fresnel
            );
        }
    }
    return vec3(0.9);
}

#define SWITCH_TIME 4.0
void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    float sw = smoothstep(0.5, 1.0, mod(time, SWITCH_TIME) / SWITCH_TIME) > 1.0 - gl_FragCoord.y / resolution.y ? 1.0 : 0.0;
    float timeOffset = 100.0 * random(floor(time / SWITCH_TIME) + sw);

    vec3 ro = vec3(
        8.0 * cos(0.3 * time + timeOffset),
        2.0 * sin(0.5 * time + timeOffset),
        8.0 * sin(0.3 * time + timeOffset)
    );

    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = raymarch(ro, rd);
    gl_FragColor = vec4(pow(c, vec3(1.0 / 2.2)), 1.0);
}