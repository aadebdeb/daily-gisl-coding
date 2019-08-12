precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 c = vec3(1.0);

    for (int i = 0; i < 5; i++) {
        st = vec2(sin(3.24 * st.y) + 2.432 * length(st), sin(0.83 * st.x) + length(st + sin(float(i) * time)));
        if (fract(st.x) < 0.2) {
            st = -st.yx;
        }
        st = abs(st);
        c = mix(c, vec3(sin(vec3(float(i) + time * 0.32, float(i) * 10.0 + time + 34.433, float(i) * 10.0 + time + 342.3))), step(0.0, sin(0.2 * st.x) * sin(0.2 * st.y)));
        //c = mix(c, vec3(sin(vec3(float(i) + time * 0.32, float(i) * 10.0 + time + 34.433, float(i) * 10.0 + time + 342.3))), sin(0.1 * length(st)) * 0.5 + 0.5);
    }

    // for (int i = 0; i < 5; i++) {
    //     if (sin(st.x) > 0.0) {
    //         c *= 1.01;
    //         c = 1.0 - c;
    //     }
    //     st = st.yx;
    // }

    gl_FragColor = vec4(c, 1.0);
}