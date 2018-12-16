// by @aa_debdeb (https://twitter.com/aa_debdeb)
// 2018/12/07

#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.14159265359
#define RECIPROCAL_GAMMA 0.45454545454

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float box(vec3 p, vec3 s, float r) {
	vec3 d = abs(p) - s ;
	return length(max(d, 0.0)) - r + min(max(d.x, max(d.y, d.z)), 0.0);	
}

vec3 repeat(vec3 p, vec3 s) {
	return mod(p, s) - s * 0.5;
}

vec3 repeatIndex(vec3 p, vec3 s) {
	return p / s;
}

vec3 rotateX(vec3 p, float r) {
	float s = sin(r);
	float c = cos(r);
	p.yz *= mat2(c, -s, s, c);
	return p;
}

vec3 rotateY(vec3 p, float r) {
	float s = sin(r);
	float c = cos(r);
	p.zx *= mat2(c, -s, s, c);
	return p;
}

// rgb: color, w: distance
vec4 map(vec3 p) {
	p = rotateX(p, time * 0.5);
	p = rotateY(p, time * 0.7);
	vec3 q = repeat(p, vec3(1.0));
	vec3 m = floor(p / vec3(1.0));
	return max(
		vec4(vec3(0.2), box(p, vec3(3.0), 0.0)),
		vec4(mod(m.x + m.y + m.z, 2.0) < 0.5 ? vec3(1.0) : vec3(0.05, 0.15, 0.95), box(q, vec3(0.32), 0.1))
	);
}

vec3 normal(vec3 p) {
	float d = 0.01;
	return normalize(vec3(
		map(p + vec3(d, 0.0, 0.0)).w - map(p - vec3(d, 0.0, 0.0)).w,
		map(p + vec3(0.0, d, 0.0)).w - map(p - vec3(0.0, d, 0.0)).w,
		map(p + vec3(0.0, 0.0, d)).w - map(p - vec3(0.0, 0.0, d)).w
	));
}

vec3 F0 = vec3(0.95);

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
	
	return  D * G * F / (4.0 * dotNL * dotNV);
}

vec3 specular(vec3 normal, vec3 lightDir, vec3 viewDir, float roughness, vec3 specularColor, vec3 lightColor) {
	return specularColor * lightColor * brdfCookTorrance(normal, lightDir, viewDir, roughness) * max(0.0, dot(normal, lightDir));
}

float brdfLambert(vec3 normal, vec3 lightDir) {
	return max(0.0, dot(normal, lightDir)) / PI;
}

vec3 diffuse(vec3 normal, vec3 diffuseColor, vec3 lightColor, vec3 lightDir) {
	return diffuseColor * lightColor  * brdfLambert(normal, lightDir) * max(0.0, dot(normal, lightDir));
}

float ambientOcclusion(vec3 p, vec3 n) {
	float sum = 0.0;
	float scale = 0.5;
	for (float i = 1.0; i <= 5.0; i++) {
		float d = i * 0.2;
		float m = max(map(p + n * d).w, 0.0);
		sum += scale * (m / d);
		scale *= 0.5;
	}
	return sum;
}

vec3 lightColor1 = vec3(1.5);
vec3 lightDir1 = normalize(vec3(1.0));
vec3 lightColor2 = vec3(1.0);
vec3 lightDir2 = normalize(vec3(-1.0, -1.0, 3.0));
float metallic = 0.75;

vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
vec3 lightColor = vec3(1.0);
vec3 ambient = vec3(0.05);

vec3 raymarch(vec3 ro, vec3 rd) {
	vec3 p = ro;
	for (int i  = 0; i < 64; i++) {
		vec4 v = map(p);
		p += v.w * rd;
		if (v.w < 0.01) {
			vec3 n = normal(p);
			
			float ao = ambientOcclusion(p, n);
			vec3 dif = diffuse(n, v.rgb , lightColor1, lightDir1) + diffuse(n, v.rgb , lightColor2, lightDir2);
			vec3 spec = specular(n, lightDir1, -rd, 0.5, v.rgb, lightColor1) + specular(n, lightDir2, -rd, 0.5, v.rgb, lightColor2);
			return ((1.0 - metallic) * dif + metallic * spec + ambient) * ao;
		}
	}
	return vec3(-1.0);
}

vec3 background(vec2 st) {
	return mix(vec3(0.7), vec3(0.4), smoothstep(0.5, 1.5, length(st)));
}

void main( void ) {

	vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);
	
	vec3 ro = vec3(0.0, 0.0, 10.0);
	vec3 ta = vec3(0.0);
	vec3 z = normalize(ta - ro);
	vec3 x = normalize(cross(z, vec3(0.0, 1.0, 0.0)));
	vec3 y = normalize(cross(x, z));
	
	vec3 rd = normalize(x * st.x + y * st.y + z * 1.5);
	
	vec3 c = raymarch(ro, rd);
	if (c.r > 0.0) {
		c = pow(c, vec3(RECIPROCAL_GAMMA));
	} else {
		c = background(st);
	}
	
	gl_FragColor = vec4(c, 1.0);

}