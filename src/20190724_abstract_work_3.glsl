precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

const float TWO_PI = 2.0 * acos(-1.0);

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(TWO_PI * (c * t + d));
}

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

void main(void) {
    vec3 st =  vec3((2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y), 0.25 * sin(0.15 * time));

    for (int i = 0; i < 3; i++) {
        vec3 uv =st;
        st.x = 1.25 * uv.z * sin(1.35 * length(uv - vec3(-0.85, 0.43, -0.21)) + 0.1 * float(i) * time);
        st.y = 1.2 * uv.x * sin(1.45 * length(uv - vec3(0.31, -0.19, 0.04)) + 0.11 * float(i) * time);
        st.z = 1.1 * uv.y * sin(1.52 * length(uv + vec3(0.14, -0.22, 0.21)) + 0.08 * float(i) * time);
        st.xz *= rotate(8.1 * length(uv) + 1.1 * time);
        st.yz *= rotate(-9.4 * length(uv) + 1.35 * time);
    }

    st *= 5.19;
    vec3 c = palette( smoothstep(max(abs(st.x), max(abs(st.y), abs(st.z))), 0.2, 0.5), vec3(0.75, 0.0, 0.5), vec3(0.25, 1.0, 0.5), vec3(1.0, 1.0, 1.0), vec3(0.12, 0.16, 0.18));

    gl_FragColor = vec4(c, 1.0);
}