/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

vec3 hsv2rgb(float h, float s, float v) {
    h = mod(h, 360.0);
    if (s == 0.0) {
        return vec3(0.0, 0.0, 0.0);
    }
    float c = v * s;
    float i = h / 60.0;
    float x = c * (1.0 - abs(mod(i, 2.0) - 1.0)); 
    return vec3(v - c) + (i < 1.0 ? vec3(c, x, 0.0) : 
        i < 2.0 ? vec3(x, c, 0.0) :
        i < 3.0 ? vec3(0.0, c, x) :
        i < 4.0 ? vec3(0.0, x, c) :
        i < 5.0 ? vec3(x, 0.0, c) :
        vec3(c, 0.0, x));
}

float random(vec2 x){
    return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

float valuenoise(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(random(i), random(i + vec2(1.0, 0.0)), u.x),
        mix(random(i + vec2(0.0, 1.0)), random(vec2(i + vec2(1.0, 1.0))), u.x),
        u.y
    );
}

float sdRect(vec2 p, vec2 r) {
    p = abs(p) - r;
    return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
} 

float map(vec3 p) {
    vec2 idx = floor(p.xz / 20.0);
    p.xz = mod(p.xz, 20.0) - 10.0;
    return max(p.y - random(idx) * 25.0, sdRect(p.xz, vec2(5.0)));
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

float linearFog(float d, float start, float end) {
    return clamp((end - d) / (end - start), 0.0, 1.0);
}

float exp2Fog(float d, float density) {
    float dd = d * density;
    return exp(-dd * dd);
}

#define MAX_RAYMARCH_LENGTH 300.0

float raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;
    float t = 0.0;
    for (int i = 0; i < 128; i++) {
        float d = map(p) * 0.3;
        p += d * rd;
        t += d;
        if (d < 0.01) {
            return t;
        }
        if (t >= MAX_RAYMARCH_LENGTH) {
            return MAX_RAYMARCH_LENGTH;
        }
    }
    return MAX_RAYMARCH_LENGTH;
}

float plane(vec3 ro, vec3 rd, float height) {
    return (height - ro.y) / rd.y;
}

float getFogHeight(vec3 p) {
    return valuenoise(p.xz * 0.05 + vec2(time * 0.1)) * 10.0;
}

float noisemap(vec3 p) {
    return p.y - valuenoise(p.xz * 0.05 + vec2(time * 0.1)) * 10.0;
}

float raymarchFog(vec3 ro, vec3 rd) {
    vec3 p = ro;
    float t = 0.0;
    for (int i = 0; i < 32; i++) {
        float h = getFogHeight(p);
        if (p.y < h) {
            return t;
        }
        float d = p.y - h;
        p += d * rd;
        t += d;
        if (d < 0.1) {
            return t;
        }
    }
    return 1000.0;
}

#define FOG_COLOR vec3(0.3)

vec3 surfaceColor(vec3 pos, vec3 normal) {
    if (abs(dot(normal, vec3(0.0, 1.0, 0.0))) > 0.99) {
        return vec3(0.0);
    }
    vec2 idx = floor(pos.xz / 20.0);
    // vec3 c = hsv2rgb(floor((length(idx * 300.0) - time * 500.0) / 60.0) * 6.0, 1.0, 1.0);

    vec3 c = hsv2rgb(pos.y * 10.0 - time * 100.0, 1.0, 1.0);
    return mix(vec3(0.0), 3.0 * c, pow(sin(pos.y * 2.0) * 0.5 + 0.5, 200.0));
} 

vec3 getColor(vec3 ro, vec3 rd) {
    float t = raymarch(ro, rd);

    if (t >= MAX_RAYMARCH_LENGTH) {
        return FOG_COLOR;
    }

    vec3 p = ro + t * rd;
    vec3 n = calcNormal(p);
    vec3 c = n * 0.5 + 0.5;
    c = surfaceColor(p, n);

    float ft = raymarchFog(ro, rd);
    c = mix(FOG_COLOR, c, linearFog(t, 0.5 * MAX_RAYMARCH_LENGTH, 0.9 * MAX_RAYMARCH_LENGTH));
    // c = mix(FOG_COLOR, c, exp2Fog(t, 0.005));
    c = mix(FOG_COLOR, c, exp(-0.1 * max(0.0, t - ft)));


    return c;
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec2 m = (mouse * 2.0 - 1.0);

    vec3 ro = vec3(100.0 * m.x, 50.0, 100.0 *m.y);
    // vec3 ro = vec3(50.0, 10.0, 50.0);
    vec3 ta = vec3(0.0, -30.0, 0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 color = getColor(ro, rd);

    gl_FragColor = vec4(pow(color, vec3(1.0 / 2.2)), 1.0);
}