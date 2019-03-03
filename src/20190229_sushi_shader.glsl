/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

precision highp float;

#define PI 3.14159265359

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

struct Intersection {
    float d;
    vec3 diffuse;
    vec3 specular;
    float shiness;
};

Intersection intersection(float d, vec3 diffuse, vec3 specular, float shiness) {
    Intersection isec;
    isec.d = d;
    isec.diffuse = diffuse;
    isec.specular = specular;
    isec.shiness = shiness;
    return isec;
}

Intersection intersection(float d, vec3 diffuse) {
    Intersection isec;
    isec.d = d;
    isec.diffuse = diffuse;
    isec.specular = vec3(0.0);
    isec.shiness = 1.0;
    return isec;
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

float fbm(vec3 x) {
    float sum = 0.0;
    float amp = 0.5;
    float scale = 1.0;
    for (int i = 0; i < 5; i++) {
        sum += amp * valuenoise(x);
        amp *= 0.5;
        x *= 2.1;
    }
    return sum;
}

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
} 

vec3 opBendX(vec3 p, float k) {
    float c = cos(k * p.x);
    float s = sin(k * p.x);
    mat2 m = mat2(c, -s, s, c);
    p.xy = m * p.xy;
    return p;
}

vec3 opBendZ(vec3 p, float k) {
    float c = cos(k * p.z);
    float s = sin(k * p.z);
    mat2 m = mat2(c, -s, s, c);
    p.zy = m * p.zy;
    return p;
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
    p = abs(p) - b;
    return length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0);
}

float sdRoundBox(vec3 p, vec3 b, float r) {
    p = abs(p) - b;
    return length(max(p, 0.0)) + min(max(p.x, max(p.y, p.z)), 0.0) - r;
}

float sdRect(vec2 p, vec2 b) {
    p = abs(p) - b;
    return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

float sdRoundRect(vec2 p, vec2 b, float r) {
    p = abs(p) - b;
    return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0) - r;
}

Intersection shari(vec3 p) {
    p.y -= 0.5;
    float r = 0.3;
    float d = sdRoundBox(p, vec3(0.8 - r, 0.5 - r, 0.5 - r), r);
    float disp = 0.1 * (0.5 * valuenoise(p * vec3(2.0, 4.0, 3.0) + vec3(8.23, 6.19, 6.12))
        + 0.5 * valuenoise(p * vec3(8.0, 12.0, 8.0) + vec3(16.43, 19.23, 26.32)));
    return intersection(d + disp, vec3(0.95, 0.95, 0.95));
}

Intersection netaMaguro(vec3 p) {
    p = opBendX(p, -0.2);
    p = opBendZ(p, -0.3);
    p .y -= 1.0;
    float r = 0.1;
    float d= sdRoundBox(p, vec3(1.2 -r, 0.1 - r, 0.5 -r), r);
    return intersection(d, vec3(1.0, 0.3, 0.5), 0.2 * vec3(1.0, 0.7, 0.7), 2.0);
}

Intersection sushiMaguro(vec3 p) {
    Intersection sd = shari(p);
    Intersection nd = netaMaguro(p);
    if (sd.d < nd.d) {
        return sd;
    } else {
        return nd;
    }
}

Intersection netaIka(vec3 p) {
    p = opBendX(p, -0.3);
    p = opBendZ(p, -0.35);
    p .y -= 1.0;
    float r = 0.05;
    float d= sdRoundBox(p, vec3(1.2 -r, 0.05 - r, 0.45 - r), r);
    float cut = sdBox(vec3(p.x, p.y - 0.05, mod(p.z, 0.08) - 0.04), vec3(1.1, 0.05, 0.015));
    return intersection(max(d, -cut), vec3(1.5), vec3(1.0), 1.0);
}

Intersection sushiIka(vec3 p) {
    Intersection sd = shari(p);
    Intersection nd = netaIka(p);
    if (sd.d < nd.d) {
        return sd;
    } else {
        return nd;
    }
}

vec3 tamagoColor(vec3 p) {
    float n = valuenoise(p * vec3(1.0, 2.0, 1.5) + vec3(34.19, 18.43, 21.53)) * 10.0;
    float v = sin(length(p.xz * vec2(10.0, 30.0) + n)) * 0.5 + 0.5;
    return mix(vec3(1.0, 1.0, 0.1), vec3(0.8, 0.7, 0.2), pow(v, 50.0));
}

Intersection netaTamago(vec3 p) {
    vec3 c = tamagoColor(p);
    p = opBendX(p, -0.15);
    p = opBendZ(p, -0.25);
    p .y -= 1.0;
    float r = 0.02;
    float d= sdRoundBox(p, vec3(1.2 -r, 0.15 - r, 0.45 -r), r);
    return intersection(d, c);
}

Intersection sushiTamago(vec3 p) {
    Intersection sd = shari(p);
    Intersection nd = netaTamago(p);
    Intersection nearest = sd;
    if (nd.d < nearest.d) {
        nearest = nd;
    }
    if (abs(p.x) < 0.3) {
        nearest.diffuse = vec3(0.0);
    }
    return nearest;
}

float sdGunkan(vec3 p, vec3 s, float r) {
    float d = sdRoundRect(p.xz, vec2(s.x - r, s.z -r), r);
    vec2 w = vec2(d, abs(p.y) - s.y);
    return length(max(w, 0.0)) + min(max(w.x, w.y), 0.0);
}

Intersection gunkan(vec3 p) {
    p.y -= 0.5;
    float r = 0.5;
    float d1 = sdGunkan(p, vec3(0.8, 0.5, 0.5), r);
    float d2 = sdGunkan(p, vec3(0.6, 0.5, 0.4), r);
    return intersection(max(d1, -d2), vec3(0.0));
}

Intersection netaIkura(vec3 p) {
    p.y -= 1.0;
    float d = 1e5;
    vec2 size = vec2(0.8, 0.4);
    vec2 half_size = size * 0.5;
    vec2 gap = size * 0.25;
    for (float x = 0.0; x <= 4.0; x++) {
        for (float y = 0.0; y <= 4.0; y++) {
            vec3 q = p;
            q.xz += gap * vec2(x, y) - half_size;
            q.y += random((x + y) * vec3(12.43, 19.39, 21.31)) * 0.2;
            d = min(d, sdSphere(q, 0.25));
        }
    }
    return intersection(d, vec3(1.3, 0.4, 0.0), vec3(1.0, 0.5, 0.0), 16.0);
}

Intersection sushiIkura(vec3 p) {
    Intersection sd = gunkan(p);
    Intersection nd = netaIkura(p);
    if (sd.d < nd.d) {
        return sd;
    } else {
        return nd;
    }
}

vec3 woodTexture(vec3 p) {
    float n = fbm(p * vec3(0.5, 2.0, 5.0) + vec3(132.23, 183.43, 152.91));
    float v = sin(n) * 0.5 + 0.5;
    return mix(vec3(0.9, 0.8, 0.3), vec3(0.8, 0.4, 0.2), pow(v, 7.0));
}

Intersection woodPlate(vec3 p) {
    vec3 size = vec3(5.0, 0.5, 3.0);
    vec3 q = vec3(abs(p.x), p.y + size.y, abs(p.z));
    float dh = sdBox(q, size);
    float dl = sdBox(q - vec3(size.x * 0.5, -2.0 * size.y, 0.0), vec3(size.x * 0.1, size.y, size.z));
    vec3 c = woodTexture(p);
    return intersection(min(dh, dl), c);
}

Intersection map(vec3 p) {
    p.xz *= rotate(-time * 0.5);
    Intersection nearest = intersection(1e5, vec3(0.0));
    vec3 mp = p;
    mp.x -= 3.0;
    mp.xz *= rotate(-PI / 3.0);
    Intersection maguro = sushiMaguro(mp);
    if (maguro.d < nearest.d) {
        nearest = maguro;
    }
    vec3 ip = p;
    ip.x -= 1.0;
    ip.xz *= rotate(-PI / 3.0);
    Intersection ika = sushiIka(ip);
    if (ika.d < nearest.d) {
        nearest = ika;
    }
    vec3 tp = p;
    tp.x += 1.0;
    tp.xz *= rotate(-PI / 3.0);
    Intersection tamago = sushiTamago(tp);
    if (tamago.d < nearest.d) {
        nearest = tamago;
    }
    vec3 ikp = p;
    ikp.x += 3.0;
    ikp.xz *= rotate(-PI / 3.0);
    Intersection ikura = sushiIkura(ikp);
    if (ikura.d < nearest.d) {
        nearest = ikura;
    }
    Intersection plate = woodPlate(p);
    if (plate.d < nearest.d) {
        nearest = plate;
    }

    return nearest;
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)).d - map(p - vec3(d, 0.0, 0.0)).d,
        map(p + vec3(0.0, d, 0.0)).d - map(p - vec3(0.0, d, 0.0)).d,
        map(p + vec3(0.0, 0.0, d)).d - map(p - vec3(0.0, 0.0, d)).d
    ));
}

vec3 LightDir = normalize(vec3(-1.0, 1.0, -1.0));

vec3 color(vec3 rd, vec3 normal, Intersection isec) {
    vec3 diff = isec.diffuse * max(0.5, dot(normal, LightDir));
    vec3 ref = reflect(rd, normal);
    vec3 spec = isec.specular * pow(max(0.0, dot(ref, LightDir)), isec.shiness);
    return diff + spec;
}

vec3 background(vec2 st) {
    float r = atan(st.y, st.x);
    float v = sin(r * 10.0);
    return mix(vec3(1.0, 0.3, 0.0), vec3(1.0, 1.0, 0.0), step(0.0, v));
}

vec3 raymarch(vec3 ro, vec3 rd, vec2 st) {
    vec3 p = ro;
    for (int i = 0; i < 64; i++) {
        Intersection isec = map(p);
        float d = 0.8 * isec.d;
        p += d * rd;
        if (d < 0.01) {
            vec3 n = calcNormal(p);
            return color(rd, n, isec);
        }
    }
    return background(st);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ro = vec3(0.0, 5.0, -7.0);
    vec3 ta = vec3(0.0);
    vec3 z = normalize(ta - ro);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 x = normalize(cross(z, up));
    vec3 y = normalize(cross(x, z));
    vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);

    vec3 c = raymarch(ro, rd, st);

    gl_FragColor = vec4(c, 1.0);
}