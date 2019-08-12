/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 c = vec3(0.0);
    for (int i = 0; i < 5; i++) {
        st.x = 0.92 * cos(5.4 * st.x);
        st.y = 0.85 * cos(3.5 * st.y);
        st *= rotate(10.0 * float(i) + 0.45 * time);
        c = mix(c, vec3(
            fract(0.2 * float(i)), 
            fract(0.5 * float(i)), fract(0.8 * float(i))), 
            sin(10.0 * st.x) * 0.5 + 0.5);
    }

    gl_FragColor = vec4(c, 1.0);
}