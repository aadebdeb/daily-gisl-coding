precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    st *= 1.45;
    for (float i = 0.0; i < 5.0; i += 1.0) {
        st += 1.0 * sin(vec2(4.15, 1.24) * st.yx + i * vec2(0.14, 0.32) * time);
    }

    st = mod(10.0 * st, 5.0) - 2.5;
    vec3 c = vec3(1.0) * smoothstep(1.0, 0.5, length(st));
    gl_FragColor = vec4(c, 1.0);
}