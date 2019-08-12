precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

const float PI = acos(-1.0);

float TIME_STEP;

float random(float x){
    return fract(sin(x * 12.9898) * 43758.5453);
}

vec3 random3(float x) {
    return fract(sin(x * vec3(12.9898, 51.431, 29.964)) * vec3(43758.5453, 71932.1354, 39215.4221));
}

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(2.0 * PI * (c * t + d));
}

float sdRect(vec2 p, vec2 r) {
    p = abs(p) - r;
    return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

float sdBox(vec3 p, vec3 b) {
    p = abs(p) - b;
    return length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0);
}

float map(vec3 p) {
    vec3 q = p;
    p = mod(p, 50.0) - 25.0;
    float d = 1e8;
    float s = 1.0;
    for (float i = 1.0; i <= 5.0; i++) {
        p = abs(p);
        p -= 10.0 + 5.0 * random3(i + 423.9 + TIME_STEP);
        vec3 size = 3.0 * random3(i + 323.3 +TIME_STEP);
        d = min(d, sdBox(p, size) / s);
        float ss = 1.0 + 0.5 * random(i + 143.32 + TIME_STEP);
        p *= ss;
        s *= ss;
    }
    return max(d, -sdRect(q.xy, vec2(1.0)));
}

vec3 calcNormal(vec3 p) {
    float d = 0.001;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

vec3 raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;
    for (int i = 0; i < 128; i++) {
        float d = map(p);
        p += d * rd;
        if (d < 0.002) {
            float d = length(calcNormal(p + 0.01) - calcNormal(p - 0.01));
            if (d > 0.01) {
                return 2.0 * palette(random(TIME_STEP), vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.33, 0.67));
            } else {
                vec3 n = calcNormal(p);

                vec3 ld = normalize(ro - p);
                vec3 hd = normalize(-rd + ld);
                vec3 diff = vec3(0.1) * clamp(dot(n, ld), 0.0, 1.0);
                vec3 spec = vec3(0.5, 0.5, 0.65) * pow(clamp(dot(n, hd), 0.0, 1.0), 32.0);

                return diff + spec + 0.1;
            }
        }
    }
    return vec3(0.05);
}

void main(void) {
    TIME_STEP = floor(5.0 * time);

    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    float r = random(atan(st.y, st.x) + time);

    vec3 ro = vec3(0.0, 0.0, - 30.0 * time);
    vec3 ta = vec3(0.0, 0.0, ro.z - 10.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * (1.5 + 0.1 * pow(0.5 * length(st), 2.5) * r));

    vec3 c = raymarch(ro, rd);

    gl_FragColor = vec4(pow(c, vec3(1.0 / 2.2)), 1.0);
}