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
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    for (float i = 1.0; i <= 5.0; i += 1.0) {
        vec2 uv = st;
        st.x = 1.54 * sin(1.64 * uv.y);
        st.y = 1.51 * sin(1.35 * uv.x);
        st *= rotate(-0.21 * length(4.15 * uv * i) + 0.05 * i * time);
    }

    vec3 c = palette(sin(2.2 * length(st)) * 0.5 + 0.5, vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.11, 0.165));
    gl_FragColor = vec4(c, 1.0);
}