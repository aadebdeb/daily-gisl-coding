// Subsurface Scattering
//
// made by @aa_debdeb
// 2018/11/19
// http://glslsandbox.com/e#50426.1

#ifdef GL_ES
precision mediump float;
#endif

#define MULTI_SAMPLING
#define PI 3.14159265359

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

vec3 LightPosition = vec3(0.0, 10.0, 0.0);
vec3 LightColor = vec3(1.0, 1.0, 0.95);
vec3 SubstanceColor = vec3(0.24, 0.94, 0.74);

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
	p = rotateX(rotateY(p, time * 0.1), time * 0.2);
	//return torus(p, vec2(5.0, 1.0));
	return roundBox(p, vec3(1.0, 2.0, 3.0), 0.15);
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

vec3 calcColor(vec3 origin, vec3 ray) {
	float t;
	if(raymarch(origin, ray, t)) {
		vec3 posFromCamera = origin + t * ray;
		vec3 normal = normal(posFromCamera);
		vec3 lightDir = normalize(LightPosition - posFromCamera);
		raymarch(LightPosition, -lightDir, t);
		vec3 posFromLight = LightPosition + t * (-lightDir);
		float d = length(posFromCamera - posFromLight);
		float NdotL = dot(normal, lightDir);

		return SubstanceColor * LightColor * (max(0.0, NdotL) + 0.1 * max(1.0, 1.0 /  (d * 0.2 + 0.1)));
	}
	return vec3(0.0);
}

vec3 _sample(vec2 st) {
	vec3 origin = vec3(10.0 * cos(time * 0.3),  0.0 * sin(time * 0.15), 10.0 * sin(time * 0.3));
	vec3 target = vec3(0.0, 0.0, 0.0);
	vec3 ray;
	perspective(st, origin, target, vec3(0.0, 1.0, 0.0), 60.0, resolution.x / resolution.y, origin, ray);
	return calcColor(origin, ray);
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