precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

float sdBox(vec3 p, vec3 b) {
    p = abs(p) - b;
    return length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0);
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float map(vec3 p) {
    float s = length(p) - 2.0;
    float b;
    {
        vec3 q = p - vec3(7.0, 0.0, 0.0);
        q.xy *= rotate(0.2);
        q.xz *= rotate(0.8);
        b = sdBox(q, vec3(2.0));
    }
    float t;
    {
        vec3 q = p - vec3(-7.0, 0.0, 0.0);
        q.xy *= rotate(2.4);
        q.yz *= rotate(2.4);
        t = sdTorus(q, vec2(3.0, 1.0));
    }
    return min(s, min(b, t));
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}

float random(vec3 x){
    return fract(sin(dot(x,vec3(12.9898, 78.233, 39.425))) * 43758.5453);
}

float valuenoise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);

    vec3 u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(
            mix(random(i + vec3(0.0, 0.0, 0.0)), random(i + vec3(1.0, 0.0, 0.0)), u.x),
            mix(random(i + vec3(0.0, 1.0, 0.0)), random(i + vec3(1.0, 1.0, 0.0)), u.x),
            u.y
        ),
        mix(
            mix(random(i + vec3(0.0, 0.0, 1.0)), random(i + vec3(1.0, 0.0, 1.0)), u.x),
            mix(random(i + vec3(0.0, 1.0, 1.0)), random(i + vec3(1.0, 1.0, 1.0)), u.x),
            u.y
        ),
        u.z);
}

vec3 random3(vec3 x) {
    return fract(sin(dot(x, vec3(32.43, 19.74, 66.85)) * vec3(12.9898, 51.431, 29.964)) * vec3(43758.5453, 71932.1354, 39215.4221));
}

float voronoi(vec3 p) {
    vec3 coord = floor(p);
    vec3 f = fract(p);

    float d = 1e6;
    for (float x = -1.0; x <= 1.0; x += 1.0) {
        for (float y = -1.0; y <= 1.0; y += 1.0) {
            for (float z = -1.0; z <= 1.0; z += 1.0) {
                vec3 offset = vec3(x, y, z);
                vec3 c = coord + offset;
                vec3 n = random3(c);
                d = min(d, length(offset + n - f));
            }
        }
    }
    return d;
}

float fbm(vec3 x) {
    float sum = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 3; i++) {
        sum += amp * valuenoise(x);
        amp *= 0.5;
        x *= 2.01;
        x.xy *= rotate(0.25);
    }
    return sum;
}

float heightmap(vec3 p) {
    return 1.0 - voronoi(p + 1242.34);
}

vec3 bumpmap(vec3 p, vec3 normal) {
    float h = heightmap(p);
    float e = 0.05;
    p *= 5.0;
    vec3 grad = vec3(
        heightmap(vec3(p.x + e, p.y, p.z)) - h,
        heightmap(vec3(p.x, p.y + e, p.z)) - h,
        heightmap(vec3(p.x, p.y, p.z + e)) - h
    ) / e;
    grad -= normal * dot(normal, grad);
    return normalize(normal - 0.02 * grad);
}

vec3 raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;
    for (int i = 0; i < 64; i++) {
        float d = map(p);
        p += d * rd;
        if (d < 0.01) {
            vec3 n = calcNormal(p);
            n = bumpmap(p, n);
            vec3 refDir =reflect(rd, n);
            vec3 lightDir = normalize(vec3(0.8, 1.0, 1.2));
            float dotNL = max(0.0, dot(n, lightDir));
            float dotLR = max(0.0, dot(lightDir, refDir));
            vec3 diffuse = vec3(0.05, 0.45, 0.5) * dotNL;
            vec3 specular = vec3(1.0) * pow(dotLR, 16.0);
            return diffuse + specular;
        }
    }
    return vec3(0.0);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec2 m = mouse * 2.0 - 1.0;

    vec3 ro = vec3(30.0 * m.x, 30.0 * m.y, 8.0);
    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = raymarch(ro, rd);

    gl_FragColor = vec4(c, 1.0);
}