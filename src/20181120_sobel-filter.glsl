// Sobel Filter
//
// by @aa_debdeb
// 2018/11/20
// http://glslsandbox.com/e#50463.0

#ifdef GL_ES
precision mediump float;
#endif

//#define MULTI_SAMPLING
#define PI 3.14159265359

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backBuffer;

float roundBox(vec3 p, vec3 size, float radius) {
	vec3 d = abs(p) - size;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0)) - radius;
}

float torus(vec3 p, vec2 t) {
	vec2 q = vec2(length(p.xz) - t.x, p.y);
	return length(q) - t.y;
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
	p = rotateX(rotateY(p, time * 0.2), time * 0.4);
	return torus(p, vec2(3.0, 1.0));
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
    vec3 right = normalize(cross(front, normalize(vup)));
    vec3 up = normalize(cross(right, front));
    origin = position;
    ray =  normalize(right * w * uv.x + up * h * uv.y + front); 
}

vec3 lightDir = normalize(vec3(0.0, 1.0, 0.0));

vec3 _sample(vec2 st) {
	vec3 pos = vec3(0.0, 8.0, 5.0);
	vec3 target = vec3(0.0, 0.0, 0.0);
	vec3 origin;
	vec3 ray;
	perspective(st, pos, target, vec3(0.0, 1.0, 0.0), 60.0, resolution.x / resolution.y, origin, ray);

	float t;
	if(raymarch(origin, ray, t)) {
		vec3 n = normal(origin + t * ray);
		vec3 ref = reflect(ray, n);
		vec3 diffuse = vec3(0.98, 0.95, 0.15) * max(0.0, dot(n, lightDir));
		vec3 specular = vec3(0.2, 0.6, 0.95) * pow(max(0.0, dot(ref, -ray)), 8.0);
		vec3 ambient = vec3(0.1);
		return  diffuse  + specular + ambient;
	}
	return vec3(0.9, 0.3, 0.4);
}

float greyScale(vec3 c) {
	return 0.299 * c.x + 0.587 * c.y + 0.114 * c.z;
}

float sobelFilter() {
	vec2 invResolution = 1.0 / resolution.xy;
	
	float ul = texture2D(backBuffer, (gl_FragCoord.xy + vec2(-1.0, 1.0)) * invResolution).w;
	float uc = texture2D(backBuffer, (gl_FragCoord.xy + vec2(0.0, 1.0)) * invResolution).w;
	float ur = texture2D(backBuffer, (gl_FragCoord.xy + vec2(1.0, 1.0)) * invResolution).w;
	float cl = texture2D(backBuffer, (gl_FragCoord.xy + vec2(-1.0, 0.0)) * invResolution).w;
	float cr = texture2D(backBuffer, (gl_FragCoord.xy + vec2(1.0, 0.0)) * invResolution).w;
	float ll = texture2D(backBuffer, (gl_FragCoord.xy + vec2(-1.0, -1.0)) * invResolution).w;
	float lc = texture2D(backBuffer, (gl_FragCoord.xy + vec2(0.0, -1.0)) * invResolution).w;
	float lr = texture2D(backBuffer, (gl_FragCoord.xy + vec2(1.0, -1.0)) * invResolution).w;
	
	float w = -ul - 2.0 * cl - ll + ur + 2.0 * cr + lr;
	float h = -ul -2.0 * uc - ur + ll + 2.0 * lc + lr;
	
	return sqrt(w * w + h * h);
}

void main( void ) {
	vec2 invResolution = 1.0 / resolution.xy;	
	vec2 st = gl_FragCoord.xy * invResolution;
	
	#ifdef MULTI_SAMPLING	
	vec3 c =  (_sample((gl_FragCoord.xy + vec2( 0.25,  0.25)) * invResolution) 
		+   _sample((gl_FragCoord.xy + vec2(-0.25, 0.25)) * invResolution) 
		+   _sample((gl_FragCoord.xy + vec2( 0.25, -0.25)) * invResolution) 
		+   _sample((gl_FragCoord.xy + vec2(-0.25, -0.25)) * invResolution)) / 4.0;
	#else
	vec3 c = _sample(st);
	#endif
	
	float g = greyScale(c);
	float s = sobelFilter();
	
	vec3 o = st.x + st.y > 1.0 ? c : vec3(s, s, s);
	
	gl_FragColor = vec4(o, g);	
}