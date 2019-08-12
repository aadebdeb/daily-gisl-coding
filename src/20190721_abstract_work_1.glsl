precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

const float TWO_PI = 2.0 * acos(-1.0);

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(TWO_PI * (c * t + d));
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    for (int i = 0; i < 5; i++) {
        st = st.yx;
        float l = 8.0 * length(st);
        st.y = 0.85 * sin(1.65 * st.y + 0.45 * l + 0.12 * time);
        st.x = 1.45 * sin(1.5 * st.x + 0.31 * l + 0.15 * time);
    }

    vec3 c = palette(sin(5.0 * length(st) + 0.24 * time) * 0.5 + 0.5, vec3(0.5), vec3(0.5), vec3(1.0, 1.0, 0.5), vec3(0.8, 0.9, 0.3));

    gl_FragColor = vec4(c, 1.0);
}