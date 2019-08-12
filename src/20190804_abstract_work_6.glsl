precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

#define PI 3.14159265359
#define INV_PI 0.31830988618

float random(float x){
    return fract(sin(x * 12.9898) * 43758.5453);
}

float srandom(float x){
    return 2.0 * fract(sin(x * 12.9898) * 43758.5453) - 1.0;
} 

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(6.28318530718 * (t * c + d));
}

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2(c, s, -s, c);
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    for (float i = 1.0; i <= 5.0; i += 1.0) {
        st.y += 0.5 * sin(0.5 * float(i) * st.x + 0.1 * time + random(i * 1.53));
        st *= rotate(i * 5.0 * PI * srandom(i * 1.42));
    }

    float y = st.y * 100.0;

    vec3 c = palette(
        st.x * 0.2 + 0.1 * time + 0.05 * sin(0.5 * floor(y * INV_PI)) + 0.1 * random(floor(y * INV_PI)),
        vec3(0.5), vec3(0.5), vec3(1.0),
        vec3(0.0, 0.1, 0.12)) * pow(abs(sin(y)), 0.5);

    gl_FragColor = vec4(c, 1.0);
}