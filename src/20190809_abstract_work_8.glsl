precision highp float;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

const float PI = acos(-1.0);

#define TIME_STEP 2.0

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

float map(vec3 p) {
    for (float i = 0.0; i < 5.0; i += 1.0) {
        p.xy *= rotate(1.734 + 0.3 * time);
        p.xz *= rotate(-0.791 - 0.21 * time);
        p += (0.55 * exp(-1.2 * mod(time, TIME_STEP))) * sin(1.45 * vec3(2.0, 1.5, 1.74) * p + 10.0 * time + i * vec3(4.32, 3.21, -1.91));
    }
    return length(p) - 2.5;
}

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(2.0 * PI * (t * c + d));
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.01, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

vec3 celing(vec3 ro, vec3 rd, float height) {
    float t = (height - ro.y) / rd.y;
    if (t <= 0.0) return vec3(0.2);
    vec3 p = ro + t * rd;
    vec2 q = abs(p.xz);
    q -= vec2(10.0, 15.0);
    float width1 = 3.0;
    float width2 = 5.0;
    return vec3(0.2) + vec3(0.95, 0.93, 0.8) * (1.0 - smoothstep(0.95 * width1, width1, abs(q.x))) * (1.0 - smoothstep(0.95 * width2, width2, abs(q.y)));
    return vec3(1.0) * step(length(p.xz), 5.0);
}

vec3 schlickFrensel(vec3 f90, float cosine) {
    return f90 + (1.0 - f90) * pow(1.0 - cosine, 5.0);
}

vec3 raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;
    for (int i = 0; i < 96; i++) {
        float d = map(p);
        p += d * rd;
        if (d < 0.001) {
            vec3 n = calcNormal(p);
            vec3 diff = 0.2 + vec3(0.5) * (dot(n, vec3(0.0, 1.0, 0.0)) * 0.5 + 0.5);
            vec3 ref = reflect(rd, n);
            vec3 fre = schlickFrensel(vec3(0.5), dot(n, ref));
            vec3 spec = 0.1 * fre * celing(p, ref, 20.0);

            return diff + spec;
        }
    }
    return mix(vec3(0.0), 0.7 * vec3(0.45, 1.0, 0.95), rd.y * 0.5 + 0.5);
}

void main( void ) {

    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    if (abs(st.x) < 0.75 && abs(st.y) < 0.75) {
        vec3 ro = vec3(0.0, 0.0, 10.0);
        vec3 ta = vec3(0.0);
        vec3 front = normalize(ta - ro);
        vec3 right = normalize(cross(front, vec3(0.0, 1.0, 0.0)));
        vec3 up = cross(right, front);
        vec3 rd = normalize(st.x * right + st.y * up + 1.5 * front);
        vec3 c = raymarch(ro, rd);
        gl_FragColor = vec4(pow(c, vec3(1.0 / 2.2)), 1.0);
    } else {

        st *= 2.2;
        st += sin(0.1 * st.x);
        for (float i = 0.0; i < 3.0; i++) {
            st.x += 1.34 * sin(1.12 * st.y + i * 0.015 * time) + 9.13;
            st.y += 1.53 * sin(2.54 * st.x - i * 0.023 * time) + 12.21;
            st *= rotate(i * 0.1 * abs(st.x) + 0.0042 * time);
        }
        vec3 c = palette(length(0.5 * st), vec3(0.5), vec3(0.5), vec3(1.0, 2.0, 1.5), vec3(1.0, 0.1, 0.02));
        gl_FragColor = vec4(c, 1.0);
    }
}