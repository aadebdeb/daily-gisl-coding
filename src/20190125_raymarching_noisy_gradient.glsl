precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float random(vec3 x){
    return fract(sin(dot(x,vec3(12.9898, 78.233, 39.425))) * 43758.5453);
}

float linearstep(float edge0, float edge1, float x) {
    return min(1.0, max(0.0, (x - edge0) / (edge1 - edge0)));
}

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

float sphere(vec3 p, float r) {
    return length(p) - r;
}

float rect(vec2 p, vec2 r) {
    p = abs(p) - r;
    return length(max(p, 0.0)) + min(0.0, max(p.x, p.y));
}

float box(vec3 p, vec3 r) {
    p = abs(p) - r;
    return length(max(p, 0.0)) + min(0.0, max(p.x, max(p.y, p.z)));
}

float distColumn(vec3 p) {
    float d = rect(p.xz * rotate(p.y * 0.5), vec2(1.0));
    {
        vec3 p = p;
        p.y = mod(p.y, 6.0) - 3.0;
        d = max(d, -sphere(p, 2.0));
        d = min(d, sphere(p, 1.5));
    }
    return d;
}

float distRepColumn(vec3 p) {
    p.x = abs(p.x);
    p.x -= 7.0;
    p.z = mod(p.z, 10.0) - 5.0;
    return distColumn(p);
}

float distSymbol(vec3 p) {
    float s = 1.0;
    float d = sphere(p, 1.5);
    p.xy *= rotate(0.4);
    for (int i = 0; i < 4; i++) {
    d = max(d, -rect(p.xy, vec2(1.3)) / s);
    d = min(d, sphere(p, 1.0) / s);
    p.xy *= rotate(-0.1);
    p *= 2.0;
    s *= 2.0;
    }
    return d;
}

float map(vec3 p) {

    float d1 = distRepColumn(p);
    float d2 = distSymbol(p);
    return min(d1, d2);
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

vec3 raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;
    for (int i = 0; i < 64; i++) {
        float d = map(p);
        p += d * rd;
        if (d < 0.01) {
            vec3 n = calcNormal(p);
            vec3 l = normalize(vec3(0.5, 0.8, -1.0));
            float dotNL = dot(n, l);
            vec3 v = mix(vec3(0.0), vec3(0.9), step(random(p) + 0.0001, linearstep(-0.5, 1.0, dotNL)));
            return v;
        }
    }
    return vec3(0.0);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(0.0, 0.0, -5.0);
    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = raymarch(ro, rd);

    gl_FragColor = vec4(c, 1.0);
}