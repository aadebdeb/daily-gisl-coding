// by @aa_debdeb (https://twitter.com/aa_debdeb)

#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.151519

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;


float sphere(vec3 p, float r) {
	return length(p) - r;
}

float hex(vec3 p, vec2 h) {
	vec3 k = vec3(-0.8660254, 0.57735, 0.5);
	p = abs(p);
	p.xz -= 2.0 * min(dot(k.xz, p.xz), 0.0) * k.xz;
	vec2 d = vec2(
		length(p.xz - vec2(clamp(p.x, -k.y * h.x, k.y * h.x), h.x)) * sign(p.z - h.x),
		p.y - h.y
	);
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

vec3 rotateXZ(vec3 p, float r) {
	float c = cos(r);
	float s = sin(r);
	p.xz *= mat2(c, s, -s, c);
	return p;
}

float honeycomb(vec3 p) {	
	float r = 0.8;
	
	vec2 rep = vec2(2.0, 2.0 * sqrt(3.0)) * r;
	
	vec3 p1 = p;
	p1.xz +=vec2(r);
	p1.xz = mod(p1.xz, rep) - rep * 0.5;
	
	vec3 p2 = p;
	p2.xz -= vec2(0.0, (sqrt(3.0) - 1.0) *  r);
	p2.xz = mod(p2.xz, rep) - rep * 0.5;
	
	float maxSize = 0.5 * sqrt(3.0) * r;
	
	return min(
		hex(rotateXZ(p1, PI * 0.5), vec2(maxSize * 1.0, 5.0)),
		hex(rotateXZ(p2, PI * 0.5), vec2(maxSize * 1.0, 5.0))
	);
}

float map(vec3 p) {
	p.y = -abs(p.y);
	p.y += 7.0;
	return honeycomb(p);
}

vec3 normal(vec3 p) {
	float d = 0.01;
	return normalize(vec3(
		map(p + vec3(d, 0.0, 0.0)) - map(p - vec3(d, 0.0, 0.0)),
		map(p + vec3(0.0, d, 0.0)) - map(p - vec3(0.0, d, 0.0)),
		map(p + vec3(0.0, 0.0, d)) - map(p - vec3(0.0, 0.0, d))
	));
}

vec3 lightDir = normalize(vec3(0.0, 0.5, -1.0));
vec3 lightColor = vec3(1.0);
vec3 diffuseColor = vec3(0.3, 0.3, 0.7);
vec3 specularColor = vec3(1.0);
vec3 growColor = vec3(0.8, 0.5, 1.0);
float growIntensity = 2.0;

vec3 raymarch(vec3 ro, vec3 rd) {
	vec3 p = ro;
	for (int i = 0; i < 96; i++) {
		float t = map(p);
		p += t * rd;
		if (t < 0.01) {
			vec3 n = normal(p);
			vec3 grow = growColor * growIntensity * float(i) / 96.0;
			vec3 diffuse = diffuseColor * lightColor * max(dot(n, lightDir), 0.0) / PI;
			vec3 refDir = reflect(n, rd);
			vec3 specular = specularColor * lightColor * pow(max(dot(lightDir, refDir), 0.0), 16.0) * (16.0 + 2.0 ) / (2.0 * PI);
			return 0.7 * diffuse + 0.3 * specular +  grow;
		}
	}
	return growColor * growIntensity;
}

void main( void ) {
	vec2 st = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);
	
	
	float s = sin(time * 0.4);
	
	vec3 ro = vec3(s * 15.0, 0.0, 50.0 - time * 7.0);
	vec3 ta = vec3(0.0, 0.0, 0.0 - time * 7.0);
	vec3 z = normalize(ta - ro);
	vec3 up = normalize(vec3(-0.4 * s, 1.0, 0.0));
	vec3 x = normalize(cross(z, up));
	vec3 y = normalize(cross(x, z));
	vec3 rd = normalize(st.x * x  + st.y * y + z * 1.5);
	
	vec3 c = raymarch(ro, rd);
	
	gl_FragColor  = vec4(c, 1.0);
	
}