// Chromatic Aberration
//
// by @aa_debdeb (https://twitter.com/aa_debdeb)
// 2018/11/26

#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.14159265359

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backBuffer;


float cylinder(vec3 p, float radius) {
	return length(p.xz) - radius;
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

vec3 rotateZ(vec3 p, float radian) {
	float s = sin(-radian);
	float c = cos(-radian);
	return vec3(c * p.x + s * p.y, -s * p.x + c * p.y, p.z);
}

vec3 translate(vec3 p, vec3 offset) {
	return p - offset;
}

vec3 repeat(vec3 p, vec3 interval) {
	return mod(p, interval) - 0.5 * interval;
}

float scene(vec3 p) {
	p = translate(p, vec3(0.0, 0.0, time * 8.0));
	p = rotateZ(p, pow(mod(time, 5.0) / 5.0, 0.75) * PI);
	p = repeat(p, vec3(5.0, 5.0, 3.5));
	return min(
		cylinder(rotateX(p, PI * 0.5), 0.1),
		min(
			cylinder(rotateY(p, PI * 0.5), 0.1),
			cylinder(rotateZ(p, PI * 0.5), 0.1)
		 )
	);
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

vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
vec3 lightColor = vec3(1.0);

vec3 _sample(vec2 st) {
	vec3 origin = vec3(0.0, 0.0, 10.0);
	vec3 target = vec3(0.0, 0.0, 0.0);
	vec3 ray;
	perspective(st, origin, target, vec3(0.0, 1.0, 0.0), 60.0, resolution.x / resolution.y, origin, ray);

	float t;
	if(raymarch(origin, ray, t)) {
		vec3 n = normal(origin + t * ray);
		vec3 c =  max(0.0, dot(n, lightDir)) * lightColor;
		return mix(c, vec3(0.0), smoothstep(10.0, 40.0, t));
	}
	return vec3(0.0);
}

vec3 chromaticAberration() {
	vec2 st = gl_FragCoord.xy / resolution;
	vec2 offset = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);

	float r = texture2D(backBuffer, st  + offset * 0.004).w;
	float g = texture2D(backBuffer, st).w;
	float b = texture2D(backBuffer, st + offset * 0.002).w;
	
	return vec3(r, g, b);
}

void main( void ) {
	vec2 st = gl_FragCoord.xy / resolution.xy;
	vec3 c = _sample(st);
	vec3 rgb = chromaticAberration();
	
	gl_FragColor = vec4(rgb, c.r);	
}