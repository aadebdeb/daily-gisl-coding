#ifdef GL_ES
precision mediump float;
#endif

// 0: no fog, 1: linear fog, 2 : exp fog, 3 : exp2 fog
#define FOG_TYPE 3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float sphere(vec3 p, float r) {
	return length(p) - r;
}

vec3 repeatXZ(vec3 p, vec2 s) {
	p.xz = mod(p.xz, s) - 0.5 * s;
	return p;
}

float map(vec3 p) {
	p = repeatXZ(p, vec2(2.5));
	return sphere(p, 1.0);
}

vec3 normal(vec3 p) {
	float d = 0.01;
	return normalize(vec3(
		map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
		map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
		map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
	));
}

vec4 ground(vec3 ro, vec3 rd, float y) {
	if (rd.y > 0.0) {
		return vec4(vec3(0.0), 100);	
	}
	float d = (y - ro.y) / rd.y;
	vec2 xz = ro.xz + d * rd.xz;
	return sin(xz.x * 5.0) * sin(xz.y * 5.0) > 0.0 ? vec4(vec3(0.8), d) : vec4(vec3(0.4), d);
}

float linearFog(float d, float start, float end) {
	return clamp((end - d) / (end - start), 0.0, 1.0);
}

float expFog(float d, float density) {
	return exp(-d * density);
}

float exp2Fog(float d, float density) {
	float dd = d * density;
	return exp(-dd * dd);
}

void main( void ) {	
	vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);
	vec2 m = (2.0 * mouse - 1.0) * vec2(10.0, 8.0);
	
	vec3 ro = vec3(m.x, 10.0 + m.y, 5.0);
	vec3 ta = vec3(0.0);
	vec3 z = normalize(ta - ro);
	vec3 x = normalize(cross(z, vec3(0.0, 1.0, 0.0)));
	vec3 y = normalize(cross(x, z));
	vec3 rd = normalize(x * st.x + y * st.y + z);
	
	vec3 ld = normalize(vec3(1.0));
	vec3 lc = vec3(0.2, 0.9, 0.6);
	vec3 amb = vec3(0.1);
	
	float d = 0.0;
	vec3 p = ro;
	vec3 c = vec3(0.0);
	bool reached = false;
	for (int i = 0; i < 64; i++) {
		float t = map(p);
		d += t;
		p += t * rd;
		if (t < 0.01) {
			vec3 n = normal(p);
			c = lc * max(0.0, dot(n, ld)) + amb;
			reached = true;
			break;
		}
	}
	if (!reached) {
		vec4 res = ground(ro, rd, -0.5);
		c = res.rgb;
		d = res.w;
	}
	
	vec3 fogColor = vec3(1.0, 0.9, 0.95);
	if (FOG_TYPE == 1) {
		float f = linearFog(d, 30.0, 60.0);
		c = mix(fogColor, c, f);
	} else if (FOG_TYPE == 2) {
		float f = expFog(d, 0.05);
		c = mix(fogColor, c, f);
	} else if (FOG_TYPE == 3) {
		float f = exp2Fog(d, 0.05);
		c = mix(fogColor, c, f);
	}

	gl_FragColor = vec4(c, 1.0);
}