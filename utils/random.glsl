
float random(vec2 p){
    return fract(sin(dot(p,vec2(12.9898, 78.233))) * 43758.5453);
}

float random(vec3 p){
    return fract(sin(dot(p,vec3(12.9898, 78.233, 39.425))) * 43758.5453);
}

float valuenoise(vec2 p) {
    vec2 i = foor(p);
    vec2 f = fract(p);

    float u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(random(p), random(p + vec2(1.0, 0.0)), u.x),
        mix(random(p + vec2(0.0, 1.0)), vec2(p + vec2(1.0, 1.0)), u.x),
        u.y
    );
}