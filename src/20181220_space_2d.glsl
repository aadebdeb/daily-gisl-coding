/*
 * by @aa_debdeb (https://twitter.com/aa_debdeb)
 */

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float random(vec2 p){
    return fract(sin(dot(p,vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
    vec2 p = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);
    p.y += time * 0.1;

    vec3 color = vec3(0.0);
    for (int i = 15; i >= 1; i--) {
        vec2 q = p * 5.0 * float(i);
        vec2 idx = floor(q);
        q = mod(q, 1.0) - 0.5;
        float d = length(q);
        vec3 c = vec3(1.0) + random(idx + vec2(31.43, 24.43)) * vec3(random(idx + vec2(4.32, 2.19)), random(idx + vec2(7.23, 5.21)), random(idx + vec2((3.23, 1.43))));
        c = mix(c, vec3(1.0), random(idx + vec2(17.21, 11.32)));
        color += c * (1.0 - smoothstep(0.05, 0.20, d)) * smoothstep(0.95, 1.0, random(idx + vec2(4.12, 9.32)));
        p += vec2(19.24, 31.43);
    }
    gl_FragColor = vec4(color, 1.0);
}