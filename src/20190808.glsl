precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

const float SPHERE_SPACING = 5.0;
const float SPHERE_RADIUS = 0.5;
const float PI = acos(-1.0);

float random(vec3 x){
    return fract(sin(dot(x,vec3(12.9898, 78.233, 39.425))) * 43758.5453);
}

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(2.0 * PI * (t * c + d));
}

void main(void) {
    vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

    vec3 ori = vec3(-0.5, -1.0, 5.0);
    vec3 tar = vec3(0.0);
    vec3 front = normalize(tar - ori);
    vec3 right = normalize(cross(front, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(right, front);
    vec3 dir = normalize(right * st.x + up * st.y + front * 1.5);

    vec4 c = vec4(0.0);
    for (float i = 0.0; i <= 5.0; i += 1.0) {
        float d = -i * 15.0;
        float t = (d - ori.z) / dir.z;

        if (t < 0.0) continue;

        vec3 p = ori + t * dir;
        p.y -= pow(i, 1.5) * time;
        vec2 id = floor(p.xy / SPHERE_SPACING);
        p = vec3(mod(p.xy, SPHERE_SPACING) - 0.5 * SPHERE_SPACING, p.z);
        p.y += 2.0 * sin(10.0 * random(vec3(id, i) * vec3(34.23, 19.32, 21.32)) + time);
        p.x += 2.0 * sin(10.0 * random(vec3(id, i) * vec3(7.01, 13.98, 17.25)) + time);
        float a1 = pow(max(0.0, sin(0.2 * time + 20.0 * random(vec3(id, i) * vec3(21.19, 15.32, 11.64)))), 5.0);
        float edge0 = max(0.0, (0.6 - i * 0.1)) * SPHERE_RADIUS;
        float edge1 = min(2.0, (1.0 + i * 0.1)) * SPHERE_RADIUS;
        float a2 = 1.0 - smoothstep(edge0, edge1, length(p.xy));
        float a = a1 * a2 * exp(-0.2 * i);
        c.a += a;
        c.rgb += a * palette(0.02 * i + 0.003 * time, vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.33, 0.67));
    }

    c.rgb += (1.0 - c.a) * vec3(0.995, 1.0, 0.99);
    gl_FragColor = vec4(c.rgb, 1.0);
}