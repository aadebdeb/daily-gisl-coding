precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float getValue(vec2 st) {
    for (float i = 0.0; i < 5.0; i += 1.0) {
        st += vec2(0.15, -0.43) * sin(vec2(-2.4, 8.2) * st.yx + vec2(0.11, -0.065) * i * time);
        st *= 0.8;
    }
    return sin(50.0 * st.y) * 0.5 + 0.5;
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec2 soffset = vec2(0.02, -0.02);
    vec2 sst = st - soffset;
    float sv = getValue(sst);

    vec3 c = vec3(1.0);
    c = mix(c, vec3(0.8), (1.0 - smoothstep(0.3, 0.5, sv)) * step(max(abs(sst.x), abs(sst.y)), 0.8));

    float v = getValue(st);
    c = mix(c, vec3(1.0, 0.2, 0.05), (1.0 - smoothstep(0.4, 0.5, v)) * step(max(abs(st.x), abs(st.y)), 0.8));

    gl_FragColor = vec4(c, 1.0);
    return;
}