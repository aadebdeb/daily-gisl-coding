float random(float x){
    return fract(sin(x * 12.9898) * 43758.5453);
}

float random(vec2 x){
    return fract(sin(dot(x,vec2(12.9898, 78.233))) * 43758.5453);
}

float random(vec3 x){
    return fract(sin(dot(x,vec3(12.9898, 78.233, 39.425))) * 43758.5453);
}

float random(vec4 x){
    return fract(sin(dot(x,vec4(12.9898, 78.233, 39.425, 27.196))) * 43758.5453);
}

vec2 random2(float x) {
    return fract(sin(x * vec2(12.9898, 51.431)) * vec2(43758.5453, 71932.1354));
}

vec3 random3(float x) {
    return fract(sin(x * vec3(12.9898, 51.431, 29.964)) * vec3(43758.5453, 71932.1354, 39215.4221));
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
    vec2 i = floor(x);
    vec2 f = fract(x);

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(random(i), random(i + vec2(1.0, 0.0)), u.x),
        mix(random(i + vec2(0.0, 1.0)), random(vec2(i + vec2(1.0, 1.0))), u.x),
        u.y
    );
}

float valuenoise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);

    vec3 u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(
            mix(random(i + vec3(0.0, 0.0, 0.0)), random(i + vec3(1.0, 0.0, 0.0)), u.x),
            mix(random(i + vec3(0.0, 1.0, 0.0)), random(i + vec3(1.0, 1.0, 0.0)), u.x),
            u.y
        ),
        mix(
            mix(random(i + vec3(0.0, 0.0, 1.0)), random(i + vec3(1.0, 0.0, 1.0)), u.x),
            mix(random(i + vec3(0.0, 1.0, 1.0)), random(i + vec3(1.0, 1.0, 1.0)), u.x),
            u.y
        ),
        u.z);
}

float valuenoise(vec4 x) {
  vec4 i = floor(x);
  vec4 f = fract(x);

  vec4 u = f * f * (3.0 - 2.0 * f);

  return mix(
    mix(
      mix(
          mix(random(i + vec4(0.0, 0.0, 0.0, 0.0)), random(i + vec4(1.0, 0.0, 0.0, 0.0)), u.x),
          mix(random(i + vec4(0.0, 1.0, 0.0, 0.0)), random(i + vec4(1.0, 1.0, 0.0, 0.0)), u.x),
          u.y
      ),
      mix(
          mix(random(i + vec4(0.0, 0.0, 1.0, 0.0)), random(i + vec4(1.0, 0.0, 1.0, 0.0)), u.x),
          mix(random(i + vec4(0.0, 1.0, 1.0, 0.0)), random(i + vec4(1.0, 1.0, 1.0, 0.0)), u.x),
          u.y
      ),
      u.z
    ),
    mix(
      mix(
          mix(random(i + vec4(0.0, 0.0, 0.0, 1.0)), random(i + vec4(1.0, 0.0, 0.0, 1.0)), u.x),
          mix(random(i + vec4(0.0, 1.0, 0.0, 1.0)), random(i + vec4(1.0, 1.0, 0.0, 1.0)), u.x),
          u.y
      ),
      mix(
          mix(random(i + vec4(0.0, 0.0, 1.0, 1.0)), random(i + vec4(1.0, 0.0, 1.0, 1.0)), u.x),
          mix(random(i + vec4(0.0, 1.0, 1.0, 1.0)), random(i + vec4(1.0, 1.0, 1.0, 1.0)), u.x),
          u.y
      ),
      u.z
    ),
    u.w
  );
}

