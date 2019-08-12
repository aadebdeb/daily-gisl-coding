/*
 * for raymarching
 *
 */

#define smin(a, b, k) (-log2(exp2(-k*a)+exp2(-k*b))/k)
#define sabs(p, k) (abs(p)-2.0*smin(0.0,abs(p),k))
#define smod(p, o, k) smin(abs(mod(p, o) - 0.5 * o), 0.5 * o, k)

vec2 pmod(vec2 p, float n) {
    float r = 2.0 * PI / n;
    float a = atan(p.x, p.y) + 0.5 * r;
    return p * rotate(-floor(a / r) * r);
}

float map(vec3 p) {
    p = mod(p, 4.0) - 2.0;
    return length(p) - 1.0;
}

vec3 calcNormal(vec3 p) {
    float d = 0.01;
    return normalize(vec3(
        map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
        map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
        map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
    ));
}