precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float random(float x){
    return fract(sin(x * 12.9898) * 43758.5453);
}

float random(vec2 x){
    return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

float random(vec3 x){
    return fract(sin(dot(x,vec3(12.9898, 78.233, 39.425))) * 43758.5453);
}

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

const float PI = acos(-1.0);
const float TWO_PI = 2.0 * PI;

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(TWO_PI * (t * c + d));
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    st *= 5.0;
    for (float i = 1.0; i <= 5.0; i++) {
        vec2 id = floor(st / 2.0);
        if (random(vec3(i + floor(time), id.x, id.y)) < 0.2) {
            st = mod(st, 2.0) - 1.0;
            if (random(vec3(i, id.x, id.y)) < 0.5) {
                st = st.yx;
            }
        }
        st = abs(st);
        st += 0.5;
        st *= 1.0 + 0.05 * (2.0 * random(vec3(i, id.x, id.y)) - 1.0);
    }

    st *= 0.1;
    for (float i = 1.0; i <= 5.0; i++) {
        st = st.yx;
        float l = length(st);
        st.x = 1.43 * sin(st.x * 2.32 + l * 1.43 + 1.51 * time);
        st.y = 1.19 * sin(-st.y * 7.23 + l * 1.81 + -1.34 * time);
    }

    vec3 c = palette(0.5 * length(st), vec3(0.2), vec3(0.8), vec3(1.0), vec3(0.0, 0.01, 0.05));
    gl_FragColor = vec4(c, 1.0);
}