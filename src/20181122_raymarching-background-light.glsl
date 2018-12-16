// Background Lighting
//
//by @aa_debdeb (https://twitter.com/aa_debdeb)
//2018/11/22

#ifdef GL_ES
precision mediump float;
#endif

//#define MULTI_SAMPLING
#define PI 3.14159265359

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float roundBox(vec3 p, vec3 size, float radius) {
	vec3 d = abs(p) - size;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0)) - radius;
}

float torus(vec3 p, vec2 size) {
	vec2 q = vec2(length(p.xz) - size.x, p.y);
	return length(q) - size.y;
}


vec3 rotateX(vec3 p, float radian) {
	float s = sin(-radian);
	float c = cos(-radian);
	return vec3(p.x, c * p.y - s * p.z, s * p.y + c * p.z);
}

vec3 rotateY(vec3 p, float radian) {
	float s = sin(-radian);
	float c = cos(-radian);
	return vec3(c * p.x + s * p.z, p.y, -s * p.x + c * p.z);
}

float scene(vec3 p) {
	vec3 p1 = rotateX(rotateY(p, time * 0.5), -time * 0.8);
	vec3 p2 = rotateX(rotateY(p, -time * 1.2), time * 1.9);
	return min(roundBox(p1, vec3(1.0), 0.1), torus(p2, vec2(3.5, 0.25)));
}

vec3 normal(vec3 p) {
	float d = 0.001;
	return normalize(vec3(
		scene(p + vec3(d, 0.0, 0.0)) - scene(p + vec3(-d, 0.0, 0.0)),
		scene(p + vec3(0.0, d, 0.0)) - scene(p + vec3(0.0, -d, 0.0)),
		scene(p + vec3(0.0, 0.0, d)) - scene(p + vec3(0.0, 0.0, -d))
	));
}

bool raymarch(vec3 origin, vec3 ray, out float t) {
	vec3 point = origin;
	t = 0.0;
	for (int i = 0; i < 64; i++) {
		float d = scene(point);
		point += ray * d;
		t += d;
		if (d < 0.01) {
			return true;
		}
	}
	return false;
}

void perspective(vec2 st, vec3 position, vec3 target, vec3 vup, float vfov, float aspect, out vec3 origin, out vec3 ray) {
    vec2 uv = st * 2.0 - 1.0;
    float radian = vfov * PI / 180.0;
    float h = tan(radian * 0.5);
    float w = h * aspect;
    vec3 front = normalize(target - position);
    vec3 right = cross(front, normalize(vup));
    vec3 up = cross(right, front);
    origin = position;
    ray =  normalize(right * w * uv.x + up * h * uv.y + front); 
}

vec3 backgroundColor = vec3(0.35, 0.75, 0.95);
float backgroundIntensity = 3.0;
float backgroundZ = -10.0;
vec3 background(vec3 pos, vec3 ray) {
	float d = (backgroundZ - pos.z) / ray.z;
	vec2 uv = pos.xy + d * ray.xy;
	return mix(
		(pow(sin(time * 2.0) * 0.5 + 0.5, 4.0) * 0.95 + 0.05) * backgroundIntensity * backgroundColor,
		vec3(0.0),
		pow(sin(pow(length(uv), 0.2) * 2.0 - time * 4.0), 2.0)
	);
}

vec3 rimLighting(vec3 p, vec3 n) {
	return background(p, vec3(0.0, 0.0, -1.0))  * pow((1.0 - max(0.0, dot(n, vec3(0.0, 0.0, 1.0)))), 5.0);
}

vec3 specularLighting(vec3 p, vec3 r) {
	return background(p, r) * pow(max(0.0, dot(r, vec3(0.0, 0.0, -1.0))), 12.0);
}

vec3 _sample(vec2 st) {
	vec3 origin = vec3(0.0, 0.0, 10.0);
	vec3 target = vec3(0.0, 0.0, 0.0);
	vec3 ray;
	perspective(st, origin, target, vec3(0.0, 1.0, 0.0), 60.0, resolution.x / resolution.y, origin, ray);

	float t;
	if(raymarch(origin, ray, t)) {
		vec3 p = origin + t * ray;
		vec3 n = normal(p);
		vec3 r = reflect(ray, n);
		return specularLighting(p, r) + rimLighting(p, n);
	}
	return background(origin, ray);
}

void main( void ) {
	vec2 st = gl_FragCoord.xy / resolution.xy;
	#ifdef MULTI_SAMPLING
	vec3 c =  (_sample((gl_FragCoord.xy + vec2( 0.25,  0.25)) / resolution.xy) 
		+   _sample((gl_FragCoord.xy + vec2(-0.25, 0.25)) / resolution.xy) 
		+   _sample((gl_FragCoord.xy + vec2( 0.25, -0.25)) / resolution.xy) 
		+   _sample((gl_FragCoord.xy + vec2(-0.25, -0.25)) / resolution.xy)) / 4.0;
	#else
	vec3 c = _sample(st);
	#endif
	gl_FragColor = vec4(c, 1.0);	
}