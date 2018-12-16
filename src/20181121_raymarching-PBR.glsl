// Phisically Based Rendering
// http://glslsandbox.com/e#50488.0
//
// @aa_debdeb(https://twitter.com/aa_debdeb)
// 2018/11/21

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

float sphere(vec3 p, float radius) {
	return length(p) - radius;
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

vec3 translate(vec3 p, vec3 offset) {
	return p - offset;
}

float mysmooth(float d1, float d2, float k) {
	float h = clamp(0.5 +  0.5 * (d2 - d1) / k, 0.0, 1.0);
	return mix(d2, d1, h) - k * h * (1.0 - h);
}

float smoothSubtract(float d1, float d2, float k) {
	float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
	return mix(d2, -d1, h) + k * h * (1.0 - h);
}
	

float scene(vec3 p) {
	vec3 q = rotateX(rotateY(p, time * 0.1), time * 0.2);
	return  smoothSubtract(
			sphere(translate(p, vec3(1.4 * sin(time * 1.4), 2.4 * sin(time * 3.2), 3.2 * sin(time * 1.9))), 2.5),
			mysmooth(
				sphere(translate(p, vec3(3.0 * sin(time * 2.5), 3.4 * sin(time * 1.8), 2.3 * sin(time * 4.2))), 1.5),
				roundBox(q, vec3(1.5, 1.8, 2.4), 0.15),
				0.5),
			0.2
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

vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
const float lightIntensity = 2.0;
vec3 lightColor = vec3(1.0, 1.0, 0.95) * lightIntensity;
float refractiveIndex = 1.5;
float metallic = 0.8;

vec3 diffuseColor = vec3(0.5, 0.5, 0.3);
vec3 specularColor = vec3(1.0);
vec3 ambientColor = vec3(0.1);
vec3 F0 = vec3(0.5, 0.4, 0.3);

float beckmannNormalDistribution(float m, float dotNH) {
	float d2 = dotNH * dotNH;
	float d4 = d2 * d2;
	float a = 4.0 * m * m * d4;
	float b = exp(-((1.0 - d2) / d2) / m);
	return b / a;
}

float geometricAttenuation(float dotNH, float dotNL, float dotNV, float dotVH) {
	float d = 1.0 / dotVH;
	float a = dotNH * dotNL * d;
	float b = dotNH * dotNV * d;
	return min(1.0, min(a, b));
}

vec3 schlickFresnel(vec3 f0, float dotLH) {
	return f0 + (vec3(1.0) - f0) * pow((1.0 - dotLH), 5.0);
}

vec3 brdfCookTorrance(vec3 normal, vec3 lightDir, vec3 viewDir, float roughness) {
	float m = roughness * roughness;
	
	vec3 halfDir = normalize(lightDir + viewDir);
	
	float dotNL = dot(normal, lightDir);
	float dotNV = dot(normal, viewDir);
	float dotNH = dot(normal, halfDir);
	float dotLH = dot(lightDir, halfDir);
	float dotVH = dot(viewDir, halfDir);
	
	float D = beckmannNormalDistribution(m, dotNH);
	float G = geometricAttenuation(dotNH, dotNL, dotNV, dotVH);
	vec3 F = schlickFresnel(F0, dotLH);
	
	return specularColor * lightColor * D * G * F / (4.0 * dotNL * dotNV);
}

vec3 specular(vec3 normal, vec3 lightDir, vec3 viewDir, float roughness) {
	return specularColor * lightColor * brdfCookTorrance(normal, lightDir, viewDir, roughness) * max(0.0, dot(normal, lightDir));
}

float brdfLambert(vec3 normal, vec3 lightDir) {
	return max(0.0, dot(normal, lightDir)) / PI;
}

vec3 diffuse(vec3 normal, vec3 lightDir) {
	return diffuseColor * lightColor  * brdfLambert(normal, lightDir) * max(0.0, dot(normal, lightDir));
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

vec3 _sample(vec2 st) {
	vec3 origin = vec3(0.0, 0.0, 10.0);
	vec3 target = vec3(0.0, 0.0, 0.0);
	vec3 ray;
	perspective(st, origin, target, vec3(0.0, 1.0, 0.0), 60.0, resolution.x / resolution.y, origin, ray);

	float t;
	if(raymarch(origin, ray, t)) {
		vec3 normal = normal(origin + t * ray);
		vec3 viewDir = -ray;
		return (1.0 - metallic) * diffuse(normal, lightDir) + metallic * specular(normal, lightDir, viewDir, 0.5) + ambientColor;
	}
	return vec3(0.0);
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