precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

const float PI = acos(-1.0);

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(2.0 * PI * (t * c + d));
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    st *= 1.5;
    for (float i = 0.0; i <= 4.0; i++) {
        st.y += 0.15 * sin(st.x * 2.0 + time);
        st *= rotate(10.23 * sin(10.0 * i));
        st *= 1.0 - 1.0 * exp(-2.0 * pow(length(3.0 * (mod(st + 0.5, 1.0) - 0.5)), 2.0));
    }
    
    vec3 c = palette(sin(15.0 * st.y), vec3(0.0, 0.2, 0.5), vec3(1.0, 0.8, 0.5), vec3(1.0), vec3(0.0, 0.1, 0.15));
    gl_FragColor = vec4(c, 1.0);
}