/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

float random(vec2 p){
    return fract(sin(dot(p,vec2(12.9898, 78.233))) * 43758.5453);
}

float valuenoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * f * (10.0 + f * (6.0 * f - 15.0));
    //vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(random(i), random(i + vec2(1.0, 0.0)), u.x),
        mix(random(i + vec2(0.0, 1.0)), random(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}


float fbm(vec2 p) {
    float res = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        res += amp * valuenoise(p);
        amp * 0.5;
        p *= rotate(0.03);
        p += vec2(34.43, 19.65);
        p *= 1.98;
    }
    return res;
}

float map(vec3 p) {
    p = mod(p, 4.0) - 2.0;
    return length(p) - 1.0;
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

float heightmap(vec2 uv) {
    return fbm(uv);
}

vec3 bumpmap(vec2 uv) {
    float d = 0.01;
    return normalize(vec3(
        heightmap(uv + vec2(d, 0.0)) - heightmap(uv - vec2(d, 0.0)),
        2.0 * d,
        heightmap(uv + vec2(0.0, d)) - heightmap(uv - vec2(0.0, d))
    ));
}

struct Light {
    vec3 pos;
    vec3 col;
};

Light[3] getLights() {
    Light lights[3];

    lights[0].pos =  vec3(15.0 * cos(time * -1.94), 4.0 * sin(time * 4.29), 15.0 * sin(time * 3.21));
    lights[0].col = vec3(1.0, 0.25, 0.25);
    lights[1].pos =  vec3(15.0 * cos(time * 1.43), 4.0 * sin(time * -3.72), 15.0 * sin(time * -2.12));
    lights[1].col = vec3(0.25, 1.0, 0.25);
    lights[2].pos =  vec3(15.0 * cos(time * 2.77), 4.0 * sin(time * 2.18), 15.0 * sin(time * -1.29));
    lights[2].col = vec3(0.25, 0.25, 1.0);    

    return lights;
}

vec3 ground(vec3 ro, vec3 rd, float h) {
    if (rd.y >= 0.0 || ro.y <= h) {
        return vec3(0.0);
    }
    float d = (h - ro.y) / rd.y;
    vec2 xz = ro.xz + d * rd.xz;

    vec3 p = vec3(xz.x, h, xz.y);

    vec3 lightPos = vec3(20.0 * cos(time), 0.0, 20.0 * sin(time));
    vec3 lightDir = normalize(lightPos - p);

    Light lights[3] = getLights();

    vec3 res = vec3(0.0);
    if (sin(xz.x * 2.0) * sin(xz.y * 2.0) > 0.0) {
        vec3 c = vec3(0.5);
        vec3 n = mix(vec3(0.0, 1.0, 0.0), bumpmap(xz * 1.5), 0.2);
        for (int i = 0; i < 3; i++) {
            float l = length(lights[i].pos - p);
            float atten = 1.0 - smoothstep(10.0, 15.0, l);
            vec3 lightDir = normalize(lights[i].pos - p);
            res += atten * c * lights[i].col * max(0.0, dot(lightDir, n));
        }
    } else {
        vec3 c = vec3(1.0);
        vec3 cs = vec3(1.0);
        vec3 n = vec3(0.0, 1.0, 0.0);
        vec3 ref = reflect(rd, n);
        for (int i = 0; i < 3; i++) {
            float l = length(lights[i].pos - p);
            float atten = 1.0 - smoothstep(10.0, 15.0, l);
            vec3 lightDir = normalize(lights[i].pos - p);
            res += atten * (c * lights[i].col * max(0.0, dot(lightDir, n)) + cs * pow(max(0.0, dot(ref, lightDir)), 8.0));
        }
    }

    return res;
    // vec3 c = sin(xz.x?) * sin(xz.y) > 0.0 ? vec3(1.0, 0.4, 0.8) : vec3(0.25, 0.4, 0.8);
    // vec3 n = mix(vec3(0.0, 1.0, 0.0), bumpmap(xz * 1.5), 0.2);


}

vec3 raymarch(vec3 ro, vec3 rd) {
    return ground(ro, rd, -5.0);
    vec3 p = ro;
    for (int i = 0; i < 64; i++) {
        float d = map(p);
        p += d * rd;
        if (d < 0.01) {
            vec3 n = calcNormal(p);
            return n * 0.5 + 0.5;
        }
    }
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec2 m = vec2((2.0 * mouse.x - 1.0) * 10.0, mouse.y * 50.0 - 5.0);

    vec3 ro = vec3(m.x, m.y, -30.0);
    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 2.0);

    vec3 c = raymarch(ro, rd);

    gl_FragColor = vec4(c, 1.0);
}