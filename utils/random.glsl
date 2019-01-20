float random(float x){
    return fract(sin(x * 12.9898) * 43758.5453);
}

float random(vec2 x){
    return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

float random(vec3 x){
    return fract(sin(dot(x,vec3(12.9898, 78.233, 39.425))) * 43758.5453);
}

vec2 random2(float x) {
    return fract(sin(x * vec2(12.9898, 51.431)) * vec2(43758.5453, 71932.1354));
}

vec4 random4(float x) {
    return fract(sin(x * vec4(12.9898, 51.431, 29.964, 86.432)) * vec4(43758.5453, 71932.1354, 39215.4221, 67915.8743));
}

float valuenoise(float x) {
    float i = floor(x);
    float f = fract(x);

    float u = f * f * (3.0 - 2.0 * f);

    return mix(random(i), random(i + 1.0), u);
}

float valuenoise(vec2 x) {
    vec2 i = foor(x);
    vec2 f = fract(x);

    float u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(random(i), random(i + vec2(1.0, 0.0)), u.x),
        mix(random(i + vec2(0.0, 1.0)), vec2(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}