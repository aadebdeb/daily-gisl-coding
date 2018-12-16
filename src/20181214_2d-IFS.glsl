#ifdef GL_ES
precision mediump float;
#endif

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;


float sphere(vec2 p, float r) {
	return length(p) - r;
}

float box(vec2 p, vec2 s) {
	p = abs(p) - s;
	return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

vec2 translate(vec2 p, vec2 o) {
	return p - o;
}

mat2 rotate(float r) {
	float c = cos(r);
	float s = sin(r);
	return mat2(c, s, -s, c);
}

vec2 foldX(vec2 p) {
	p.x = abs(p.x);
	return p;
}

vec2 foldY(vec2 p) {
	p.y = abs(p.y);
	return p;
}

void main( void ) {

	vec2 p = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);
	
	float d = 9999.0;
	float size = 0.1;
	
	for (int i = 0; i < 7; i++) { 
		p *= rotate(0.5 * time / float(i + 1));
		p = foldX(p);
		p = foldY(p);
		p = translate(p, vec2(0.2, 0.1));
		d = min(d, box(p * rotate(1.0 * time * float(i)), vec2(size)));
		size *= 0.75;
	}
	
	
	vec3 c = vec3(1.0) * smoothstep(0.0, 0.01, abs(d));
	
	gl_FragColor = vec4(c, 1.0);
}